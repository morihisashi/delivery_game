import 'package:flutter/material.dart';

import '../controllers/infinite_delivery_controller.dart';

class InfiniteHudBar extends StatelessWidget {
  const InfiniteHudBar({super.key, required this.controller});

  final InfiniteDeliveryController controller;

  @override
  Widget build(BuildContext context) {
    final statusText = controller.hasPackage ? '配達中' : '未所持';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('体力: ${controller.hp} / ${InfiniteDeliveryController.maxHp}'),
          const SizedBox(height: 4),
          Text('スコア: ${controller.score}'),
          const SizedBox(height: 4),
          Text('大型車: ${controller.largeVehicleCount}  軽自動車: ${controller.lightVehicleCount}'),
          const SizedBox(height: 4),
          Text('状態: $statusText  指定店舗: ${controller.currentStorePosition}'),
        ],
      ),
    );
  }
}
