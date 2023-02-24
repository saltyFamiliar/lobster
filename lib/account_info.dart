import 'dart:math';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:shared_preferences/shared_preferences.dart';
import 'binance.dart';
import 'holdings.dart';

List<DataColumn> columnHeaders = [
  DataColumn(label: Text('Currency')),
  DataColumn(label: Text('Price')),
  DataColumn(label: Text('Amount')),
  DataColumn(label: Text('Value')),
  DataColumn(label: Text('Target %')),
  DataColumn(label: Text('Total')),
  //DataColumn(label: Text('% Range')),
  DataColumn(label: Text('To Buy'))
];
List<String> blacklist = [
  'SBTC',
  'BCX',
  'EON',
  'ADD',
  'MEETONE',
  'ATD',
  'EOP',
  'ASR'
];
List<Holding> allHoldings = [], valueFilteredHoldings = [], unionHoldings = [];
List<DataRow> dataRows = [];
Map targetMap = {};
double totalAccountValue = 0;
double rebalanceRange = 0.175;

class AccountInfo extends StatefulWidget {
  AccountInfo({Key key}) : super(key: key);

  @override
  _AccountInfoState createState() => _AccountInfoState();
}

Map<String, double> genPriceMap(List<dynamic> json) {
  Map<String, double> priceMap = {};

  for (var s = 0; s < json.length; s++) {
    var pairMap = json[s];
    var pairName = pairMap['symbol'];
    priceMap[pairName] = double.parse(pairMap['price']);
  }
  return priceMap;
}

List<Holding> joinHoldings(List<Holding> holdings) {
  List<Holding> joinedHoldings = [];
  var alreadyCounted = {};

  for (var i = 0; i < holdings.length; i++) {
    if (alreadyCounted.containsKey(i)) {
      continue;
    }

    var h = holdings[i].clone();

    for (var j = i + 1; j < holdings.length; j++) {
      if (holdings[j].usdtPair == h.usdtPair) {
        h.amount += holdings[j].amount;
        alreadyCounted[j] = 0;
      }
    }
    h.value = h.amount * h.price;
    joinedHoldings.add(h);
  }

  return joinedHoldings;
}

DataRow dataRowFromHolding(Holding h, double accountValue) {
  double lowerBound = targetMap[h.usdtPair] * (1 - rebalanceRange);
  double upperBound = targetMap[h.usdtPair] * (1 + rebalanceRange);
  double totalPercent = h.value / accountValue * 100;
  double toBuy = ((targetMap[h.usdtPair] - totalPercent) * totalAccountValue) /
      h.price /
      100;
  var totalColor;
  if (totalPercent > upperBound) {
    totalColor = Colors.green;
  } else if (totalPercent < lowerBound) {
    totalColor = Colors.red;
  } else {
    totalColor = Colors.white;
  }
  return DataRow(cells: [
    DataCell(Text(h.name)),
    DataCell(Text('\$' + h.price.toStringAsFixed(2))),
    DataCell(Text(h.amount.toStringAsFixed(5))),
    DataCell(Text('\$' + h.value.toStringAsFixed(2))),
    DataCell(TextFormField(
      initialValue: targetMap[h.usdtPair].toString(),
      onFieldSubmitted: (value) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        double newValue = h.value / accountValue * 100;
        try {
          newValue = double.parse(value);
        } catch (_) {}
        prefs.setDouble(h.usdtPair, newValue);
      },
    )),
    DataCell(Text(totalPercent.toStringAsFixed(2) + '%',
        style: TextStyle(color: totalColor))),
    //DataCell(Text(
    //    '${lowerBound.toStringAsFixed(2)} - ${upperBound.toStringAsFixed(2)}')),
    DataCell(
        Text(toBuy.toStringAsPrecision(4), style: TextStyle(color: totalColor)))
  ]);
}

Future<List<charts.Series<Holding, int>>> _generateAccountData() async {
  allHoldings = [];
  valueFilteredHoldings = [];
  totalAccountValue = 0;
  int holdingsCount = 0;
  var spotHoldings = [], savHoldings = [];

  final spotData = await fetchData(spotEP, '${timeStampQ()}');
  final spotAmounts = spotData['balances'];
  final marketData = await fetchPrices();
  var priceMap = genPriceMap(marketData);


  for (var s in spotAmounts) {
    if (double.parse(s['free']) > 0) {
      var holding = Holding.fromJson(holdingsCount, s);
      if (holding.name != 'LDUSDT' && holding.name != 'USDT') {
        if (!priceMap.containsKey(holding.usdtPair)) {
          continue;
        }
      }
      allHoldings.add(holding);
      holdingsCount += 1;

      if (holding.isInSavings) {
        savHoldings.add(holding);
      } else {
        spotHoldings.add(holding);
      }
    }
  }


  for (Holding h in allHoldings) {
    if (h.name == 'USDT') {
      continue;
    }
    if (h.name == 'LDUSDT') {
      h.amount += 100;
      h.setPrice(1);
    } else {
      h.setPrice(priceMap[h.usdtPair]);
    }
    if (h.value > 10) {
      valueFilteredHoldings.add(h);
      totalAccountValue += h.value;
    }
  }
  valueFilteredHoldings.sort((a, b) => b.value.compareTo(a.value));


  SharedPreferences prefs = await SharedPreferences.getInstance();
  for (var h in valueFilteredHoldings) {
    targetMap[h.usdtPair] = (prefs.getDouble(h.usdtPair) ?? 0);
  }


  print(valueFilteredHoldings);
  dataRows = valueFilteredHoldings
      .map((x) => dataRowFromHolding(x, totalAccountValue))
      .toList();


  return [
    charts.Series<Holding, int>(
      id: 'Holdings',
      domainFn: (Holding holding, _) => holding.domain,
      measureFn: (Holding holding, _) => holding.value,
      data: valueFilteredHoldings,
      colorFn: (_, index) => charts.MaterialPalette.deepOrange
          .makeShades(valueFilteredHoldings.length)[index],
      labelAccessorFn: (Holding row, _) => '${row.name}',
    )
  ];
}

Future<charts.PieChart> myPieChart() async {
  var chartData = await _generateAccountData();
  return charts.PieChart(chartData,
      animate: true,
      defaultRenderer: charts.ArcRendererConfig(
          arcWidth: 62,
          startAngle: pi,
          arcRendererDecorators: [
            charts.ArcLabelDecorator(
                labelPosition: charts.ArcLabelPosition.outside,
                outsideLabelStyleSpec: charts.TextStyleSpec(
                    fontSize: 12, color: charts.Color.white))
          ]));
}

class _AccountInfoState extends State<AccountInfo> {
  dynamic myPie;

  void refreshData() {
    setState(() {
      myPie = myPieChart();
    });
  }

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portfolio'),
      ),
      body: Row(children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FutureBuilder(
                    future: myPie,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [
                            Container(
                                height: 250, child: snapshot.data as Widget),
                            Text(
                              "\n\nTotal \$: $totalAccountValue",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Divider(
                                color: Colors.white,
                                height: 50,
                                thickness: 0.0),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                child: DataTable(
                                    columns: columnHeaders, rows: dataRows),
                              ),
                            )
                          ],
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(100.0),
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepOrange),
                          ),
                        );
                      }
                    })
              ],
            ),
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepOrange,
          onPressed: refreshData,
          tooltip: 'Refresh Data',
          child: Icon(Icons.refresh)),
    );
  }
}
