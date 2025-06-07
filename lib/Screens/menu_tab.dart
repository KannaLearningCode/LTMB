import 'package:flutter/material.dart';

class MenuTab extends StatelessWidget {
  const MenuTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Thực đơn',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
} 