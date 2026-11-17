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
      this.boss = false});
  double x, y, hp, radius, speed;
  bool boss;
  double fireClock = 0;
}

class DragonLunaryvellGame extends FlameGame {
  DragonLunaryvellGame({this.dragon = DragonProfile.astralis});
  final DragonProfile dragon;
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
  double _flightClock = 0;
  int _flightFrame = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _flightFrames = await Future.wait<ui.Image>(
      List.generate(
        8,
        (i) => images.load(
          'dragons/astralis/flight/astralis_flight_wing_${i.toString().padLeft(2, '0')}.png',
        ),
      ),
    );
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
      if (_flightClock >= .1) {
        _flightClock -= .1;
        _flightFrame = (_flightFrame + 1) % _flightFrames.length;
      }
    }
    if (_specialCooldown > 0) {
      _specialCooldown = math.max(0.0, _specialCooldown - step).toDouble();
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
        _foes.add(_Foe(
          x: 24 + _random.nextDouble() * math.max(1.0, size.x - 48).toDouble(),
          y: -24,
          hp: 1.0 + (_wave ~/ 3),
          radius: 13 + _random.nextDouble() * 5,
          speed: 65 + _wave * 4,
        ));
      }
    }

    for (final bolt in _bolts) {
      bolt.y -= bolt.speed * step;
    }
    _bolts.removeWhere((b) => b.y < -30);

    for (final foe in _foes) {
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
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(bolt.x, bolt.y), width: 4, height: 18),
              const Radius.circular(3)),
          gold);
    }
    for (final shot in _enemyBolts) {
      canvas.drawCircle(
          Offset(shot.x, shot.y), 5, Paint()..color = const Color(0xFFFF7895));
      canvas.drawCircle(
          Offset(shot.x, shot.y),
          9,
          Paint()
            ..color = const Color(0x55FF7895)
            ..style = PaintingStyle.stroke);
    }
    for (final foe in _foes) {
      canvas.drawCircle(Offset(foe.x, foe.y), foe.radius, red);
      canvas.drawCircle(
          Offset(foe.x, foe.y),
          foe.radius + 4,
          Paint()
            ..color = red.color.withOpacity(.18)
            ..style = PaintingStyle.stroke);
    }
    if (_boss case final boss?) {
      canvas.drawCircle(Offset(boss.x, boss.y), boss.radius + 8,
          Paint()..color = const Color(0xFFFF5577).withOpacity(.18));
      canvas.drawCircle(Offset(boss.x, boss.y), boss.radius, red);
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
    if (_playerInvulnerable <= 0 || (_playerInvulnerable * 12).floor().isEven) {
      if (_flightFrames.isNotEmpty) {
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
      }
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
