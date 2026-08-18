import 'package:flutter/material.dart';

const mensaAllergenNames = {
  'A': 'Glutenhaltiges Getreide',
  'B': 'Krebstiere',
  'C': 'Eier / Geflügel',
  'D': 'Fisch',
  'E': 'Erdnüsse',
  'F': 'Sojabohnen',
  'G': 'Milch / Laktose',
  'H': 'Schalenfrüchte',
  'L': 'Sellerie',
  'M': 'Senf',
  'N': 'Sesamsamen',
  'O': 'Schwefeldioxid / Sulfite',
  'P': 'Lupinen',
  'R': 'Weichtiere',
};

class MensaCategoryStyle {
  const MensaCategoryStyle(this.background, this.foreground, this.icon);
  final Color background;
  final Color foreground;
  final IconData icon;
}

MensaCategoryStyle mensaCategoryStyleFor(String category, ColorScheme cs) {
  switch (category) {
    case 'Vegan':
      return MensaCategoryStyle(
        cs.secondaryContainer,
        cs.onSecondaryContainer,
        Icons.eco_outlined,
      );
    case 'Menü 2':
      return MensaCategoryStyle(
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        Icons.ramen_dining_outlined,
      );
    default:
      return MensaCategoryStyle(
        cs.primaryContainer,
        cs.onPrimaryContainer,
        Icons.restaurant_menu_outlined,
      );
  }
}
