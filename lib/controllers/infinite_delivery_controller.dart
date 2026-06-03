import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/game_map_data.dart';
import '../models/building.dart';
import '../models/direction.dart';
import '../models/enemy.dart';
import '../models/game_status.dart';
import '../models/position.dart';
import '../models/vehicle.dart';

class InfiniteDeliveryController {
  static const int gridSize = 10;
  static const int storeCount = 5;
  static const int maxHp = 100;
  static const int crabCount = 2;
  static const int deliveriesPerExtraCar = 5;
  static const int carMovesPerTick = 1;

  InfiniteDeliveryController({Random? random}) : _random = random ?? Random();

  final Random _random;

  Timer? _gameTimer;
  VoidCallback? onTick;

  List<Building> buildings = [];
  int _currentStoreIndex = 0;

  Position targetPosition = const Position(0, 0);
  Position playerPosition = const Position(0, 0);

  List<Enemy> crabs = [];
  List<Vehicle> vehicles = [];

  bool hasPackage = false;
  int score = 0;
  int hp = maxHp;
  GameStatus gameStatus = GameStatus.playing;

  int get deliveryCount => score;

  int get targetVehicleCount => 1 + (score ~/ deliveriesPerExtraCar);

  bool isCrabAt(Position p) => crabs.any((c) => c.position == p);

  bool isVehicleAt(Position p) => vehicles.any((v) => v.position == p);

  int tileAt(Position p) => GameMapData.cells[p.y][p.x];

  bool isRoad(Position p) => tileAt(p) == 1;

  bool isEmptyPlot(Position p) => tileAt(p) == 0;

  Position get currentStorePosition => buildings[_currentStoreIndex].position;

  Set<Position> get storePositions =>
      buildings.map((b) => b.position).toSet();

  void resetGame() {
    stopGameTimer();

    hasPackage = false;
    score = 0;
    hp = maxHp;
    gameStatus = GameStatus.playing;

    _setupWorld();
    startGameTimer();

    onTick?.call();
  }

  void _setupWorld() {
    buildings = _generateStores();
    targetPosition = _spawnTarget(avoidCurrentTarget: false);
    playerPosition = _pickInitialPlayerRoad();
    selectNextStore();
    _spawnCrabs();
    vehicles = [
      Vehicle(_spawnRoadPosition(occupied: _occupiedPositions())),
    ];
  }

  void startGameTimer() {
    stopGameTimer();
    if (gameStatus != GameStatus.playing) return;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameStatus != GameStatus.playing) {
        stopGameTimer();
        return;
      }

      if (hp > 0) hp--;

      if (hp <= 0) {
        hp = 0;
        gameStatus = GameStatus.finished;
        stopGameTimer();
        onTick?.call();
        return;
      }

      _moveAllVehicles();
      onTick?.call();
    });
  }

  void stopGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void dispose() {
    stopGameTimer();
  }

  void step(Direction dir) {
    if (gameStatus != GameStatus.playing) return;
    if (hp <= 0) return;

    movePlayer(dir);
    pickupIfOnCurrentStore();
    deliverIfOnTarget();
    _checkCrabPickup();
    _checkVehicleCollision();

    onTick?.call();
  }

  void movePlayer(Direction dir) {
    final from = playerPosition;
    final next = _moved(from, dir);
    if (!_isInBounds(next)) return;
    if (!canMove(from, next)) return;
    playerPosition = next;
  }

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
      _syncVehicleCount();
    }
  }

  void selectNextStore() {
    if (buildings.isEmpty) return;
    _currentStoreIndex = _random.nextInt(buildings.length);
  }

  void _checkCrabPickup() {
    var collected = false;
    crabs.removeWhere((c) {
      if (c.position == playerPosition) {
        collected = true;
        return true;
      }
      return false;
    });

    if (collected) {
      hp = min(maxHp, hp + 5);
      _ensureCrabCount();
    }
  }

  void _checkVehicleCollision() {
    if (!vehicles.any((v) => v.position == playerPosition)) return;

    hp -= 20;
    if (hp <= 0) {
      hp = 0;
      gameStatus = GameStatus.finished;
      stopGameTimer();
    }
  }

  void _spawnCrabs() {
    crabs = [];
    _ensureCrabCount();
  }

  void _ensureCrabCount() {
    final occupied = _occupiedPositions();
    while (crabs.length < crabCount) {
      crabs.add(Enemy(_spawnRoadPosition(occupied: occupied)));
      occupied.add(crabs.last.position);
    }
  }

  void _syncVehicleCount() {
    final occupied = _occupiedPositions();
    while (vehicles.length < targetVehicleCount) {
      vehicles.add(Vehicle(_spawnRoadPosition(occupied: occupied)));
      occupied.add(vehicles.last.position);
    }
  }

  void _moveAllVehicles() {
    for (final vehicle in vehicles) {
      for (var i = 0; i < carMovesPerTick; i++) {
        _moveVehicleOneStep(vehicle);
      }
    }
  }

  void _moveVehicleOneStep(Vehicle vehicle) {
    final neighbors = _roadNeighbors(vehicle.position);
    if (neighbors.isEmpty) return;

    final from = vehicle.position;
    final Position next;
    if (neighbors.length == 1) {
      next = neighbors.first;
    } else {
      next = (List<Position>.from(neighbors)..shuffle(_random)).first;
    }

    vehicle.position = next;
    vehicle.lastMove = _directionBetween(from, next);
  }

  List<Position> _roadNeighbors(Position p) {
    final out = <Position>[];
    for (final d in _orthoDeltas) {
      final n = Position(p.x + d.$1, p.y + d.$2);
      if (_isInBounds(n) && isRoad(n)) out.add(n);
    }
    return out;
  }

  Set<Position> _occupiedPositions() {
    final s = <Position>{playerPosition, targetPosition};
    s.addAll(storePositions);
    for (final c in crabs) {
      s.add(c.position);
    }
    for (final v in vehicles) {
      s.add(v.position);
    }
    return s;
  }

  List<Building> _generateStores() {
    final candidates = _emptyCellsWithAdjacentRoad();
    candidates.shuffle(_random);

    if (candidates.length < storeCount) {
      throw StateError('Not enough valid store cells');
    }

    return candidates
        .take(storeCount)
        .map((p) => Building(position: p))
        .toList();
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

    if (candidates.isEmpty) return current;

    candidates.shuffle(_random);
    return candidates.first;
  }

  Position _spawnRoadPosition({required Set<Position> occupied}) {
    final roads = <Position>[];
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (!isRoad(p)) continue;
        if (occupied.contains(p)) continue;
        roads.add(p);
      }
    }

    roads.shuffle(_random);
    if (roads.isNotEmpty) return roads.first;

    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final p = Position(x, y);
        if (isRoad(p)) return p;
      }
    }
    return const Position(0, 0);
  }

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

  Direction _directionBetween(Position from, Position to) {
    if (to.x > from.x) return Direction.right;
    if (to.x < from.x) return Direction.left;
    if (to.y > from.y) return Direction.down;
    return Direction.up;
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
