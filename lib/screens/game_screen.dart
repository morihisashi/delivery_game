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
  Direction? _currentDirection;

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

    _currentDirection = dir;

    setState(() {
      controller.step(dir);
    });

    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (controller.gameStatus == GameStatus.finished) return;

      setState(() {
        controller.step(dir);
      });
    });
  }

  void _stopMoving() {
    _moveTimer?.cancel();
    _moveTimer = null;
    _currentDirection = null;
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

                    final child = () {
                      if (p != controller.playerPosition) return null;

                      return Opacity(
                        opacity: controller.hasPackage ? 1.0 : 0.7,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/delivery_icon.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
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

  static const double _buttonSize = 80;
  static const double _iconSize = 40;

  Widget _buildButton(IconData icon, Direction dir) {
    return GestureDetector(
      onTapDown: (_) => onStartMove(dir),
      onTapUp: (_) => onStopMove(),
      onTapCancel: onStopMove,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: hasPackage ? Colors.orange : Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: null,
            child: Icon(icon, size: _iconSize),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(Icons.arrow_upward, Direction.up),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(Icons.arrow_back, Direction.left),
              const SizedBox(width: 20),
              _buildButton(Icons.arrow_forward, Direction.right),
            ],
          ),
          _buildButton(Icons.arrow_downward, Direction.down),
        ],
      ),
    );
  }
}

