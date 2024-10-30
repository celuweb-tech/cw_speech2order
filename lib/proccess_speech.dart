import 'package:cw_speech2order/constants/dictionary.dart';
import 'package:cw_speech2order/constants/numbers.dart';
import 'package:cw_speech2order/model.dart';
import 'package:cw_speech2order/search.dart';

/// Processes the results of speech recognition and prepares data for display.
///
/// This function takes the recognized speech text and a list of products as input.
/// It then performs the following steps:
///   1. Processes the speech text using the `processWords` function .
///   2. Extracts the product quantity from the processed words using `processProductQuantity`.
///   3. Removes the quantity information from the processed words using `removeProductQuantity`.
///   4. Searches for products based on the processed words using the `searchProducts`.
///   5. Returns the response list.
///
Future<List<Map<String, dynamic>>> proccesSpeechResult({
  required String speechText,
  required List<Speech2OrderProduct> products,
}) async {
  if (speechText.isEmpty) {
    return [];
  }

  List<Map<String, dynamic>> response = [];

  products = normalizeProducts(products);

  // Process speech text
  List<String> processedText = normalizeWords(speechText.split(' '));

  processedText = processNumbers(speechText);
  // Extract and remove product quantity (implementations assumed elsewhere)
  int productQuantity = processProductQuantity(processedText);
  if (productQuantity > 0) {
    processedText = removeProductQuantity(processedText);
  }

  processedText = processDictionaryWords(processedText.join(' '));

  // Search for products based on processed words
  List<Speech2OrderProduct> productsBySearch =
      searchProducts(products, processedText);

  // Build response with product information if found
  if (productsBySearch.isNotEmpty) {
    for (var product in productsBySearch) {
      Map<String, dynamic> item = {
        'title': product.title,
        'code': product.barCode,
        'quantity': productQuantity,
      };
      response.add(item);
    }

    return response;
  } else {
    // No products found, return empty list
    return [];
  }
}

List<String> normalizeWords(List<String> words) {
  // Normalize keywords
  return words = words
      .map((word) => word
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[áàâãäå]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòôõöø]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u')
          .replaceAll(RegExp(r'[.?!-]'), ''))
      .toList();
}

List<Speech2OrderProduct> normalizeProducts(
    List<Speech2OrderProduct> products) {
  // Normalize product titles
  return products = products
      .map((producto) => Speech2OrderProduct(
          title: producto.title
              .toLowerCase()
              .replaceAll(RegExp(r'[áàâãäå]'), 'a')
              .replaceAll(RegExp(r'[éèêë]'), 'e')
              .replaceAll(RegExp(r'[íìîï]'), 'i')
              .replaceAll(RegExp(r'[óòôõöø]'), 'o')
              .replaceAll(RegExp(r'[úùûü]'), 'u')
              .replaceAll(RegExp(r'[.?!-]'), ''),
          barCode: producto.barCode))
      .toList();
}

/// Procesa las palabras del texto reemplazándolas por sus abreviaturas si existen en el diccionario.
List<String> processDictionaryWords(String text) {
  final words = text.split(' ');

  for (int i = 0; i < words.length; i++) {
    final word = words[i];

    if (dictionary.containsKey(word)) {
      final abbreviations = dictionary[word]!;
      words.replaceRange(
        i,
        i + 1,
        [word, ...abbreviations],
      );
      i += abbreviations.length;
    }
  }

  return words;
}

///   * `processNumbers`: Splits text into words, replaces written-out numbers
///     with numeric equivalents, groups sequences of digits, and identifies
///     quantities with "x" followed by a number.
List<String> processNumbers(String text) {
  final words = text.split(' ');

  for (int i = 0; i < words.length; i++) {
    for (int j = words.length; j >= i + 1; j--) {
      final combinacion = words.sublist(i, j).join(' ');
      if (numbersByTextName.containsKey(combinacion)) {
        words.replaceRange(i, j, [numbersByTextName[combinacion].toString()]);
        break; // Salimos del bucle interior una vez que se encuentra una coincidencia
      }
    }
  }

  List<String> result = groupNumbers(words);

  for (int i = 0; i < result.length; i++) {
    if ((result[i] == 'por' || result[i] == '*') && result.length > i + 1) {
      final numero = result[i + 1];
      if (RegExp(r'^\d+$').hasMatch(numero)) {
        result.replaceRange(i, i + 2, ['x$numero']);
      }
    }
  }

  return result;
}

///   * `processProductQuantity`: Extracts the quantity information from the
///     processed words. It checks for formats like "x25" or direct numbers
///     and returns the quantity as an integer.
int processProductQuantity(List<String> words) {
  // Verificar si alguna palabra contiene una cantidad directa o un formato 'x25'
  if (words.any((word) => RegExp(r'^x\d+$').hasMatch(word))) {
    // Buscar el formato 'x25' y devolver la cantidad
    final xFormat = words.firstWhere((word) => RegExp(r'^x\d+$').hasMatch(word),
        orElse: () => '');
    if (xFormat.isNotEmpty) {
      return int.parse(xFormat.substring(1));
    }
  }

  return 1;
}

///   * `removeProductQuantity`: Removes any quantity information (words
///     starting with "x" followed by digits) from the processed words list.
List<String> removeProductQuantity(List<String> words) {
  final regex = RegExp(r'^x\d+$');
  return words
      .map((word) => word.replaceFirst(regex, ''))
      .where((element) => element.isNotEmpty)
      .toList();
}

///   * `groupNumbers`: Groups sequences of digits together into single words
///     in the processed text.
List<String> groupNumbers(List<String> palabras) {
  List<String> result = [];
  String currentNumber = '';

  for (String palabra in palabras) {
    if (RegExp(r'^\d+$').hasMatch(palabra)) {
      currentNumber += palabra;
    } else {
      if (currentNumber.isNotEmpty) {
        result.add(currentNumber);
        currentNumber = '';
      }
      result.add(palabra);
    }
  }

  if (currentNumber.isNotEmpty) {
    result.add(currentNumber);
  }

  return result;
}
