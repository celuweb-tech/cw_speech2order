import 'package:cw_speech2order/model.dart';

/// Busca productos en la [productos] basados en las [palabrasClave].
///
/// Si la primera palabra clave coincide con el patrón `^\[0-9\].*`, se realiza una búsqueda por código de barras.
/// De lo contrario, se realiza una búsqueda difusa por título.
///
/// En la búsqueda por título, se intenta encontrar coincidencias para la frase completa.
/// Si no se encuentran coincidencias para la frase completa, se realiza una búsqueda por frase parcial.
/// Si no se encuentran coincidencias para la frase parcial, se realiza una búsqueda por prefijos de la palabra clave.
///
/// Los títulos de los productos y las palabras clave se normalizan eliminando tildes y convirtiendo a minúsculas antes de la búsqueda.
///
/// Devuelve una lista de [Speech2OrderProduct] que coinciden con las palabras clave, ordenados por relevancia.
List<Speech2OrderProduct> searchProducts(
    List<Speech2OrderProduct> productos, List<String> palabrasClave) {
  bool searchByCode = RegExp(r'^[0-9]').hasMatch(palabrasClave.first);
  const productsToTake = 20;

  if (searchByCode) {
    //if (palabrasClave.every((palabra) => RegExp(r'^\d+$').hasMatch(palabra))) {
    return productos
        .where((producto) =>
            producto.code.toLowerCase().endsWith(palabrasClave.first))
        .take(productsToTake)
        .toList();
  } else {
    return [];
  }
  //}
  // return [];
}

/// Extensión para la clase [List] que agrega un método [firstWhereOrNull].
extension ListExtension<T> on List<T> {
  /// Devuelve el primer elemento de la lista que cumple con la condición [test],
  /// o `null` si no se encuentra ninguno.
  T? firstWhereOrNull(bool Function(T) test) {
    for (var item in this) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}
