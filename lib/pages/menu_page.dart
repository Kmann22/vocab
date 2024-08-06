import 'package:flutter/material.dart';
import 'package:vocab/pages/add_new_word.dart';
import 'package:vocab/pages/global_dictionary_page.dart';
import 'package:vocab/pages/our_dictionary_page.dart';
import 'package:vocab/pages/play_page.dart';

class MenuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocabulary App',
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
        title: Text(
          'Vocabulary Menu',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Color.fromARGB(255, 20, 14, 2),
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
            _buildMenuItem(context, 'Add a New Word', Icons.add_circle,
                NewWordPage(), 'Expand your vocabulary.'),
            _buildMenuItem(context, 'Our Dictionary', Icons.book,
                OurDictionary(), 'Explore your saved words.'),
            _buildMenuItem(context, 'Global Dictionary', Icons.language,
                GlobalDictionary(), 'Look up new words globally.'),
            _buildMenuItem(context, 'Play', Icons.videogame_asset, Play(),
                'Learn with fun games.'),
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
}
