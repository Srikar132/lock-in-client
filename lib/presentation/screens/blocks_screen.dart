import 'package:flutter/material.dart';

class BlocksScreen extends StatelessWidget {
  const BlocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: Colors.blueAccent),
          SizedBox(height: 20),
          Text('Blocks Mode', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
