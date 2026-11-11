import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/welcome_page.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Keep a local copy of the database so screens open instantly from cache
  // and keep working offline; Firestore syncs changes in the background.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await _activateAppCheck();
  runApp(const WordWiserApp());
}

/// reCAPTCHA v3 site key for the web build (Firebase console › App Check).
/// Leave empty if you only run on Android/iOS.
const _recaptchaSiteKey = '';

/// App Check proves requests come from your real app. Firebase AI Logic
/// (used for the word of the day) requires it. In debug builds a debug token
/// is printed in the console — add it in Firebase console › App Check.
Future<void> _activateAppCheck() async {
  try {
    if (kIsWeb && _recaptchaSiteKey.isEmpty) return;
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttestWithDeviceCheckFallback,
      webProvider: kIsWeb ? ReCaptchaV3Provider(_recaptchaSiteKey) : null,
    );
  } catch (e) {
    // Never block the app; the word of the day falls back to the built-in list.
    debugPrint('App Check not activated: $e');
  }
}

class WordWiserApp extends StatelessWidget {
  const WordWiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordWiser',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// Shows the welcome screen when signed out and the home screen when signed
/// in. Because it listens to the auth state, logging in, signing up and
/// logging out all land on the right screen automatically, and people stay
/// logged in between launches.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the penguin once up front so it never pops in late.
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage(penguinAsset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges also fires when the display name is set after sign-up.
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: snapshot.data == null
              ? const WelcomePage(key: ValueKey('welcome'))
              : HomePage(key: ValueKey(snapshot.data!.uid)),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: WWBackground(
        child: Center(child: WordWiserLogo(size: 48)),
      ),
    );
  }
}
