import 'package:flutter_test/flutter_test.dart';
import 'package:swarved/utils/membership_draft.dart';

void main() {
  group('MembershipDraft', () {
    test('starts with the playlists the song is already in', () {
      final draft = MembershipDraft({'liked', 'pl_a'});

      expect(draft.isChosen('liked'), isTrue);
      expect(draft.isChosen('pl_a'), isTrue);
      expect(draft.isChosen('pl_b'), isFalse);
      expect(draft.playlistIds, {'liked', 'pl_a'});
      expect(draft.hasChanges, isFalse);
    });

    test('toggle clears a tick and sets it again', () {
      final draft = MembershipDraft({'pl_a'});

      draft.toggle('pl_a');
      expect(draft.isChosen('pl_a'), isFalse);

      draft.toggle('pl_a');
      expect(draft.isChosen('pl_a'), isTrue);
    });

    test('a tick cleared and set again is no change at all', () {
      final draft = MembershipDraft({'pl_a', 'pl_b'});

      draft.toggle('pl_a');
      expect(draft.hasChanges, isTrue);
      draft.toggle('pl_a');

      expect(draft.hasChanges, isFalse);
      expect(draft.playlistIds, {'pl_a', 'pl_b'});
    });

    test('ticking a new playlist is a change, and so is clearing one', () {
      final ticked = MembershipDraft({'pl_a'})..toggle('pl_b');
      final cleared = MembershipDraft({'pl_a'})..toggle('pl_a');

      expect(ticked.hasChanges, isTrue);
      expect(cleared.hasChanges, isTrue);
    });

    test('playlistIds is a copy', () {
      final draft = MembershipDraft({'pl_a'});

      draft.playlistIds.add('pl_z');

      expect(draft.isChosen('pl_z'), isFalse);
    });

    test('does not change the set it was given', () {
      final given = {'pl_a'};
      final draft = MembershipDraft(given);

      draft.toggle('pl_a');

      expect(given, {'pl_a'});
    });
  });

  group('MembershipDraft, new playlists', () {
    test('a new name is cleaned and starts ticked', () {
      final draft = MembershipDraft({});

      expect(draft.addNew('  Late   night '), isTrue);

      expect(draft.staged.single.name, 'Late night');
      expect(draft.staged.single.chosen, isTrue);
      expect(draft.newNames, ['Late night']);
      expect(draft.hasChanges, isTrue);
    });

    test('an empty name is refused', () {
      final draft = MembershipDraft({});

      expect(draft.addNew('   '), isFalse);
      expect(draft.staged, isEmpty);
      expect(draft.hasChanges, isFalse);
    });

    test('they are listed newest first but made oldest first', () {
      final draft = MembershipDraft({})
        ..addNew('First')
        ..addNew('Second');

      expect([for (final s in draft.staged) s.name], ['Second', 'First']);
      expect(draft.newNames, ['First', 'Second']);
    });

    test('the same name twice is one playlist, ticked again', () {
      final draft = MembershipDraft({})..addNew('Road trip');
      draft.toggleStaged(draft.staged.single);
      expect(draft.newNames, isEmpty);

      draft.addNew('  road TRIP ');

      expect(draft.staged, hasLength(1));
      expect(draft.newNames, ['Road trip']);
    });

    test('one that is cleared is not made, and is no change', () {
      final draft = MembershipDraft({})..addNew('Maybe');

      draft.toggleStaged(draft.staged.single);

      expect(draft.newNames, isEmpty);
      expect(draft.hasChanges, isFalse);
    });
  });
}
