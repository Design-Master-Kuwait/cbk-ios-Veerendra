//
//  NewsAppTests.swift
//  NewsAppTests
//
//  Created by Apple on 25/05/23.
//

import XCTest
@testable import NewsApp

final class NewsAppTests: XCTestCase {
    
    override func setUpWithError() throws {
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        XCTAssertTrue(testAPIWorking())
        XCTAssertTrue(login())
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testUppercaseFirst() {
        
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // MARK: - Home API Test
    func testAPIWorking() -> Bool
    {
        var HomeMdl : HomeBaseMDL?
        var isSuccess = false
        let expectation = self.expectation(description: "Home Api")
        let url = "https://newsapi.org/v2/top-headlines?country=us&apiKey=a9f7b40a4b1b47009caf85e25f6a998f&page=1&category="
        
        Services.getRequest(url: url,view: UIView(), shouldAnimateHudd: true) { (responseData) in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                do {
                    HomeMdl = try JSONDecoder().decode(HomeBaseMDL.self, from: responseData)
                    if HomeMdl?.status == "ok" {
                        XCTAssertTrue(true)
                        isSuccess = true
                      print("API_TESTING_WORKING")
                    }
                }
                catch {
                    
                }
                expectation.fulfill()
            }
            
        }
        // We ask the unit test to wait our expectation to finish.
        self.waitForExpectations(timeout: 5, handler: nil)
        return isSuccess
    }
    
    
    func login() -> Bool {
        let email = "veer@gmail.com"
        return email.isEmail()
    }
    
}
