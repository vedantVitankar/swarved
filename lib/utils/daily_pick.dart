/// Whole days since 1970 for the calendar day of [when], so every moment of
/// one day gives the same number. Pass a local time (DateTime.now()).
int dayNumber(DateTime when) =>
    DateTime.utc(when.year, when.month, when.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// The item [seed] points at, wrapping around the list, or null when the
/// list is empty. The same seed always gives the same item.
T? pickBySeed<T>(List<T> items, int seed) =>
    items.isEmpty ? null : items[seed % items.length];

/// A steady number made from [text]: the same text always gives the same
/// number, different texts usually give different ones.
int seedFromText(String text) =>
    text.codeUnits.fold(0, (sum, unit) => (sum * 31 + unit) & 0x7fffffff);
