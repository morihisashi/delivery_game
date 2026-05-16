import 'game_difficulty.dart';

class DifficultySettings {
  const DifficultySettings({
    required this.crabCount,
    required this.clearScore,
    required this.timeLimitSeconds,
  });

  final int crabCount;
  final int clearScore;
  final int timeLimitSeconds;

  static const Map<GameDifficulty, DifficultySettings> settingsByDifficulty = {
    GameDifficulty.easy: DifficultySettings(
      crabCount: 1,
      clearScore: 5,
      timeLimitSeconds: 60,
    ),
    GameDifficulty.normal: DifficultySettings(
      crabCount: 2,
      clearScore: 5,
      timeLimitSeconds: 60,
    ),
    GameDifficulty.hard: DifficultySettings(
      crabCount: 3,
      clearScore: 10,
      timeLimitSeconds: 60,
    ),
  };

  static DifficultySettings forDifficulty(GameDifficulty difficulty) =>
      settingsByDifficulty[difficulty]!;
}
