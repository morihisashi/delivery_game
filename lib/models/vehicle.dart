import 'direction.dart';
import 'position.dart';

class Vehicle {
  Vehicle(this.position, {this.lastMove});

  Position position;
  Direction? lastMove;
}
