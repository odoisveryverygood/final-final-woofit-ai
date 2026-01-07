// vet_agent.dart

class VetAgent {
  /// Strict Vet Agent system prompt.
  /// Output MUST be valid JSON and follow the schema exactly.
  static String systemPrompt({
    required String dogName,
  }) {
    return '''
You are WoofFit Vet Check, a strict first-layer triage assistant for dog health concerns.

NON-NEGOTIABLE RULES:
- You are NOT a veterinarian and you do NOT provide a medical diagnosis.
- You do NOT prescribe medications or dosages.
- Output ONLY valid JSON. No extra text outside JSON.
- If the situation could be urgent, set risk_level="urgent" and clearly list when_to_see_vet actions.
- If information is missing, ask targeted questions.
- Be calm, practical, and safety-first.

RISK LEVEL DEFINITIONS:
- "low": mild issue, monitoring and basic care guidance is reasonable
- "moderate": concerning but not clearly emergent; recommend vet visit if not improving soon
- "urgent": potential emergency or serious issue; recommend contacting a vet/ER now

JSON SCHEMA (MUST MATCH EXACTLY):
{
  "agent": "vet",
  "dog_name": "<string>",
  "risk_level": "low|moderate|urgent",
  "possible_causes": [ "<string>", ... ],
  "recommended_actions": [ "<string>", ... ],
  "when_to_see_vet": [ "<string>", ... ],
  "red_flags": [ "<string>", ... ],
  "questions": [ "<string>", ... ],
  "disclaimer": "<string>"
}

Dog name: ${_escape(dogName)}.
''';
  }

  /// User prompt template with optional context.
  /// recentActivity can help: sudden drop, limping after exercise, etc.
  static String userPrompt({
    required String userMessage,
    Map<String, dynamic>? dogProfile,
    Map<String, dynamic>? recentActivity,
    String? visionSummary, // optional: text summary from image analysis
  }) {
    final profileStr = dogProfile == null ? "null" : dogProfile.toString();
    final activityStr = recentActivity == null ? "null" : recentActivity.toString();
    final visionStr = visionSummary == null ? "null" : visionSummary;

    return '''
User message:
${userMessage.trim()}

Context:
dogProfile=$profileStr
recentActivity=$activityStr
visionSummary=$visionStr

TASK:
1) Choose risk_level (low/moderate/urgent) based on symptoms described.
2) Provide possible_causes as non-diagnostic possibilities (no definitive claims).
3) Provide recommended_actions that are safe and conservative (no meds/dosage).
4) Provide when_to_see_vet and red_flags clearly.
5) Ask questions only if needed to decide risk_level or next steps.
6) Return ONLY valid JSON following the schema.
''';
  }

  /// Simple local rule hints (optional). This is not the final authority,
  /// but helps you add deterministic guardrails later.
  static const List<String> urgentKeywords = [
    'difficulty breathing',
    'can’t breathe',
    'blue gums',
    'collapse',
    'collapsed',
    'seizure',
    'seizing',
    'unconscious',
    'won’t wake',
    'bloated',
    'swollen belly',
    'hit by car',
    'poison',
    'toxin',
    'choking',
    'profuse bleeding',
    'blood everywhere',
    'vomiting blood',
    'bloody vomit',
    'black tarry stool',
    'cannot stand',
    'severe pain',
    'severe lethargy',
    'pale gums',
  ];

  static const List<String> moderateKeywords = [
    'limp',
    'limping',
    'vomit',
    'vomiting',
    'diarrhea',
    'diarrhoea',
    'not eating',
    'loss of appetite',
    'fever',
    'shivering',
    'itch',
    'itching',
    'rash',
    'swelling',
    'ear pain',
    'eye discharge',
    'cough',
    'pain',
    'lump',
  ];

  static bool containsAny(String text, List<String> keywords) {
    final t = text.toLowerCase();
    return keywords.any((k) => t.contains(k));
  }

  /// Deterministic fallback risk suggestion (optional usage):
  /// - If urgent keywords present => urgent
  /// - else if moderate keywords present => moderate
  /// - else => low
  static String quickRiskHeuristic(String userMessage) {
    if (containsAny(userMessage, urgentKeywords)) return "urgent";
    if (containsAny(userMessage, moderateKeywords)) return "moderate";
    return "low";
  }

  static String _escape(String s) {
    return s.replaceAll(r'$', r'\$');
  }
}
