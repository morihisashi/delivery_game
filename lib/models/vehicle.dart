import 'position.dart';
import 'vehicle_type.dart';

class Vehicle {
  Vehicle(
    this.position, {
    required this.type,
    this.previousPosition,
  });

  Position position;
  Position? previousPosition;
  VehicleType type;
}
