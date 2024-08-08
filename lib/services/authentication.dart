import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Optionally update the user's profile with the provided name
      await userCredential.user?.updateProfile(displayName: name);
      await userCredential.user?.reload();
      // Optionally add additional user data to your database
    } catch (e) {
      throw e; // Propagate the error
    }
  }

  static Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e; // Propagate the error
    }
  }
}
