import 'package:flutter/material.dart';

import '../models/game_entry.dart';

/// A card on the home page that opens a game.
class GameTile extends StatelessWidget {
  /// Creates a tile for [game].
  const GameTile({super.key, required this.game, required this.onTap});

  /// The game to show.
  final GameEntry game;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(game.icon, size: 32),
        title: Text(game.title),
        subtitle: Text(game.subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
