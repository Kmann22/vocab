import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocab/pages/add_new_word.dart';
import 'package:vocab/pages/game_wordle.dart';
import 'package:vocab/pages/loginpage.dart';
import 'package:vocab/pages/our_dictionary_page.dart';
import 'package:vocab/pages/game_hangaroo.dart';

void main() => runApp(MenuApp());

class MenuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WORDWISER',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headline6: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          bodyText2: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
        ),
      ),
      home: MenuPage(),
    );
  }
}

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.white), // Profile icon
          onPressed: () {
            // Show profile dialog
            _showProfileDialog(context);
          },
        ),
        title: Text(
          'WORDWISER',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Color.fromARGB(255, 20, 14, 2),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ), // Logout icon
            onPressed: () {
              // Handle logout action
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigoAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
          children: <Widget>[
            // Add New Word
            _buildMenuItem(
              context,
              'Add a New Word',
              Icons.add_circle,
              NewWordPage(),
              'Expand your vocabulary.',
            ),
            // Our Dictionary
            _buildMenuItem(
              context,
              'Our Dictionary',
              Icons.book,
              OurDictionary(),
              'Explore your saved words.',
            ),
            // Option 3: Hangaroo
            _buildMenuItem(
              context,
              'Hangaroo',
              Icons.games,
              HangarooPage(), // Assume this is the page for Hangaroo
              'Guess words in this classic game.',
            ),
            // Option 4: Wordle
            _buildMenuItem(
              context,
              'Wordle',
              Icons.videogame_asset,
              WordlePage(), // Page for Wordle
              'Learn with this fun word game.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
    String description,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: Theme.of(context).textTheme.headline6),
        subtitle:
            Text(description, style: Theme.of(context).textTheme.bodyText2),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => page,
            ),
          );
        },
      ),
    );
  }

  void _showProfileDialog(BuildContext context) async {
    // Fetch user details
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // User is not logged in
    }

    String email = user.email ?? 'Not available';
    String name = user.displayName ?? 'Not available';

    // Fetch number of words added by the user
    int wordCount = await _getUserWordCount(user.uid);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Profile Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text(name),
                subtitle: Text('Name'),
              ),
              ListTile(
                leading: Icon(Icons.email),
                title: Text(email),
                subtitle: Text('Email'),
              ),
              ListTile(
                leading: Icon(Icons.library_books),
                title: Text('$wordCount words'),
                subtitle: Text('Words Added'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<int> _getUserWordCount(String userId) async {
    try {
      // Query Firestore for words added by the user
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Words')
          .where('UserId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching user word count: $e');
      return 0;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await FirebaseAuth.instance.signOut(); // Firebase sign-out
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                ); // Navigate to the login page
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
