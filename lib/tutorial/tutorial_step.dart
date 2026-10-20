import '../content/words.dart';

/// The stops on the tour of Home, in order. Each lights up one part of the
/// screen, with a few words about it. If the song from the welcome is still
/// on, it plays under the tour.
enum TutorialStep {
  folders,
  chips,

  /// The mini player, which only exists once a song is on. The song is
  /// started in the welcome, so this stop is only there if she did.
  player,
  search,
  library,

  /// Taking her to the Library tab to pick the folder her songs live in.
  /// Only there when she has no folder yet.
  addFolder,
  us;

  /// Steps that make no sense without a song on.
  bool get needsSong => this == player;

  /// Steps where she does something herself, so the lit part takes her tap
  /// while everything else stays blocked.
  bool get isInteractive => this == addFolder;
}

/// The steps of the tour. With no song on there is no mini player to point
/// at, so that stop is left out. Pointing at the folder button only makes
/// sense when she still has to choose a folder.
List<TutorialStep> tutorialSteps({
  required bool withSong,
  bool addFolder = false,
}) =>
    [
      for (final step in TutorialStep.values)
        if ((withSong || !step.needsSong) &&
            (addFolder || step != TutorialStep.addFolder))
          step,
    ];

/// What to say at [step]: his own caption if he wrote one, otherwise the
/// default. With no folders yet, the folders step says where they will be.
String tutorialCaption(
  TutorialStep step, {
  Map<String, String> own = const {},
  bool noFolders = false,
}) {
  final written = own[step.name];
  if (written != null && written.trim().isNotEmpty) return written;
  return switch (step) {
    TutorialStep.folders =>
      noFolders ? Words.tutorialFoldersEmpty : Words.tutorialFolders,
    TutorialStep.chips => Words.tutorialChips,
    TutorialStep.player => Words.tutorialPlayer,
    TutorialStep.search => Words.tutorialSearch,
    TutorialStep.library => Words.tutorialLibrary,
    TutorialStep.addFolder => Words.tutorialAddFolder,
    TutorialStep.us => Words.tutorialUs,
  };
}
