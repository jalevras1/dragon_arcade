import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DragonApp());
}

class DragonApp extends StatelessWidget {
  const DragonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = DragonGame();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DRAGON LUNARYVELL',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => game.moveShip(details.localPosition),
          onTap: () => game.fire(),
          child: GameWidget(game: game),
        ),
      ),
    );
  }
}

class DragonGame extends FlameGame {
  Offset ship = const Offset(180, 520);
  final List<Offset> bullets = [];
  final List<Offset> enemies = [];
  final math.Random random = math.Random(7);
  double spawnTimer = 0;
  double shotTimer = 0;
  int score = 0;
  int health = 3;
  bool gameOver = false;

  void moveShip(Offset point) {
    if (gameOver) return;
    ship = Offset(
      point.dx.clamp(25.0, math.max(25.0, size.x - 25)),
      point.dy.clamp(100.0, math.max(100.0, size.y - 45)),
    );
  }

  void fire() {
    if (gameOver) {
      score = 0;
      health = 3;
      bullets.clear();
      enemies.clear();
      gameOver = false;
      return;
    }
    if (shotTimer <= 0) {
      bullets.add(Offset(ship.dx, ship.dy - 30));
      shotTimer = 0.22;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;
    shotTimer -= dt;
    spawnTimer += dt;
    if (spawnTimer > 1.15) {
      spawnTimer = 0;
      enemies.add(Offset(30 + random.nextDouble() * math.max(1, size.x - 60), -25));
    }
    for (int i = 0; i < bullets.length; i++) {
      bullets[i] = bullets[i].translate(0, -440 * dt);
    }
    bullets.removeWhere((b) => b.dy < -10);
    for (int i = 0; i < enemies.length; i++) {
      enemies[i] = enemies[i].translate(0, 115 * dt);
    }
    for (final enemy in List<Offset>.from(enemies)) {
      if ((enemy - ship).distance < 29) {
        enemies.remove(enemy);
        health--;
        if (health <= 0) gameOver = true;
      } else if (enemy.dy > size.y + 20) {
        enemies.remove(enemy);
        health--;
        if (health <= 0) gameOver = true;
      }
    }
    for (final bullet in List<Offset>.from(bullets)) {
      for (final enemy in List<Offset>.from(enemies)) {
        if ((bullet - enemy).distance < 23) {
          bullets.remove(bullet);
          enemies.remove(enemy);
          score += 100;
          break;
        }
      }
    }
  }

  void drawText(Canvas canvas, String value, Offset position, double fontSize, Color color) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = const LinearGradient(colors: [Color(0xFF080B24), Color(0xFF241044), Color(0xFF080B24)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, w, h)));
    for (int i = 0; i < 75; i++) {
      final x = (i * 83.7) % math.max(1, w);
      final y = (i * 137.3) % math.max(1, h);
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.8 : 1, Paint()..color = Colors.white.withValues(alpha: 0.35 + (i % 4) * 0.12));
    }
    drawText(canvas, 'DRAGON LUNARYVELL', const Offset(18, 35), 19, const Color(0xFFFFD879));
    drawText(canvas, 'SCORE  $score', const Offset(18, 70), 15, Colors.white);
    drawText(canvas, 'LIVES  ${'♥ ' * health}', Offset(math.max(18, w - 125), 70), 15, const Color(0xFFFF6688));

    for (final bullet in bullets) {
      canvas.drawCircle(bullet, 7, Paint()..color = const Color(0xFF45F4FF).withValues(alpha: 0.3));
      canvas.drawCircle(bullet, 3.5, Paint()..color = const Color(0xFF8BFFFF));
    }
    for (final enemy in enemies) {
      final path = Path()..moveTo(enemy.dx, enemy.dy - 17)..lineTo(enemy.dx + 16, enemy.dy)..lineTo(enemy.dx, enemy.dy + 17)..lineTo(enemy.dx - 16, enemy.dy)..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFF4DAD));
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFFFC1EC));
    }

    final shipPath = Path()..moveTo(ship.dx, ship.dy - 28)..lineTo(ship.dx + 23, ship.dy + 20)..lineTo(ship.dx, ship.dy + 12)..lineTo(ship.dx - 23, ship.dy + 20)..close();
    canvas.drawCircle(ship, 29, Paint()..color = const Color(0xFF39DFFF).withValues(alpha: 0.13));
    canvas.drawPath(shipPath, Paint()..color = const Color(0xFFFFD66E));
    canvas.drawPath(shipPath, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white);
    canvas.drawOval(Rect.fromCenter(center: ship.translate(0, -4), width: 9, height: 17), Paint()..color = const Color(0xFF65E9FF));
    drawText(canvas, 'DRAG TO MOVE  •  TAP TO FIRE', Offset(18, h - 42), 12, const Color(0xFFB9C7FF));

    if (gameOver) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.black.withValues(alpha: 0.72));
      drawText(canvas, 'SHIP DESTROYED', Offset(w / 2 - 95, h / 2 - 35), 23, const Color(0xFFFF789A));
      drawText(canvas, 'FINAL SCORE: $score', Offset(w / 2 - 82, h / 2 + 5), 15, Colors.white);
      drawText(canvas, 'TAP TO PLAY AGAIN', Offset(w / 2 - 91, h / 2 + 45), 14, const Color(0xFFFFD879));
    }
  }
}
