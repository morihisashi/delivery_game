import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/game_map_data.dart';
import '../models/building.dart';
import '../models/direction.dart';
import '../models/enemy.dart';
import '../models/game_status.dart';
import '../models/position.dart';
import '../models/tile_type.dart';

class GameController {
  static const int gridSize = 10;
  static const int initialTimeSeconds = 60;
  static const int storeCount = 5;

  GameController({Random? random}) : _random = random ?? Random();

  final Random _random;

  Timer? _timer;
  Timer? _enemyTimer;
  Timer? _stunTimer;
  VoidCallback? onTick;

  /// 店舗（5件）。建物マスへは、上下左右に隣接する道路マスのいずれからでも侵入可能。
  List<Building> buildings = [];

  /// 現在の指定店舗（`buildings` の要素への参照ではなく index で持つ）
  int _currentStoreIndex = 0;

  Position targetPosition = const Position(0, 0);

  Position playerPosition = const Position(0, 0);

  Enemy enemy = Enemy(const Position(0, 0));
  bool isStunned = false;

  bool hasPackage = false;
  int score = 0;
  int timeLeft = initialTimeSeconds;
  GameStatus gameStatus = GameStatus.playing;

  int tileAt(Position p) => GameMapData.cells[p.y][p.x];

  bool isRoad(Position p) => tileAt(p) == 1;

  bool isEmptyPlot(Position p) => tileAt(p) == 0;

  TileType tileKind(Position p) =>
      isRoad(p) ? TileType.road : TileType.empty;

  Position get currentStorePosition => buildings[_currentStoreIndex].position;

  Building get currentStore => buildings[_currentStoreIndex];

  Set<Position> get storePositions =>
      buildings.map((b) => b.position).toSet();

  /// 各建物に隣接する道路マス（入口候補）。複数道路に面している場合はすべて含む。
  Set<Position> get allEntrances {
    final s = <Position>{};
    for (final b in buildings) {
      s.addAll(adjacentRoadCells(b.position));
    }
    s.addAll(adjacentRoadCells(targetPosition));
    return s;
  }

  Set<Position> adjacentRoadCells(Position buildingPos) {
    final out = <Position>{};
    for (final d in _orthoDeltas) {
      final n = Position(buildingPos.x + d.$1, buildingPos.y + d.$2);
      if (_isInBounds(n) && isRoad(n)) out.add(n);
    }
    return out;
  }

  void resetGame() {
    stopTimer();
    stopEnemyMovement();
    _clearStun();

    hasPackage = false;
    score = 0;
    timeLeft = initialTimeSeconds;
    gameStatus = GameStatus.playing;

    _setupWorld();
    startEnemyMovement();

    onTick?.call();
  }

  void _setupWorld() {
    buildings = _generateStores();

    targetPosition = _spawnTarget(avoidCurrentTarget: false);

    playerPosition = _pickInitialPlayerRoad();
    selectNextStore();

    enemy = Enemy(_spawnEnemyRoadPosition(minManhattanDistance: 2));
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
    stopEnemyMovement();
    _clearStun();
  }

  void step(Direction dir) {
    if (gameStatus != GameStatus.playing) return;
    if (timeLeft <= 0) return;
    if (isStunned) return;

    movePlayer(dir);
    pickupIfOnCurrentStore();
    deliverIfOnTarget();
    _checkCollision();

    onTick?.call();
  }

  void movePlayer(Direction dir) {
    final from = playerPosition;
    final next = _moved(from, dir);
    if (!_isInBounds(next)) return;
    if (!canMove(from, next)) return;
    playerPosition = next;
  }

  void startEnemyMovement() {
    stopEnemyMovement();

    if (gameStatus != GameStatus.playing) return;

    _enemyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameStatus != GameStatus.playing) {
        stopEnemyMovement();
        return;
      }

      moveEnemy();
      onTick?.call();
    });
  }

  void stopEnemyMovement() {
    _enemyTimer?.cancel();
    _enemyTimer = null;
  }

  void moveEnemy() {
    final dirs = Direction.values.toList()..shuffle(_random);

    for (final dir in dirs) {
      final next = _moved(enemy.position, dir);
      if (!_isInBounds(next)) continue;
      if (!isRoad(next)) continue;
      enemy.position = next;
      break;
    }

    _checkCollision();
  }

  void _checkCollision() {
    if (enemy.position == playerPosition) {
      _stunPlayer();
    }
  }

  void _stunPlayer() {
    if (isStunned) return;

    isStunned = true;
    _stunTimer?.cancel();
    _stunTimer = Timer(const Duration(seconds: 3), () {
      isStunned = false;
      onTick?.call();
    });
  }

  void _clearStun() {
    _stunTimer?.cancel();
    _stunTimer = null;
    isStunned = false;
  }

  /// 道路は自由。店舗・配達先の建物マスは、**隣接する道路マス**からならどこからでも進入可能。
  bool canMove(Position from, Position to) {
    if (isRoad(to)) return true;

    for (final b in buildings) {
      if (to == b.position) {
        return isRoad(from) && _isOrthogonalNeighbor(from, to);
      }
    }
    if (to == targetPosition) {
      return isRoad(from) && _isOrthogonalNeighbor(from, to);
    }
    return false;
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
      targetPosition = _spawnTarget(avoidCurrentTarget: true);
      selectNextStore();
    }
  }

  void selectNextStore() {
    if (buildings.isEmpty) return;
    _currentStoreIndex = _random.nextInt(buildings.length);
  }

  List<Building> _generateStores() {
    final candidates = _emptyCellsWithAdjacentRoad();
    candidates.shuffle(_random);

    if (candidates.length < storeCount) {
      throw StateError('Not enough valid store cells');
    }

    final chosen = candidates.take(storeCount).toList();
    return chosen.map((p) => Building(position: p)).toList();
  }

  Position _spawnTarget({required bool avoidCurrentTarget}) {
    final current = targetPosition;
    final taken = storePositions;

    final candidates = <Position>[];
    for (final p in _emptyCellsWithAdjacentRoad()) {
      if (taken.contains(p)) continue;
      if (p == playerPosition) continue;
      if (avoidCurrentTarget && p == current) continue;
      candidates.add(p);
    }

    if (candidates.isEmpty) {
      return current;
    }

    candidates.shuffle(_random);
    return candidates.first;
  }

  /// 空き(0)かつ上下左右のいずれかに道路(1)があるマス
  List<Position> _emptyCellsWithAdjacentRoad() {
    final out = <Position>[];
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (!isEmptyPlot(p)) continue;
        if (!_hasOrthogonalRoad(p)) continue;
        out.add(p);
      }
    }
    return out;
  }

  bool _hasOrthogonalRoad(Position p) {
    for (final d in _orthoDeltas) {
      final n = Position(p.x + d.$1, p.y + d.$2);
      if (_isInBounds(n) && isRoad(n)) return true;
    }
    return false;
  }

  bool _isOrthogonalNeighbor(Position a, Position b) {
    final dx = (a.x - b.x).abs();
    final dy = (a.y - b.y).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  Position _pickInitialPlayerRoad() {
    final roads = <Position>[];
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (isRoad(p)) roads.add(p);
      }
    }
    roads.shuffle(_random);
    return roads.isEmpty ? const Position(0, 0) : roads.first;
  }

  Position _spawnEnemyRoadPosition({required int minManhattanDistance}) {
    final roads = <Position>[];
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (!isRoad(p)) continue;
        final dist = (p.x - playerPosition.x).abs() + (p.y - playerPosition.y).abs();
        if (dist < minManhattanDistance) continue;
        roads.add(p);
      }
    }

    roads.shuffle(_random);
    if (roads.isNotEmpty) return roads.first;

    // フォールバック：距離制約なしで道路から選ぶ
    final anyRoads = <Position>[];
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (isRoad(p)) anyRoads.add(p);
      }
    }
    anyRoads.shuffle(_random);
    return anyRoads.isEmpty ? const Position(0, 0) : anyRoads.first;
  }

  static const List<(int, int)> _orthoDeltas = [
    (0, -1),
    (0, 1),
    (-1, 0),
    (1, 0),
  ];

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
