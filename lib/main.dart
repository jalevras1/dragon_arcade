import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/dragon_lunaryvell_game.dart';
import 'game/dragon_profile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DragonLunaryvellApp());
}

class DragonLunaryvellApp extends StatelessWidget {
  const DragonLunaryvellApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = DragonLunaryvellGame();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DRAGON LUNARYVELL',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050817),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF65D9FF),
          secondary: Color(0xFFFFD77A),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) =>
                  game.setTouchTarget(details.localPosition),
              onPanUpdate: (details) =>
                  game.setTouchTarget(details.localPosition),
              onPanEnd: (_) => game.releaseTouch(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GameWidget<DragonLunaryvellGame>(game: game),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 10,
                    child: ValueListenableBuilder<DragonHudState>(
                      valueListenable: game.hud,
                      builder: (context, state, _) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _HudPill(label: 'SCORE', value: '${state.score}'),
                          _HudPill(label: 'WAVE', value: '${state.wave}'),
                          _HudPill(label: 'HULL', value: '${state.health}'),
                          PopupMenuButton<DragonProfile>(
                            tooltip: 'Choose your dragon',
                            onSelected: (profile) {
                              game.selectDragon(profile);
                            },
                            itemBuilder: (context) => DragonProfile.all
                                .map((profile) => PopupMenuItem(
                                      value: profile,
                                      child: Text(profile.name),
                                    ))
                                .toList(),
                            child: _HudPill(
                                label: 'DRAGON', value: state.dragonName),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 16,
                    child: ValueListenableBuilder<DragonHudState>(
                      valueListenable: game.hud,
                      builder: (context, state, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (state.bossActive)
                            const Text('BOSS INBOUND',
                                style: TextStyle(
                                  color: Color(0xFFFF8C9A),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.4,
                                )),
                          Text('DRAG TO FLY  •  AUTO-FIRE',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(.72),
                                  fontSize: 11,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: game.activateSpecial,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: Text(game.dragon.specialAbility),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ValueListenableBuilder<DragonHudState>(
                      valueListenable: game.hud,
                      builder: (context, state, _) => state.health <= 0
                          ? Center(
                              child: FilledButton.icon(
                                onPressed: game.restartGame,
                                icon: const Icon(Icons.replay),
                                label: const Text('FLY AGAIN'),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: ValueListenableBuilder<DragonHudState>(
                      valueListenable: game.hud,
                      builder: (context, state, _) => IconButton.filledTonal(
                        tooltip: state.paused ? 'Resume' : 'Pause',
                        onPressed: game.togglePause,
                        icon:
                            Icon(state.paused ? Icons.play_arrow : Icons.pause),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC101A35),
          border: Border.all(color: const Color(0x665CCFFF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: Color(0xFF8CCFEF))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      );
}
