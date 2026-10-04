import 'package:flutter/material.dart';
import '../content/labels.dart';

/// One tab of the app: its icon and its name.
typedef SwarDestination = ({IconData icon, String label});

/// The tabs, in order. Shared by the bottom bar and the side rail, so the
/// two can never disagree.
const List<SwarDestination> swarDestinations = [
  (icon: Icons.home_outlined, label: Labels.navHome),
  (icon: Icons.search, label: Labels.navSearch),
  (icon: Icons.library_music_outlined, label: Labels.navLibrary),
  (icon: Icons.favorite_border, label: Labels.navUs),
];
