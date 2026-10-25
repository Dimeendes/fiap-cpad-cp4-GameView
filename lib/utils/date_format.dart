const _months = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

/// Data curta do diário, ex.: "24 out 2025". Vazio para datas desconhecidas.
String formatLoggedDate(int? millis) {
  if (millis == null || millis <= 0) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
