import 'position.dart';

/// 店舗。建物マスは空きタイル上。侵入は上下左右に隣接する道路マスから可能。
class Building {
  const Building({required this.position});

  final Position position;
}
