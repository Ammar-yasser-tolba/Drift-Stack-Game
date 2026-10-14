import 'package:flutter/material.dart';

/// Section 15.5 skin palettes + Section 10 prices.
class SkinDef {
  const SkinDef({
    required this.id,
    required this.name,
    required this.price,
    required this.blockColors,
    required this.bgTop,
    required this.bgBottom,
    this.outline,
  });

  final String id;
  final String name;
  final int price;
  final List<Color> blockColors;
  final Color bgTop;
  final Color bgBottom;

  /// Pharaoh blocks get a 2 dp gold outline.
  final Color? outline;

  bool get isFree => price == 0;

  /// Block colours cycle in order with the floor index.
  Color colorAt(int floor) => blockColors[floor % blockColors.length];

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[bgTop, bgBottom],
      );
}

class Skins {
  Skins._();

  static const SkinDef neon = SkinDef(
    id: 'neon',
    name: 'Neon',
    price: 0,
    blockColors: <Color>[Color(0xFF18FFFF), Color(0xFFFF4081), Color(0xFFFFC107)],
    bgTop: Color(0xFF0B0F2B),
    bgBottom: Color(0xFF1B0B3A),
  );

  static const SkinDef desert = SkinDef(
    id: 'desert',
    name: 'Desert',
    price: 100,
    blockColors: <Color>[Color(0xFFE6B566), Color(0xFFC77D3A), Color(0xFFF2D49B)],
    bgTop: Color(0xFF3D1F0D),
    bgBottom: Color(0xFF7A4A1E),
  );

  static const SkinDef pharaoh = SkinDef(
    id: 'pharaoh',
    name: 'Pharaoh',
    price: 250,
    blockColors: <Color>[Color(0xFFD4AF37), Color(0xFF1F6FEB), Color(0xFFF5E6A8)],
    bgTop: Color(0xFF0A1A2F),
    bgBottom: Color(0xFF14365C),
    outline: Color(0xFFD4AF37),
  );

  static const List<SkinDef> all = <SkinDef>[neon, desert, pharaoh];

  static SkinDef byId(String id) {
    for (final SkinDef s in all) {
      if (s.id == id) return s;
    }
    return neon;
  }
}
