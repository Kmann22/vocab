import 'package:flutter/material.dart';
import 'package:vocab/pages/loginpage.dart';
import 'package:vocab/pages/menu_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dictionary App',
      // theme: ThemeData(
      //   primaryColor: Color(0xFF1a1a2e),
      //   hintColor: Color(0xFFe94560),
      //   backgroundColor: Color(0xFFf5f5f5),
      //   visualDensity: VisualDensity.adaptivePlatformDensity,
      // ),
      home: LoginPage(),
    );
  }
}
