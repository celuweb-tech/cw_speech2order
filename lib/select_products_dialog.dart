import 'package:flutter/material.dart';

class Speech2OrderSelectionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Color primaryColor;

  const Speech2OrderSelectionDialog(
      {Key? key, required this.items, required this.primaryColor})
      : super(key: key);

  @override
  Speech2OrderSelectionDialogState createState() =>
      Speech2OrderSelectionDialogState();
}

class Speech2OrderSelectionDialogState
    extends State<Speech2OrderSelectionDialog> {
  late List<bool> _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = List.filled(widget.items.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Select products to add",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            widget.items.length,
            (index) {
              String title = widget.items[index]['title'];
              String code = widget.items[index]['code'];
              int quantity = widget.items[index]['quantity'];

              return CheckboxListTile(
                title: Card(
                  color: Colors.white,
                  elevation: 8,
                  child: ListTile(
                    title: Text(
                      "$code x$quantity",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 20, color: widget.primaryColor)),
                      ],
                    ),
                  ),
                ),
                checkColor: Colors.white,
                value: _isSelected[index],
                onChanged: (bool? value) {
                  setState(() {
                    _isSelected[index] = value!;
                  });
                },
              );
            },
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                widget.primaryColor), // Here Im having the error
          ),
          onPressed: () {
            List<Map<String, dynamic>> selectedItems = [];
            for (int i = 0; i < widget.items.length; i++) {
              if (_isSelected[i]) {
                selectedItems.add(widget.items[i]);
              }
            }
            Navigator.of(context).pop(selectedItems);
          },
          child: const Text(
            "Accept",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
