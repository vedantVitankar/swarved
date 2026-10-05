import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/volume_level.dart';

void main() {
  group('VolumeLevel.clamp', () {
    test('passes values already in range', () {
      expect(VolumeLevel.clamp(0.5), 0.5);
    });
    test('clamps below zero to 0.0', () {
      expect(VolumeLevel.clamp(-1), 0.0);
    });
    test('clamps above one to 1.0', () {
      expect(VolumeLevel.clamp(2), 1.0);
    });
  });

  group('VolumeLevel.isMuted', () {
    test('zero is muted', () => expect(VolumeLevel.isMuted(0.0), isTrue));
    test('any positive value is not muted',
        () => expect(VolumeLevel.isMuted(0.01), isFalse));
  });

  group('VolumeLevel.unmutedLevel', () {
    test('returns remembered level when it is positive', () {
      expect(VolumeLevel.unmutedLevel(0.6), 0.6);
    });
    test('falls back to default when remembered is zero', () {
      expect(VolumeLevel.unmutedLevel(0.0), VolumeLevel.defaultLevel);
    });
  });

  group('VolumeLevel.tier', () {
    test('0.0 → mute', () => expect(VolumeLevel.tier(0.0), VolumeTier.mute));
    test('0.1 → low', () => expect(VolumeLevel.tier(0.1), VolumeTier.low));
    test('0.33 → low (boundary)', () => expect(VolumeLevel.tier(1 / 3), VolumeTier.low));
    test('0.34 → mid', () => expect(VolumeLevel.tier(0.34), VolumeTier.mid));
    test('0.66 → mid (boundary)', () => expect(VolumeLevel.tier(2 / 3), VolumeTier.mid));
    test('0.67 → high', () => expect(VolumeLevel.tier(0.67), VolumeTier.high));
    test('1.0 → high', () => expect(VolumeLevel.tier(1.0), VolumeTier.high));
  });
}
