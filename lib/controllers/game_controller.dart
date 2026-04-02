import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/position.dart';

class GameController {
  static const int gridSize = 10;
  static const int initialTimeSeconds = 60;

  GameController({Random? random}) : _random = random ?? Random();

  final Random _random;

  Timer? _timer;
  VoidCallback? onTick;

  Position playerPosition = const Position(5, 5);

  final Set<Position> storePositions = {
    const Position(1, 1),
    const Position(1, 8),
    const Position(5, 5),
    const Position(8, 1),
    const Position(8, 8),
  };

  Position currentStorePosition = const Position(1, 1);
  Position targetPosition = const Position(0, 0);

  bool hasPackage = false;
  int score = 0;
  int timeLeft = initialTimeSeconds;
  GameStatus gameStatus = GameStatus.playing;

  void resetGame() {
    stopTimer();

    playerPosition = const Position(5, 5);
    hasPackage = false;
    score = 0;
    timeLeft = initialTimeSeconds;
    gameStatus = GameStatus.playing;

    selectNextStore();
    targetPosition = spawnTarget(avoidCurrentTarget: false);

    onTick?.call();
  }

  void startTimer() {
    stopTimer();

    if (gameStatus != GameStatus.playing) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameStatus != GameStatus.playing) {
        stopTimer();
        return;
      }

      if (timeLeft > 0) timeLeft--;

      if (timeLeft <= 0) {
        timeLeft = 0;
        gameStatus = GameStatus.finished;
        stopTimer();
      }

      onTick?.call();
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopTimer();
  }

  void step(Direction dir) {
    if (gameStatus != GameStatus.playing) return;
    if (timeLeft <= 0) return;

    movePlayer(dir);
    pickupIfOnCurrentStore();
    deliverIfOnTarget();

    onTick?.call();
  }

  void movePlayer(Direction dir) {
    final next = _moved(playerPosition, dir);
    if (_isInBounds(next)) {
      playerPosition = next;
    }
  }

  void pickupIfOnCurrentStore() {
    if (!hasPackage && playerPosition == currentStorePosition) {
      hasPackage = true;
    }
  }

  void deliverIfOnTarget() {
    if (hasPackage && playerPosition == targetPosition) {
      score += 1;
      hasPackage = false;
      targetPosition = spawnTarget(avoidCurrentTarget: true);
      selectNextStore();
    }
  }

  void selectNextStore() {
    final stores = storePositions.toList()..shuffle(_random);
    currentStorePosition = stores.first;
  }

  Position spawnTarget({required bool avoidCurrentTarget}) {
    final current = targetPosition;

    final candidates = <Position>[];
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (storePositions.contains(p)) continue;
        if (p == playerPosition) continue;
        if (avoidCurrentTarget && p == current) continue;
        candidates.add(p);
      }
    }

    if (candidates.isEmpty) {
      return current;
    }

    candidates.shuffle(_random);
    return candidates.first;
  }

  Position _moved(Position p, Direction dir) {
    switch (dir) {
      case Direction.up:
        return Position(p.x, p.y - 1);
      case Direction.down:
        return Position(p.x, p.y + 1);
      case Direction.left:
        return Position(p.x - 1, p.y);
      case Direction.right:
        return Position(p.x + 1, p.y);
    }
  }

  bool _isInBounds(Position p) =>
      p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize;
}

