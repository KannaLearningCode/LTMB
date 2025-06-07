import 'package:flutter/material.dart';

class CartTab extends StatelessWidget {
  const CartTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Giỏ hàng',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
} 