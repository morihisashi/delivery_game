import 'package:flutter/material.dart';

import '../models/difficulty_settings.dart';
import '../models/game_difficulty.dart';
import 'game_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  static const double _buttonHeight = 72;

  void _startGame(BuildContext context, GameDifficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(difficulty: difficulty),
      ),
    );
  }

  Widget _difficultyButton(
    BuildContext context, {
    required String label,
    required String description,
    required GameDifficulty difficulty,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: _buttonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 2,
            side: BorderSide(color: Colors.grey.shade400),
          ),
          onPressed: () => _startGame(context, difficulty),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final easy = DifficultySettings.forDifficulty(GameDifficulty.easy);
    final normal = DifficultySettings.forDifficulty(GameDifficulty.normal);
    final hard = DifficultySettings.forDifficulty(GameDifficulty.hard);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              const Text(
                'Delivery Game',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '荷物を届けてスコアを稼ごう',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _difficultyButton(
                context,
                label: 'かんたん',
                description:
                    '蟹${easy.crabCount}匹 / ${easy.timeLimitSeconds}秒 / クリア${easy.clearScore}点',
                difficulty: GameDifficulty.easy,
              ),
              _difficultyButton(
                context,
                label: 'ふつう',
                description:
                    '蟹${normal.crabCount}匹 / ${normal.timeLimitSeconds}秒 / クリア${normal.clearScore}点',
                difficulty: GameDifficulty.normal,
              ),
              _difficultyButton(
                context,
                label: 'むずかしい',
                description:
                    '蟹${hard.crabCount}匹 / ${hard.timeLimitSeconds}秒 / クリア${hard.clearScore}点',
                difficulty: GameDifficulty.hard,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
