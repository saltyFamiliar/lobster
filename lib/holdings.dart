class Holding {
  final int domain;
  double amount;
  String name;
  double price;
  double value;
  String usdtPair;
  bool isInSavings;

  Holding(this.domain, this.amount, this.name) {
    if (this.name == "BETH") {
      this.name = "ETH";
    }
    this.isInSavings = (name.substring(0, 2) == 'LD');
    if (this.isInSavings) {
      this.usdtPair = name.substring(2) + 'USDT';
    } else {
      this.usdtPair = name + 'USDT';
    }
  }

  factory Holding.fromJson(domainIndex, json) {
    return Holding(domainIndex, double.parse(json['free']), json['asset']);
  }

  Holding clone() {
    return Holding(this.domain, this.amount, this.name);
  }

  void setPrice(double price) {
    this.price = price;
    this.value = this.price * this.amount;
  }
}
