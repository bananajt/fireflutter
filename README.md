# Fire Flutter

[한국어 설명 보기](readme.ko.md)

A free, open source, rapid development flutter package to build social apps, community apps, and more.

- This package has complete features (see Features below) that most of apps are needed.
- `Simple, easy and the right way`.
  We want it to be really simple but right way for ourselves and for the builders in the world.
  We know when it gets complicated, developers' lives would get even more complicated.

## Features

- User

  - User registration, login, profile update with email/password
  - Social logins
    - Google,
    - Apple (only on iOS),
    - Facebook,
    - Developers can their own social login. see `Kakao Login` example.
  - User profile photo update
  - Phone number authentication

- Forum

  - Complete forum functioanlities.
    - Forum category add/update/delete in admin page.
    - Post and comment create/update/read/delete, likes/dislikes, file upload/delete. And any other extra functioanalties to compete forum feature.
  - Forum search with Algolia.
  - Infinite scroll.
  - Real time.
    - If a user create a comment, it will appear on other user's phone. And this goes same to all edit/delete, likes/dislikes.
  - A category of forum could be re-designed for online shopping mall purpose.

- Push notifications

  - Admin can send push notifications to all users.
  - Admin can send push notifications to users of a forum.
  - User can enable/disable to get notification when other users creates comments under his posts/comments.
  - User can subscribe/unsubscribe for new posts or comments under a forum.

- Settings in real time.

  - Admin can update app settings via Admin page and the change will apply to app immediately.

- Internalization (Localization) in real time.

  - Texts in menu, text screens could be translated/update at any via Admin page and it appears in the app immediately.

- Security

  - Tight Firestore security rules are applied.
  - For some functionalities that cannot be covered by Firestore security are covered by Cloud Functions.

- Fully Customizable
  - FireFlutter package does not involve in any of part application's login or UI. It is completely separated from the app. Thus, it's highly customizable.

## References

- [FireFlutter Package](https://pub.dev/packages/fireflutter) - This package.
- [FireFlutter Sample App](https://github.com/thruthesky/fireflutter_sample_app) - Sample flutter application.
- [FireFlutter Firebase Project](https://github.com/thruthesky/fireflutter-firebase) - Firebase project for Firestore security rules and Functions.

## Components

- Firebase.
  Firebase is a leading cloud system powered by Google. It has lots of goods to build web and app.

  - We first built it with Firebase and LEMP(Linux + Nginx + MySQL + PHP). we realized maintaing two different systems would be a pressure for many of developers. So, We decided to remove LEMP and we built it again.

  - You may use Firebase as free plan for a test. But for production, you need `Pay as you go` plan since `Cloud Function` works only on `Pay as you go` plan.
    - You may not use `Cloud Function` for testing.

- Algolia.
  Firebase does not support full text search which means users cannot search posts and comments.
  Algolia does it.

## Installation

- If you are not familiar with Firebase and Flutter, you may have difficulties to install it.

  - FireFlutter is not a smple package that you just add it into pubspec.yaml and ready to go.
  - Furthermore, the settings that are not directly from coming FireFlutter package like social login settings, Algolia setting, Android and iOS developer's accont settings are also hard to implement if you are not get used to them.

- We cover all the settings and will try to put it as demonstrative as it can be.

  - We will begin with Firebase settings and contiue gradually with Flutter.

- If you have any difficulties on installatin, you may ask it on
  [Git issues](https://github.com/thruthesky/fireflutter/issues).

- We also have a premium paid servie to support installation and development.

### Firebase Project Creation

- You need to create a Firebase project for the first time. You may use existing Firebase project.

- Go to Firebsae console, https://console.firebase.google.com/

  - click `(+) Add project` menu.
  - enter project name. You can enter any name. ex) fireflutter-test
  - click `Continue` button.
  - disable `Enable Google Analytics for this project`. You can eanble it if you can handle it.
    - click `Continue` button.
  - new Firebase project will be created for you in a few seconds.
    - Tehn, click `Continue` button.

- Read [Understand Firebase projects](https://firebase.google.com/docs/projects/learn-more) for details.

### Firebase Email/Password Login

- Go to Authentication => Sign-in Method
- Click `Enable/Password` (without Email link).
- It is your choice weather you would let users to register by their email and password or not. But for installation test, just enable it.

- Refer [Firebase Authentication](https://firebase.google.com/docs/auth) and [FlutterFire Social Authenticatino](https://firebase.flutter.dev/docs/auth/social) for details.

### Create Firestore Database

- Go to `Cloud Firestore` menu.
- Click `Create Database`.
- Choose `Start in test mode`. We will change it to `production mode` later.
- Click `Next`.
- Choose nearest `Cloud Firestore location`.
- Click `Enable`.

### Create Flutter project

- Create a Flutter project like below;

```
$ flutter create fireflutter_sample_app
$ cd fireflutter_sample_app
$ flutter run
```

#### Setup Flutter to connect to Firebase

##### iOS Setup

- Click `iOS` icon on `Project Overview` page to add `iOS` app to Firebase.
- Enter iOS Bundle ID. Ex) com.sonub.fireflutter
  - From now on, we assume that your iOS Bundle ID is `com.sonub.fireflutter`.
- click `Register app`.
- click `Download GoogleService-Info.plist`
  - And save it under `fireflutter_sample_app/ios/Runner` folder.
- click `Next`.
- click `Next` again.
- click `Next` again.
- click `Continue to console`.

- open `fireflutter_sample_app/ios/Runner.xcworkspace` with Xcode.
- click `Runner` on the top of left pane.
- click `Runner` on TARGETS.
- edit `Bundle Identifier` to `com.sonub.fireflutter`.
- set `iOS 11.0` under Deployment Info.
- Darg `fireflutter_sample_app/ios/Runner/GoogleService-Info.plist` file under `Runner/Runner` on left pane of Xcode.
- Close Xcode.

- You may want to test if the settings are alright.
  - Open VSCode and do [FireFlutter Initialization](#fireflutter-initialization) do some registration code. see [User Registration](#user-email-and-password-registration) for more details.

##### Android Setup

- Click `Android` icon on `Project Overview` page to add `Android` app to Firebase.
  - If you don't see `Android` icon, look for `+ Add app` button and click, then you would see `Android` icon.
- Enter `iOS Bundle ID` into `Android package name`. `iOS Bundle ID` and `Android package name` should be kept in idendentical name for easy to maintain. In our case, it is `com.sonub.fireflutter`.
- Click `Register app` button.
- Click `Download google-services.json` file to downlaod
- And save it under `fireflutter_sample_app/android/app` folder.
- Click `Next`
- Click `Next`
- Click `Continue to console`.
- Open VSCode with `fireflutter_sample_app` project.
- Open `fireflutter_sample_app/android/app/build.gradle` file.
- Update `minSdkVersion 16` to `minSdkVersion 21`.
- Add below to the end of `fireflutter_sample_app/android/app/build.gradle`. This is for Flutter to read `google-services.json`.

```gradle
apply plugin: 'com.google.gms.google-services'
```

- Open `fireflutter_sample_app/android/build.gradle`. Do not confuse with the other build.gradle.
- Add the dependency below in the buildscript tag.

```gradle
dependencies {
  // ...
  classpath 'com.google.gms:google-services:4.3.3' // Add this line.
}
```

- Open the 5 files and update the package name to `com.sonub.fireflutter`.

  - android/app/src/main/AndroidManifest.xml
  - android/app/src/debug/AndroidManifest.xml
  - android/app/src/profile/AndroidManifest.xml
  - android/app/build.gradle
  - android/app/src/main/kotlin/….MainActivity.kt

- That's it.
- You may want to test if the settings are alright.
  - Open VSCode and do [FireFlutter Initialization](#fireflutter-initialization) do some registration code. see [User Registration](#user-email-and-password-registration) for more details.

### Add fireflutter package to Flutter project

- Add `fireflutter` to pubspec.yaml
  - fireflutter package contains other packages like algolia, dio, firebase related packages, and more as its dependency. You don't have to install the same packages again in your pubspec.yaml
  - See [the pubspect.yaml in sample app](https://github.com/thruthesky/fireflutter_sample_app/blob/fireflutter-initialization/pubspec.yaml).
  - You need to update the latest version of `fireflutter`.
- See [FireFlutter Initialization](#fireflutter-initialization) to initialize `fireflutter` package.
- See [Add GetX](#add-getx) to use route, state management, localization and more.

### Firebase Social Login

- Under Authentication => Sign-in Methods, Enable

  - Email/Password
  - Google
  - Apple
  - Facebook
  - Phone
    All of them are optional. You may only enable those you want to provide for user login.

- Settings for Firebase Social login are in Android and iOS platform already done app. You need to set the settings on Apple, Facebook.

  - If you are not going to use the sample app, you need to setup by yourself.

- Refer [Firebase Authentication](https://firebase.google.com/docs/auth) and [FlutterFire Social Authenticatino](https://firebase.flutter.dev/docs/auth/social) for details.

#### Google Login Setup

- Go to Authentication => Sign-in method
- Click Google
- Click Enable
- Choose your email address in Project support email.
- Click Save.

- That's it. If you want to test the setting, try to code in [Google Login](#google-login) section.

#### Facebook Login Setup

#### Apple Login Setup

### Firestore security rules

- Firestore needs security rules and Functions needs functions to support FireFlutter package.

  - If you wish, you can continue without this settings. But it's not secure and some functionality may not work.

- Install firebase tools.

```
# npm install -g firebase-tools
$ cd firebase
$ firebase login
```

- Git clone(or fork) https://github.com/thruthesky/fireflutter-firebase and install with `npm i`
- Update Firebase project ID in `.firebaserc ==> projects ==> default`.
- Save `Firebase SDK Admin Service Key` to `firebase-service-account-key.json`.
- Run `firebase deploy --only firestore,functions`. You will need Firebase `Pay as you go` plan to deploy it.

#### Security Rules Testing

- If you wish to test Firestore security rules, you may do so with the following;

Run Firebase emualtor first.

```
$ firebase emulators:start --only firestore
```

run the tests.

```
$ npm run test
$ npm run test:basic
$ npm run test:user
$ npm run test:admin
$ npm run test:category
$ npm run test:post
$ npm run test:comment
$ npm run test:vote
$ npm run test:user.token
```

### Cloud Functions

- We tried to limit the usage of Cloud Functions as less as possible. But there are some functionalities we cannot acheive without it.

  - One of the reason why we use Cloud Funtions is to enable like and dislike functionality. It is a simple functionality but when it comes with Firestore security rule, it's not an easy work. And Cloud Functions does better with it.

### Funtions Test

- If you whish to test Functins, you may do so with the following;

```
$ cd functions
$ npm test
```

### Push Notification

- Settings of push notification on Android and iOS platform are done in the sample app.

  - If you are not going to use the sample app, you need to setup by yourself.

- Refer [Firestore Messaging](https://pub.dev/packages/firebase_messaging)

### Localization

- To add a language, the language needs to be set in Info.plist of iOS platform. No setting is needed on Android platform.
- you need to add the translation under Firestore `translations` collection.
- you need to use it in your app.
- Localization could be used for menus, texts in screens.
-

### Algolia Installation

- There are two settings for Algolia.
- First, you need to put ALGOLIA_ID(Application ID), ALGOLIA_ADMIN_KEY, ALGOLIA_INDEX_NAME in `firebase-settings.js`.
  - deploy with `firebase deploy --only functions`.
  - For testing, do `npm run test:algolia`.
- Second, you need to add(or update) ALGOLIA_APP_ID(Application ID), ALGOLIA_SEARCH_KEY(Search Only Api Key), ALGOLIA_INDEX_NAME in Firestore `settings/app` document.
  Optionally, you can put the settings inside `FireFlutter.init()`.
- Algolia free account give you 10,000 free search every months. This is good enough for small sized projects.

### Admin Account Setting

- Any user who has `isAdmin` property with `true`.
- Admin property is protected by Firestore security rules and cannot be edited by client app.

## App Management

- The app management here is based on the sample code and app.
- FireFlutter is a flutter package to build social apps and is fully customizable. When you may build your own customized app, we recommend to use our sample codes.

### App Settings

- Developers can set default settings on `FireFlutter.init()`.
- Admin can overwrite all the settings by updating Firestore `settings` docuemnts.

### Internalization (Localization)

- Menus and page contents can be translated depending on user's device. Or developer can put a menu to let users to choose their languages.

- When admin update the translation text in Firestore `translations` collectin, the will get the update in real time. The app, should update the screen.

- The localization is managed by `GetX` package that is used for routing and state management on the sample code.

### Forum Management

#### Forum Category Management

- You can create forum categories in admin screen.

## For Developers

### General Setup

- Add latest version of [FireFlutter](https://pub.dev/packages/fireflutter) in pubspec.yaml
- Add latest version of [GetX](https://pub.dev/packages/get).
  - We have chosen `GetX` package for routing, state management, localization and other functionalities.
    - GetX is really simple. We recommed you to use it.
    - All the code explained here is with GetX.
    - You may choose different packages and that's very fine.

#### FireFlutter Initialization

- Open `main.dart`
- Add the following code;

```dart
import 'package:fireflutter/fireflutter.dart';

FireFlutter ff = FireFlutter();
void main() async {
  await ff.init();
  runApp(MainApp());
}
```

- The variable `ff` is an instace of `FireFlutter` and should be shared across all the screens.

- Create a `global_variables.dart` on the same folder of main.dart.

  - And move the `ff` variable into `global_variables.dart`.

- The complete code is on [fireflutter-initialization branch](https://github.com/thruthesky/fireflutter_sample_app/tree/fireflutter-initialization/lib) of sample app.

- todo: app settings
- todo: translations
- todo: how to use settings.

#### Add GetX

- To add GetX to Flutter app,
  - open main.dart
  - split `Home Screen` into `lib/screens/home/home.screen.dart`.
  - and replace `MaterialApp` with `GetMaterialApp`.
  - add `initialRotue: 'home'`
  - add HomeScreen to route.
  - To see the complete code, visit [getx branch of sample app](https://github.com/thruthesky/fireflutter_sample_app/tree/getx).

### Firestore Structure

- Principle. Properties and sub collections(documents) of a document should be under that document.

- `users/{uid}` is user's private data document.

  - `users/{uid}/meta/public` is user's public data document.
  - `users/{uid}/meta/tokens` is where the user's tokens are saved.

- `/posts/{postId}` is the post document.
  - `/posts/{postId}/votes/{uid}` is the vote document of each user.
  - `/posts/{postId}/comments/{commentId}` is the comment document under of the post document.

### Coding Guidelines

- `null` event will be fired for the first time on `FireFlutter.userChange.listen`.
- `auth` event will be fired for the first time on `FirebaseAuth.authChagnes`.

### User

- Private user information is saved under `/users/{uid}` documentation.
- User's notification subscription information is saved under `/users/{uid}/meta/public` documents.
- Push notification tokens are saved under `/users/{uid}/meta/tokens` document.

### Create Register Screen

- Do [General Setup](#general-setup).
- Create register screen with `lib/screens/register/register.screen.dart` file.
- Put a route named `register`

### Create Login Screen

### Create Profile Screen

#### User Email And Password Registration

- Open register.screen.dart
- Put a button for opening register screen.
- Then, add email input box, password input box and a submit button.

  - You may add more input box for displaName and other informations.
  - You may put a profile photo upload button.

  - For the complete code, see [register branch in sample app](https://github.com/thruthesky/fireflutter_sample_app/tree/register/lib).

- When the submit button is pressed, you would write codes like below for the user to actually register into Firebase.

```dart
try {
  User user = await ff.register({
    'email': emailController.text,
    'password': passwordController.text,
    'displayName': displayNameController.text,
    'favoriteColor': favoriteColorController.text
  });
  // register success. App may redirect to home screen.
} catch (e) {
  // do error handling
}
```

- It may take serveral seconds depending on the user's internet connectivity.
  - And FireFlutter package does a lot of works under the hood.
    - When the `register()` method invoked, it does,
      - create account in Firebase Auth,
      - update displayName,
      - update extra user data into Firestore,
      - reload Firebase Auth account,
      - push notification token saving,
        thus, it may take more than a second. It is recommended to put a progress spinner while registration.
- As you may know, you can save email, display name, profile photo url in Firebase Auth. Other information goes into `/users/{uid}` firebase.
- After registration, you will see there is a new record under Users in Firebase console => Authentication page.

- Visit [register branch of sample app](https://github.com/thruthesky/fireflutter_sample_app/tree/register) for registration sample code.

- You can add some extra public data like below.
  - User's information is private and is not available for other.
  - User's public data is open to the world. But it can only be updated by the user.

```dart
User user = await ff.register({
  // ...
}, meta: {
  "public": {
    "notifyPost": true,
    "notifyComment": true,
  }
});
```

- There is another branch for more complete regration sample code. See [register-2 branch](https://github.com/thruthesky/fireflutter_sample_app/tree/register-2) for more complete regiration code.
- We recommend you to copy the sample code and apply it into your own project.

### Forum

- To fetch posts and listing, you need to declare `ForumData` object.
  - How to declare forum data.

```dart
class ForumScreen extends StatefulWidget {
  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  ForumData forum;

  @override
  void initState() {
    super.initState();
    forum = ForumData(
      category: Get.arguments['category'], // Category of forum
      /// [render] callback will be invoked on post/comment/file CRUD and fetching posts.
      render: (RenderType x) {
        if (mounted) setState(() => null);
      },
    );
  }
}

```

### Logic for Vote

- Post voting and comment voting have same logic and same(similiar) document structure.
- Choice of vote could be one of `empty string('')`, `like`, `dislike`. Otherwise, permission error will happen.
- When a user votes for the first time, choice must be one of `like` or `dislike`. Otherwise, permission error will happen.
- Properties names of like and dislike in post and comment documents are in plural forms that are `likes` and `dislikes`.
- `likes` and `dislikes` may not exists in the document or could be set to 0.
- For votes under post, `/posts/{postId}/votes/{uid}` is the document path.
- For votes under comments, `/posts/{postId}/comments/{commentId}/votes/{uid}` is the document path.
- User can vote on his posts and comments.
- A user voted `like` and the user vote `like` again, he means, he wants to cancel the vote. The client should save empty string('').
- A user voted `like` and the user vote `dislike`, then `likes` will be decreased by 1 and `dislikes` will be increased by 1.
- Admin should not fix vote document manually, since it may produce wierd results.
- Voting works asynchronously.
  - When a user votes in the order of `like => dislike => like => dislike`,
    the server(Firestore) may receive in the order of `like => like => dislike => dislike` since it is **asynchronous**.
    So, client app should block the user not to vote again while voting is in progress.

### Push Notification

- Must be enableNotification `true` on main on FireFlutter init
  - to handble notification you can pass method via notificationHandler.

```dart
ff.init(
    enableNotification: true,
    notificationHandler: (Map<String, dynamic> notification,
        Map<String, dynamic> data, NotificationType type) {
          // do something here.
          // display, alert, move to specific page
    },
  );
```

### Social Login

#### Google Login

- Open login.screen.dart or create following [Create Login Screen](#create-login-screen)
- You can use the social Login by calling signInWithGoogle.

```dart
RaisedButton(
  child: Text('Google Sign-in'),
  onPressed: ff.signInWithGoogle,
)
```

- Tip: you may customize your registration page to put a button saying `Login with social accounts`. When it is touched, redirect the user to login screen where actual social login buttons are appear.

#### Facebook Login

- Follow the instructions on how to setup Facebook project.

```dart
RaisedButton(
  child: Text('Facebook Sign-in'),
  onPressed: ff.signInWithFacebook,
);
```

#### Apple Login

- Follow the instructions on how to setup Apple project.
- Enable `Apple` in Sign-in Method.

```dart
SignInWithAppleButton(
  onPressed: () async {
    try {
      await ff.signInWithApple();
      Get.toNamed(RouteNames.home);
    } catch (e) {
      Service.error(e);
    }
  },
),
```

### External Logins

#### Kakao Login

- Kakao login is completely separated from `fireflutter` since it is not part of `Firebase`.
  - The sample app has an example code on how to do `Kakao login` and link to `Firebase Auth` account.

## I18N

- The app's i18n is managed by `GetX` i18n feature.

- If you want to add another language,

  - Add the language code in `Info.plist`
  - Add the language on `translations`
  - Add the lanugage on `FireFlutter.init()`
  - Add the language on `FireFlutter.settingsChange`
  - Add the language on Firebase `settings` collection.

- Default i18n translations(texts) can be set through `FireFlutter` initializatin and is overwritten by the `translations` collection of Firebase.
  The Firestore is working offline mode, so overwriting with Firestore translation would happen so quickly.

## Settings

- Default settings can be set through `FireFlutter` initialization and is overwritten by `settings` collection of Firebase.
  The Firestore is working offline mode, so overwriting with Firestore translation would happen so quickly.

- If `show-phone-verification-after-login` is set to true, then users who do not have their phone numbers will be redirected to phone verification page.
  - Developers can customize it by putting 'skip' button.
- If `create-phone-verified-user-only` is set to true, only the user who verified thier phone numbers can create posts and comments.

<!-- - `GcpApiKey` is the GCP ApiKey and if you don't know what it is, then here is a simple tip. `GCP ApiKey` is a API Key to access GCP service and should be kept in secret. `Firebase` is a part of GCP Service and GCP ApiKey is needed to use Firebase functionality. And FireFlutter needs this key to access GCP service like phone number verification.
  - To get `GcpApiKey`,
    - Go to `GCP ==> Choose Project ==> APIs & Service ==> Credentials ==> API Kyes`
    - `+ CREATE CREDENTIALS => RESTRICT KEY`
    - Name it to `FireFlutterApiKey`
    - Choose `None` under `Application restrictions`
    - Choose `Don't restrict key` under `API restrctions`
    - `Save`
    - Copy the Api Key on `FireFlutterApiKey`.
    - Paste it into `Firestore` => `/settings` collection => `app` document => `GcpApiKey`.
  - You may put the `GcpApiKey` in the source code (as in FireFlutter initialization) but that's not recommended. -->
