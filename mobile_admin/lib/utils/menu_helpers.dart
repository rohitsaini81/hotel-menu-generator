String formatPrice(int value, String currency) {
  const symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
  };
  final symbol = symbols[currency] ?? r'$';
  return '$symbol$value';
}

String slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)+'), '');
}

List<String> splitList(String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}
