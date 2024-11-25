class Speech2OrderProduct {
  final String title;
  final String code;
  String? quantity;

  Speech2OrderProduct({
    required this.title,
    required this.code,
    this.quantity,
  });

  factory Speech2OrderProduct.fromJson(Map<String, dynamic> json) {
    return Speech2OrderProduct(
      title: json['title'],
      code: json['code'],
      quantity: json['quantity'],
    );
  }
}
