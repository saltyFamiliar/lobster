import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lobster/binance.dart' as binance;
import 'package:shared_preferences/shared_preferences.dart';

List<String> pairList = ['BNBUSDT', 'BTCUSDT', 'ETHUSDT'];

class CoinData extends StatefulWidget {
  CoinData({Key key}) : super(key: key);

  @override
  _CoinDataState createState() => _CoinDataState();
}

Future<String> parseBalances() async {
  dynamic balances =
      await binance.fetchData(binance.spotEP, binance.timeStampQ());
  var amounts = balances['balances'];
  String nonZeroBalances = '';
  for (var b in amounts) {
    if (double.parse(b['free']) > 0) {
      nonZeroBalances += b['asset'];
    }
  }

  return nonZeroBalances;
}

class _CoinDataState extends State<CoinData> {
  int _counter = 0;

  _loadCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = (prefs.getInt('counter'));
    });
  }

  incrementCounter(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int newCounter = 0;
    try {
      newCounter = int.parse(value);
    } catch (_) {}

    setState(() {
      _counter = newCounter;
      prefs.setInt('counter', _counter);
    });
  }

  void refreshData() {
    setState(() {
      incrementCounter('blah');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      
      // body: Row(
      //     children: [
      //       Column(
      //         mainAxisAlignment: MainAxisAlignment.start,
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         children: <Widget>[
      //           Text(_counter.toString()),
      //           TextField(onSubmitted: incrementCounter)
      //         ],
      //       ),
      //       Column(
      //         mainAxisAlignment: MainAxisAlignment.start,
      //         crossAxisAlignment: CrossAxisAlignment.center,
      //         children: <Widget>[
      //           Text(_counter.toString()),
      //           TextField(onSubmitted: incrementCounter)
      //         ],
      //       )
      //     ],
      //   ),
    );
  }
}
