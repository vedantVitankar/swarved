const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "14 February 2025".
String longDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
