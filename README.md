# Flutter web template with Roble services

A Flutter project to test authentication and data services based on Roble following clean architecture principles.

An improved immplementation of the datasources has beeen implemented, using an unified error handling and reducing code repetition.

Now we use Flutter's snackbar implementation instead of GetX's one to help with error messaging and testing.

Add this on the AndroidManifest.xml (just bellow the manifest xmlns:android="http://schemas.android.com/apk/res/android" line)
```
<uses-permission android:name="android.permission.INTERNET" />
```

Backend server:   

```
https://roble.openlab.uninorte.edu.co/
```

To generate ICONS:
1. Copy the icon on assets/launcher_icon/
2. Run
```
flutter pub run flutter_launcher_icons:main
```

Use the .env.sample as template to include Roble´s project contract

Using this structure:


<img width="657" height="497" alt="image" src="https://github.com/user-attachments/assets/bb3bf21c-a2d4-4982-b6d0-a048cb1cff69" />




## Testing

### Pure widget tests

On these test we test the UI mocking the controllers.

1. add_product_page_test
2. list_product_page_test
3. login_page_test

### Widget test up to data source 

On this test we verify the UI, controllers, repositories, and the data source, but we mock the http client and shared preferences.

1. product_data_source_test

Run all tests with:

```
flutter test
```

Or run a specific test with:

```
flutter test test/path_to_test.dart
```

### Integration test

On this test we verify the entire flow of the app, from the UI to the backend, using a mock http client and shared preferences.

Run the integration test with:

```flutter test integration_test/app_test.dart
```

