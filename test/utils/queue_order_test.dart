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
}
