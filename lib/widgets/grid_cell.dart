import 'package:flutter/material.dart';

class GridCell extends StatelessWidget {
  const GridCell({super.key, required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black12),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

