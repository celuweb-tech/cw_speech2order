import 'dart:convert';
import 'package:cw_speech2order/speech2order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<List<Speech2OrderProduct>> fetchProducts() async {
    final jsonData = await rootBundle.loadString('assets/products.json');
    final jsonList = json.decode(jsonData) as List<dynamic>;
    return jsonList.map((json) => Speech2OrderProduct.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(fetchProducts: fetchProducts),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Future<List<Speech2OrderProduct>> Function() fetchProducts;

  const MainScreen({super.key, required this.fetchProducts});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Speech2OrderProduct> speech2OrderProducts = [];
  bool _needsRefresh = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          elevation: 10.0,
          title: const Text(
            'speech2Order',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: FutureBuilder<List<Speech2OrderProduct>>(
              key: ValueKey(
                  _needsRefresh), // Forzar reconstrucción cuando sea necesario
              future: widget.fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading products');
                } else if (snapshot.hasData) {
                  if (!_needsRefresh) {
                    speech2OrderProducts = snapshot.data!;
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var product in speech2OrderProducts)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Card(
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(product.code),
                                trailing: Visibility(
                                  visible: product.quantity != '0',
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'x${product.quantity}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                } else {
                  return const Text('No products found');
                }
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.blueGrey,
          onPressed: () async {
            final result = await Navigator.push<List<Map<String, dynamic>>>(
              context,
              MaterialPageRoute(
                builder: (context) => Speech2OrderPage(
                  primaryColor: Colors.blueGrey,
                  products: speech2OrderProducts,
                ),
              ),
            );

            if (result != null && result.isNotEmpty) {
              // Resetear todas las cantidades primero
              for (var product in speech2OrderProducts) {
                product.quantity = "0";
              }

              // Actualizar las cantidades de los productos seleccionados
              for (var element in result) {
                int index = speech2OrderProducts
                    .indexWhere((p) => p.code == element['code']);
                if (index != -1) {
                  speech2OrderProducts[index].quantity =
                      element['quantity'].toString();
                }
              }

              setState(() {
                _needsRefresh = !_needsRefresh; // Forzar reconstrucción
              });
            }
          },
          label: const Row(
            children: [
              Text(
                'speech',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(width: 10),
              Icon(
                Icons.mic_outlined,
                color: Colors.white,
              )
            ],
          ),
        ),
      ),
    );
  }
}
