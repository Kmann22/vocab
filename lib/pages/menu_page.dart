import 'package:flutter/material.dart';
import 'package:vocab/pages/add_new_word.dart';
import 'package:vocab/pages/global_dictionary_page.dart';
import 'package:vocab/pages/our_dictionary_page.dart';
import 'package:vocab/pages/play_page.dart';

class MenuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Page Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        title: Text('Menu Page'),
      ),
      body: ListView(
        children: <Widget>[
          _buildMenuItem(
              context, 'Add a new word', Icons.settings, NewWordPage()),
          _buildMenuItem(
              context, 'Our Dictionary', Icons.account_circle, OurDictionary()),
          _buildMenuItem(
              context, 'Dictionary', Icons.shopping_cart, GlobalDictionary()),
          _buildMenuItem(context, 'Play', Icons.info, Play()),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}
