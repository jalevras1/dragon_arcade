import 'package:flutter/material.dart';

/// Approved playable dragon identities for DRAGON LUNARYVELL.
/// Artwork remains 2D sprite-based; these colors are temporary UI/gameplay tints.
class DragonProfile {
  const DragonProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.palette,
    required this.playStyle,
    required this.specialAbility,
    required this.specialDescription,
    required this.agility,
    required this.power,
    required this.armor,
  });

  final String id;
  final String name;
  final String title;
  final Color palette;
  final String playStyle;
  final String specialAbility;
  final String specialDescription;
  final int agility;
  final int power;
  final int armor;

  static const astralis = DragonProfile(
    id: 'astralis',
    name: 'ASTRALIS',
    title: 'Celestial Dragon',
    palette: Color(0xFF4F9EFF),
    playStyle: 'Balanced starter',
    specialAbility: 'Celestial Nova',
    specialDescription: 'A circular burst of celestial energy.',
    agility: 3,
    power: 3,
    armor: 3,
  );
  static const temperstryx = DragonProfile(
    id: 'temperstryx',
    name: 'TEMPESTRYX',
    title: 'Lightning Dragon',
    palette: Color(0xFF8D7BFF),
    playStyle: 'Extreme agility',
    specialAbility: 'Lightning Dash',
    specialDescription: 'A rapid phase-dash through danger.',
    agility: 5,
    power: 3,
    armor: 2,
  );
  static const ignivar = DragonProfile(
    id: 'ignivar',
    name: 'IGNIVAR',
    title: 'Infernal Dragon',
    palette: Color(0xFFE95B4D),
    playStyle: 'Heavy armor, slower flight',
    specialAbility: 'Dragonfire Barrage',
    specialDescription: 'A concentrated forward fire barrage.',
    agility: 2,
    power: 5,
    armor: 5,
  );
  static const nyxariel = DragonProfile(
    id: 'nyxariel',
    name: 'NYXARIEL',
    title: 'Phantom Dragon',
    palette: Color(0xFF9B72D9),
    playStyle: 'Evasive and elusive',
    specialAbility: 'Void Shift',
    specialDescription: 'A short phase shift that avoids incoming harm.',
    agility: 5,
    power: 2,
    armor: 2,
  );
  static const solarion = DragonProfile(
    id: 'solarion',
    name: 'SOLARION',
    title: 'Solar Dragon',
    palette: Color(0xFFFFD16A),
    playStyle: 'Charged energy attacks',
    specialAbility: 'Solar Collapse',
    specialDescription: 'A charged solar blast that damages nearby foes.',
    agility: 3,
    power: 5,
    armor: 3,
  );
  static const aquaryth = DragonProfile(
    id: 'aquaryth',
    name: 'AQUARYTH',
    title: 'Tidal Dragon',
    palette: Color(0xFF42D8D0),
    playStyle: 'Precision and control',
    specialAbility: 'Tidal Vortex',
    specialDescription: 'A focused vortex that slows and damages enemies.',
    agility: 4,
    power: 3,
    armor: 3,
  );

  static const all = <DragonProfile>[
    astralis,
    temperstryx,
    ignivar,
    nyxariel,
    solarion,
    aquaryth,
  ];
}
