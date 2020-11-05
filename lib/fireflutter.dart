library fireflutter;

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/subjects.dart';
import 'package:algolia/algolia.dart';
import './functions.dart';
part './definitions.dart';
part './base.dart';

/// FireFlutter
///
/// Recommendation: instantiate `FireFlutter` class into a global variable
/// and use it all over the app runtime.
///
/// Warning: instantiate it after `initFirebase`. One of good places is insdie
/// the first widget loaded by `runApp()` or home screen.
class FireFlutter extends Base {
  /// [socialLoginHandler] will be invoked when a social login success or fail.
  FireFlutter() {
    // print('FireFlutter');
  }

  ///
  /// [remoteConfigFetchInterval] is the interval that the app will fetch remote config data again.
  /// the unit of [remoteConfigFetchInterval] is minute. In debug mode, it can be set to 1.
  /// But in release mode, it must not be less than 15. If it is less than 15,
  /// then it will be escalated to 15.
  ///
  Future<void> init({
    bool enableNotification = false,
    String firebaseServerToken,
    String pushNotificationSound,
    Map<String, Map<dynamic, dynamic>> settings,
    Map<String, Map<String, String>> translations,
  }) async {
    this.enableNotification = enableNotification;
    this.firebaseServerToken = firebaseServerToken;
    this.pushNotificationSound = pushNotificationSound;

    /// Must be called before firebase init
    ///
    if (settings != null) {
      _settings = settings;
      settingsChange.add(_settings);
    }

    if (translations != null) {
      translationsChange
          .add(translations); // Must be called before firebase init
    }
    return initFirebase().then((firebaseApp) {
      initUser();
      initFirebaseMessaging();
      listenSettingsChange();
      listenTranslationsChange(translations);

      /// Initialize or Re-initialize based on the setting's update.
      settingsChange.listen((settings) {
        // print('settingsChange.listen() on fireflutter::init() $settings');

        // Initalize Algolia
        String applicationId = appSetting('ALGOLIA_APP_ID');
        String apiKey = appSetting('ALGOLIA_SEARCH_KEY');
        if (applicationId != '' && apiKey != '') {
          algolia = Algolia.init(
            applicationId: applicationId,
            apiKey: apiKey,
          );
        }
      });

      return firebaseApp;
    });
  }

  bool get isAdmin => this.data['isAdmin'] == true;
  bool get userIsLoggedIn => user != null;
  bool get userIsLoggedOut => !userIsLoggedIn;

  /// Register into Firebase with email/password
  ///
  /// `authStateChanges` will fire event with login info immediately after the
  /// user register but before updating user displayName and photoURL meaning.
  /// This means, when `authStateChanges` event fired, the user have no
  /// `displayNamd` and `photoURL` in the User data.
  ///
  /// The `user` will have updated `displayName` and `photoURL` after
  /// registration and updating `displayName` and `photoURL`.
  ///
  /// Consideration: It cannot have a fixed data type since developers may want
  /// to add extra data on registration.
  Future<User> register(
    Map<String, dynamic> data, {
    Map<String, Map<String, dynamic>> meta,
  }) async {
    assert(data['photoUrl'] == null, 'Use photoURL');

    if (data['email'] == null) throw 'email_is_empty';
    if (data['password'] == null) throw 'password_is_empty';

    // print('req: $data');

    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: data['email'],
      password: data['password'],
    );

    /// For registraion, it is okay that displayName or photoUrl is empty.
    await userCredential.user.updateProfile(
      displayName: data['displayName'],
      photoURL: data['photoURL'],
    );

    await userCredential.user.reload();
    user = FirebaseAuth.instance.currentUser;

    /// Remove default data.
    /// And if there is no more properties to save into document, then save
    /// empty object.
    data.remove('email');
    data.remove('password');
    data.remove('displayName');
    data.remove('photoURL');

    /// Login Success
    DocumentReference userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user.uid);

    /// Set user extra information

    await userDoc.set(data);

    /// Default meta
    Map<String, Map<String, dynamic>> defaultMeta = {
      'public': {
        "notification_post": true,
        "notification_comment": true,
      }
    };

    /// Merge default with new meta data.
    meta.forEach((key, value) {
      for (String name in value.keys) {
        if (defaultMeta[key] == null) defaultMeta[key] = {};
        defaultMeta[key][name] = value[name];
      }
    });

    await updateUserMeta(defaultMeta);

    onLogin(user);
    return user;
  }

  /// Logs out from Firebase Auth.
  Future<void> logout() {
    return FirebaseAuth.instance.signOut();
  }

  /// Logs into Firebase Auth.
  ///
  /// TODO Leave last login timestamp.
  /// TODO Increment login count
  /// TODO Leave last login device & IP address.
  Future<User> login({
    @required String email,
    @required String password,
    Map<String, Map<String, dynamic>> meta,
  }) async {
    // print('email: $email');
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await updateUserMeta(meta);
    onLogin(userCredential.user);
    return userCredential.user;
  }

  /// Updates a user's profile data.
  ///
  /// After update, `user` will have updated `displayName` and `photoURL`.
  ///
  /// TODO Make a model(interface type)
  Future<void> updateProfile(
    Map<String, dynamic> data, {
    Map<String, Map<String, dynamic>> meta,
  }) async {
    if (data == null) return;
    if (data['displayName'] != null) {
      await user.updateProfile(displayName: data['displayName']);
    }
    if (data['photoURL'] != null) {
      await user.updateProfile(photoURL: data['photoURL']);
    }

    await user.reload();
    user = FirebaseAuth.instance.currentUser;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    data.remove('displayName');
    data.remove('photoURL');
    await userDoc.set(data, SetOptions(merge: true));

    await updateUserMeta(meta);
  }

  /// Update user's profile photo
  ///
  ///
  Future<void> updatePhoto(String url) async {
    await user.updateProfile(photoURL: url);
    await user.reload();
    user = FirebaseAuth.instance.currentUser;
  }

  /////////////////////////////////////////////////////////////////////////////
  ///
  /// Forum Functions
  ///
  /////////////////////////////////////////////////////////////////////////////

  /// Add url to post or comment document `files` field.
  ///
  /// Note: Same URL can be added twice. The user may upload same file twice.
  ///
  /// ```
  /// // after upload
  /// // get url
  /// ff.addFile(url: url, path: 'post or comment path', files: comments['files'] );
  /// ```
  // addFiles({
  //   @required String url,
  //   List<String> files,
  //   @required String path,
  // }) {
  //   if (files == null) files = [];
  //   files.add(url);
  //   final doc =
  //       FirebaseFirestore.instance.doc(path);
  //   doc.set({'files': files}, SetOptions(merge: true));
  // }

  /// Deletes a file from firebase storage.
  ///
  /// If the file is not found on the firebase storage, it will ignore the error.
  Future deleteFile(String url) async {
    Reference ref = FirebaseStorage.instance.refFromURL(url);
    await ref.delete().catchError((e) {
      if (!e.toString().contains('object-not-found')) {
        throw e;
      }
    });
  }

  /// Get more posts from Firestore
  ///
  /// This does not fetch again while it is in progress of fetching.
  fetchPosts(ForumData forum) {
    if (forum.shouldNotFetch) return;
    // print('category: ${forum.category}');
    // print('should fetch?: ${forum.shouldFetch}');
    forum.updateScreen(RenderType.fetching);
    // forum.pageNo++;
    // print('pageNo: ${forum.pageNo}');

    /// Prepare query
    Query postsQuery = postsCol.where('category', isEqualTo: forum.category);
    postsQuery = postsQuery.orderBy('createdAt', descending: true);
    //set default limit
    int limit = _settings['forum']['no-of-posts-per-fetch'] ?? 12;

    //if it has specific limit on settings set the corresponding settings.
    if (_settings[forum.category] != null &&
        _settings[forum.category]['no-of-posts-per-fetch'] != null)
      limit = _settings[forum.category]['no-of-posts-per-fetch'];
    // print(limit);
    postsQuery = postsQuery.limit(limit);

    /// Fetch from the last post that had been fetched.
    if (forum.posts.isNotEmpty) {
      postsQuery = postsQuery.startAfter([forum.posts.last['createdAt']]);
    }

    /// Listen to coming posts.
    forum.postQuerySubscription =
        postsQuery.snapshots().listen((QuerySnapshot snapshot) {
      // if snapshot size is 0, means no documents has been fetched.
      if (snapshot.size == 0) {
        if (forum.posts.isEmpty) {
          forum.status = ForumStatus.noPosts;
        } else {
          forum.status = ForumStatus.noMorePosts;
        }
      } else if (snapshot.docs.length < limit) {
        forum.status = ForumStatus.noMorePosts;
      }

      forum.updateScreen(RenderType.finishFetching);
      snapshot.docChanges.forEach((DocumentChange documentChange) {
        final post = documentChange.doc.data();
        post['id'] = documentChange.doc.id;

        if (documentChange.type == DocumentChangeType.added) {
          /// [createdAt] is null on author mobile (since it is cached locally).
          if (post['createdAt'] == null) {
            forum.posts.insert(0, post);
          }

          /// [createdAt] is not null on other user's mobile and have the
          /// biggest value among other posts.
          else if (forum.posts.isNotEmpty &&
              post['createdAt'].microsecondsSinceEpoch >
                  forum.posts[0]['createdAt'].microsecondsSinceEpoch) {
            forum.posts.insert(0, post);
          }

          /// Or, it is a post that should be added at the bottom for infinite
          /// page scrolling.
          else {
            forum.posts.add(post);
          }

          if (post['comments'] == null) post['comments'] = [];

          /// TODO: have a placeholder for all the posts' comments change subscription.
          forum.commentsSubcriptions[post['id']] = FirebaseFirestore.instance
              .collection('posts/${post['id']}/comments')
              .orderBy('order', descending: true)
              .snapshots()
              .listen((QuerySnapshot snapshot) {
            snapshot.docChanges.forEach((DocumentChange commentsChange) {
              final commentData = commentsChange.doc.data();
              commentData['id'] = commentsChange.doc.id;

              /// comment added
              if (commentsChange.type == DocumentChangeType.added) {
                /// TODO For comments loading on post view, it does not need to loop.
                /// TODO Only for newly created comment needs to have loop and find a position to insert.

                int found = (post['comments'] as List).indexWhere(
                    (c) => c['order'].compareTo(commentData['order']) < 0);
                if (found > -1) {
                  post['comments'].insert(found, commentData);
                } else {
                  post['comments'].add(commentData);
                }

                forum.render(RenderType.commentCreate);
              }

              /// comment modified
              else if (commentsChange.type == DocumentChangeType.modified) {
                final int ci = post['comments']
                    .indexWhere((c) => c['id'] == commentData['id']);

                // print('comment index : $ci');
                if (ci > -1) {
                  post['comments'][ci] = commentData;
                }
                forum.render(RenderType.commentUpdate);
              }

              /// comment deleted
              else if (commentsChange.type == DocumentChangeType.removed) {
                post['comments']
                    .removeWhere((c) => c['id'] == commentData['id']);
                forum.render(RenderType.commentDelete);
              }
            });
          });
        }

        /// post update
        else if (documentChange.type == DocumentChangeType.modified) {
          // print('post updated');
          // print(post.toString());

          final int i = forum.posts.indexWhere((p) => p['id'] == post['id']);
          if (i > -1) {
            /// after post is updated, it doesn't have the 'comments' data.
            /// so it needs to be re-inserted.
            post['comments'] = forum.posts[i]['comments'];
            forum.posts[i] = post;
          }
          forum.render(RenderType.postUpdate);
        }

        /// post delete
        else if (documentChange.type == DocumentChangeType.removed) {
          /// TODO: when post is deleted, also remove comment list subscription to avoid memory leak.
          forum.commentsSubcriptions[post['id']].cancel();
          forum.posts.removeWhere((p) => p['id'] == post['id']);
          forum.render(RenderType.postDelete);
        } else {
          assert(false, 'This is error');
        }
      });
    });
  }

  /// [data] is the map to save into post document.
  ///
  /// `data['title']` and `data['content']` are needed to send push notification.
  Future editPost(Map<String, dynamic> data) async {
    if (data['title'] == null && data['content'] == null)
      throw "ERROR_TITLE_AND_CONTENT_EMPTY";

    if (data['id'] != null) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await postsCol.doc(data['id']).set(
            data,
            SetOptions(merge: true),
          );
    } else {
      data.remove('id');
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      DocumentReference doc = await postsCol.add(data);

      sendNotification(
        data['title'],
        data['content'],
        screen: '/forumView',
        id: doc.id,
        topic: "notification_post_" + data['category'],
      );
    }
  }

  /// [data] is the map to save into comment document.
  ///
  /// `post` property of [data] is required.
  Future editComment(Map<String, dynamic> data) async {
    if (data['post'] == null) throw 'ERROR_POST_IS_REQUIRED';
    final Map<String, dynamic> post = data['post'];
    data.remove('post');

    final commentsCol = commentsCollection(post['id']);
    data.remove('postid');

    // print('ref.path: ' + commentsCol.path.toString());

    /// update
    if (data['id'] != null) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await commentsCol.doc(data['id']).set(data, SetOptions(merge: true));
    }

    /// create
    else {
      final int parentIndex = data['parentIndex'];
      data.remove('parentIndex');

      /// get order
      data['order'] = getCommentOrderOf(post, parentIndex);
      data['uid'] = user.uid;

      /// get depth
      dynamic parent = getCommentParent(post['comments'], parentIndex);
      data['depth'] = parent == null ? 0 : parent['depth'] + 1;
      data['like'] = 0;
      data['dislike'] = 0;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      // print('comment create data: $data');
      await commentsCol.add(data);
      sendCommentNotification(post, data);
    }
  }

  Future deletePost(String postID) async {
    if (postID == null) throw "ERROR_POST_ID_IS_REQUIRED";
    await postsCol.doc(postID).delete();
  }

  Future deleteComment(String postID, String commentID) async {
    if (postID == null) throw "ERROR_POST_ID_IS_REQUIRED";
    if (commentID == null) throw "ERROR_COMMENT_ID_IS_REQUIRED";
    await postsCol.doc(postID).collection('comments').doc(commentID).delete();
  }

  /// Google sign-in
  ///
  ///
  Future<User> signInWithGoogle() async {
    // Trigger the authentication flow

    await GoogleSignIn().signOut(); // to ensure you can sign in different user.

    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw ERROR_SIGNIN_ABORTED;

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    onSocialLogin(userCredential.user);
    return userCredential.user;
  }

  /// Facebook social login
  ///
  ///
  Future<User> signInWithFacebook() async {
    // Trigger the sign-in flow
    LoginResult result;

    await FacebookAuth.instance
        .logOut(); // Need to logout to avoid 'User logged in as different Facebook user'
    result = await FacebookAuth.instance.login();
    if (result == null || result.accessToken == null) {
      throw ERROR_SIGNIN_ABORTED;
    }

    // Create a credential from the access token
    final FacebookAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(result.accessToken.token);

    // Once signed in, return the UserCredential
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(facebookAuthCredential);

    onSocialLogin(userCredential.user);

    return userCredential.user;
  }

  Future<User> signInWithApple() async {
    final oauthCred = await createAppleOAuthCred();
    // print(oauthCred);

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(oauthCred);
    return userCredential.user;
  }

  /// [folder] is the folder name on Firebase Storage.
  /// [source] is the source of file input. It can be Camera or Gallery.
  /// [maxWidth] is the max width of image to upload.
  /// [quality] is the quality of the jpeg image.
  ///
  /// It will return a string of URL of uploaded file.
  ///
  /// 'upload-cancelled' may return when there is no return(no value) from file selection.
  Future<String> uploadFile({
    @required String folder,
    ImageSource source,
    // @required File file,
    double maxWidth = 1024,
    int quality = 90,
    void progress(double progress),
  }) async {
    /// select file.
    File file = await pickImage(
      source: source,
      maxWidth: maxWidth,
      quality: quality,
    );

    /// if no file is selected then do nothing.
    if (file == null) throw 'upload-cancelled';
    // print('success: file picked: ${file.path}');

    final ref = FirebaseStorage.instance
        .ref(folder + '/' + getFilenameFromPath(file.path));

    UploadTask task = ref.putFile(file);
    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      double p = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      progress(p);
    });

    await task;
    final url = await ref.getDownloadURL();
    // print('DOWNLOAD URL : $url');
    return url;
  }

  /// [internationalNo] is the number to send the code to.
  ///
  /// [resendToken] is optional, and can be used when requesting to resend the verification code.
  /// [resendToken] can be obtained from [onCodeSent]'s return value.
  ///
  /// [onCodeSent] will be invoked once the code is generated and send to the number.
  /// It will include the [verificationID] and [codeResendToken].
  ///
  /// [onError] will be invoked when an error happen. It contains the error.
  ///
  /// first time requesting for verification code
  /// ```dart
  /// f.mobileAuthSendCode(
  ///     internationalNo,
  ///     ...
  ///  );
  /// ```
  ///
  /// resending verification code.
  /// ```dart
  ///  ff.mobileAuthSendCode(
  ///     internationalNo,
  ///     resendToken: codeResendToken,
  ///     ...
  ///  );
  /// ```
  ///
  mobileAuthSendCode(
    String internationalNo, {
    int resendToken,
    onCodeSent(String verificationID, int codeResendToken),
    onError(dynamic error),
  }) {
    if (internationalNo == null || internationalNo == '') {
      onError('Input your number');
    }

    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: internationalNo,

      /// resend token can be null.
      forceResendingToken: resendToken,

      /// called after the user submitted the phone number.
      codeSent: (String verID, [int forceResendToken]) async {
        // print('codeSent!');
        onCodeSent(verID, forceResendToken);
      },

      /// called whenever error happens
      verificationFailed: (FirebaseAuthException e) async {
        // print('verificationFailed!');
        onError(e);
      },

      /// time limit allowed for the automatic code retrieval to operate.
      timeout: const Duration(seconds: 30),

      /// will invoke after `timeout` duration has passed.
      codeAutoRetrievalTimeout: (String verID) {},

      /// this will only be called after the automatic code retrieval is performed.
      /// some phone may have the automatic code retrieval. some may not.
      verificationCompleted: (PhoneAuthCredential credential) {
        /// we can handle linking here.
        /// the user doesn't need to be redirected to code verification page.
        /// TODO: handle automatic linking/updating of user phone number.
      },
    );
  }

  /// [code] is the verification code sent to user's mobile number.
  /// [verificationId] is used to verify the current session, which is associated with the user's mobile number.
  ///
  /// After phone is verified, it will link/update the current user's phone number.
  Future mobileAuthVerifyCode({
    @required String code,
    @required String verificationId,
  }) async {
    PhoneAuthCredential creds = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    /// will throw error when
    ///   1: `code` is incorrect.
    ///   2: the mobile number associated by the verificationId is already in linked with other user.
    await user.linkWithCredential(creds);
  }

  /// Returns previous choice
  ///
  /// If it's first time vote, returns null.
  /// Or it returns the value of `choice`.
  Future<String> _voteChoice(DocumentReference doc) async {
    final snap = await doc.get();
    if (snap.exists) {
      final data = snap.data();
      return data['choice'];
    } else {
      return null;
    }
  }

  /// Returns vote document reference.
  _voteDoc({String postId, String commentId}) {
    DocumentReference voteDoc;
    if (commentId == null)
      voteDoc = postDocument(postId);
    else
      voteDoc = commentDocument(postId, commentId);
    voteDoc = voteDoc.collection('votes').doc(user.uid);
    return voteDoc;
  }

  /// Voting
  ///
  /// It supports post and comment.
  Future vote({String postId, String commentId, String choice}) async {
    if (choice != VoteChoice.like && choice != VoteChoice.dislike)
      throw 'wrong-choice';
    DocumentReference voteDoc = _voteDoc(postId: postId, commentId: commentId);

    final String previousChoice = await _voteChoice(voteDoc);
    if (previousChoice == null) {
      return voteDoc.set({'choice': choice});
    } else if (previousChoice == choice) {
      return voteDoc.set({'choice': ''});
    } else {
      return voteDoc.set({'choice': choice});
    }
  }

  Future<List<Map<String, dynamic>>> search(String keyword,
      {int hitsPerPage = 10, int pageNo = 0}) async {
    String algoliaIndexName = appSetting('ALGOLIA_INDEX_NAME');
    AlgoliaQuery query = algolia.instance
        .index(algoliaIndexName)
        .setPage(pageNo)
        .setHitsPerPage(hitsPerPage)
        .search(keyword);
    AlgoliaQuerySnapshot snap = await query.getObjects();
    // print('Result count: ${snap.nbHits}'); // no of results
    List<AlgoliaObjectSnapshot> results = snap.hits; // search result.

    List<Map<String, dynamic>> searchResults = [];
    results.forEach((object) {
      Map<String, dynamic> data = object.data;
      data['path'] = object.objectID;
      searchResults.add(data);
    });
    return searchResults;
  }
}
