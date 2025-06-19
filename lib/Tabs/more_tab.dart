import 'package:flutter/material.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Thêm',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
} 