import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/queue_order.dart';

QueueOrder _started({
  required int length,
  int start = 0,
  bool shuffle = false,
  QueueRepeat repeat = QueueRepeat.off,
  int seed = 1,
}) {
  final order = QueueOrder(random: Random(seed))
    ..setShuffle(shuffle)
    ..repeat = repeat;
  order.start(length: length, startIndex: start);
  return order;
}

/// Every position the order hands out from here on, the current one first.
List<int> _walk(QueueOrder order) {
  final songs = <int>[order.currentIndex!];
  for (var next = order.advance(); next != null; next = order.advance()) {
    songs.add(next);
  }
  return songs;
}

void main() {
  group('in order (shuffle off)', () {
    test('a song added at the end is played after the last one', () {
      final order = _started(length: 3, start: 1);

      order.remap(oldToNew: [0, 1, 2], newLength: 4, added: [3]);

      expect(order.currentIndex, 1);
      expect(_walk(order), [1, 2, 3]);
    });

    test('a song taken out before the current one keeps the same song', () {
      final order = _started(length: 4, start: 2);

      order.remap(oldToNew: [null, 0, 1, 2], newLength: 3, added: []);

      expect(order.currentIndex, 1); // the song that was at 2
      expect(_walk(order), [1, 2]);
    });

    test('a reorder goes on from the song that is playing', () {
      final order = _started(length: 3, start: 1);

      // b, a, c became c, a, b: b (was 1) is now at 2.
      order.remap(oldToNew: [1, 2, 0], newLength: 3, added: []);

      expect(order.currentIndex, 2);
      expect(order.hasNext, isFalse);
    });

    test('with nothing left after it, the queue ends there', () {
      final order = _started(length: 3, start: 2);

      order.remap(oldToNew: [0, 1, 2], newLength: 3, added: []);

      expect(order.advance(), isNull);
    });
  });

  group('shuffle on', () {
    test('the song playing and the order of the rest are kept', () {
      final order = _started(length: 5, shuffle: true, seed: 4);
      final before = _walk(_started(length: 5, shuffle: true, seed: 4));

      // Nothing moved, one song was added.
      order.remap(oldToNew: [0, 1, 2, 3, 4], newLength: 6, added: [5]);

      final after = _walk(order);
      expect(after.first, before.first);
      expect(after.where((p) => p != 5).toList(), before);
    });

    test('a new song is slipped in among the songs still to come', () {
      for (var seed = 0; seed < 30; seed++) {
        final order = _started(length: 4, shuffle: true, seed: seed);
        order.advance(); // one song has been played

        order.remap(oldToNew: [0, 1, 2, 3], newLength: 5, added: [4]);

        final walk = _walk(order);
        expect(walk.length, 4); // from the song playing: 3 old + the new one
        expect(walk.contains(4), isTrue);
        expect(walk.first, isNot(4));
      }
    });

    test('a played song is never brought back by a new one', () {
      for (var seed = 0; seed < 30; seed++) {
        final order = _started(length: 4, shuffle: true, seed: seed);
        final first = order.currentIndex!;
        order.advance();

        order.remap(oldToNew: [0, 1, 2, 3], newLength: 5, added: [4]);

        expect(_walk(order).contains(first), isFalse);
      }
    });

    test('songs taken out are gone and the rest keep their order', () {
      final order = _started(length: 4, shuffle: true, seed: 2);
      final before = _walk(_started(length: 4, shuffle: true, seed: 2));
      final gone = before.last;
      final oldToNew = List<int?>.filled(4, null);
      var next = 0;
      for (var i = 0; i < 4; i++) {
        if (i != gone) oldToNew[i] = next++;
      }

      order.remap(oldToNew: oldToNew, newLength: 3, added: []);

      final after = _walk(order);
      expect(after.length, 3);
      expect(after.toSet(), {0, 1, 2});
      expect(after.first, oldToNew[before.first]);
    });

    test('whatever changes, every position is in the order once', () {
      final random = Random(9);
      for (var round = 0; round < 200; round++) {
        final length = 1 + random.nextInt(8);
        final order = _started(
          length: length,
          start: random.nextInt(length),
          shuffle: random.nextBool(),
          seed: round,
        );
        for (var i = random.nextInt(length); i > 0; i--) {
          order.advance();
        }

        final oldToNew = List<int?>.filled(length, null);
        var kept = 0;
        for (var i = 0; i < length; i++) {
          if (random.nextInt(3) != 0) oldToNew[i] = kept++;
        }
        final added = [for (var i = 0; i < random.nextInt(4); i++) kept + i];
        final newLength = kept + added.length;
        if (newLength == 0) continue;

        order.remap(oldToNew: oldToNew, newLength: newLength, added: added);

        // From the song playing (or the next one that stayed) to the end,
        // nothing is handed out twice and nothing is out of range.
        final cursor = order.currentIndex;
        if (cursor == null) continue;
        final walk = _walk(order);
        expect(walk.toSet().length, walk.length);
        expect(walk.every((p) => p >= 0 && p < newLength), isTrue);
      }
    });
  });

  test('with repeat all the next round covers the new songs too', () {
    final order = _started(length: 2, repeat: QueueRepeat.all);

    order.remap(oldToNew: [0, 1], newLength: 3, added: [2]);
    final round = [order.currentIndex!, order.advance()!, order.advance()!];

    expect(round, [0, 1, 2]);
    expect(order.advance(), 0); // and round again
  });

  test('an emptied queue has nothing to play', () {
    final order = _started(length: 2);

    order.remap(oldToNew: [null, null], newLength: 0, added: []);

    expect(order.currentIndex, isNull);
    expect(order.hasNext, isFalse);
  });
}
