/// Plain interface labels: tabs, chips and buttons.
/// The app's personal voice lives in words.dart instead.
class Labels {
  Labels._();

  // Bottom navigation.
  static const navHome = 'Home';
  static const navSearch = 'Search';
  static const navLibrary = 'Library';
  static const navUs = 'Us';

  // Filter chips.
  static const chipAll = 'All';
  static const chipFolders = 'Folders';
  static const chipMixes = 'Mixes';
  static const chipNotes = 'Notes';

  // Screen titles and buttons.
  static const libraryTitle = 'Your library';
  static const chooseFolder = 'Choose folder';
  static const openSettings = 'Open settings';

  static String playingFrom(String folder) => 'Playing from $folder';

  static String songCount(int count) => count == 1 ? '1 song' : '$count songs';
}
