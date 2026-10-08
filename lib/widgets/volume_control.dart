import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content/labels.dart';
import '../services/player_service.dart';
import '../theme/colors.dart';
import '../utils/volume_level.dart';

/// Speaker icon whose glyph follows the volume tier, plus a compact slider.
/// Tapping the icon mutes or unmutes. Dragging the slider sets the level.
///
/// Reuses the rose SliderTheme already defined in AppTheme.dark —
/// no new colours are introduced here.
class VolumeControl extends StatelessWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, double>(
      selector: (_, player) => player.volume,
      builder: (context, vol, _) {
        final player = context.read<PlayerService>();
        final isMuted = VolumeLevel.isMuted(vol);

        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mute / unmute button — the icon reflects the current tier.
              Tooltip(
                message: isMuted ? Labels.unmute : Labels.mute,
                child: InkWell(
                  onTap: player.toggleMute,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _iconFor(VolumeLevel.tier(vol)),
                      size: 20,
                      color: isMuted
                          ? AppColors.textFaint
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              // Slider width-constrained; height is bounded by IntrinsicHeight
              // so it never expands to fill an unconstrained bottomNavigationBar.
              SizedBox(
                width: 88,
                child: Slider(
                  min: VolumeLevel.min,
                  max: VolumeLevel.max,
                  value: vol,
                  onChanged: player.setVolume,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static IconData _iconFor(VolumeTier tier) => switch (tier) {
        VolumeTier.mute => Icons.volume_off,
        VolumeTier.low => Icons.volume_down,
        VolumeTier.mid => Icons.volume_down,
        VolumeTier.high => Icons.volume_up,
      };
}
