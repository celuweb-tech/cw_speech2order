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
    List<Speech2OrderProduct> speech2OrderProducts = [];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 10.0,
            title: const Text('speech2Order'),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  print('Carrito de compras presionado');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: FutureBuilder<List<Speech2OrderProduct>>(
                future: fetchProducts(),
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
                      children: [
                        for (var product in products) Text(product.title),
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
                          )),
                );

                if (selectedItems.isNotEmpty) {
                  for (var element in selectedItems) {
                    var product = speech2OrderProducts.firstWhere(
                        (e) => e.barCode == element.values.elementAt(1));
                    product.quantity = element.values.elementAt(2);
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
              )),
        ),
      ),
    );
  }
}
