class CoachMemory {
  int tooHard = 0;
  int tooEasy = 0;
  int skipped = 0;
  int pain = 0;
  int success = 0;

  String lastNote = "";

  CoachMemory();

  Map<String, dynamic> toJson() => {
        "tooHard": tooHard,
        "tooEasy": tooEasy,
        "skipped": skipped,
        "pain": pain,
        "success": success,
        "lastNote": lastNote,
      };

  static CoachMemory fromJson(Map<String, dynamic> j) {
    final m = CoachMemory();
    m.tooHard = j["tooHard"] ?? 0;
    m.tooEasy = j["tooEasy"] ?? 0;
    m.skipped = j["skipped"] ?? 0;
    m.pain = j["pain"] ?? 0;
    m.success = j["success"] ?? 0;
    m.lastNote = j["lastNote"] ?? "";
    return m;
  }

  bool get hasSignal =>
      tooHard + tooEasy + skipped + pain + success > 0;

  String summarize() {
    final lines = <String>[];

    if (tooHard > 0) lines.add("Previous plans felt too intense.");
    if (tooEasy > 0) lines.add("Previous plans felt too easy.");
    if (skipped > 0) lines.add("Some planned days were skipped.");
    if (pain > 0) lines.add("Pet showed pain or stiffness.");
    if (success > 0) lines.add("Some plans worked well.");

    if (lastNote.isNotEmpty) {
      lines.add("Most recent feedback: \"$lastNote\"");
    }

    return lines.join(" ");
  }
}
