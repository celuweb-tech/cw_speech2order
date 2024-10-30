class Speech2OrderProduct {
  final String title;
  final String barCode;
  final String? quantity;
  final String? unitQuantity;

  Speech2OrderProduct(
      {required this.title,
      required this.barCode,
      this.quantity,
      this.unitQuantity});

  factory Speech2OrderProduct.fromJson(Map<String, dynamic> json) {
    return Speech2OrderProduct(
      title: json['titulo'],
      barCode: json['cod_barras'],
      quantity: json['cantidad'],
      unitQuantity: json['cantidad_de_unidades'],
    );
  }
}
