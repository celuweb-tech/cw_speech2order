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
  Speech2OrderPageState createState() => Speech2OrderPageState();
}

class Speech2OrderPageState extends State<Speech2OrderPage> {
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

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (_speechToText.isNotListening) {
      List<Map<String, dynamic>> response = await proccesSpeechResult(
          speechText: result.recognizedWords, products: widget.products);

      if (response.isNotEmpty) {
        if (response.length <= 1) {
          _updateRecognitionResult(response);
        } else {
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
            _updateRecognitionResult(selectedItems);
          }
        }
      }
    }
  }

  void _updateRecognitionResult(List<Map<String, dynamic>> newItems) {
    setState(() {
      for (var newItem in newItems) {
        int existingIndex = _recognitionResult
            .indexWhere((item) => item['code'] == newItem['code']);

        if (existingIndex != -1) {
          // Update quantity of existing item
          _recognitionResult[existingIndex]['quantity'] = newItem['quantity'];
        } else {
          // Add new item
          _recognitionResult.add(newItem);
        }
      }
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _recognitionResult.removeAt(index);
      } else {
        _recognitionResult[index]['quantity'] = newQuantity;
      }
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
          );
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
              _updateQuantity(index, newQuantity);
              Navigator.pop(context);
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
                _updateQuantity(index, newQuantity);
                Navigator.pop(context);
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
                    _speechToText.isListening
                        ? _lastWords
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
                                child: Icon(Icons.delete,
                                    color: widget.secondaryColor),
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
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: widget.secondaryColor),
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
                _speechToText.isNotListening ? _startListening : _stopListening,
            tooltip: 'Listen',
            child: Icon(
              _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
              color: widget.secondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          if (_recognitionResult.isNotEmpty) ...[
            FloatingActionButton(
              heroTag: 'clear',
              onPressed: () {
                setState(() {
                  _recognitionResult.clear();
                });
              },
              tooltip: 'Clear',
              child: Icon(
                Icons.clear,
                color: widget.secondaryColor,
              ),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'complete',
              onPressed: () {
                Navigator.of(context).pop(_recognitionResult);
              },
              tooltip: 'Complete',
              child: Icon(
                Icons.card_travel_sharp,
                color: widget.secondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
