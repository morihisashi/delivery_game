import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/position.dart';
import '../widgets/grid_cell.dart';
import '../widgets/hud_bar.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController controller;

  @override
  void initState() {
    super.initState();

    controller = GameController();
    controller.onTick = () => setState(() {});
    controller.resetGame();
    controller.startTimer();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = controller.gameStatus == GameStatus.finished;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Game')),
      body: Column(
        children: [
          HudBar(controller: controller),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  itemCount: GameController.gridSize * GameController.gridSize,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: GameController.gridSize,
                  ),
                  itemBuilder: (context, index) {
                    final x = index % GameController.gridSize;
                    final y = index ~/ GameController.gridSize;

                    final p = Position(x, y);

                    final color = () {
                      if (p == controller.playerPosition) return Colors.blue;
                      if (controller.storePositions.contains(p)) {
                        if (p == controller.currentStorePosition) {
                          return Colors.green.shade800;
                        }
                        return Colors.green.shade200;
                      }
                      if (p == controller.targetPosition) return Colors.red;
                      return Colors.white;
                    }();

                    return GridCell(color: color);
                  },
                ),
              ),
            ),
          ),
          if (finished)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text('Game Over', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text('Final Score: ${controller.score}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      controller.resetGame();
                      controller.startTimer();
                    },
                    child: const Text('Restart'),
                  ),
                ],
              ),
            )
          else
            _Controls(
              onMove: (dir) {
                controller.step(dir);
              },
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.onMove});

  final void Function(Direction dir) onMove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => onMove(Direction.up),
            child: const Text('↑'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => onMove(Direction.left),
                child: const Text('←'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => onMove(Direction.right),
                child: const Text('→'),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => onMove(Direction.down),
            child: const Text('↓'),
          ),
        ],
      ),
    );
  }
}

