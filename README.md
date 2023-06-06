# cbk-ios-Veerendra

1. MVVM Framework: I used MVVM articture to create this project. I seperatly created M- Model, V-View, VM-View Model. You can see folders with the name of "Model", "Controller", "ViewModel".

2. Login with Biometric Authentication: I used Biometric authorization face/touch for login. I created a KeyChain Wrapper to store values securly in KeyChain. To check KeyChain functionality. In Settings you will see an option to enable KeyChain with toogle button. If you enable it. It will Disappear from seetings and If you are coming from login you will get and alert for authorization to touch/face. Once you Verified. You may able to use it.

3. News API Integration: I create an class "Services". Which is NSObject based class where i write my api function to use everywhere  . With the help of GetRequest function i integrated my API and gettting data from it. Filter and Country selection also implemented. You can choose select country and filter from navigation bar where i set selectable icon's. I used default pickerView for dropdown.

4. Localization and Arabic Support: I created an Loclaziable file where i am using enum cases based on language preference and I set all the keys in both files English and Arabic.

5. Pagination: I used pagination in News api with the help of array count and indexPath.row in cellForRowAt. Page no. is increasing according to data which coming from server.

6. News Filtering: I implemented News artcile filtration with the help of default PickerView. Where i am showing list of all article categories and showing data on behalf of artcile selection.

7. User Preferences: I created an "AppUserDefaults" variable for common use anywhere in project and storing values accordingly as per requirement.

8. Testing and Validation: I write two function's for Unit Testing 
   First: "Api" Init testing 
   Second: Email vlidation Unit testing
   
9. Dark Mode Support: I am using Color Set for Dark More also i created a function "SetColor" for manual change from code.

10. Offline Mode and Data Persistence: I am using Realm to store data locally. In this i created and persisted Table of Object type. Also create an DBOperation class to write Save, Delete, Fetch fucntions .
    I am getting data from api and storeing into DB through save function in Home Class. 
