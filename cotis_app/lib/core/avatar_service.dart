import 'package:flutter/material.dart';

class AvatarService {
  // Active DiceBear style
  static const String _style = 'adventurer';
  
  // DiceBear API base URL for version 9.x
  static const String _baseUrl = 'https://api.dicebear.com/9.x';

  // Supported styles registry for DiceBear API v9.x
  static const List<String> supportedStyles = [
    'adventurer',
    'adventurer-neutral',
    'avataaars',
    'avataaars-neutral',
    'big-ears',
    'big-ears-neutral',
    'big-smile',
    'bottts',
    'bottts-neutral',
    'croodles',
    'croodles-neutral',
    'dylan',
    'fun-emoji',
    'glass',
    'icons',
    'identicon',
    'initials',
    'lorelei',
    'lorelei-neutral',
    'micah',
    'miniavs',
    'notionists',
    'notionists-neutral',
    'open-peeps',
    'personas',
    'pixel-art',
    'pixel-art-neutral',
    'rings',
    'shapes',
    'thumbs',
    'toon-head',
  ];

  static String generateFromEmail(String email) {
    final seed = Uri.encodeComponent(email.toLowerCase().trim());
    return '$_baseUrl/$_style/png?seed=$seed'
        '&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf'
        '&backgroundType=gradientLinear'
        '&radius=50';
  }

  /// Fallback: extracts user initials from email
  static String initialsFromEmail(String email) {
    if (email.trim().isEmpty) return '?';
    final parts = email.split('@').first.split('.');
    if (parts.length >= 2) {
      if (parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }
    final trimmed = email.trim();
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Fallback: stable and consistent background color based on email hash
  static Color colorFromEmail(String email) {
    final colors = [
      const Color(0xFF5C35D9), // Sleek Violet
      const Color(0xFF1D9E75), // Deep Teal
      const Color(0xFFD85A30), // Warm Coral
      const Color(0xFF378ADD), // Bright Blue
      const Color(0xFFBA7517), // Rich Amber
    ];
    if (email.isEmpty) return colors[0];
    final index = email.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}
