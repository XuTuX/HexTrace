import 'package:flutter_test/flutter_test.dart';
import 'package:hexor/game/hex_game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily challenge seed creates a playable controller', () {
    final controller = HexGameController(
      sessionConfig: const GameSessionConfig(
        mode: GameMode.dailyOfficial,
        seed: 459315,
        dateKey: '2026-04-25',
        isOfficialScoreSubmission: true,
      ),
    );

    addTearDown(controller.dispose);

    expect(controller.board.length, controller.rows);
    expect(controller.colorBar.length, controller.colorBarSize);
    expect(controller.hasAnyValidMove(), isTrue);
  });
}
