import 'package:flutter/material.dart';

/// Centralized Color Palette for the Admin Dashboard.
///
/// Whenever you need to change any color in the entire app,
/// modify the values right here and it will reflect across all screens!
class AppColors {
  // -------------------------------------------------------------
  // Primary Surfaces & Backgrounds
  // -------------------------------------------------------------
  /// Deep Slate / Dark Navy background (#0F172A)
  static const Color backgroundPrimary = Color(0xFF0F172A);

  /// Card Surface / Containers (#1E293B)
  static const Color cardSurface = Color(0xFF1E293B);

  /// Subtle Border color for cards, dividers, and outlines
  static const Color cardBorder = Color(0xFF334155);

  // -------------------------------------------------------------
  // Brand & Accent Colors
  // -------------------------------------------------------------
  /// Primary Accent / Active Buttons (#6366F1 - Indigo / Electric Violet)
  static const Color primaryAccent = Color(0xFF6366F1);

  /// Lighter tint of primary accent for hover/light highlights
  static const Color primaryAccentLight = Color(0xFF818CF8);

  /// Primary accent with low opacity for pill buttons and subtle backings
  static const Color primaryAccentMuted = Color(0x266366F1); // ~15% opacity

  // -------------------------------------------------------------
  // Status & Badges
  // -------------------------------------------------------------
  /// Success / Stock Badges / Online (#10B981 - Emerald Green)
  static const Color success = Color(0xFF10B981);

  /// Success with low opacity for badge backgrounds
  static const Color successMuted = Color(0x2610B981); // ~15% opacity

  /// Warning / Delivery Badges / Pending (#F59E0B - Amber Orange)
  static const Color warning = Color(0xFFF59E0B);

  /// Warning with low opacity for alert containers
  static const Color warningMuted = Color(0x26F59E0B); // ~15% opacity

  // -------------------------------------------------------------
  // Typography Hierarchy
  // -------------------------------------------------------------
  /// Text Primary (#F8FAFC - Pure White / Off-white)
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Text Secondary (#94A3B8 - Muted Slate Grey)
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Text Muted / Hints (#64748B - Darker Slate)
  static const Color textMuted = Color(0xFF64748B);

  // -------------------------------------------------------------
  // Charts & Visualizations
  // -------------------------------------------------------------
  /// Indigo fill bar for fulfilled orders
  static const Color chartFulfilled = Color(0xFF6366F1);

  /// Slate background bar representing weekly target
  static const Color chartTarget = Color(0xFF334155);

  /// Subtle chart grid / baseline line
  static const Color chartBaseline = Color(0xFF1E293B);

  // -------------------------------------------------------------
  // Navigation & Bottom Bar
  // -------------------------------------------------------------
  /// Bottom bar background
  static const Color navBackground = Color(0xFF0F172A);

  /// Active tab pill background
  static const Color navSelectedBackground = Color(0xFF1E293B);

  /// Active tab icon and label color
  static const Color navSelected = Color(0xFF6366F1);

  /// Inactive tab icon and label color
  static const Color navUnselected = Color(0xFF64748B);
}

