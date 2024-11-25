import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cw_speech2order/speech2order.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class Speech2OrderPage extends StatefulWidget {
  const Speech2OrderPage({
    Key? key,
    required this.products,
    required this.primaryColor,
    this.secondaryColor = Colors.white,
  }) : super(key: key);

  final List<Speech2OrderProduct> products;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  _Speech2OrderPageState createState() => _Speech2OrderPageState();
}

class _Speech2OrderPageState extends State<Speech2OrderPage> {
  final SpeechToText _speechToText = SpeechToText();
  final List<Map<String, dynamic>> _recognitionResult = [];
  final List<Map<String, dynamic>> _searchResults = [];
  bool _speechEnabled = false;
  bool _continuousListening = false;
  bool _isProcessing = false;
  String _lastWords = '';
  Timer? _sessionTimer;
  Timer? _restartTimer;
  static const int _sessionDurationMinutes = 10;
  static const Duration _restartDelay = Duration(milliseconds: 1000);
  DateTime? _sessionStartTime;
  int _errorCount = 0;
  static const int _maxErrorCount = 5;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restartTimer?.cancel();
    _stopListening();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onError,
        debugLogging: true,
      );
      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  void _onError(SpeechRecognitionError error) {
    print('Error: ${error.errorMsg}');

    // Solo incrementar el contador para errores críticos
    // excluyendo específicamente error_not_match
    switch (error.errorMsg) {
      case 'error_not_match':
        // Ignora este error y continúa escuchando
        break;
      case 'error_busy':
      case 'error_speech_timeout':
        if (_continuousListening) {
          _restartTimer?.cancel();
          _restartTimer = Timer(_restartDelay, () {
            if (_continuousListening && !_isProcessing) {
              _startListening();
            }
          });
        }
        if (error.permanent) {
          _errorCount++;
        }
        break;
      default:
        if (error.permanent) {
          _errorCount++;
        }
    }

    // Verificar el contador de errores críticos
    if (_errorCount >= _maxErrorCount) {
      _stopListening();
      _showErrorDialog(
          'Se han producido demasiados errores. Por favor, intente nuevamente.');
      _errorCount = 0;
      return;
    }

    // Detener solo para errores permanentes críticos
    if (error.permanent &&
        error.errorMsg != 'error_not_match' &&
        error.errorMsg != 'error_speech_timeout' &&
        error.errorMsg != 'error_busy') {
      _stopListening();
      _showErrorDialog('Error en el reconocimiento de voz: ${error.errorMsg}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _onSpeechStatus(String status) async {
    print('Speech status: $status');

    if (status == 'done' &&
        _continuousListening &&
        _speechEnabled &&
        !_isProcessing) {
      _restartTimer?.cancel();
      _restartTimer = Timer(_restartDelay, () {
        if (_continuousListening && !_isProcessing) {
          _startListening();
        }
      });
    }
  }

  void _toggleListening() async {
    if (_speechToText.isNotListening) {
      setState(() {
        _continuousListening = true;
        _errorCount = 0;
      });
      _startSession();
      await _startListening();
    } else {
      await _stopListening();
    }
  }

  Future<void> _startListening() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error starting listening: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _stopListening() async {
    _sessionTimer?.cancel();
    _restartTimer?.cancel();

    try {
      await _speechToText.stop();
    } catch (e) {
      print('Error stopping listening: $e');
    }

    setState(() {
      _continuousListening = false;
      _sessionStartTime = null;
      _isProcessing = false;
      _errorCount = 0;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    if (_isProcessing) return;

    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult) {
      setState(() {
        _isProcessing = true;
      });

      try {
        List<Map<String, dynamic>> response = await proccesSpeechResult(
          speechText: result.recognizedWords,
          products: widget.products,
        );

        if (!mounted) return;

        setState(() {
          _searchResults.clear();
          _searchResults.addAll(response);
        });

        if (_searchResults.isNotEmpty) {
          if (_searchResults.length <= 1) {
            _updateRecognitionResult(_searchResults);
          } else {
            List<Map<String, dynamic>>? selectedItems = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Speech2OrderSelectionDialog(
                  items: _searchResults,
                  primaryColor: widget.primaryColor,
                );
              },
            );

            if (selectedItems != null && selectedItems.isNotEmpty) {
              _updateRecognitionResult(selectedItems);
            }
          }

          setState(() {
            _searchResults.clear();
          });
        }
      } catch (e) {
        print('Error processing speech result: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          // Reiniciar el reconocimiento si está en modo continuo
          if (_continuousListening) {
            _restartTimer?.cancel();
            _restartTimer = Timer(_restartDelay, () {
              if (_continuousListening && !_isProcessing) {
                _startListening();
              }
            });
          }
        }
      }
    }
  }

  void _showSessionEndDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesión Finalizada'),
          content: const Text(
              'La sesión de reconocimiento de voz ha terminado. ¿Desea iniciar una nueva sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Finalizar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleListening();
              },
              child: const Text('Nueva Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _startSession() {
    _sessionStartTime = DateTime.now();
    _sessionTimer = Timer(Duration(minutes: _sessionDurationMinutes), () {
      _stopListening();
      setState(() {
        _continuousListening = false;
      });
      _showSessionEndDialog();
    });
  }

  String get _remainingTime {
    if (_sessionStartTime == null) return '';
    final elapsed = DateTime.now().difference(_sessionStartTime!);
    final remaining = Duration(minutes: _sessionDurationMinutes) - elapsed;
    if (remaining.isNegative) return '0:00';
    return '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void _updateRecognitionResult(List<Map<String, dynamic>> newItems) {
    setState(() {
      for (var newItem in newItems) {
        int existingIndex = _recognitionResult
            .indexWhere((item) => item['code'] == newItem['code']);

        if (existingIndex != -1) {
          _recognitionResult[existingIndex]['quantity'] = newItem['quantity'];
        } else {
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
      appBar: AppBar(
        title: const Text('Reconocimiento de Voz'),
        backgroundColor: widget.primaryColor,
        actions: [
          if (_sessionStartTime != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _remainingTime,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                _speechToText.isListening
                                    ? Icons.mic
                                    : Icons.mic_off,
                                size: 48,
                                color: _continuousListening
                                    ? Colors.red
                                    : widget.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _speechToText.isListening
                                    ? 'Escuchando: $_lastWords'
                                    : _speechEnabled
                                        ? 'Toca el micrófono para iniciar el reconocimiento continuo'
                                        : 'El reconocimiento de voz no está disponible',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_searchResults.isNotEmpty &&
                          _speechToText.isListening)
                        Container(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: widget.primaryColor,
                                    child: Text(
                                      '${result['quantity']}',
                                      style: TextStyle(
                                          color: widget.secondaryColor),
                                    ),
                                  ),
                                  title: Text(
                                    result['code'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(result['title']),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
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
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: widget.primaryColor,
                                    child: Text(
                                      '$quantity',
                                      style: TextStyle(
                                          color: widget.secondaryColor),
                                    ),
                                  ),
                                  title: Text(code),
                                  subtitle: Text(title),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showQuantityDialog(index),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            "No hay productos seleccionados",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
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
            onPressed: _speechEnabled ? _toggleListening : null,
            tooltip: 'Iniciar/Detener Reconocimiento',
            backgroundColor:
                _continuousListening ? Colors.red : widget.primaryColor,
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
              backgroundColor: widget.primaryColor,
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
              backgroundColor: widget.primaryColor,
              child: Icon(
                Icons.check,
                color: widget.secondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
