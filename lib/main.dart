import 'package:flutter/material.dart';
import 'package:cw_speech2order/model.dart';
import 'package:badges/badges.dart' as badge;

import 'package:cw_speech2order/proccess_speech.dart';
import 'package:cw_speech2order/select_products_dialog.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Speech2OrderPage extends StatefulWidget {
  const Speech2OrderPage(
      {Key? key,
      required this.products,
      required this.primaryColor,
      this.secondaryColor = Colors.white})
      : super(key: key);

  final List<Speech2OrderProduct> products;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  // ignore: library_private_types_in_public_api
  _Speech2OrderPageState createState() => _Speech2OrderPageState();
}

class _Speech2OrderPageState extends State<Speech2OrderPage> {
  final SpeechToText _speechToText = SpeechToText();
  final List<Map<String, dynamic>> _recognitionResult = [];

  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (_speechToText.isNotListening) {
      List<Map<String, dynamic>> response = await proccesSpeechResult(
          speechText: result.recognizedWords, products: widget.products);
      if (response.isNotEmpty) {
        if (response.length <= 1) {
          setState(() {
            _recognitionResult.addAll(response);
          });
        } else {
          // ignore: use_build_context_synchronously
          List<Map<String, dynamic>> selectedItems = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Speech2OrderSelectionDialog(
                    items: response,
                    primaryColor: widget.primaryColor,
                  );
                },
              ) ??
              [];

          if (selectedItems.isNotEmpty) {
            setState(() {
              _recognitionResult.addAll(selectedItems);
            });
          }
        }
      }
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      _recognitionResult[index]['quantity'] = newQuantity;
    });
  }

  void _showQuantityDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController quantityController = TextEditingController(
          text: _recognitionResult[index]['quantity'].toString(),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          quantityController.selection = TextSelection.fromPosition(
            TextPosition(offset: quantityController.text.length),
          ); // Set cursor position after frame build
        });

        return AlertDialog(
          title: const Text('Cambiar Cantidad'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Ingrese la cantidad',
            ),
            onSubmitted: (text) {
              int newQuantity = int.tryParse(quantityController.text) ?? 1;
              if (newQuantity > 0) {
                _updateQuantity(index, newQuantity);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La cantidad debe ser mayor a 0'),
                  ),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                int newQuantity = int.tryParse(quantityController.text) ?? 1;
                if (newQuantity > 0) {
                  _updateQuantity(index, newQuantity);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La cantidad debe ser mayor a 0'),
                    ),
                  );
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    // If listening is active show the recognized words
                    _speechToText.isListening
                        ? _lastWords
                        // If listening isn't active but could be tell the user
                        // how to start it, otherwise indicate that speech
                        // recognition is not yet ready or not supported on
                        // the target device
                        : _speechEnabled
                            ? 'Tap the microphone to start listening...'
                            : 'Speech not available',
                  ),
                ),
                Expanded(
                  child: _recognitionResult.isNotEmpty
                      ? ListView.builder(
                          itemCount: _recognitionResult.length,
                          itemBuilder: (context, index) {
                            String title = _recognitionResult[index]['title'];
                            String code = _recognitionResult[index]['code'];
                            int quantity =
                                _recognitionResult[index]['quantity'];

                            return Dismissible(
                              key: UniqueKey(),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                setState(() {
                                  _recognitionResult.removeAt(index);
                                });
                              },
                              background: Container(
                                color: Colors.transparent,
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: InkWell(
                                onTap: () => _showQuantityDialog(index),
                                child: badge.Badge(
                                  badgeStyle: badge.BadgeStyle(
                                      badgeColor: widget.primaryColor),
                                  badgeContent: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ),
                                  child: Card(
                                    margin: const EdgeInsets.all(10),
                                    color: Colors.white,
                                    elevation: 8,
                                    child: ListTile(
                                      title: Text(
                                        code,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(title,
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: widget.primaryColor)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Text("No results yet"),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'listen',
            onPressed:
                // If not yet listening for speech start, otherwise stop
                _speechToText.isNotListening ? _startListening : _stopListening,
            tooltip: 'Listen',
            child:
                Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
          ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _recognitionResult.isNotEmpty,
            child: FloatingActionButton(
              heroTag: 'clear',
              onPressed: () {
                _recognitionResult.clear();
                setState(() {});
              },
              tooltip: 'Clear',
              child: const Icon(Icons.clear),
            ),
          ),
          Visibility(
            visible: _recognitionResult.isNotEmpty,
            child: const SizedBox(
              height: 10,
            ),
          ),
          Visibility(
            visible: _recognitionResult.isNotEmpty,
            child: FloatingActionButton(
              heroTag: 'complete',
              onPressed: () {
                Navigator.of(context).pop(_recognitionResult);
              },
              tooltip: 'Complete',
              child: const Icon(Icons.card_travel_sharp),
            ),
          ),
        ],
      ),
    );
  }
}
