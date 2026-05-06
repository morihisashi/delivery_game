import 'dart:async';

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
  Timer? _moveTimer;

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
    _stopMoving();
    controller.dispose();
    super.dispose();
  }

  void _startMoving(Direction dir) {
    if (controller.gameStatus == GameStatus.finished) return;

    setState(() {
      controller.step(dir);
    });

    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (controller.gameStatus == GameStatus.finished) return;

      setState(() {
        controller.step(dir);
      });
    });
  }

  void _stopMoving() {
    _moveTimer?.cancel();
    _moveTimer = null;
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

                    final isPlayer = p == controller.playerPosition;
                    final isEnemy = p == controller.enemy.position;
                    final isTarget = p == controller.targetPosition;
                    final isCurrentStore =
                        p == controller.currentStorePosition;
                    final isOtherStore =
                        !isCurrentStore &&
                        controller.storePositions.contains(p);

                    final color = () {
                      if (isEnemy) return Colors.deepPurple.shade400;
                      if (isTarget) return Colors.red.shade400;
                      if (isCurrentStore) return Colors.green.shade600;
                      if (isOtherStore) return Colors.green.shade200;
                      if (controller.isRoad(p)) return Colors.grey.shade400;
                      return Colors.white;
                    }();

                    final child = () {
                      final playerWidget = isPlayer
                          ? Opacity(
                              opacity: controller.hasPackage ? 1.0 : 0.7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/delivery_icon.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : null;

                      final enemyWidget = isEnemy
                          ? const Center(
                              child: Text(
                                '🦀',
                                style: TextStyle(fontSize: 20),
                              ),
                            )
                          : null;

                      if (playerWidget != null && enemyWidget != null) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            playerWidget,
                            Align(alignment: Alignment.center, child: enemyWidget),
                          ],
                        );
                      }
                      if (playerWidget != null) return playerWidget;
                      if (enemyWidget != null) return enemyWidget;

                      if (isTarget) {
                        return const Center(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 22,
                          ),
                        );
                      }
                      if (isCurrentStore) {
                        return const Center(
                          child: Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 22,
                          ),
                        );
                      }
                      if (isOtherStore) {
                        return const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white54,
                            size: 18,
                          ),
                        );
                      }
                      return null;
                    }();

                    return GridCell(color: color, child: child);
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
              hasPackage: controller.hasPackage,
              onStartMove: _startMoving,
              onStopMove: _stopMoving,
            ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.onStartMove,
    required this.onStopMove,
    required this.hasPackage,
  });

  final void Function(Direction dir) onStartMove;
  final VoidCallback onStopMove;
  final bool hasPackage;

  static const double _buttonSize = 108;
  static const double _iconSize = 52;
  static const double _gapBetweenLR = 28;

  Widget _buildButton(IconData icon, Direction dir) {
    final bg = hasPackage ? Colors.orange : Colors.blue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onStartMove(dir),
      onTapUp: (_) => onStopMove(),
      onTapCancel: onStopMove,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Material(
          color: bg,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black45,
          child: SizedBox(
            width: _buttonSize,
            height: _buttonSize,
            child: Icon(icon, size: _iconSize, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(Icons.arrow_upward, Direction.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(Icons.arrow_back, Direction.left),
              const SizedBox(width: _gapBetweenLR),
              _buildButton(Icons.arrow_forward, Direction.right),
            ],
          ),
          _buildButton(Icons.arrow_downward, Direction.down),
        ],
      ),
    );
  }
}

