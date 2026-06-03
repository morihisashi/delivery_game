import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/infinite_delivery_controller.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/position.dart';
import '../widgets/grid_cell.dart';
import '../widgets/infinite_hud_bar.dart';

class InfiniteDeliveryScreen extends StatefulWidget {
  const InfiniteDeliveryScreen({super.key});

  @override
  State<InfiniteDeliveryScreen> createState() => _InfiniteDeliveryScreenState();
}

class _InfiniteDeliveryScreenState extends State<InfiniteDeliveryScreen> {
  late final InfiniteDeliveryController controller;
  late final FocusNode _focusNode;
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    controller = InfiniteDeliveryController();
    controller.onTick = () => setState(() {});
    controller.resetGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _stopMoving();
    _focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  Direction? _directionFromKey(LogicalKeyboardKey key) {
    return switch (key) {
      LogicalKeyboardKey.arrowUp => Direction.up,
      LogicalKeyboardKey.arrowDown => Direction.down,
      LogicalKeyboardKey.arrowLeft => Direction.left,
      LogicalKeyboardKey.arrowRight => Direction.right,
      _ => null,
    };
  }

  void _handleKeyEvent(KeyEvent event) {
    final dir = _directionFromKey(event.logicalKey);
    if (dir == null) return;

    if (event is KeyDownEvent) {
      if (event is KeyRepeatEvent) return;
      if (controller.gameStatus != GameStatus.playing) return;
      _startMoving(dir);
      return;
    }

    if (event is KeyUpEvent) {
      _stopMoving();
    }
  }

  void _startMoving(Direction dir) {
    if (controller.gameStatus != GameStatus.playing) return;

    setState(() {
      controller.step(dir);
    });

    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (controller.gameStatus != GameStatus.playing) return;

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
      appBar: AppBar(
        title: const Text('無限配達モード'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            InfiniteHudBar(controller: controller),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    itemCount: InfiniteDeliveryController.gridSize *
                        InfiniteDeliveryController.gridSize,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: InfiniteDeliveryController.gridSize,
                    ),
                    itemBuilder: (context, index) {
                      final x = index % InfiniteDeliveryController.gridSize;
                      final y = index ~/ InfiniteDeliveryController.gridSize;
                      final p = Position(x, y);

                      final isPlayer = p == controller.playerPosition;
                      final isCrab = controller.isCrabAt(p);
                      final isVehicle = controller.isVehicleAt(p);
                      final isTarget = p == controller.targetPosition;
                      final isCurrentStore =
                          p == controller.currentStorePosition;
                      final isOtherStore =
                          !isCurrentStore &&
                          controller.storePositions.contains(p);

                      final color = () {
                        if (isVehicle) return Colors.blueGrey.shade700;
                        if (isCrab) return Colors.deepPurple.shade400;
                        if (isTarget) return Colors.red.shade400;
                        if (isCurrentStore) return Colors.green.shade600;
                        if (isOtherStore) return Colors.green.shade200;
                        if (controller.isRoad(p)) return Colors.grey.shade400;
                        return Colors.white;
                      }();

                      final child = () {
                        final layers = <Widget>[];

                        if (isVehicle) {
                          layers.add(
                            const Center(
                              child: Icon(
                                Icons.directions_car,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        }
                        if (isCrab) {
                          layers.add(
                            const Center(
                              child: Text(
                                '🦀',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        }
                        if (isTarget) {
                          layers.add(
                            const Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        } else if (isCurrentStore) {
                          layers.add(
                            const Center(
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        } else if (isOtherStore) {
                          layers.add(
                            const Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ),
                          );
                        }
                        if (isPlayer) {
                          layers.add(
                            Opacity(
                              opacity: controller.hasPackage ? 1.0 : 0.7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/delivery_icon.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }

                        if (layers.isEmpty) return null;
                        if (layers.length == 1) return layers.first;
                        return Stack(
                          fit: StackFit.expand,
                          children: layers,
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
                    Text('最終スコア: ${controller.score}'),
                    Text('配達回数: ${controller.deliveryCount}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        controller.resetGame();
                        _focusNode.requestFocus();
                      },
                      child: const Text('もう一度'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('タイトルへ'),
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

  static const double _buttonSize = 72;
  static const double _iconSize = 36;
  static const double _gapBetweenLR = 16;

  Widget _buildButton(IconData icon, Direction dir) {
    final bg = hasPackage ? Colors.orange : Colors.blue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onStartMove(dir),
      onTapUp: (_) => onStopMove(),
      onTapCancel: onStopMove,
      child: Padding(
        padding: const EdgeInsets.all(6),
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
