import 'package:flutter/material.dart';

class GridCell extends StatelessWidget {
  const GridCell({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}

