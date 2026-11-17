import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_lunaryvell/game/dragon_profile.dart';

void main() {
  test('all six approved dragons are present exactly once', () {
    expect(DragonProfile.all.map((d) => d.id).toSet(), hasLength(6));
    expect(DragonProfile.all.map((d) => d.name).toSet(), {
      'ASTRALIS',
      'TEMPESTRYX',
      'IGNIVAR',
      'NYXARIEL',
      'SOLARION',
      'AQUARYTH',
    });
  });

  test('every dragon has a distinct special ability', () {
    expect(
        DragonProfile.all.map((d) => d.specialAbility).toSet(), hasLength(6));
  });

  test('stats remain within the five-point design scale', () {
    for (final dragon in DragonProfile.all) {
      expect(dragon.agility, inInclusiveRange(1, 5));
      expect(dragon.power, inInclusiveRange(1, 5));
      expect(dragon.armor, inInclusiveRange(1, 5));
    }
  });
}
