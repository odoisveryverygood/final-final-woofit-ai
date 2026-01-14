// lib/agents/species.dart
// AGENT INTERFACE LOCKED
// Changes require:
// - Test update
// - Version bump
// - Analytics review

class Species {
  /// Canonical supported list (product decision).
  static const List<String> supported = [
    "Guinea pig",
    "Rabbit",
    "Rat",
    "Mouse",
    "Hamster",
    "Gerbil",
    "Ferret",
  ];

  /// Normalize common inputs (case/synonyms) into one of the canonical strings.
  /// If unknown, returns fallback (default: "Guinea pig").
  static String normalize(String input, {String fallback = "Guinea pig"}) {
    final t = input.trim().toLowerCase();
    if (t.isEmpty) return fallback;

    if (t.contains("guinea") || t.contains("cavy")) return "Guinea pig";
    if (t.contains("rabbit") || t.contains("bunny")) return "Rabbit";
    if (t == "rat" || t.contains(" rat")) return "Rat";
    if (t == "mouse" || t.contains(" mouse") || t.contains("mice")) return "Mouse";
    if (t.contains("hamster")) return "Hamster";
    if (t.contains("gerbil")) return "Gerbil";
    if (t.contains("ferret")) return "Ferret";

    // If it's already one of the canonical values (but maybe different casing)
    for (final s in supported) {
      if (s.toLowerCase() == t) return s;
    }

    return fallback;
  }

  static bool isSupported(String input) {
    final s = normalize(input, fallback: "");
    return supported.contains(s);
  }
}
