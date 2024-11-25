import 'package:cw_speech2order/constants/dictionary.dart';
import 'package:cw_speech2order/constants/numbers.dart';
import 'package:cw_speech2order/model.dart';
import 'package:cw_speech2order/search.dart';

/// Processes speech text into product orders.
///
/// [speechText] The text from speech recognition.
/// [products] List of available products to search from.
///
/// Returns list of maps containing matched products with quantities.
/// Returns empty list if no valid orders found or text doesn't start with number.
Future<List<Map<String, dynamic>>> proccesSpeechResult({
  required String speechText,
  required List<Speech2OrderProduct> products,
}) async {
  List<String> words = speechText.split(' ');
  if (words.isNotEmpty && !RegExp(r'^\d+').hasMatch(words[0])) {
    return [];
  }

  List<Map<String, dynamic>> response = [];
  List<String> processedText = normalizeWords(words);

  products = normalizeProducts(products);
  processedText = processNumbers(speechText);
  int productQuantity = processProductQuantity(processedText);

  if (productQuantity > 0) {
    processedText = removeProductQuantity(processedText);
  }

  processedText = processDictionaryWords(processedText.join(' '));

  List<Speech2OrderProduct> productsBySearch =
      searchProducts(products, processedText);

  if (productsBySearch.isNotEmpty) {
    for (var product in productsBySearch) {
      Map<String, dynamic> item = {
        'title': product.title,
        'code': product.code,
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

/// Normalizes text by removing accents and special characters.
///
/// [words] List of words to normalize.
///
/// Returns list of normalized words in lowercase without special characters.
List<String> normalizeWords(List<String> words) {
  return words = words
      .map((word) => word
          .trim()
          .toLowerCase()
          .replaceAll(':', '')
          .replaceAll(RegExp(r'[áàâãäå]'), 'a')
          .replaceAll(RegExp(r'[éèêë]'), 'e')
          .replaceAll(RegExp(r'[íìîï]'), 'i')
          .replaceAll(RegExp(r'[óòôõöø]'), 'o')
          .replaceAll(RegExp(r'[úùûü]'), 'u')
          .replaceAll(RegExp(r'[.?!-]'), ''))
      .toList();
}

/// Normalizes product titles for consistent search matching.
///
/// [products] List of products to normalize.
///
/// Returns new list with normalized product titles.
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
          code: producto.code))
      .toList();
}

// Replaces words with their dictionary abbreviations.
///
/// [text] Text to process with dictionary.
///
/// Returns list containing original words and their abbreviations.
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

/// Converts text numbers to digits and formats quantities.
///
/// [text] Text containing numbers to process.
///
/// Returns list with numbers converted to standard formats.
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

/// Extracts product quantity from formatted text.
///
/// [words] List of processed words to check for quantity.
///
/// Returns quantity as integer, defaults to 1 if not found.
/// RegExp(r'^x\d+$') check format (x25)
int processProductQuantity(List<String> words) {
  if (words.any((word) => RegExp(r'^x\d+$').hasMatch(word))) {
    final xFormat = words.firstWhere((word) => RegExp(r'^x\d+$').hasMatch(word),
        orElse: () => '');
    if (xFormat.isNotEmpty) {
      return int.parse(xFormat.substring(1));
    }
  }

  return 1;
}

/// Removes quantity indicators from word list.
///
/// [words] List to remove quantity formats from.
///
/// Returns filtered list without quantity indicators.
List<String> removeProductQuantity(List<String> words) {
  final regex = RegExp(r'^x\d+$');
  return words
      .map((word) => word.replaceFirst(regex, ''))
      .where((element) => element.isNotEmpty)
      .toList();
}

/// Removes quantity indicators from word list.
///
/// [words] List to remove quantity formats from.
///
/// Returns filtered list without quantity indicators.
List<String> groupNumbers(List<String> words) {
  List<String> result = [];
  String currentNumber = '';

  for (String word in words) {
    if (RegExp(r'^\d+$').hasMatch(word)) {
      currentNumber += word;
    } else {
      if (currentNumber.isNotEmpty) {
        result.add(currentNumber);
        currentNumber = '';
      }
      result.add(word);
    }
  }

  if (currentNumber.isNotEmpty) {
    result.add(currentNumber);
  }

  return result;
}
