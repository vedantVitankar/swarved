import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/queue_order.dart';

QueueOrder _started({
  int length = 5,
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

/// Every position the order hands out from here to the end, current first.
List<int> _walk(QueueOrder order) {
  final songs = <int>[order.currentIndex!];
  for (var next = order.advance(); next != null; next = order.advance()) {
    songs.add(next);
  }
  return songs;
}

void main() {
  _savingTests();
  group('in order (shuffle off)', () {
    test('starts where it is told', () {
      expect(_started(start: 2).currentIndex, 2);
    });

    test('walks forward to the end, then stops', () {
      final order = _started(length: 3);

      expect(order.advance(), 1);
      expect(order.advance(), 2);
      expect(order.advance(), isNull);
      expect(order.currentIndex, 2);
      expect(order.hasNext, isFalse);
    });

    test('walks backward to the start, then stops', () {
      final order = _started(length: 3, start: 2);

      expect(order.back(), 1);
      expect(order.back(), 0);
      expect(order.back(), isNull);
      expect(order.currentIndex, 0);
      expect(order.hasPrevious, isFalse);
    });

    test('a start outside the queue is pulled inside', () {
      final order = QueueOrder()..start(length: 3, startIndex: 9);
      expect(order.currentIndex, 2);

      order.start(length: 3, startIndex: -4);
      expect(order.currentIndex, 0);
    });

    test('an empty queue has nothing to play', () {
      final order = QueueOrder()..start(length: 0, startIndex: 0);

      expect(order.currentIndex, isNull);
      expect(order.hasNext, isFalse);
      expect(order.hasPrevious, isFalse);
      expect(order.advance(), isNull);
      expect(order.back(), isNull);
      expect(order.onSongEnded(), isNull);
    });
  });

  group('shuffle', () {
    test('plays the chosen song first, then every song once', () {
      for (var seed = 0; seed < 10; seed++) {
        final songs =
            _walk(_started(length: 6, start: 3, shuffle: true, seed: seed));

        expect(songs.first, 3);
        expect(songs.length, 6);
        expect([...songs]..sort(), [0, 1, 2, 3, 4, 5]);
      }
    });

    test('switching on mid-song keeps the song and mixes the rest', () {
      for (var seed = 0; seed < 10; seed++) {
        final order = _started(length: 5, start: 1, seed: seed)..advance();
        order.setShuffle(true);

        final songs = _walk(order);
        expect(songs.first, 2);
        expect([...songs]..sort(), [0, 1, 2, 3, 4]);
      }
    });

    test('switching off keeps the song and carries on in order', () {
      for (var seed = 0; seed < 10; seed++) {
        final order = _started(length: 5, start: 3, shuffle: true, seed: seed);
        order.advance();
        final playing = order.currentIndex!;

        order.setShuffle(false);

        expect(order.currentIndex, playing);
        expect(order.advance(), playing < 4 ? playing + 1 : isNull);
      }
    });

    test('setting shuffle to its current value changes nothing', () {
      final a = _started(length: 5, start: 2, shuffle: true, seed: 4);
      final b = _started(length: 5, start: 2, shuffle: true, seed: 4)
        ..setShuffle(true)
        ..setShuffle(true);

      expect(_walk(b), _walk(a));
    });

    test('can be switched on before any queue exists', () {
      final order = QueueOrder(random: Random(2))..setShuffle(true);
      order.start(length: 5, startIndex: 4);

      final songs = _walk(order);
      expect(songs.first, 4);
      expect([...songs]..sort(), [0, 1, 2, 3, 4]);
    });
  });

  group('repeat all', () {
    test('wraps from the last song to the first', () {
      final order = _started(length: 3, start: 2, repeat: QueueRepeat.all);

      expect(order.hasNext, isTrue);
      expect(order.advance(), 0);
    });

    test('wraps back from the first song to the last', () {
      final order = _started(length: 3, repeat: QueueRepeat.all);

      expect(order.hasPrevious, isTrue);
      expect(order.back(), 2);
    });

    test(
        'with shuffle, each round has every song and never opens with '
        'the song that just ended', () {
      for (var seed = 0; seed < 20; seed++) {
        final order = _started(
          length: 4,
          shuffle: true,
          repeat: QueueRepeat.all,
          seed: seed,
        );
        final played = <int>[order.currentIndex!];
        for (var i = 0; i < 11; i++) {
          played.add(order.advance()!);
        }
        final rounds = [
          for (var r = 0; r < 12; r += 4) played.sublist(r, r + 4),
        ];

        for (final round in rounds) {
          expect([...round]..sort(), [0, 1, 2, 3]);
        }
        for (var r = 1; r < rounds.length; r++) {
          expect(rounds[r].first, isNot(rounds[r - 1].last));
        }
      }
    });

    test('a one-song queue repeats itself', () {
      expect(_started(length: 1, repeat: QueueRepeat.all).advance(), 0);
      expect(_started(length: 1).advance(), isNull);
    });
  });

  group('repeat one', () {
    test('a finished song plays again', () {
      final order = _started(length: 3, start: 1, repeat: QueueRepeat.one);

      expect([order.onSongEnded(), order.onSongEnded(), order.onSongEnded()],
          [1, 1, 1]);
    });

    test('skipping still moves on', () {
      final order = _started(length: 3, start: 1, repeat: QueueRepeat.one);

      expect(order.advance(), 2);
    });
  });

  group('repeat off', () {
    test('a finished song moves on, and the last one stops', () {
      final order = _started(length: 2);

      expect(order.onSongEnded(), 1);
      expect(order.onSongEnded(), isNull);
      expect(order.currentIndex, 1);
    });

    test('repeat can be changed while playing', () {
      final order = _started(length: 2, start: 1);
      expect(order.hasNext, isFalse);

      order.repeat = QueueRepeat.all;
      expect(order.hasNext, isTrue);
    });
  });

  group('upcomingIndex', () {
    test('is the next position, and does not move', () {
      final order = _started(length: 3);

      expect(order.upcomingIndex, 1);
      expect(order.upcomingIndex, 1);
      expect(order.currentIndex, 0);
    });

    test('is null on the last song with repeat off', () {
      final order = _started(length: 3, start: 2);

      expect(order.upcomingIndex, isNull);
    });

    test('wraps to the first song with repeat all', () {
      final order = _started(length: 3, start: 2, repeat: QueueRepeat.all);

      expect(order.upcomingIndex, 0);
    });

    test('with shuffle, is the song advance() then returns', () {
      final order = _started(length: 5, shuffle: true, seed: 3);
      final upcoming = order.upcomingIndex;

      expect(order.advance(), upcoming);
    });

    test('is unknown at the end of a shuffled round with repeat all', () {
      final order = _started(
        length: 3,
        shuffle: true,
        repeat: QueueRepeat.all,
      );
      order
        ..advance()
        ..advance();

      expect(order.upcomingIndex, isNull);
    });

    test('is null for an empty queue', () {
      expect(QueueOrder().upcomingIndex, isNull);
    });
  });
}

void _savingTests() {
  group('QueueOrder saving and restoring', () {
    test('a restored order carries on exactly where the saved one was', () {
      final saved = _started(length: 6, start: 2, shuffle: true, seed: 7)
        ..repeat = QueueRepeat.all;
      saved.advance();
      saved.advance();

      final restored = QueueOrder(random: Random(99));
      expect(restored.restore(saved.toJson(), length: 6), isTrue);

      expect(restored.currentIndex, saved.currentIndex);
      expect(restored.shuffle, isTrue);
      expect(restored.repeat, QueueRepeat.all);
      expect(restored.upcomingIndex, saved.upcomingIndex);
      // The whole remaining sequence matches, not just the next song.
      final fromSaved = <int?>[], fromRestored = <int?>[];
      for (var i = 0; i < 3; i++) {
        fromSaved.add(saved.advance());
        fromRestored.add(restored.advance());
      }
      expect(fromRestored, fromSaved);
    });

    test('the saved form is plain data that survives a round trip as text', () {
      final saved = _started(length: 4, start: 1, shuffle: true, seed: 3);
      final text = jsonEncode(saved.toJson());
      final restored = QueueOrder();
      expect(restored.restore(jsonDecode(text), length: 4), isTrue);
      expect(restored.currentIndex, saved.currentIndex);
    });

    test('an order that does not fit the queue is refused and changes nothing',
        () {
      final order = _started(length: 3, start: 1);
      final good = order.toJson();
      Map<String, Object?> with_(String key, Object? value) =>
          {...good, key: value};

      final refused = <Object?>[
        null,
        'text',
        {},
        with_('order', [0, 1]), // one song short
        with_('order', [0, 1, 1]), // a position twice
        with_('order', [0, 1, 3]), // a position outside the queue
        with_('order', [0, 1, -1]),
        with_('order', [0, 1, 'x']),
        with_('cursor', 3),
        with_('cursor', -1),
        with_('cursor', '1'),
        with_('shuffle', 'yes'),
        with_('repeat', 'forever'),
      ];
      for (final json in refused) {
        expect(order.restore(json, length: 3), isFalse, reason: '$json');
        expect(order.currentIndex, 1, reason: 'unchanged after $json');
      }
      expect(order.restore(good, length: 0), isFalse);
      expect(order.restore(good, length: 4), isFalse, reason: 'wrong length');
    });

    test('restoring into a used order replaces it completely', () {
      final target = _started(length: 5, start: 4, shuffle: true, seed: 2)
        ..repeat = QueueRepeat.one;
      final source = _started(length: 5, start: 1);
      expect(target.restore(source.toJson(), length: 5), isTrue);
      expect(target.shuffle, isFalse);
      expect(target.repeat, QueueRepeat.off);
      expect(target.currentIndex, 1);
    });
  });
}
