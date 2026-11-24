import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/queue_order.dart';

QueueOrder _started({
  required int length,
  int start = 0,
  bool shuffle = false,
  int seed = 1,
}) {
  final order = QueueOrder(random: Random(seed))..setShuffle(shuffle);
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
  group('this loop', () {
    test('lists the song playing and the ones still to come', () {
      final order = _started(length: 5, start: 1);

      expect(order.thisRound, [1, 2, 3, 4]);
    });

    test('follows the shuffled order', () {
      final order = _started(length: 4, shuffle: true, seed: 3);
      final expected = _walk(_started(length: 4, shuffle: true, seed: 3));

      expect(order.thisRound, expected);
    });

    test('shrinks as songs are played', () {
      final order = _started(length: 3);
      order.advance();

      expect(order.thisRound, [1, 2]);
    });

    test('is empty when nothing is queued', () {
      expect(QueueOrder().thisRound, isEmpty);
    });
  });

  group('dragging a song to come', () {
    test('moves it down, counting places after the song playing', () {
      final order = _started(length: 5); // playing 0; to come 1 2 3 4

      expect(order.moveUpcoming(0, 2), isTrue);

      expect(order.thisRound, [0, 2, 3, 1, 4]);
    });

    test('moves it up', () {
      final order = _started(length: 5);

      expect(order.moveUpcoming(3, 0), isTrue);

      expect(order.thisRound, [0, 4, 1, 2, 3]);
    });

    test('the song playing and the played songs stay where they are', () {
      final order = _started(length: 5, start: 2); // 0 and 1 come before it

      order.moveUpcoming(0, 1);

      expect(order.currentIndex, 2);
      expect(order.thisRound, [2, 4, 3]);
      expect(order.hasPrevious, isTrue);
    });

    test('playing goes on in the new order', () {
      final order = _started(length: 4);

      order.moveUpcoming(2, 0); // to come 1 2 3 -> 3 1 2

      expect(_walk(order), [0, 3, 1, 2]);
    });

    test('works with shuffle on and keeps the shuffled rest', () {
      final order = _started(length: 5, shuffle: true, seed: 5);
      final before = order.thisRound;

      order.moveUpcoming(0, 3);

      final upcoming = before.sublist(1);
      upcoming.insert(3, upcoming.removeAt(0));
      expect(order.thisRound, [before.first, ...upcoming]);
    });

    test('refuses a move that goes nowhere or off the list', () {
      final order = _started(length: 4);

      expect(order.moveUpcoming(1, 1), isFalse);
      expect(order.moveUpcoming(-1, 0), isFalse);
      expect(order.moveUpcoming(0, 3), isFalse); // only 3 songs to come: 0..2
      expect(order.moveUpcoming(3, 0), isFalse);
      expect(order.thisRound, [0, 1, 2, 3]);
    });

    test('with nothing queued there is nothing to move', () {
      expect(QueueOrder().moveUpcoming(0, 1), isFalse);
    });
  });

  group('her order is kept', () {
    test('a song added later goes last, and the order stays hers', () {
      final order = _started(length: 4);
      order.moveUpcoming(2, 0); // 0, 3, 1, 2

      order.remap(oldToNew: [0, 1, 2, 3], newLength: 5, added: [4]);

      expect(order.thisRound, [0, 3, 1, 2, 4]);
    });

    test('a song taken out leaves the rest in her order', () {
      final order = _started(length: 4);
      order.moveUpcoming(2, 0); // 0, 3, 1, 2

      order.remap(oldToNew: [0, null, 1, 2], newLength: 3, added: []);

      expect(order.thisRound, [0, 2, 1]);
    });

    test('is kept across a restart', () {
      final order = _started(length: 4);
      order.moveUpcoming(2, 0);
      final saved = order.toJson();

      final back = QueueOrder()..repeat = QueueRepeat.off;
      expect(back.restore(saved, length: 4), isTrue);
      back.remap(oldToNew: [0, 1, 2, 3], newLength: 5, added: [4]);

      expect(back.thisRound, [0, 3, 1, 2, 4]);
    });

    test('turning shuffle on and off puts the plain order back', () {
      final order = _started(length: 4);
      order.moveUpcoming(2, 0);

      order.setShuffle(true);
      order.setShuffle(false);

      expect(order.thisRound, [0, 1, 2, 3]);
    });

    test('a new queue starts in plain order again', () {
      final order = _started(length: 4);
      order.moveUpcoming(2, 0);

      order.start(length: 3, startIndex: 0);

      expect(order.thisRound, [0, 1, 2]);
    });

    test('with repeat all the next round plays in her order', () {
      final order = _started(length: 3);
      order.repeat = QueueRepeat.all;
      order.moveUpcoming(1, 0); // 0, 2, 1

      expect(_walkOneRound(order), [0, 2, 1]);
      expect(order.advance(), 0); // round again, same order
      expect(order.advance(), 2);
    });
  });
}

List<int> _walkOneRound(QueueOrder order) {
  final songs = <int>[order.currentIndex!];
  for (var i = 0; i < 2; i++) {
    songs.add(order.advance()!);
  }
  return songs;
}
