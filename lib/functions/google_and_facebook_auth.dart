// ignore_for_file: await_only_futures

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_admission/constants.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseAuth firebaseAuth = FirebaseAuth.instance;

// Log in with Google ID
class GoogleLogIn {

  signInWithGoogle() async {
    final connCheck = await checkConnection();
    if (connCheck == true) {
      try {

        final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: <String>["email"]).signIn();

        final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
        if (googleUser?.email != null) {
          final methods = await firebaseAuth.fetchSignInMethodsForEmail(googleUser!.email);

          if (methods.isNotEmpty) {
            final credential = GoogleAuthProvider.credential(accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);
            try {
              var userDetails = await FirebaseAuth.instance.signInWithCredential(credential);
              final userdetails = firebaseAuth.currentUser;
              final userID = userdetails!.uid;
              final userEmail = userdetails.email;
              final userName = userdetails.displayName;
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("email", userEmail.toString());
              await prefs.setString('userID', userID);
              await prefs.setString('userName', userName.toString());
              await prefs.setBool('isGoogleSignIn', true);
              await prefs.setBool('admin', false);
              _firestore.terminate();
              return userDetails;
            }
            on FirebaseException {
              showToast('Encountered error while trying to process your request.\nTry to Login again');
            }
          }
          else{
            GoogleSignIn _googleSignIn = GoogleSignIn();
            await _googleSignIn.disconnect();
            await firebaseAuth.signOut();
            showToast('User does not exist.\nRegister User');
          }
        }
        else {
          showToast('No account selected.\nSelect account to proceed');
        }
      }
      catch (e) {
        await googleSignOut();
        showToast('Error contacting google servers.\nTry again in a while');
      }
    }
    else {
      showToast('No Internet Connection.\nConnect to Internet to Login.');
    }
  }

  googleSignOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? googleSignIn = await prefs.getBool('isGoogleSignIn');
    if(googleSignIn == true) {
      try {
        final connCheck = await checkConnection();
        if (connCheck == true) {
          GoogleSignIn _googleSignIn = GoogleSignIn();
          await _googleSignIn.disconnect();
          await firebaseAuth.signOut();
          await prefs.clear();
          return true;
        }
        else {
          showToast('No Internet Connection.\nCannot logout');
          return false;
        }
      }
      catch (e) {
        showToast("Encountered Unexpected Error. Cannot Logout");
        return false;
      }
    }
    else{
      await prefs.clear();
      return true;
    }
  }
}

// Sign up with Google ID
class GoogleSignUp {

  signInWithGoogle() async {
    final connCheck = await checkConnection();
    if(connCheck == true) {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: <String>["email"]).signIn();
        final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
        if (googleUser?.email != null) {
          final methods = await firebaseAuth.fetchSignInMethodsForEmail(googleUser!.email);
          if (methods.isEmpty) {
            final credential = await GoogleAuthProvider.credential(accessToken: googleAuth?.accessToken, idToken: googleAuth?.idToken);
            var userDetails = await firebaseAuth.signInWithCredential(credential);
            final userdetails = await firebaseAuth.currentUser;
            final userName = userdetails!.displayName;
            final userEmail = userdetails.email;
            final userID = userdetails.uid;
            final userData = {
              "email": "$userEmail",
              "name": "$userName",
              "admin": false
            };
            await _firestore.collection('user_data').doc(userID).set(userData);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("email", "$userEmail");
            await prefs.setString("userID", userID);
            await prefs.setString('userName', "$userName");
            await prefs.setBool('isGoogleSignIn', true);
            await prefs.setBool('admin', false);
            _firestore.terminate();
            return userDetails;
          }
          else {
            await GoogleLogIn().googleSignOut();
            showToast("User already exists. Log In.");
          }
        }
        else{
          showToast('No account selected.\nSelect account to proceed');
        }
      }
      catch (e) {
        await GoogleLogIn().googleSignOut();
        showToast('Error Reaching the Google servers for authentication');
      }
    }
    else{
      showToast('No internet connection.');
    }
  }
}

// class FacebookLogin {
//   Future<dynamic> signInWithFaceBook() async {
//     final connCheck = await checkConnection();
//     if(connCheck == true) {
//       try {
//         final LoginResult loginResult = await FacebookAuth.instance.login();
//         if(loginResult.accessToken == null){
//           showToast('No Account Selected');
//           FacebookAuth.instance.logOut();
//           return null;
//         }
//         else {
//           final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);
//           final userDetails = await FacebookAuth.instance.getUserData();
//           final methods = await firebaseAuth.fetchSignInMethodsForEmail(userDetails['email']);
//           if (methods.isNotEmpty) {
//             final details = await firebaseAuth.signInWithCredential(facebookAuthCredential);
//             SharedPreferences prefs = await SharedPreferences.getInstance();
//             final userEmail = details.user?.email;
//             final userID = details.user?.uid;
//             final userName = details.user?.displayName;
//             await prefs.setString("email", "$userEmail");
//             await prefs.setString('userID', "$userID");
//             await prefs.setString('userName', "$userName");
//             await prefs.setBool('isFacebookUser', true);
//             return details;
//           }
//           else {
//             showToast('User does not exist.\nRegister User');
//             return null;
//           }
//         }
//       } catch (e) {
//         showToast('Unexpected Error.\nTry Again');
//       }
//     }
//     else{
//       showToast('No Internet Connection.');
//     }
//   }
//   signOut()async{
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final connCheck = await checkConnection();
//     if(connCheck == true) {
//       try {
//         await FacebookAuth.instance.logOut();
//         await firebaseAuth.signOut();
//         await _firestore.terminate();
//         await prefs.clear();
//       }
//       catch (e){
//         showToast('Unexpected Error.\nCannot Logout');
//       }
//     }
//     else{
//       showToast('No Internet Connection.\nCannot Logout');
//     }
//   }
// }
//
// class FacebookSignUp{
//   Future<dynamic> signInWithFaceBook() async {
//     final connCheck = await checkConnection();
//     if(connCheck == true) {
//       try {
//         final LoginResult loginResult = await FacebookAuth.instance.login();
//         if(loginResult.accessToken == null){
//           showToast('No Account Selected');
//           FacebookAuth.instance.logOut();
//           return null;
//         }
//         else {
//           final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken!.token);
//           final userDetails = await FacebookAuth.instance.getUserData();
//           final methods = await firebaseAuth.fetchSignInMethodsForEmail(userDetails['email']);
//           if (methods.isEmpty) {
//               final details = await firebaseAuth.signInWithCredential(facebookAuthCredential);
//               SharedPreferences prefs = await SharedPreferences.getInstance();
//               final userEmail = details.user?.email;
//               final userID = details.user?.uid;
//               final userName = details.user?.displayName;
//               await prefs.setString("email", "$userEmail");
//               await prefs.setString('userID', "$userID");
//               await prefs.setString('userName', "$userName");
//               await prefs.setBool('isFacebookUser', true);
//               final userData = {
//                 "email": "$userEmail",
//                 "name": "$userName",
//                 "admin": false
//               };
//               await _firestore.collection('user_data').doc(userID).set(userData);
//               return details;
//             }
//           else {
//             showToast('User already exists.\nLog In');
//             return null;
//           }
//         }
//       } catch (e) {
//         showToast('Unexpected Error.\nTry Again');
//         return null;
//       }
//     }
//     else{
//       showToast('No Internet Connection.');
//       return null;
//     }
//   }
// }