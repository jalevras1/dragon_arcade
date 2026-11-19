import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dragon_profile.dart';

class DragonHudState {
  const DragonHudState({
    this.score = 0,
    this.wave = 1,
    this.health = 3,
    this.paused = false,
    this.bossActive = false,
    this.dragonName = 'ASTRALIS',
  });
  final int score;
  final int wave;
  final int health;
  final bool paused;
  final bool bossActive;
  final String dragonName;

  DragonHudState copyWith(
          {int? score,
          int? wave,
          int? health,
          bool? paused,
          bool? bossActive,
          String? dragonName}) =>
      DragonHudState(
        score: score ?? this.score,
        wave: wave ?? this.wave,
        health: health ?? this.health,
        paused: paused ?? this.paused,
        bossActive: bossActive ?? this.bossActive,
        dragonName: dragonName ?? this.dragonName,
      );
}

class _Bolt {
  _Bolt(this.x, this.y, {this.speed = 520});
  double x, y;
  final double speed;
}

class _EnemyBolt {
  _EnemyBolt(this.x, this.y, this.vx, this.vy);
  double x, y;
  final double vx, vy;
}

class _Foe {
  _Foe(
      {required this.x,
      required this.y,
      required this.hp,
      required this.radius,
      required this.speed,
      this.boss = false,
      this.typeIndex = 0,
      this.spriteSize = 60});
  double x, y, hp, radius, speed, spriteSize;
  bool boss;
  int typeIndex;
  double fireClock = 0;
  double animationClock = 0;
  int animationFrame = 0;
}

class DragonLunaryvellGame extends FlameGame {
  DragonLunaryvellGame({this.dragon = DragonProfile.astralis});
  DragonProfile dragon;
  final ValueNotifier<DragonHudState> hud =
      ValueNotifier(const DragonHudState());
  final List<_Bolt> _bolts = [];
  final List<_EnemyBolt> _enemyBolts = [];
  final List<_Foe> _foes = [];
  final math.Random _random = math.Random(17);

  double _playerX = 0, _playerY = 0;
  double _targetX = 0, _targetY = 0;
  double _fireClock = 0, _spawnClock = 0, _hudClock = 0;
  double _waveElapsed = 0;
  double _playerInvulnerable = 0;
  double _bossAttackClock = 0;
  double _specialCooldown = 0;
  double _specialClock = 0;
  int _spawnedThisWave = 0, _defeatedThisWave = 0;
  int _score = 0, _wave = 1, _health = 3;
  bool _touching = false, _paused = false, _gameOver = false;
  _Foe? _boss;
  List<ui.Image> _flightFrames = [];
  List<List<ui.Image>> _enemyFrames = [];
  double _flightClock = 0;
  int _flightFrame = 0;
  final Map<String, ui.Image> _run31DragonStills = {};
  final Map<String, List<ui.Image>> _run32DragonFlights = {};
  List<ui.Image> _run32PlayerBoltFrames = [];
  List<ui.Image> _run32EnemyBoltFrames = [];
  final Map<String, ui.Image> _run31AbilityImages = {};
  ui.Image? _run31BossImage;
  // Sprite file names use 'tempestryx'; the existing profile ID is
  // 'temperstryx'. Keep that historical ID so saves and selection still work.
  static const Map<String, String> _run32DragonPaths = {
    'temperstryx': 'tempestryx',
    'ignivar': 'ignivar',
    'nyxariel': 'nyxariel',
    'solarion': 'solarion',
    'aquaryth': 'aquaryth',
  };
  static const List<int> _run32WingCycle = [0, 1, 2, 3, 2, 1];
  static const Map<String, String> _run31DragonPaths = {
    'temperstryx': 'run31/dragons/tempestryx_flight_base.png',
    'ignivar': 'run31/dragons/ignivar_flight_base.png',
    'nyxariel': 'run31/dragons/nyxariel_flight_base.png',
    'solarion': 'run31/dragons/solarion_flight_base.png',
    'aquaryth': 'run31/dragons/aquaryth_flight_base.png',
  };
  static const Map<String, String> _run31AbilityPaths = {
    'astralis': 'run31/abilities/astralis_celestial_nova.png',
    'temperstryx': 'run31/abilities/tempestryx_lightning_dash.png',
    'ignivar': 'run31/abilities/ignivar_dragonfire_barrage.png',
    'nyxariel': 'run31/abilities/nyxariel_void_shift.png',
    'solarion': 'run31/abilities/solarion_solar_collapse.png',
    'aquaryth': 'run31/abilities/aquaryth_tidal_vortex.png',
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _flightFrames = await Future.wait(
      List.generate(
        8,
        (i) => images.load(
          'dragons/astralis/flight/astralis_flight_wing_${i.toString().padLeft(2, '0')}.png',
        ),
      ),
    );
    _enemyFrames = [
      await Future.wait(List.generate(4, (i) => images.load(
          'enemies/goblin_sky_raider/goblin_${i.toString().padLeft(2, '0')}.png'))),
      await Future.wait(List.generate(3, (i) => images.load(
          'enemies/harpy/harpy_${i.toString().padLeft(2, '0')}.png'))),
      await Future.wait(List.generate(3, (i) => images.load(
          'enemies/shadow_wyvern/shadow_wyvern_${i.toString().padLeft(2, '0')}.png'))),
    ];
    // Decode optional Run 31 artwork in the background, not on the critical
    // path for the existing eight-frame ASTRALIS animation.
    unawaited(_preloadRun31Assets());
    // These projectile sprites already ship with the project. Render their
    // three-frame art when available; leave the proven shape fallback intact.
    unawaited(_preloadRun32Projectiles());
  }

  Future<void> _preloadRun32Projectiles() async {
    try {
      _run32PlayerBoltFrames = await Future.wait(List.generate(
        3,
        (i) => images.load(
          'projectiles/player/celestial_bolt_${i.toString().padLeft(2, '0')}.png',
        ),
      ));
    } catch (error) {
      debugPrint('Existing player projectile sprites unavailable: $error');
    }
    try {
      _run32EnemyBoltFrames = await Future.wait(List.generate(
        3,
        (i) => images.load(
          'projectiles/enemy/ember_bolt_${i.toString().padLeft(2, '0')}.png',
        ),
      ));
    } catch (error) {
      debugPrint('Existing enemy projectile sprites unavailable: $error');
    }
  }

  Future<void> _preloadRun31Assets() async {
    // Run 31 artwork is optional at runtime: preserve existing sprites if a
    // new asset is absent, and keep the ASTRALIS flight cycle untouched.
    try {
      _run31BossImage =
          await images.load('run31/bosses/eclipse_gargoyle_warden.png');
    } catch (error) {
      debugPrint('Run 31 boss art unavailable: $error');
    }
    try {
      _run31AbilityImages['astralis'] =
          await images.load(_run31AbilityPaths['astralis']!);
    } catch (error) {
      debugPrint('Run 31 ASTRALIS effect unavailable: $error');
    }
  }

  @override
  void onRemove() {
    hud.dispose();
    super.onRemove();
  }

  @override
  Color backgroundColor() => const Color(0xFF050817);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_playerX == 0) {
      _playerX = size.x / 2;
      _playerY = size.y * .78;
      _targetX = _playerX;
      _targetY = _playerY;
    }
  }

  void setTouchTarget(Offset point) {
    _touching = true;
    _targetX = point.dx.clamp(18.0, size.x - 18.0).toDouble();
    _targetY = point.dy.clamp(size.y * .38, size.y - 28.0).toDouble();
  }

  void releaseTouch() => _touching = false;

  Future<void> selectDragon(DragonProfile profile) async {
    if (profile.id == dragon.id) return;
    // ASTRALIS retains its original eight-frame animation. The other five
    // dragons use their own four illustrated wing positions in a six-step
    // forward/reverse cycle; Run 31 still art remains a safe fallback.
    final flightName = _run32DragonPaths[profile.id];
    if (flightName != null && !_run32DragonFlights.containsKey(profile.id)) {
      try {
        _run32DragonFlights[profile.id] = await Future.wait(List.generate(
          4,
          (i) => images.load(
            'run32/dragons/$flightName/flight/${flightName}_flight_${i.toString().padLeft(2, '0')}.png',
          ),
        ));
      } catch (error) {
        debugPrint('Run 32 dragon animation unavailable: $error');
      }
    }
    if (!_run32DragonFlights.containsKey(profile.id)) {
      final stillPath = _run31DragonPaths[profile.id];
      if (stillPath != null && !_run31DragonStills.containsKey(profile.id)) {
        try {
          _run31DragonStills[profile.id] = await images.load(stillPath);
        } catch (error) {
          debugPrint('Run 31 dragon art unavailable: $error');
          return;
        }
      }
    }
    final effectPath = _run31AbilityPaths[profile.id];
    if (effectPath != null && !_run31AbilityImages.containsKey(profile.id)) {
      try {
        _run31AbilityImages[profile.id] = await images.load(effectPath);
      } catch (error) {
        debugPrint('Run 31 ability art unavailable: $error');
      }
    }
    dragon = profile;
    _specialClock = 0;
    _publishHud(force: true);
  }

  void togglePause() {
    if (_gameOver) return;
    _paused = !_paused;
    _publishHud(force: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_paused || _gameOver || size.x <= 0 || size.y <= 0) return;
    final step = dt.clamp(0.0, .05).toDouble();
    if (_flightFrames.isNotEmpty) {
      _flightClock += step;
      while (_flightClock >= .1) {
        _flightClock -= .1;
        _flightFrame = (_flightFrame + 1) % _flightFrames.length;
      }
    }
    if (_specialCooldown > 0) {
      _specialCooldown = math.max(0.0, _specialCooldown - step).toDouble();
    }
    if (_specialClock > 0) {
      _specialClock = math.max(0.0, _specialClock - step).toDouble();
    }
    _waveElapsed += step;
    if (_playerInvulnerable > 0) {
      _playerInvulnerable =
          math.max(0.0, _playerInvulnerable - step).toDouble();
    }

    if (_touching) {
      final blend = (step * 8).clamp(0.0, 1.0).toDouble();
      _playerX += (_targetX - _playerX) * blend;
      _playerY += (_targetY - _playerY) * blend;
    }

    _fireClock += step;
    if (_fireClock >= .22) {
      _fireClock = 0;
      _bolts.add(_Bolt(_playerX, _playerY - 22));
    }

    final quota = 7 + _wave * 2;
    final bossWave = _wave % 5 == 0;
    if (_boss == null && _spawnedThisWave < quota) {
      _spawnClock += step;
      final interval = math.max(.32, .95 - _wave * .035);
      if (_spawnClock >= interval) {
        _spawnClock = 0;
        _spawnedThisWave++;
        final enemyType = _random.nextInt(3);
        final enemyRadius = [13.0, 15.0, 17.0][enemyType];
        final enemySpeed = [78.0, 68.0, 58.0][enemyType] + _wave * 4;
        final enemySize = [56.0, 64.0, 72.0][enemyType];
        _foes.add(_Foe(
          x: 24 + _random.nextDouble() * math.max(1.0, size.x - 48).toDouble(),
          y: -24,
          hp: 1.0 + (_wave ~/ 3),
          radius: enemyRadius,
          speed: enemySpeed,
          typeIndex: enemyType,
          spriteSize: enemySize,
        ));
      }
    }

    for (final bolt in _bolts) {
      bolt.y -= bolt.speed * step;
    }
    _bolts.removeWhere((b) => b.y < -30);

    for (final foe in _foes) {
      if (foe.typeIndex >= 0 && foe.typeIndex < _enemyFrames.length) {
        final frames = _enemyFrames[foe.typeIndex];
        if (frames.isNotEmpty) {
          foe.animationClock += step;
          while (foe.animationClock >= .14) {
            foe.animationClock -= .14;
            foe.animationFrame = (foe.animationFrame + 1) % frames.length;
          }
        }
      }
      foe.y += foe.speed * step;
      foe.x += math.sin((_waveElapsed * 2) + foe.y * .01) * 22 * step;
      foe.fireClock += step;
      if (foe.fireClock >= 1.8 && foe.y > 8 && foe.y < size.y * .72) {
        foe.fireClock = 0;
        final dx = _playerX - foe.x;
        final dy = _playerY - foe.y;
        final length = math.max(1.0, math.sqrt(dx * dx + dy * dy));
        const shotSpeed = 165.0;
        _enemyBolts.add(_EnemyBolt(foe.x, foe.y + foe.radius,
            dx / length * shotSpeed, dy / length * shotSpeed));
      }
    }

    for (final bolt in _bolts.toList()) {
      for (final foe in _foes.toList()) {
        if (_distance(bolt.x, bolt.y, foe.x, foe.y) < foe.radius + 5) {
          foe.hp -= 1;
          _bolts.remove(bolt);
          if (foe.hp <= 0) {
            _foes.remove(foe);
            _defeatedThisWave++;
            _score += 100;
          }
          break;
        }
      }
    }

    for (final foe in _foes.toList()) {
      if (_distance(_playerX, _playerY, foe.x, foe.y) < foe.radius + 13) {
        _foes.remove(foe);
        _damagePlayer();
      } else if (foe.y > size.y + 25) {
        _foes.remove(foe);
        _damagePlayer();
      }
    }

    for (final shot in _enemyBolts) {
      shot.x += shot.vx * step;
      shot.y += shot.vy * step;
    }
    _enemyBolts.removeWhere(
        (shot) => shot.y > size.y + 24 || shot.x < -24 || shot.x > size.x + 24);
    for (final shot in _enemyBolts.toList()) {
      if (_distance(_playerX, _playerY, shot.x, shot.y) < 17) {
        _enemyBolts.remove(shot);
        _damagePlayer();
      }
    }

    if (_spawnedThisWave >= quota && _foes.isEmpty && _boss == null) {
      if (bossWave) {
        _boss = _Foe(
            x: size.x / 2,
            y: -60,
            hp: 20 + _wave * 4,
            radius: 34,
            speed: 48,
            boss: true);
      } else {
        _advanceWave();
      }
    }

    if (_boss case final boss?) {
      boss.y = math.min(size.y * .23, boss.y + boss.speed * step).toDouble();
      boss.x = size.x / 2 + math.sin(_waveElapsed * .9) * size.x * .24;
      for (final bolt in _bolts.toList()) {
        if (_distance(bolt.x, bolt.y, boss.x, boss.y) < boss.radius + 5) {
          boss.hp -= 1;
          _bolts.remove(bolt);
        }
      }
      _bossAttackClock += step;
      if (_bossAttackClock >= 1.35 && boss.y > 0) {
        _bossAttackClock = 0;
        final dx = _playerX - boss.x;
        final dy = _playerY - boss.y;
        final length = math.max(1.0, math.sqrt(dx * dx + dy * dy));
        final vx = dx / length * 190;
        final vy = dy / length * 190;
        _enemyBolts.add(_EnemyBolt(boss.x, boss.y + boss.radius, vx, vy));
        _enemyBolts.add(_EnemyBolt(boss.x, boss.y + boss.radius, vx - 48, vy));
        _enemyBolts.add(_EnemyBolt(boss.x, boss.y + boss.radius, vx + 48, vy));
      }
      if (boss.hp <= 0) {
        _score += 2500;
        _boss = null;
        _advanceWave();
      }
      if (_distance(_playerX, _playerY, boss.x, boss.y) < boss.radius + 12) {
        _damagePlayer();
      }
    }

    _hudClock += step;
    if (_hudClock >= .12) {
      _hudClock = 0;
      _publishHud();
    }
  }

  void _advanceWave() {
    _wave++;
    _spawnedThisWave = 0;
    _defeatedThisWave = 0;
    _spawnClock = 0;
    _waveElapsed = 0;
  }

  void _damagePlayer() {
    if (_playerInvulnerable > 0 || _gameOver) return;
    _playerInvulnerable = 1.0;
    _health--;
    _enemyBolts.clear();
    if (_health <= 0) {
      _gameOver = true;
      _health = 0;
    }
    _publishHud(force: true);
  }

  bool activateSpecial() {
    if (_paused || _gameOver || _specialCooldown > 0) return false;
    _specialCooldown = 12.0;
    _specialClock = .65;
    switch (dragon.id) {
      case 'temperstryx':
      case 'nyxariel':
        _playerInvulnerable = math.max(_playerInvulnerable, 2.0).toDouble();
        break;
      case 'ignivar':
      case 'solarion':
      case 'aquaryth':
      case 'astralis':
      default:
        final radius = dragon.id == 'solarion' ? size.x * .72 : size.x * .48;
        for (final foe in _foes.toList()) {
          if (_distance(_playerX, _playerY, foe.x, foe.y) <= radius) {
            foe.hp -= dragon.power.toDouble() + 2;
            if (foe.hp <= 0) {
              _foes.remove(foe);
              _score += 100;
            }
          }
        }
        if (_boss != null) _boss!.hp -= dragon.power.toDouble() * 2 + 3;
        break;
    }
    _publishHud(force: true);
    return true;
  }

  double get specialCooldownRemaining => _specialCooldown;

  void restartGame() {
    _bolts.clear();
    _enemyBolts.clear();
    _foes.clear();
    _boss = null;
    _score = 0;
    _wave = 1;
    _health = 3;
    _spawnedThisWave = 0;
    _defeatedThisWave = 0;
    _fireClock = 0;
    _spawnClock = 0;
    _hudClock = 0;
    _waveElapsed = 0;
    _playerInvulnerable = 0;
    _bossAttackClock = 0;
    _specialCooldown = 0;
    _specialClock = 0;
    _paused = false;
    _gameOver = false;
    _touching = false;
    if (size.x > 0 && size.y > 0) {
      _playerX = size.x / 2;
      _playerY = size.y * .78;
      _targetX = _playerX;
      _targetY = _playerY;
    }
    _publishHud(force: true);
  }

  double _distance(double ax, double ay, double bx, double by) =>
      math.sqrt(math.pow(ax - bx, 2) + math.pow(ay - by, 2));

  void _publishHud({bool force = false}) {
    final next = DragonHudState(
        score: _score,
        wave: _wave,
        health: _health,
        paused: _paused,
        bossActive: _boss != null,
        dragonName: dragon.name);
    if (force ||
        next.score != hud.value.score ||
        next.wave != hud.value.wave ||
        next.health != hud.value.health ||
        next.paused != hud.value.paused ||
        next.bossActive != hud.value.bossActive ||
        next.dragonName != hud.value.dragonName) {
      hud.value = next;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawStars(canvas);
    final player = Paint()..color = dragon.palette;
    final gold = Paint()..color = const Color(0xFFFFD77A);
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = const Color(0xFFFF667E);

    for (final bolt in _bolts) {
      if (_run32PlayerBoltFrames.isNotEmpty) {
        final frame = _run32PlayerBoltFrames[
            _flightFrame % _run32PlayerBoltFrames.length];
        canvas.drawImageRect(
          frame,
          Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
          Rect.fromCenter(center: Offset(bolt.x, bolt.y), width: 16, height: 28),
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(bolt.x, bolt.y), width: 4, height: 18),
                const Radius.circular(3)),
            gold);
      }
    }
    for (final shot in _enemyBolts) {
      if (_run32EnemyBoltFrames.isNotEmpty) {
        final frame = _run32EnemyBoltFrames[
            _flightFrame % _run32EnemyBoltFrames.length];
        canvas.drawImageRect(
          frame,
          Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
          Rect.fromCenter(center: Offset(shot.x, shot.y), width: 22, height: 22),
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        canvas.drawCircle(Offset(shot.x, shot.y), 5,
            Paint()..color = const Color(0xFFFF7895));
        canvas.drawCircle(
            Offset(shot.x, shot.y),
            9,
            Paint()
              ..color = const Color(0x55FF7895)
              ..style = PaintingStyle.stroke);
      }
    }
    for (final foe in _foes) {
      if (foe.typeIndex >= 0 && foe.typeIndex < _enemyFrames.length &&
          _enemyFrames[foe.typeIndex].isNotEmpty) {
        final frames = _enemyFrames[foe.typeIndex];
        final frame = frames[foe.animationFrame % frames.length];
        canvas.drawImageRect(
          frame,
          Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
          Rect.fromCenter(
            center: Offset(foe.x, foe.y),
            width: foe.spriteSize,
            height: foe.spriteSize,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
      } else {
        canvas.drawCircle(Offset(foe.x, foe.y), foe.radius, red);
        canvas.drawCircle(
            Offset(foe.x, foe.y),
            foe.radius + 4,
            Paint()
              ..color = red.color.withOpacity(.18)
              ..style = PaintingStyle.stroke);
      }
    }
    if (_boss case final boss?) {
      if (_run31BossImage case final bossArt?) {
        canvas.drawImageRect(
          bossArt,
          Rect.fromLTWH(0, 0, bossArt.width.toDouble(), bossArt.height.toDouble()),
          Rect.fromCenter(
            center: Offset(boss.x, boss.y),
            width: 126,
            height: 96,
          ),
          Paint()..filterQuality = FilterQuality.medium,
        );
      } else {
        canvas.drawCircle(Offset(boss.x, boss.y), boss.radius + 8,
            Paint()..color = const Color(0xFFFF5577).withOpacity(.18));
        canvas.drawCircle(Offset(boss.x, boss.y), boss.radius, red);
      }
      final bar = Rect.fromLTWH(size.x * .2, 54, size.x * .6, 7);
      canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(4)),
          white..color = const Color(0xFF482638));
      final ratio = (boss.hp / (20 + _wave * 4)).clamp(0.0, 1.0).toDouble();
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(bar.left, bar.top, bar.width * ratio, bar.height),
              const Radius.circular(4)),
          red);
    }
    // Run 31 ability effect: brief, fading, and drawn behind the player.
    final effectArt = _run31AbilityImages[dragon.id];
    if (_specialClock > 0 && effectArt != null) {
      final width = math.min(size.x * .78, 270.0).toDouble();
      final height = width * effectArt.height / effectArt.width;
      canvas.drawImageRect(
        effectArt,
        Rect.fromLTWH(
            0, 0, effectArt.width.toDouble(), effectArt.height.toDouble()),
        Rect.fromCenter(
          center: Offset(_playerX, _playerY - 12),
          width: width,
          height: height,
        ),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withOpacity(
              (_specialClock / .65).clamp(0.0, 1.0).toDouble()),
      );
    }
    // Preserve the existing animated ASTRALIS sprite and vector fallback.
    final path = Path()
      ..moveTo(_playerX, _playerY - 22)
      ..quadraticBezierTo(_playerX + 22, _playerY + 5, _playerX, _playerY + 15)
      ..quadraticBezierTo(_playerX - 22, _playerY + 5, _playerX, _playerY - 22)
      ..close();
    if (_playerInvulnerable <= 0 || (_playerInvulnerable * 12).floor().isEven) {
      if (dragon.id == 'astralis' && _flightFrames.isNotEmpty) {
        final frame = _flightFrames[_flightFrame];
        canvas.drawImageRect(
          frame,
          Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
          Rect.fromCenter(
            center: Offset(_playerX, _playerY),
            width: 86,
            height: 114,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
      } else if (_run32DragonFlights[dragon.id] case final frames?) {
        final frame = frames[
            _run32WingCycle[_flightFrame % _run32WingCycle.length]];
        canvas.drawImageRect(
          frame,
          Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
          Rect.fromCenter(
            center: Offset(_playerX, _playerY),
            width: 96,
            height: 108,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
      } else if (_run31DragonStills[dragon.id] case final dragonArt?) {
        canvas.drawImageRect(
          dragonArt,
          Rect.fromLTWH(
              0, 0, dragonArt.width.toDouble(), dragonArt.height.toDouble()),
          Rect.fromCenter(
            center: Offset(_playerX, _playerY),
            width: 90,
            height: 108,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
      } else {
        canvas.drawPath(path, player);
      }
    } else {
      canvas.drawPath(path, Paint()..color = const Color(0x88FFFFFF));
    }
    if (_playerInvulnerable > 0) {
      canvas.drawCircle(
          Offset(_playerX, _playerY),
          25,
          Paint()
            ..color = const Color(0x665CCFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawCircle(Offset(_playerX, _playerY - 2), 4, gold);
    if (_paused || _gameOver) {
      final overlay = Paint()..color = const Color(0xBB050817);
      canvas.drawRect(Offset.zero & Size(size.x, size.y), overlay);
      final text = TextPainter(
        text: TextSpan(
            text: _gameOver ? 'FLIGHT ENDED' : 'PAUSED',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 3)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x);
      text.paint(canvas, Offset((size.x - text.width) / 2, size.y * .46));
      if (_gameOver) {
        final hint = TextPainter(
          text: const TextSpan(
              text: 'Tap FLY AGAIN to restart',
              style: TextStyle(color: Color(0xFF9CC7D8), fontSize: 12)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.x);
        hint.paint(
            canvas, Offset((size.x - hint.width) / 2, size.y * .46 + 42));
      }
    }
  }

  void _drawStars(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF8DBDEB).withOpacity(.5);
    for (var i = 0; i < 42; i++) {
      final x = (i * 73.0) % math.max(1.0, size.x).toDouble();
      final y = ((i * 131.0) + _waveElapsed * (12 + i % 4 * 5)) %
          math.max(1.0, size.y).toDouble();
      canvas.drawCircle(Offset(x, y), i % 7 == 0 ? 1.6 : .8, paint);
    }
  }
}
