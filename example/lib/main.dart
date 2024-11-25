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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 10.0,
          title: const Text('speech2Order'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                debugPrint('[speech2Order] Carrito de compras presionado');
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: FutureBuilder<List<Speech2OrderProduct>>(
              future: widget.fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error loading products');
                } else if (snapshot.hasData) {
                  final products = snapshot.data!;
                  speech2OrderProducts = products;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var product in products)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Card(
                                child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    product.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(product.code),
                                ],
                              ),
                            )),
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
          onPressed: () async {
            List<Map<String, dynamic>> selectedItems = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Speech2OrderPage(
                  primaryColor: Colors.green,
                  products: speech2OrderProducts,
                ),
              ),
            );

            if (selectedItems.isNotEmpty) {
              for (var element in selectedItems) {
                var product = speech2OrderProducts.firstWhere(
                  (e) => e.code == element.values.elementAt(1),
                );
                //product.quantity = element.values.elementAt(2);
              }
            }
          },
          label: const Row(
            children: [
              Text('speech '),
              SizedBox(
                width: 10,
              ),
              Icon(Icons.mic_outlined)
            ],
          ),
        ),
      ),
    );
  }
}
