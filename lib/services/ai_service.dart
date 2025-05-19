class AiService {
  String enhanceDescription(String input) {
    final Map<String, String> replacements = {
      'sketchy': 'suspicious',
      'bad vibes': 'unsafe atmosphere',
      'creepy': 'concerning',
      'dark': 'poorly lit',
    };

    String result = input.toLowerCase();
    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result.isNotEmpty
        ? result[0].toUpperCase() + result.substring(1)
        : result;
  }
}