import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';

class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final statusText = controller.hasPackage ? '配達中' : '未所持';
    final storeText = controller.currentStorePosition.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.black12,
      child: Row(
        children: [
          Text(
            'Score: ${controller.score}/${controller.clearScore}',
          ),
          const SizedBox(width: 16),
          Text('Time: ${controller.timeLeft}'),
          const SizedBox(width: 16),
          Text('状態: $statusText'),
          const SizedBox(width: 16),
          Text('指定店舗: $storeText'),
          const Spacer(),
          Text('Pos: ${controller.playerPosition}'),
        ],
      ),
    );
  }
}

