/*************************************************************************
 *
 * Copyright 2016 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 **************************************************************************/

/*
A query consists of node objects, one for each query condition. Each node contains pointers to all other nodes:

node1        node2         node3
------       -----         -----
node2*       node1*        node1*
node3*       node3*        node2*

The construction of all this takes part in query.cpp. Each node has two important functions:

    aggregate(start, end)
    aggregate_local(start, end)

The aggregate() function executes the aggregate of a query. You can call the method on any of the nodes
(except children nodes of OrNode and SubtableNode) - it has the same behaviour. The function contains
scheduling that calls aggregate_local(start, end) on different nodes with different start/end ranges,
depending on what it finds is most optimal.

The aggregate_local() function contains a tight loop that tests the condition of its own node, and upon match
it tests all other conditions at that index to report a full match or not. It will remain in the tight loop
after a full match.

So a call stack with 2 and 9 being local matches of a node could look like this:

aggregate(0, 10)
    node1->aggregate_local(0, 3)
        node2->find_first_local(2, 3)
        node3->find_first_local(2, 3)
    node3->aggregate_local(3, 10)
        node1->find_first_local(4, 5)
        node2->find_first_local(4, 5)
        node1->find_first_local(7, 8)
        node2->find_first_local(7, 8)

find_first_local(n, n + 1) is a function that can be used to test a single row of another condition. Note that
this is very simplified. There are other statistical arguments to the methods, and also, find_first_local() can be
called from a callback function called by an integer Array.


Template arguments in methods:
----------------------------------------------------------------------------------------------------

TConditionFunction: Each node has a condition from query_conditions.c such as Equal, GreaterEqual, etc

TConditionValue:    Type of values in condition column. That is, int64_t, float, int, bool, etc

TAction:            What to do with each search result, from the enums act_ReturnFirst, act_Count, act_Sum, etc

TResult:            Type of result of actions - float, double, int64_t, etc. Special notes: For act_Count it's
                    int64_t, for RLM_FIND_ALL it's int64_t which points at destination array.

TSourceColumn:      Type of source column used in actions, or *ignored* if no source column is used (like for
                    act_Count, act_ReturnFirst)


There are two important classes used in queries:
----------------------------------------------------------------------------------------------------
SequentialGetter    Column iterator used to get successive values with leaf caching. Used both for condition columns
                    and aggregate source column

AggregateState      State of the aggregate - contains a state variable that stores intermediate sum, max, min,
                    etc, etc.

*/

#ifndef REALM_QUERY_ENGINE_HPP
#define REALM_QUERY_ENGINE_HPP

#include <algorithm>
#include <functional>
#include <sstream>
#include <string>
#include <array>

#include <realm/array_basic.hpp>
#include <realm/array_key.hpp>
#include <realm/array_string.hpp>
#include <realm/array_binary.hpp>
#include <realm/array_integer_tpl.hpp>
#include <realm/array_timestamp.hpp>
#include <realm/array_decimal128.hpp>
#include <realm/array_fixed_bytes.hpp>
#include <realm/array_mixed.hpp>
#include <realm/array_list.hpp>
#include <realm/array_bool.hpp>
#include <realm/array_backlink.hpp>
#include <realm/column_type_traits.hpp>
#include <realm/metrics/query_info.hpp>
#include <realm/query_conditions.hpp>
#include <realm/table.hpp>
#include <realm/column_integer.hpp>
#include <realm/unicode.hpp>
#include <realm/util/miscellaneous.hpp>
#include <realm/util/serializer.hpp>
#include <realm/utilities.hpp>
#include <realm/index_string.hpp>

#include <map>
#include <unordered_set>

#if REALM_X86_OR_X64_TRUE && defined(_MSC_FULL_VER) && _MSC_FULL_VER >= 160040219
#include <immintrin.h>
#endif

namespace realm {

// Number of matches to find in best condition loop before breaking out to probe other conditions. Too low value gives
// too many constant time overheads everywhere in the query engine. Too high value makes it adapt less rapidly to
// changes in match frequencies.
const size_t findlocals = 64;

// Average match distance in linear searches where further increase in distance no longer increases query speed
// (because time spent on handling each match becomes insignificant compared to time spent on the search).
const size_t bestdist = 512;

// Minimum number of matches required in a certain condition before it can be used to compute statistics. Too high
// value can spent too much time in a bad node (with high match frequency). Too low value gives inaccurate statistics.
const size_t probe_matches = 4;

const size_t bitwidth_time_unit = 64;

typedef bool (*CallbackDummy)(int64_t);
using Evaluator = util::FunctionRef<bool(const Obj& obj)>;

class ParentNode {
    typedef ParentNode ThisType;

public:
    ParentNode() = default;
    virtual ~ParentNode() = default;

    virtual bool has_search_index() const
    {
        return false;
    }
    virtual const std::vector<ObjKey>& index_based_keys()
    {
        return s_dummy_keys;
    }

    void gather_children(std::vector<ParentNode*>& v)
    {
        m_children.clear();
        size_t i = v.size();
        v.push_back(this);

        if (m_child)
            m_child->gather_children(v);

        m_children = v;
        m_children.erase(m_children.begin() + i);
        m_children.insert(m_children.begin(), this);
    }

    double cost() const
    {
        // dt = 1/64 to 1. Match dist is 8 times more important than bitwidth
        return 8 * bitwidth_time_unit / m_dD + m_dT;
    }

    size_t find_first(size_t start, size_t end);

    bool match(const Obj& obj);

    virtual void init(bool will_query_ranges)
    {
        m_dD = 100.0;

        if (m_child)
            m_child->init(will_query_ranges);
    }

    void get_link_dependencies(std::vector<TableKey>& tables) const
    {
        collect_dependencies(tables);
        if (m_child)
            m_child->get_link_dependencies(tables);
    }

    void set_table(ConstTableRef table)
    {
        if (table == m_table)
            return;

        m_table = table;
        if (m_child)
            m_child->set_table(table);
        table_changed();
    }

    void set_cluster(const Cluster* cluster)
    {
        m_cluster = cluster;
        if (m_child)
            m_child->set_cluster(cluster);
        cluster_changed();
    }

    virtual void collect_dependencies(std::vector<TableKey>&) const
    {
    }

    virtual size_t find_first_local(size_t start, size_t end) = 0;
    virtual size_t find_all_local(size_t start, size_t end);

    virtual size_t aggregate_local(QueryStateBase* st, size_t start, size_t end, size_t local_limit,
                                   ArrayPayload* source_column);

    virtual std::string validate()
    {
        return m_child ? m_child->validate() : "";
    }

    ParentNode(const ParentNode& from);

    void add_child(std::unique_ptr<ParentNode> child)
    {
        if (m_child)
            m_child->add_child(std::move(child));
        else
            m_child = std::move(child);
    }

    virtual std::unique_ptr<ParentNode> clone() const = 0;

    virtual std::string describe(util::serializer::SerialisationState&) const
    {
        return "";
    }

    virtual std::string describe_condition() const
    {
        return "matches";
    }

    virtual std::string describe_expression(util::serializer::SerialisationState& state) const
    {
        std::string s;
        s = describe(state);
        if (m_child) {
            s = s + " and " + m_child->describe_expression(state);
        }
        return s;
    }

    bool consume_condition(ParentNode& other, bool ignore_indexes)
    {
        // We can only combine conditions if they're the same operator on the
        // same column and there's no additional conditions ANDed on
        if (m_condition_column_key != other.m_condition_column_key)
            return false;
        if (m_child || other.m_child)
            return false;
        if (typeid(*this) != typeid(other))
            return false;

        // If a search index is present, don't try to combine conditions since index search is most likely faster.
        // Assuming N elements to search and M conditions to check:
        // 1) search index present:                     O(log(N)*M)
        // 2) no search index, combine conditions:      O(N)
        // 3) no search index, conditions not combined: O(N*M)
        // In practice N is much larger than M, so if we have a search index, choose 1, otherwise if possible
        // choose 2. The exception is if we're inside a Not group or if the query is restricted to a view, as in those
        // cases end will always be start+1 and we'll have O(N*M) runtime even with a search index, so we want to
        // combine even with an index.
        if (has_search_index() && !ignore_indexes)
            return false;
        return do_consume_condition(other);
    }

    std::unique_ptr<ParentNode> m_child;
    std::vector<ParentNode*> m_children;
    mutable ColKey m_condition_column_key = ColKey(); // Column of search criteria
    ArrayPayload* m_source_column = nullptr;

    double m_dD;       // Average row distance between each local match at current position
    double m_dT = 1.0; // Time overhead of testing index i + 1 if we have just tested index i. > 1 for linear scans, 0
    // for index/tableview

    size_t m_probes = 0;
    size_t m_matches = 0;

protected:
    ConstTableRef m_table = ConstTableRef();
    const Cluster* m_cluster = nullptr;
    QueryStateBase* m_state = nullptr;
    static std::vector<ObjKey> s_dummy_keys;

    ColumnType get_real_column_type(ColKey key)
    {
        return m_table.unchecked_ptr()->get_real_column_type(key);
    }

private:
    virtual void table_changed()
    {
    }
    virtual void cluster_changed()
    {
        // TODO: Should eventually be pure
    }
    virtual bool do_consume_condition(ParentNode&)
    {
        return false;
    }
};


class ColumnNodeBase : public ParentNode {
protected:
    ColumnNodeBase(ColKey column_key)
    {
        m_condition_column_key = column_key;
    }

    ColumnNodeBase(const ColumnNodeBase& from)
        : ParentNode(from)
    {
    }

};

template <class LeafType>
class IntegerNodeBase : public ColumnNodeBase {
public:
    using TConditionValue = typename LeafType::value_type;
    // static const bool nullable = ColType::nullable;

protected:
    IntegerNodeBase(TConditionValue value, ColKey column_key)
        : ColumnNodeBase(column_key)
        , m_value(std::move(value))
    {
    }

    IntegerNodeBase(const IntegerNodeBase& from)
        : ColumnNodeBase(from)
        , m_value(from.m_value)
    {
    }

    void cluster_changed() override
    {
        // Assigning nullptr will cause the Leaf destructor to be called. Must
        // be done before assigning a new one. Otherwise the destructor will be
        // called after the constructor is called and that is unfortunate if
        // the object has the same address. (As in this case)
        m_array_ptr = nullptr;
        // Create new Leaf
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) LeafType(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    void init(bool will_query_ranges) override
    {
        ColumnNodeBase::init(will_query_ranges);

        m_dT = .25;
    }

    bool run_single() const
    {
        if (m_source_column == nullptr)
            return true;
        // Compare leafs to see if they are the same
        auto leaf = dynamic_cast<LeafType*>(m_source_column);
        return leaf ? leaf->get_ref() == m_leaf_ptr->get_ref() : false;
    }

    template <class TConditionFunction>
    size_t find_all_local(size_t start, size_t end)
    {
        if (run_single()) {
            m_leaf_ptr->template find<TConditionFunction>(m_value, start, end, m_state, nullptr);
        }
        else {
            auto callback = [this](size_t index) {
                auto val = m_source_column->get_any(index);
                return m_state->match(index, val);
            };
            m_leaf_ptr->template find<TConditionFunction>(m_value, start, end, m_state, callback);
        }

        return end;
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        return state.describe_column(ParentNode::m_table, ColumnNodeBase::m_condition_column_key) + " " +
               describe_condition() + " " + util::serializer::print_value(this->m_value);
    }


    // Search value:
    TConditionValue m_value;

    // Leaf cache
    using LeafCacheStorage = typename std::aligned_storage<sizeof(LeafType), alignof(LeafType)>::type;
    using LeafPtr = std::unique_ptr<LeafType, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const LeafType* m_leaf_ptr = nullptr;
};


template <class LeafType, class TConditionFunction>
class IntegerNode : public IntegerNodeBase<LeafType> {
    using BaseType = IntegerNodeBase<LeafType>;
    using ThisType = IntegerNode<LeafType, TConditionFunction>;

public:
    using TConditionValue = typename BaseType::TConditionValue;

    IntegerNode(TConditionValue value, ColKey column_key)
        : BaseType(value, column_key)
    {
    }
    IntegerNode(const IntegerNode& from)
        : BaseType(from)
    {
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        return this->m_leaf_ptr->template find_first<TConditionFunction>(this->m_value, start, end);
    }

    size_t find_all_local(size_t start, size_t end) override
    {
        return BaseType::template find_all_local<TConditionFunction>(start, end);
    }

    std::string describe_condition() const override
    {
        return TConditionFunction::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new ThisType(*this));
    }
};

template <size_t linear_search_threshold, class LeafType, class NeedleContainer>
static size_t find_first_haystack(LeafType& leaf, NeedleContainer& needles, size_t start, size_t end)
{
    // for a small number of conditions, it is faster to do a linear search than to compute the hash
    // the exact thresholds were found experimentally
    if (needles.size() < linear_search_threshold) {
        for (size_t i = start; i < end; ++i) {
            auto element = leaf.get(i);
            if (std::find(needles.begin(), needles.end(), element) != needles.end())
                return i;
        }
    }
    else {
        for (size_t i = start; i < end; ++i) {
            auto element = leaf.get(i);
            if (needles.count(element))
                return i;
        }
    }
    return realm::npos;
}

template <class LeafType>
class IntegerNode<LeafType, Equal> : public IntegerNodeBase<LeafType> {
public:
    using BaseType = IntegerNodeBase<LeafType>;
    using TConditionValue = typename BaseType::TConditionValue;
    using ThisType = IntegerNode<LeafType, Equal>;

    IntegerNode(TConditionValue value, ColKey column_key)
        : BaseType(value, column_key)
    {
    }
    ~IntegerNode()
    {
    }

    void init(bool will_query_ranges) override
    {
        BaseType::init(will_query_ranges);
        m_nb_needles = m_needles.size();

        if (has_search_index()) {
            // _search_index_init();
            m_result.clear();
            auto index = ParentNode::m_table->get_search_index(ParentNode::m_condition_column_key);
            index->find_all(m_result, BaseType::m_value);
            m_result_get = 0;
            m_last_start_key = ObjKey();
            IntegerNodeBase<LeafType>::m_dT = 0;
        }
    }

    bool do_consume_condition(ParentNode& node) override
    {
        auto& other = static_cast<ThisType&>(node);
        REALM_ASSERT(this->m_condition_column_key == other.m_condition_column_key);
        REALM_ASSERT(other.m_needles.empty());
        if (m_needles.empty()) {
            m_needles.insert(this->m_value);
        }
        m_needles.insert(other.m_value);
        return true;
    }

    bool has_search_index() const override
    {
        return this->m_table->search_index_type(IntegerNodeBase<LeafType>::m_condition_column_key) ==
               IndexType::General;
    }

    const std::vector<ObjKey>& index_based_keys() override
    {
        return m_result;
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        REALM_ASSERT(this->m_table);
        size_t s = realm::npos;

        if (start < end) {
            if (m_nb_needles) {
                s = find_first_haystack<22>(*this->m_leaf_ptr, m_needles, start, end);
            }
            else if (has_search_index()) {
                return do_search_index(m_last_start_key, m_result_get, m_result, BaseType::m_cluster, start, end);
            }
            else if (end - start == 1) {
                if (this->m_leaf_ptr->get(start) == this->m_value) {
                    s = start;
                }
            }
            else {
                s = this->m_leaf_ptr->template find_first<Equal>(this->m_value, start, end);
            }
        }

        return s;
    }

    size_t find_all_local(size_t start, size_t end) override
    {
        return BaseType::template find_all_local<Equal>(start, end);
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(this->m_condition_column_key);
        std::string col_descr = state.describe_column(this->m_table, this->m_condition_column_key);

        if (m_needles.empty()) {
            return col_descr + " " + Equal::description() + " " +
                   util::serializer::print_value(IntegerNodeBase<LeafType>::m_value);
        }

        // FIXME: once the parser supports it, print something like "column IN {n1, n2, n3}"
        std::string desc = "(";
        bool is_first = true;
        for (auto it : m_needles) {
            if (!is_first)
                desc += " or ";
            desc +=
                col_descr + " " + Equal::description() + " " + util::serializer::print_value(it); // "it" may be null
            is_first = false;
        }
        desc += ")";
        return desc;
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new ThisType(*this));
    }

private:
    std::unordered_set<TConditionValue> m_needles;
    std::vector<ObjKey> m_result;
    size_t m_nb_needles = 0;
    size_t m_result_get = 0;
    ObjKey m_last_start_key;

    IntegerNode(const IntegerNode<LeafType, Equal>& from)
        : BaseType(from)
        , m_needles(from.m_needles)
    {
    }
};


// This node is currently used for floats and doubles only
template <class LeafType, class TConditionFunction>
class FloatDoubleNode : public ParentNode {
public:
    using TConditionValue = typename LeafType::value_type;
    static const bool special_null_node = false;

    FloatDoubleNode(TConditionValue v, ColKey column_key)
        : m_value(v)
    {
        m_condition_column_key = column_key;
        m_dT = 1.0;
    }
    FloatDoubleNode(null, ColKey column_key)
        : m_value(null::get_null_float<TConditionValue>())
    {
        m_condition_column_key = column_key;
        m_dT = 1.0;
    }

    void cluster_changed() override
    {
        // Assigning nullptr will cause the Leaf destructor to be called. Must
        // be done before assigning a new one. Otherwise the destructor will be
        // called after the constructor is called and that is unfortunate if
        // the object has the same address. (As in this case)
        m_array_ptr = nullptr;
        // Create new Leaf
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) LeafType(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction cond;

        auto find = [&](bool nullability) {
            bool m_value_nan = nullability ? null::is_null_float(m_value) : false;
            for (size_t s = start; s < end; ++s) {
                TConditionValue v = m_leaf_ptr->get(s);
                REALM_ASSERT(!(null::is_null_float(v) && !nullability));
                if (cond(v, m_value, nullability ? null::is_null_float<TConditionValue>(v) : false, m_value_nan))
                    return s;
            }
            return not_found;
        };

        // This will inline the second case but no the first. Todo, use templated lambda when switching to c++14
        if (m_table->is_nullable(m_condition_column_key))
            return find(true);
        else
            return find(false);
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " + describe_condition() + " " +
               util::serializer::print_value(FloatDoubleNode::m_value);
    }
    std::string describe_condition() const override
    {
        return TConditionFunction::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new FloatDoubleNode(*this));
    }

    FloatDoubleNode(const FloatDoubleNode& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

protected:
    TConditionValue m_value;
    // Leaf cache
    using LeafCacheStorage = typename std::aligned_storage<sizeof(LeafType), alignof(LeafType)>::type;
    using LeafPtr = std::unique_ptr<LeafType, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const LeafType* m_leaf_ptr = nullptr;
};

template <class T, class TConditionFunction>
class SizeNode : public ParentNode {
public:
    SizeNode(int64_t v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
        m_dT = 20.0;
    }

    void cluster_changed() override
    {
        // Assigning nullptr will cause the Leaf destructor to be called. Must
        // be done before assigning a new one. Otherwise the destructor will be
        // called after the constructor is called and that is unfortunate if
        // the object has the same address. (As in this case)
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) LeafType(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        for (size_t s = start; s < end; ++s) {
            T v = m_leaf_ptr->get(s);
            if (v) {
                int64_t sz = v.size();
                if (TConditionFunction()(sz, m_value))
                    return s;
            }
        }
        return not_found;
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new SizeNode(*this));
    }

    SizeNode(const SizeNode& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

private:
    // Leaf cache
    using LeafType = typename ColumnTypeTraits<T>::cluster_leaf_type;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(LeafType), alignof(LeafType)>::type;
    using LeafPtr = std::unique_ptr<LeafType, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const LeafType* m_leaf_ptr = nullptr;

    int64_t m_value;
};

extern size_t size_of_list_from_ref(ref_type ref, Allocator& alloc, ColumnType col_type, bool nullable);

template <class TConditionFunction>
class SizeListNode : public ParentNode {
public:
    SizeListNode(int64_t v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
        m_dT = 30.0;
    }

    void reset_cache()
    {
        m_cached_col_type = m_condition_column_key.get_type();
        m_cached_nullable = m_condition_column_key.is_nullable();
        REALM_ASSERT_DEBUG(m_condition_column_key.is_list());
    }

    void cluster_changed() override
    {
        // Assigning nullptr will cause the Leaf destructor to be called. Must
        // be done before assigning a new one. Otherwise the destructor will be
        // called after the constructor is called and that is unfortunate if
        // the object has the same address. (As in this case)
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayList(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
        reset_cache();
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);
        reset_cache();
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        Allocator& alloc = m_table.unchecked_ptr()->get_alloc();
        for (size_t s = start; s < end; ++s) {
            ref_type ref = m_leaf_ptr->get(s);
            if (ref) {
                int64_t sz = size_of_list_from_ref(ref, alloc, m_cached_col_type, m_cached_nullable);
                if (TConditionFunction()(sz, m_value))
                    return s;
            }
        }
        return not_found;
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new SizeListNode(*this));
    }

    SizeListNode(const SizeListNode& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

private:
    // Leaf cache
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayList), alignof(ArrayList)>::type;
    using LeafPtr = std::unique_ptr<ArrayList, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayList* m_leaf_ptr = nullptr;

    int64_t m_value;

    ColumnType m_cached_col_type;
    bool m_cached_nullable;
};


template <class TConditionFunction>
class BinaryNode : public ParentNode {
public:
    using TConditionValue = BinaryData;
    static const bool special_null_node = false;

    BinaryNode(BinaryData v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
        m_dT = 100.0;
    }

    BinaryNode(null, ColKey column)
        : BinaryNode(BinaryData{}, column)
    {
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayBinary(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction condition;
        for (size_t s = start; s < end; ++s) {
            BinaryData value = m_leaf_ptr->get(s);
            if (condition(m_value.get(), value))
                return s;
        }
        return not_found;
    }

    virtual std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " +
               TConditionFunction::description() + " " + util::serializer::print_value(BinaryNode::m_value.get());
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new BinaryNode(*this));
    }

    BinaryNode(const BinaryNode& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

private:
    OwnedBinaryData m_value;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayBinary), alignof(ArrayBinary)>::type;
    using LeafPtr = std::unique_ptr<ArrayBinary, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayBinary* m_leaf_ptr = nullptr;
};

template <class TConditionFunction>
class BoolNode : public ParentNode {
public:
    using TConditionValue = bool;

    BoolNode(util::Optional<bool> v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
    }

    BoolNode(const BoolNode& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayBoolNull(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction condition;
        bool m_value_is_null = !m_value;
        for (size_t s = start; s < end; ++s) {
            util::Optional<bool> value = m_leaf_ptr->get(s);
            if (condition(value, m_value, !value, m_value_is_null))
                return s;
        }
        return not_found;
    }

    virtual std::string describe(util::serializer::SerialisationState& state) const override
    {
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " +
               TConditionFunction::description() + " " + util::serializer::print_value(m_value);
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new BoolNode(*this));
    }

private:
    util::Optional<bool> m_value;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayBoolNull), alignof(ArrayBoolNull)>::type;
    using LeafPtr = std::unique_ptr<ArrayBoolNull, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayBoolNull* m_leaf_ptr = nullptr;
};

class TimestampNodeBase : public ParentNode {
public:
    using TConditionValue = Timestamp;
    static const bool special_null_node = false;

    TimestampNodeBase(Timestamp v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
        m_dT = 2.0;
    }

    TimestampNodeBase(null, ColKey column)
        : TimestampNodeBase(Timestamp{}, column)
    {
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayTimestamp(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

protected:
    TimestampNodeBase(const TimestampNodeBase& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

    Timestamp m_value;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayTimestamp), alignof(ArrayTimestamp)>::type;
    using LeafPtr = std::unique_ptr<ArrayTimestamp, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayTimestamp* m_leaf_ptr = nullptr;
};

template <class TConditionFunction>
class TimestampNode : public TimestampNodeBase {
public:
    using TimestampNodeBase::TimestampNodeBase;

    size_t find_first_local(size_t start, size_t end) override
    {
        return m_leaf_ptr->find_first<TConditionFunction>(m_value, start, end);
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " +
               TConditionFunction::description() + " " + util::serializer::print_value(TimestampNode::m_value);
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new TimestampNode(*this));
    }

protected:
    TimestampNode(const TimestampNode& from, Transaction* tr)
        : TimestampNodeBase(from, tr)
    {
    }
};

class DecimalNodeBase : public ParentNode {
public:
    using TConditionValue = Decimal128;
    static const bool special_null_node = false;

    DecimalNodeBase(Decimal128 v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
    }

    DecimalNodeBase(null, ColKey column)
        : DecimalNodeBase(Decimal128{null()}, column)
    {
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayDecimal128(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);

        m_dD = 100.0;
    }

protected:
    DecimalNodeBase(const DecimalNodeBase& from)
        : ParentNode(from)
        , m_value(from.m_value)
    {
    }

    Decimal128 m_value;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayDecimal128), alignof(ArrayDecimal128)>::type;
    using LeafPtr = std::unique_ptr<ArrayDecimal128, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayDecimal128* m_leaf_ptr = nullptr;
};

template <class TConditionFunction>
class DecimalNode : public DecimalNodeBase {
public:
    using DecimalNodeBase::DecimalNodeBase;

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction cond;
        bool value_is_null = m_value.is_null();
        for (size_t i = start; i < end; i++) {
            Decimal128 val = m_leaf_ptr->get(i);
            if (cond(val, m_value, val.is_null(), value_is_null))
                return i;
        }
        return realm::npos;
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " +
               TConditionFunction::description() + " " + util::serializer::print_value(DecimalNode::m_value);
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new DecimalNode(*this));
    }

protected:
    DecimalNode(const DecimalNode& from, Transaction* tr)
        : DecimalNodeBase(from, tr)
    {
    }
};

size_t do_search_index(ObjKey& last_start_key, size_t& result_get, std::vector<ObjKey>& results,
                       const Cluster* cluster, size_t start, size_t end);

template <class ObjectType, class ArrayType>
class FixedBytesNodeBase : public ParentNode {
public:
    using TConditionValue = ObjectType;
    static const bool special_null_node = false;

    FixedBytesNodeBase(ObjectType v, ColKey column)
        : m_value(v)
    {
        m_condition_column_key = column;
    }

    FixedBytesNodeBase(null, ColKey column)
        : FixedBytesNodeBase(ObjectType{}, column)
    {
        m_value_is_null = true;
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayType(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);

        m_dD = 100.0;
    }

protected:
    FixedBytesNodeBase(const FixedBytesNodeBase& from)
        : ParentNode(from)
        , m_value(from.m_value)
        , m_value_is_null(from.m_value_is_null)
    {
    }

    ObjectType m_value;
    bool m_value_is_null = false;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayType), alignof(ArrayType)>::type;
    using LeafPtr = std::unique_ptr<ArrayType, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayType* m_leaf_ptr = nullptr;
};

template <class TConditionFunction, class ObjectType, class ArrayType>
class FixedBytesNode : public FixedBytesNodeBase<ObjectType, ArrayType> {
public:
    using FixedBytesNodeBase<ObjectType, ArrayType>::FixedBytesNodeBase;

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction cond;
        for (size_t i = start; i < end; i++) {
            util::Optional<ObjectType> val = this->m_leaf_ptr->get(i);
            if (val) {
                if (cond(*val, this->m_value, false, this->m_value_is_null))
                    return i;
            }
            else {
                if (cond(ObjectType{}, this->m_value, true, this->m_value_is_null))
                    return i;
            }
        }
        return realm::npos;
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(this->m_condition_column_key);
        return state.describe_column(ParentNode::m_table, this->m_condition_column_key) + " " +
               TConditionFunction::description() + " " +
               (this->m_value_is_null ? util::serializer::print_value(realm::null())
                                      : util::serializer::print_value(this->m_value));
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new FixedBytesNode(*this));
    }

protected:
    FixedBytesNode(const FixedBytesNode& from, Transaction* tr)
        : FixedBytesNode(from, tr)
    {
    }
};

template <class ObjectType, class ArrayType>
class FixedBytesNode<Equal, ObjectType, ArrayType> : public FixedBytesNodeBase<ObjectType, ArrayType> {
public:
    using FixedBytesNodeBase<ObjectType, ArrayType>::FixedBytesNodeBase;
    using BaseType = FixedBytesNodeBase<ObjectType, ArrayType>;

    void init(bool will_query_ranges) override
    {
        BaseType::init(will_query_ranges);

        if (!this->m_value_is_null) {
            m_optional_value = this->m_value;
        }

        if (has_search_index()) {
            // _search_index_init();
            m_result.clear();
            auto index = BaseType::m_table->get_search_index(BaseType::m_condition_column_key);
            index->find_all(m_result, m_optional_value);
            m_result_get = 0;
            m_last_start_key = ObjKey();
            this->m_dT = 0;
        }
    }

    const std::vector<ObjKey>& index_based_keys() override
    {
        return m_result;
    }

    bool has_search_index() const override
    {
        return this->m_table->search_index_type(BaseType::m_condition_column_key) == IndexType::General;
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        REALM_ASSERT(this->m_table);
        size_t s = realm::npos;

        if (start < end) {
            if (has_search_index()) {
                return do_search_index(m_last_start_key, m_result_get, m_result, this->m_cluster, start, end);
            }

            if (end - start == 1) {
                if (this->m_leaf_ptr->get(start) == m_optional_value) {
                    s = start;
                }
            }
            else {
                s = this->m_leaf_ptr->find_first(m_optional_value, start, end);
            }
        }

        return s;
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(this->m_condition_column_key);
        return state.describe_column(ParentNode::m_table, this->m_condition_column_key) + " " + Equal::description() +
               " " +
               (this->m_value_is_null ? util::serializer::print_value(realm::null())
                                      : util::serializer::print_value(this->m_value));
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new FixedBytesNode(*this));
    }

protected:
    FixedBytesNode(const FixedBytesNode& from, Transaction* tr)
        : FixedBytesNode(from, tr)
    {
    }
    util::Optional<ObjectType> m_optional_value;
    std::vector<ObjKey> m_result;
    size_t m_result_get = 0;
    ObjKey m_last_start_key;
};


template <typename T>
using ObjectIdNode = FixedBytesNode<T, ObjectId, ArrayObjectIdNull>;
template <typename T>
using UUIDNode = FixedBytesNode<T, UUID, ArrayUUIDNull>;

class MixedNodeBase : public ParentNode {
public:
    using TConditionValue = Mixed;
    static const bool special_null_node = false;

    MixedNodeBase(Mixed v, ColKey column)
        : m_value(v)
        , m_value_is_null(v.is_null())
    {
        REALM_ASSERT(column.get_type() == col_type_Mixed);
        get_ownership();
        m_condition_column_key = column;
    }

    MixedNodeBase(null, ColKey column)
        : MixedNodeBase(Mixed{}, column)
    {
        m_value_is_null = true;
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayMixed(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);

        m_dD = 100.0;
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        std::string value;
        if (m_value.is_type(type_TypedLink)) {
            value = util::serializer::print_value(m_value.get<ObjLink>(), state.group);
        }
        else {
            value = util::serializer::print_value(m_value);
        }
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " + this->describe_condition() +
               " " + value;
    }

protected:
    MixedNodeBase(const MixedNodeBase& from)
        : ParentNode(from)
        , m_value(from.m_value)
        , m_value_is_null(from.m_value_is_null)
    {
        get_ownership();
    }

    void get_ownership()
    {
        if (m_value.is_type(type_String, type_Binary)) {
            auto bin = m_value.get_binary();
            m_buffer = OwnedBinaryData(bin.data(), bin.size());
            auto tmp = m_buffer.get();
            if (m_value.is_type(type_String)) {
                m_value = Mixed(StringData(tmp.data(), tmp.size()));
            }
            else {
                m_value = Mixed(tmp);
            }
        }
    }

    QueryValue m_value;
    OwnedBinaryData m_buffer;
    bool m_value_is_null = false;
    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayMixed), alignof(ArrayMixed)>::type;
    using LeafPtr = std::unique_ptr<ArrayMixed, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayMixed* m_leaf_ptr = nullptr;
};

template <class TConditionFunction>
class MixedNode : public MixedNodeBase {
public:
    using MixedNodeBase::MixedNodeBase;

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction cond;
        for (size_t i = start; i < end; i++) {
            QueryValue val(m_leaf_ptr->get(i));
            if constexpr (realm::is_any_v<TConditionFunction, BeginsWith, BeginsWithIns, EndsWith, EndsWithIns, Like,
                                          LikeIns, NotEqualIns, Contains, ContainsIns>) {
                // For some strange reason the parameters are swapped for string conditions
                if (cond(m_value, val))
                    return i;
            }
            else {
                if (cond(val, m_value))
                    return i;
            }
        }
        return realm::npos;
    }

    virtual std::string describe_condition() const override
    {
        return TConditionFunction::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new MixedNode(*this));
    }

protected:
    MixedNode(const MixedNode& from, Transaction* tr)
        : MixedNode(from, tr)
    {
    }
};

template <>
class MixedNode<Equal> : public MixedNodeBase {
public:
    MixedNode(Mixed v, ColKey column)
        : MixedNodeBase(v, column)
    {
    }
    MixedNode(const MixedNode<Equal>& other)
        : MixedNodeBase(other)
        , m_has_search_index(other.m_has_search_index)
    {
    }
    void init(bool will_query_ranges) override;

    void cluster_changed() override
    {
        // If we use searchindex, we do not need further access to clusters
        if (!m_has_search_index) {
            MixedNodeBase::cluster_changed();
        }
    }

    void table_changed() override
    {
        m_has_search_index = m_table.unchecked_ptr()->search_index_type(m_condition_column_key) == IndexType::General;
    }

    bool has_search_index() const override
    {
        return m_has_search_index;
    }

    size_t find_first_local(size_t start, size_t end) override;

    virtual std::string describe_condition() const override
    {
        return Equal::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new MixedNode<Equal>(*this));
    }

protected:
    std::vector<ObjKey> m_index_matches;

    ObjKey m_actual_key;
    ObjKey m_last_start_key;
    size_t m_results_start;
    size_t m_results_ndx;
    size_t m_results_end;
    bool m_has_search_index = false;

    const std::vector<ObjKey>& index_based_keys() override
    {
        return m_index_matches;
    }
};

class StringNodeBase : public ParentNode {
public:
    using TConditionValue = StringData;
    static const bool special_null_node = true;

    StringNodeBase(StringData v, ColKey column)
        : m_value(v.is_null() ? util::none : util::make_optional(std::string(v)))
    {
        m_condition_column_key = column;
        m_dT = 10.0;
    }

    void table_changed() override
    {
        m_is_string_enum = m_table.unchecked_ptr()->is_enumerated(m_condition_column_key);
    }

    void cluster_changed() override
    {
        // Assigning nullptr will cause the Leaf destructor to be called. Must
        // be done before assigning a new one. Otherwise the destructor will be
        // called after the constructor is called and that is unfortunate if
        // the object has the same address. (As in this case)
        m_array_ptr = nullptr;
        // Create new Leaf
        m_array_ptr = LeafPtr(new (&m_leaf_cache_storage) ArrayString(m_table.unchecked_ptr()->get_alloc()));
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);

        m_probes = 0;
        m_matches = 0;
        m_end_s = 0;
        m_leaf_start = 0;
        m_leaf_end = 0;
    }

    virtual void clear_leaf_state()
    {
        m_array_ptr = nullptr;
    }

    StringNodeBase(const StringNodeBase& from)
        : ParentNode(from)
        , m_value(from.m_value)
        , m_is_string_enum(from.m_is_string_enum)
    {
    }

    virtual std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        StringData sd;
        if (bool(StringNodeBase::m_value)) {
            sd = StringData(*StringNodeBase::m_value);
        }
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " + describe_condition() + " " +
               util::serializer::print_value(sd);
    }

protected:
    util::Optional<std::string> m_value;

    using LeafCacheStorage = typename std::aligned_storage<sizeof(ArrayString), alignof(ArrayString)>::type;
    using LeafPtr = std::unique_ptr<ArrayString, PlacementDelete>;
    LeafCacheStorage m_leaf_cache_storage;
    LeafPtr m_array_ptr;
    const ArrayString* m_leaf_ptr = nullptr;

    bool m_is_string_enum = false;

    size_t m_end_s = 0;
    size_t m_leaf_start = 0;
    size_t m_leaf_end = 0;

    inline StringData get_string(size_t s)
    {
        return m_leaf_ptr->get(s);
    }
};

// Conditions for strings. Note that Equal is specialized later in this file!
template <class TConditionFunction>
class StringNode : public StringNodeBase {
public:
    StringNode(StringData v, ColKey column)
        : StringNodeBase(v, column)
    {
        auto upper = case_map(v, true);
        auto lower = case_map(v, false);
        if (!upper || !lower) {
            throw InvalidArgument(util::format("Malformed UTF-8: %1", v));
        }
        else {
            m_ucase = std::move(*upper);
            m_lcase = std::move(*lower);
        }
    }

    void init(bool will_query_ranges) override
    {
        StringNodeBase::init(will_query_ranges);
        clear_leaf_state();
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        TConditionFunction cond;

        for (size_t s = start; s < end; ++s) {
            StringData t = get_string(s);

            if (cond(StringData(m_value), m_ucase.c_str(), m_lcase.c_str(), t))
                return s;
        }
        return not_found;
    }

    virtual std::string describe_condition() const override
    {
        return TConditionFunction::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new StringNode<TConditionFunction>(*this));
    }

    StringNode(const StringNode& from)
        : StringNodeBase(from)
        , m_ucase(from.m_ucase)
        , m_lcase(from.m_lcase)
    {
    }

protected:
    std::string m_ucase;
    std::string m_lcase;
};

// Specialization for Contains condition on Strings - we specialize because we can utilize Boyer-Moore
template <>
class StringNode<Contains> : public StringNodeBase {
public:
    StringNode(StringData v, ColKey column)
        : StringNodeBase(v, column)
        , m_charmap()
    {
        if (v.size() == 0)
            return;

        // Build a dictionary of char-to-last distances in the search string
        // (zero indicates that the char is not in needle)
        size_t last_char_pos = v.size() - 1;
        for (size_t i = 0; i < last_char_pos; ++i) {
            // we never jump longer increments than 255 chars, even if needle is longer (to fit in one byte)
            uint8_t jump = last_char_pos - i < 255 ? static_cast<uint8_t>(last_char_pos - i) : 255;

            unsigned char c = v[i];
            m_charmap[c] = jump;
        }
        m_dT = 50.0;
    }

    void init(bool will_query_ranges) override
    {
        StringNodeBase::init(will_query_ranges);
        clear_leaf_state();
    }


    size_t find_first_local(size_t start, size_t end) override
    {
        Contains cond;

        for (size_t s = start; s < end; ++s) {
            StringData t = get_string(s);

            if (cond(StringData(m_value), m_charmap, t))
                return s;
        }
        return not_found;
    }

    virtual std::string describe_condition() const override
    {
        return Contains::description();
    }


    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new StringNode<Contains>(*this));
    }

    StringNode(const StringNode& from)
        : StringNodeBase(from)
        , m_charmap(from.m_charmap)
    {
    }

protected:
    std::array<uint8_t, 256> m_charmap;
};

// Specialization for ContainsIns condition on Strings - we specialize because we can utilize Boyer-Moore
template <>
class StringNode<ContainsIns> : public StringNodeBase {
public:
    StringNode(StringData v, ColKey column)
        : StringNodeBase(v, column)
        , m_charmap()
    {
        auto upper = case_map(v, true);
        auto lower = case_map(v, false);
        if (!upper || !lower) {
            throw query_parser::InvalidQueryError(util::format("Malformed UTF-8: %1", v));
        }
        else {
            m_ucase = std::move(*upper);
            m_lcase = std::move(*lower);
        }

        if (v.size() == 0)
            return;

        // Build a dictionary of char-to-last distances in the search string
        // (zero indicates that the char is not in needle)
        size_t last_char_pos = m_ucase.size() - 1;
        for (size_t i = 0; i < last_char_pos; ++i) {
            // we never jump longer increments than 255 chars, even if needle is longer (to fit in one byte)
            uint8_t jump = last_char_pos - i < 255 ? static_cast<uint8_t>(last_char_pos - i) : 255;

            unsigned char uc = m_ucase[i];
            unsigned char lc = m_lcase[i];
            m_charmap[uc] = jump;
            m_charmap[lc] = jump;
        }
        m_dT = 75.0;
    }

    void init(bool will_query_ranges) override
    {
        StringNodeBase::init(will_query_ranges);
        clear_leaf_state();
    }


    size_t find_first_local(size_t start, size_t end) override
    {
        ContainsIns cond;

        for (size_t s = start; s < end; ++s) {
            StringData t = get_string(s);
            // The current behaviour is to return all results when querying for a null string.
            // See comment above Query_NextGen_StringConditions on why every string including "" contains null.
            if (!bool(m_value)) {
                return s;
            }
            if (cond(StringData(m_value), m_ucase.c_str(), m_lcase.c_str(), m_charmap, t))
                return s;
        }
        return not_found;
    }

    virtual std::string describe_condition() const override
    {
        return ContainsIns::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new StringNode<ContainsIns>(*this));
    }

    StringNode(const StringNode& from)
        : StringNodeBase(from)
        , m_charmap(from.m_charmap)
        , m_ucase(from.m_ucase)
        , m_lcase(from.m_lcase)
    {
    }

protected:
    std::array<uint8_t, 256> m_charmap;
    std::string m_ucase;
    std::string m_lcase;
};

class StringNodeEqualBase : public StringNodeBase {
public:
    StringNodeEqualBase(StringData v, ColKey column)
        : StringNodeBase(v, column)
    {
    }
    StringNodeEqualBase(const StringNodeEqualBase& from)
        : StringNodeBase(from)
        , m_has_search_index(from.m_has_search_index)
    {
    }

    void init(bool) override;

    bool has_search_index() const override
    {
        return m_has_search_index;
    }

    void cluster_changed() override
    {
        // If we use searchindex, we do not need further access to clusters
        if (!m_has_search_index) {
            StringNodeBase::cluster_changed();
        }
    }

    size_t find_first_local(size_t start, size_t end) override;

    virtual std::string describe_condition() const override
    {
        return Equal::description();
    }

protected:
    ObjKey m_actual_key;
    ObjKey m_last_start_key;
    size_t m_results_start;
    size_t m_results_ndx;
    size_t m_results_end;
    bool m_has_search_index = false;

    inline BinaryData str_to_bin(const StringData& s) noexcept
    {
        return BinaryData(s.data(), s.size());
    }

    virtual ObjKey get_key(size_t ndx) const = 0;
    virtual void _search_index_init() = 0;
    virtual size_t _find_first_local(size_t start, size_t end) = 0;
};

// Specialization for Equal condition on Strings - we specialize because we can utilize indexes (if they exist) for
// Equal. This specialisation also supports combining other StringNode<Equal> conditions into itself in order to
// optimise the non-indexed linear search that can be happen when many conditions are OR'd together in an "IN" query.
// Future optimization: make specialization for greater, notequal, etc
template <>
class StringNode<Equal> : public StringNodeEqualBase {
public:
    using StringNodeEqualBase::StringNodeEqualBase;

    void table_changed() override
    {
        StringNodeBase::table_changed();
        m_has_search_index = m_table.unchecked_ptr()->search_index_type(m_condition_column_key) == IndexType::General;
    }

    void _search_index_init() override;

    bool do_consume_condition(ParentNode& other) override;

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new StringNode<Equal>(*this));
    }

    std::string describe(util::serializer::SerialisationState& state) const override;

    StringNode(const StringNode& from)
        : StringNodeEqualBase(from)
    {
        for (auto& needle : from.m_needles) {
            if (needle.is_null()) {
                m_needles.emplace();
            }
            else {
                m_needle_storage.push_back(std::make_unique<char[]>(needle.size()));
                std::copy(needle.data(), needle.data() + needle.size(), m_needle_storage.back().get());
                m_needles.insert(StringData(m_needle_storage.back().get(), needle.size()));
            }
        }
    }
    const std::vector<ObjKey>& index_based_keys() override
    {
        m_obj_key_buffer.clear();
        if (m_index_matches == nullptr) {
            if (m_results_end) { // 1 result
                m_obj_key_buffer.push_back(m_actual_key);
            }
        }
        else { // multiple results
            for (size_t t = m_results_start; t < m_results_end; ++t) {
                m_obj_key_buffer.push_back(ObjKey(m_index_matches->get(t)));
            }
        }
        return m_obj_key_buffer;
    }

private:
    std::unique_ptr<IntegerColumn> m_index_matches;

    ObjKey get_key(size_t ndx) const override
    {
        if (IntegerColumn* vec = m_index_matches.get()) {
            return ObjKey(vec->get(ndx));
        }
        else if (m_results_end == 1) {
            return m_actual_key;
        }
        return ObjKey();
    }

    size_t _find_first_local(size_t start, size_t end) override;
    std::unordered_set<StringData> m_needles;
    std::vector<std::unique_ptr<char[]>> m_needle_storage;
    std::vector<ObjKey> m_obj_key_buffer;
};


// Specialization for EqualIns condition on Strings - we specialize because we can utilize indexes (if they exist) for
// EqualIns.
template <>
class StringNode<EqualIns> : public StringNodeEqualBase {
public:
    StringNode(StringData v, ColKey column)
        : StringNodeEqualBase(v, column)
    {
        auto upper = case_map(v, true);
        auto lower = case_map(v, false);
        if (!upper || !lower) {
            throw query_parser::InvalidQueryError(util::format("Malformed UTF-8: %1", v));
        }
        else {
            m_ucase = std::move(*upper);
            m_lcase = std::move(*lower);
        }
    }

    void clear_leaf_state() override
    {
        StringNodeEqualBase::clear_leaf_state();
        m_index_matches.clear();
    }

    void table_changed() override
    {
        StringNodeBase::table_changed();
        m_has_search_index = m_table.unchecked_ptr()->search_index_type(m_condition_column_key) == IndexType::General;
    }
    void _search_index_init() override;

    virtual std::string describe_condition() const override
    {
        return EqualIns::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new StringNode(*this));
    }

    StringNode(const StringNode& from)
        : StringNodeEqualBase(from)
        , m_ucase(from.m_ucase)
        , m_lcase(from.m_lcase)
    {
    }

    const std::vector<ObjKey>& index_based_keys() override
    {
        return m_index_matches;
    }

private:
    // Used for index lookup
    std::vector<ObjKey> m_index_matches;
    std::string m_ucase;
    std::string m_lcase;

    ObjKey get_key(size_t ndx) const override
    {
        return m_index_matches[ndx];
    }

    size_t _find_first_local(size_t start, size_t end) override;
};


class LinkMap;
class StringNodeFulltext : public StringNodeEqualBase {
public:
    StringNodeFulltext(StringData v, ColKey column, std::unique_ptr<LinkMap> lm = {});

    void table_changed() override;

    void _search_index_init() override;

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new StringNodeFulltext(*this));
    }

    virtual std::string describe_condition() const override
    {
        return "FULLTEXT";
    }

    const std::vector<ObjKey>& index_based_keys() override
    {
        return m_index_matches;
    }

private:
    std::vector<ObjKey> m_index_matches;
    std::unique_ptr<LinkMap> m_link_map;

    StringNodeFulltext(const StringNodeFulltext&);

    ObjKey get_key(size_t ndx) const override
    {
        return m_index_matches[ndx];
    }

    size_t _find_first_local(size_t, size_t) override
    {
        REALM_UNREACHABLE();
    }
};

// OR node contains at least two node pointers: Two or more conditions to OR
// together in m_conditions, and the next AND condition (if any) in m_child.
//
// For 'second.equal(23).begin_group().first.equal(111).Or().first.equal(222).end_group().third().equal(555)', this
// will first set m_conditions[0] = left-hand-side through constructor, and then later, when .first.equal(222) is
// invoked, invocation will set m_conditions[1] = right-hand-side through Query& Query::Or() (see query.cpp).
// In there, m_child is also set to next AND condition (if any exists) following the OR.
class OrNode : public ParentNode {
public:
    OrNode(std::unique_ptr<ParentNode> condition)
    {
        m_dT = 50.0;
        if (condition)
            m_conditions.emplace_back(std::move(condition));
    }

    OrNode(const OrNode& other)
        : ParentNode(other)
    {
        for (const auto& condition : other.m_conditions) {
            m_conditions.emplace_back(condition->clone());
        }
    }

    void table_changed() override
    {
        for (auto& condition : m_conditions) {
            condition->set_table(m_table);
        }
    }

    void cluster_changed() override
    {
        for (auto& condition : m_conditions) {
            condition->set_cluster(m_cluster);
        }

        m_start.clear();
        m_start.resize(m_conditions.size(), 0);

        m_last.clear();
        m_last.resize(m_conditions.size(), 0);

        m_was_match.clear();
        m_was_match.resize(m_conditions.size(), false);
    }

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        std::string s;
        for (size_t i = 0; i < m_conditions.size(); ++i) {
            if (m_conditions[i]) {
                s += m_conditions[i]->describe_expression(state);
                if (i != m_conditions.size() - 1) {
                    s += " or ";
                }
            }
        }
        if (m_conditions.size() > 1) {
            s = "(" + s + ")";
        }
        return s;
    }

    void collect_dependencies(std::vector<TableKey>& versions) const override
    {
        for (const auto& cond : m_conditions) {
            cond->collect_dependencies(versions);
        }
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);
        combine_conditions(!will_query_ranges);

        m_start.clear();
        m_start.resize(m_conditions.size(), 0);

        m_last.clear();
        m_last.resize(m_conditions.size(), 0);

        m_was_match.clear();
        m_was_match.resize(m_conditions.size(), false);

        std::vector<ParentNode*> v;
        for (auto& condition : m_conditions) {
            condition->init(will_query_ranges);
            v.clear();
            condition->gather_children(v);
        }
    }

    size_t find_first_local(size_t start, size_t end) override
    {
        if (start >= end)
            return not_found;

        size_t index = not_found;

        for (size_t c = 0; c < m_conditions.size(); ++c) {
            // out of order search; have to discard cached results
            if (start < m_start[c]) {
                m_last[c] = 0;
                m_was_match[c] = false;
            }
            // already searched this range and didn't match
            else if (m_last[c] >= end)
                continue;
            // already search this range and *did* match
            else if (m_was_match[c] && m_last[c] >= start) {
                if (index > m_last[c])
                    index = m_last[c];
                continue;
            }

            m_start[c] = start;
            size_t fmax = std::max(m_last[c], start);
            size_t f = m_conditions[c]->find_first(fmax, end);
            m_was_match[c] = f != not_found;
            m_last[c] = f == not_found ? end : f;
            if (f != not_found && index > m_last[c])
                index = m_last[c];
        }

        return index;
    }

    std::string validate() override
    {
        if (m_conditions.size() == 0)
            return "Missing both arguments of OR";
        if (m_conditions.size() == 1)
            return "Missing argument of OR";
        std::string s;
        if (m_child != 0)
            s = m_child->validate();
        if (s != "")
            return s;
        for (size_t i = 0; i < m_conditions.size(); ++i) {
            s = m_conditions[i]->validate();
            if (s != "")
                return s;
        }
        return "";
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new OrNode(*this));
    }

    std::vector<std::unique_ptr<ParentNode>> m_conditions;

private:
    void combine_conditions(bool ignore_indexes)
    {
        std::sort(m_conditions.begin(), m_conditions.end(), [](auto& a, auto& b) {
            return a->m_condition_column_key < b->m_condition_column_key;
        });

        auto prev = m_conditions.begin()->get();
        auto cond = [&](auto& node) {
            if (prev->consume_condition(*node, ignore_indexes))
                return true;
            prev = &*node;
            return false;
        };
        m_conditions.erase(std::remove_if(m_conditions.begin() + 1, m_conditions.end(), cond), m_conditions.end());
    }

    // start index of the last find for each cond
    std::vector<size_t> m_start;
    // last looked at index of the lasft find for each cond
    // is a matching index if m_was_match is true
    std::vector<size_t> m_last;
    std::vector<bool> m_was_match;
};


class NotNode : public ParentNode {
public:
    NotNode(std::unique_ptr<ParentNode> condition)
        : m_condition(std::move(condition))
    {
        m_dT = 50.0;
        if (!m_condition) {
            throw query_parser::InvalidQueryError("Missing argument to Not");
        }
    }

    void table_changed() override
    {
        m_condition->set_table(m_table);
    }

    void cluster_changed() override
    {
        m_condition->set_cluster(m_cluster);
        // Heuristics bookkeeping:
        m_known_range_start = 0;
        m_known_range_end = 0;
        m_first_in_known_range = not_found;
    }

    void init(bool will_query_ranges) override
    {
        ParentNode::init(will_query_ranges);
        std::vector<ParentNode*> v;

        m_condition->init(false);
        v.clear();
        m_condition->gather_children(v);
    }

    size_t find_first_local(size_t start, size_t end) override;

    std::string describe(util::serializer::SerialisationState& state) const override
    {
        if (m_condition) {
            return "!(" + m_condition->describe_expression(state) + ")";
        }
        return "!()";
    }

    void collect_dependencies(std::vector<TableKey>& versions) const override
    {
        if (m_condition) {
            m_condition->collect_dependencies(versions);
        }
    }


    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new NotNode(*this));
    }

    NotNode(const NotNode& from)
        : ParentNode(from)
        , m_condition(from.m_condition ? from.m_condition->clone() : nullptr)
        , m_known_range_start(from.m_known_range_start)
        , m_known_range_end(from.m_known_range_end)
        , m_first_in_known_range(from.m_first_in_known_range)
    {
    }

    std::unique_ptr<ParentNode> m_condition;

private:
    // FIXME This heuristic might as well be reused for all condition nodes.
    size_t m_known_range_start;
    size_t m_known_range_end;
    size_t m_first_in_known_range;

    bool evaluate_at(size_t rowndx);
    void update_known(size_t start, size_t end, size_t first);
    size_t find_first_loop(size_t start, size_t end);
    size_t find_first_covers_known(size_t start, size_t end);
    size_t find_first_covered_by_known(size_t start, size_t end);
    size_t find_first_overlap_lower(size_t start, size_t end);
    size_t find_first_overlap_upper(size_t start, size_t end);
    size_t find_first_no_overlap(size_t start, size_t end);
};

// Compare two columns with eachother row-by-row
class TwoColumnsNodeBase : public ParentNode {
public:
    TwoColumnsNodeBase(ColKey column1, ColKey column2)
    {
        m_dT = 100.0;
        m_condition_column_key1 = column1;
        m_condition_column_key2 = column2;
        if (m_condition_column_key1.is_collection() || m_condition_column_key2.is_collection()) {
            throw Exception(ErrorCodes::InvalidQuery,
                            util::format("queries comparing two properties are not yet supported for "
                                         "collections (list/set/dictionary) (%1 and %2)",
                                         ParentNode::m_table->get_column_name(m_condition_column_key1),
                                         ParentNode::m_table->get_column_name(m_condition_column_key2)));
        }
    }

    ~TwoColumnsNodeBase() noexcept override {}
    void table_changed() override
    {
        if (this->m_table) {
            ParentNode::m_table->check_column(m_condition_column_key1);
            ParentNode::m_table->check_column(m_condition_column_key2);
        }
    }

    static std::unique_ptr<ArrayPayload> update_cached_leaf_pointers_for_column(Allocator& alloc,
                                                                                const ColKey& col_key);
    void cluster_changed() override
    {
        if (!m_leaf_ptr1) {
            m_leaf_ptr1 =
                update_cached_leaf_pointers_for_column(m_table.unchecked_ptr()->get_alloc(), m_condition_column_key1);
        }
        if (!m_leaf_ptr2) {
            m_leaf_ptr2 =
                update_cached_leaf_pointers_for_column(m_table.unchecked_ptr()->get_alloc(), m_condition_column_key2);
        }
        this->m_cluster->init_leaf(m_condition_column_key1, m_leaf_ptr1.get());
        this->m_cluster->init_leaf(m_condition_column_key2, m_leaf_ptr2.get());
    }

    virtual std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key1 && m_condition_column_key2);
        return state.describe_column(ParentNode::m_table, m_condition_column_key1) + " " + describe_condition() +
               " " + state.describe_column(ParentNode::m_table, m_condition_column_key2);
    }

    TwoColumnsNodeBase(const TwoColumnsNodeBase& from)
        : ParentNode(from)
        , m_condition_column_key1(from.m_condition_column_key1)
        , m_condition_column_key2(from.m_condition_column_key2)
    {
    }

protected:
    mutable ColKey m_condition_column_key1;
    mutable ColKey m_condition_column_key2;
    std::unique_ptr<ArrayPayload> m_leaf_ptr1 = nullptr;
    std::unique_ptr<ArrayPayload> m_leaf_ptr2 = nullptr;
};


template <class TConditionFunction>
class TwoColumnsNode : public TwoColumnsNodeBase {
public:
    using TwoColumnsNodeBase::TwoColumnsNodeBase;
    ~TwoColumnsNode() noexcept override {}
    size_t find_first_local(size_t start, size_t end) override
    {
        size_t s = start;
        while (s < end) {
            QueryValue v1(m_leaf_ptr1->get_any(s));
            QueryValue v2(m_leaf_ptr2->get_any(s));
            if (TConditionFunction()(v1, v2))
                return s;
            else
                s++;
        }
        return not_found;
    }

    virtual std::string describe_condition() const override
    {
        return TConditionFunction::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new TwoColumnsNode<TConditionFunction>(*this));
    }

protected:
    TwoColumnsNode(const TwoColumnsNode& from, Transaction* tr)
        : TwoColumnsNode(from, tr)
    {
    }
};


// For Next-Generation expressions like col1 / col2 + 123 > col4 * 100.
class ExpressionNode : public ParentNode {
public:
    ExpressionNode(std::unique_ptr<Expression>);

    void init(bool) override;
    size_t find_first_local(size_t start, size_t end) override;

    void table_changed() override;
    void cluster_changed() override;
    void collect_dependencies(std::vector<TableKey>&) const override;

    virtual std::string describe(util::serializer::SerialisationState& state) const override;

    std::unique_ptr<ParentNode> clone() const override;

private:
    ExpressionNode(const ExpressionNode& from);

    std::unique_ptr<Expression> m_expression;
};


class LinksToNodeBase : public ParentNode {
public:
    LinksToNodeBase(ColKey origin_column_key, ObjKey target_key)
        : LinksToNodeBase(origin_column_key, std::vector<ObjKey>{target_key})
    {
    }

    LinksToNodeBase(ColKey origin_column_key, const std::vector<ObjKey>& target_keys)
        : m_target_keys(target_keys)
    {
        m_dT = 50.0;
        m_condition_column_key = origin_column_key;
        m_column_type = origin_column_key.get_type();
        REALM_ASSERT(m_column_type == col_type_Link || m_column_type == col_type_LinkList);
        REALM_ASSERT(!m_target_keys.empty());
    }

    void cluster_changed() override
    {
        m_array_ptr = nullptr;
        if (m_column_type == col_type_Link) {
            m_array_ptr = LeafPtr(new (&m_storage.m_list) ArrayKey(m_table.unchecked_ptr()->get_alloc()));
        }
        else if (m_column_type == col_type_LinkList) {
            m_array_ptr = LeafPtr(new (&m_storage.m_linklist) ArrayList(m_table.unchecked_ptr()->get_alloc()));
        }
        m_cluster->init_leaf(this->m_condition_column_key, m_array_ptr.get());
        m_leaf_ptr = m_array_ptr.get();
    }

    virtual std::string describe(util::serializer::SerialisationState& state) const override
    {
        REALM_ASSERT(m_condition_column_key);
        if (m_target_keys.size() > 1)
            throw SerializationError("Serializing a query which links to multiple objects is currently unsupported.");
        ObjLink link(m_table->get_opposite_table(m_condition_column_key)->get_key(), m_target_keys[0]);
        return state.describe_column(ParentNode::m_table, m_condition_column_key) + " " + describe_condition() + " " +
               util::serializer::print_value(link, m_table->get_parent_group());
    }

protected:
    std::vector<ObjKey> m_target_keys;
    ColumnType m_column_type;
    using LeafPtr = std::unique_ptr<ArrayPayload, PlacementDelete>;
    union Storage {
        typename std::aligned_storage<sizeof(ArrayKey), alignof(ArrayKey)>::type m_list;
        typename std::aligned_storage<sizeof(ArrayList), alignof(ArrayList)>::type m_linklist;
    };
    Storage m_storage;
    LeafPtr m_array_ptr;
    const ArrayPayload* m_leaf_ptr = nullptr;

    LinksToNodeBase(const LinksToNodeBase& source)
        : ParentNode(source)
        , m_target_keys(source.m_target_keys)
        , m_column_type(source.m_column_type)
    {
    }
};

template <class TConditionFunction>
class LinksToNode : public LinksToNodeBase {
public:
    using LinksToNodeBase::LinksToNodeBase;

    virtual std::string describe_condition() const override
    {
        return TConditionFunction::description();
    }

    std::unique_ptr<ParentNode> clone() const override
    {
        return std::unique_ptr<ParentNode>(new LinksToNode<TConditionFunction>(*this));
    }

    size_t find_first_local(size_t start, size_t end) override;
};

} // namespace realm

#endif // REALM_QUERY_ENGINE_HPP
