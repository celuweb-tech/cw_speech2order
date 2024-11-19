class Speech2OrderProduct {
  final String title;
  final String barCode;
  final String? quantity;

  Speech2OrderProduct({
    required this.title,
    required this.barCode,
    this.quantity,
  });

  factory Speech2OrderProduct.fromJson(Map<String, dynamic> json) {
    return Speech2OrderProduct(
      title: json['title'],
      barCode: json['bar_code'],
      quantity: json['quantity'],
    );
  }
}
