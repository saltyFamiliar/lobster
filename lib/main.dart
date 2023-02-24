import 'package:flutter/material.dart';
import 'account_info.dart';
import 'coin_data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lobster',
      theme: ThemeData(
          primarySwatch: Colors.deepOrange, brightness: Brightness.dark),
      home: MyHomePage(title: 'Lobster Main Testing Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<Widget> _children = [CoinData(), AccountInfo()];
  int _currentIndex = 0;

  onItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
      //  title: Text(widget.title),
      //),
      
      body: _children.elementAt(_currentIndex),
      
      bottomNavigationBar: BottomNavigationBar(
        onTap: onItemTap,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        items: [
          BottomNavigationBarItem(
              label: 'Settings', icon: Icon(Icons.settings)),
          //BottomNavigationBarItem(label: 'Home', icon: Icon(Icons.home)),
          BottomNavigationBarItem(
              label: 'Account', icon: Icon(Icons.pie_chart)),
        ],
      ),
    );
  }
}
