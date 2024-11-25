import 'package:cw_speech2order/model.dart';

/// Busca productos en la [productos] basados en el codigo del producto [code].
///
/// Si la primera palabra clave coincide con el patrón `^\[0-9\].*`, se realiza una búsqueda por código de producto.
/// De lo contrario,no se realiza una búsqueda.
///
/// Devuelve una lista de [Speech2OrderProduct] que coinciden con el codigo, ordenado por relevancia.
List<Speech2OrderProduct> searchProducts(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  bool searchByCode = RegExp(r'^[0-9]').hasMatch(palabrasClave.first);
  const productsToTake = 20;

  if (searchByCode) {
    return productos
        .where((producto) =>
            producto.code.toLowerCase().endsWith(palabrasClave.first))
        .take(productsToTake)
        .toList();
  } else {
    return [];
  }
}
