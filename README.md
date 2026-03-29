# delivery_game

配達ゲーム（MVP）の Flutter 実装です。

## Requirements

- Flutter SDK（`flutter --version` が通ること）

## Run

依存関係を取得して起動します。

```bash
flutter pub get
flutter run
```

## Test / Analyze

このプロジェクトのテストは `test/widget_test.dart` のウィジェットテストです。

### Static analysis（静的解析）

```bash
flutter analyze
```

### Unit/Widget tests（テスト実行）

```bash
flutter test
```

## Notes

- タイマーは `GameController` が管理し、UI は `onTick` コールバック経由で再描画します。
- 操作は「1入力 = 1マス移動」です（長押し連続移動はしません）。
