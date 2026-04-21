import 'package:flutter/material.dart';

/// Kinds of accessories the pig can wear.
enum AccessoryKind { partyHat, sunglasses, wizardHat, bowTie, headband }

class Accessory {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final AccessoryKind kind;
  final Color primaryColor;
  final bool isPremium; // requires Pro unlock to purchase

  const Accessory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.kind,
    required this.primaryColor,
    this.isPremium = false,
  });
}

/// Full shop catalog.
const List<Accessory> kAccessories = [
  Accessory(
    id: 'party_hat',
    name: 'Party Hat',
    emoji: '🎉',
    price: 15,
    kind: AccessoryKind.partyHat,
    primaryColor: Color(0xFFFF6B9C),
  ),
  Accessory(
    id: 'sunglasses',
    name: 'Cool Shades',
    emoji: '😎',
    price: 30,
    kind: AccessoryKind.sunglasses,
    primaryColor: Color(0xFF2D2D2D),
  ),
  Accessory(
    id: 'bow_tie',
    name: 'Fancy Bow Tie',
    emoji: '🎀',
    price: 45,
    kind: AccessoryKind.bowTie,
    primaryColor: Color(0xFFE53935),
  ),
  Accessory(
    id: 'wizard_hat',
    name: 'Wizard Hat',
    emoji: '🧙',
    price: 75,
    kind: AccessoryKind.wizardHat,
    primaryColor: Color(0xFF512DA8),
    isPremium: true,
  ),
  Accessory(
    id: 'headband',
    name: 'Sport Headband',
    emoji: '🎽',
    price: 25,
    kind: AccessoryKind.headband,
    primaryColor: Color(0xFF00A86B),
  ),
  Accessory(
    id: 'royal_crown',
    name: 'Royal Crown',
    emoji: '👑',
    price: 100,
    kind: AccessoryKind.partyHat,   // reuse party-hat shape
    primaryColor: Color(0xFFFFD700),
    isPremium: true,
  ),
];

Accessory? accessoryById(String? id) {
  if (id == null) return null;
  for (final a in kAccessories) {
    if (a.id == id) return a;
  }
  return null;
}
