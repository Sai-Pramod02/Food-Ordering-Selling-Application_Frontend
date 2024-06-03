import 'package:flutter/material.dart';

class QuantitySelector extends StatefulWidget {
  final int initialQuantity;
  final Function(int) onChanged;

  QuantitySelector({required this.initialQuantity, required this.onChanged});

  @override
  _QuantitySelectorState createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _increment(bool isIncrement) {
    setState(() {
      if (isIncrement) {
        _quantity++;
      } else {
        if (_quantity > 0) {
          _quantity--;
        }
      }
      widget.onChanged(_quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _increment(true), // Increment when tapped
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _quantity == 0 ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: Colors.green),
        ),
        child: _quantity == 0
            ? Text(
          'Add+',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _increment(false), // Decrement when tapped
              child: Icon(Icons.remove, size: 20.0, color: Colors.grey),
            ),
            SizedBox(width: 8.0),
            Text(
              '$_quantity',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 8.0),
            GestureDetector(
              onTap: () => _increment(true), // Increment when tapped
              child: Icon(Icons.add, size: 20.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
