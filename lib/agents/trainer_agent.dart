// lib/agents/trainer_agent.dart

class TrainerAgent {
  /// System instruction for the conversational Trainer Agent.
  /// - Friendly, motivating coach vibe
  /// - Non-medical (no diagnosing)
  /// - If asked about symptoms or food toxicity, instructs user to use the right feature
  static String systemPrompt({
    required String dogName,
  }) {
    return '''
You are WoofFit Trainer, a friendly dog fitness coach.
Speak in a warm, motivating tone. Keep responses concise and actionable.

IMPORTANT RULES:
- Do NOT provide medical diagnosis or medical treatment advice.
- Do NOT provide food-toxicity judgments (that is the Meal agent).
- If the user asks about symptoms, injury, illness, rash, limping, vomiting, diarrhea, swelling, bleeding, or eye/ear issues: tell them you can help with safe activity adjustments but they should use the Vet Check feature for risk guidance.
- If the user asks about foods (grapes, onion, chocolate, etc.): tell them to use the Meal Safety feature.

OUTPUT FORMAT:
Return in TWO parts:
1) A short conversational message for the user.
2) A compact JSON block labeled TRAINER_JSON with the following keys:
{
  "agent": "trainer",
  "dog_name": "<dogName>",
  "insights": [ "<short insight 1>", "<short insight 2>" ],
  "today_plan": [
     { "title": "<activity>", "minutes": <int>, "intensity": "low|moderate|high", "notes": "<optional>" }
  ],
  "warnings": [ "<warning strings>" ],
  "questions": [ "<clarifying question strings>" ]
}

Make sure TRAINER_JSON is valid JSON.
Dog name: ${_escape(dogName)}.
''';
  }

  /// User prompt template. You can inject profile/activity context later.
  static String userPrompt({
    required String userMessage,
    Map<String, dynamic>? dogProfile,
    Map<String, dynamic>? recentActivity,
  }) {
    final profileStr = dogProfile == null ? "null" : dogProfile.toString();
    final activityStr = recentActivity == null ? "null" : recentActivity.toString();

    return '''
User message:
${userMessage.trim()}

Context (may be null):
dogProfile=$profileStr
recentActivity=$activityStr

TASK:
1) Respond as the WoofFit Trainer.
2) Provide 1-3 insights if possible.
3) Create a realistic plan for today (2-4 items).
4) If info is missing (breed/age/weight/goal), ask 1-2 clarifying questions in "questions".
''';
  }

  /// Minimal helper for safe string injection into system prompts.
  static String _escape(String s) {
    return s.replaceAll(r'$', r'\$');
  }

  /// Optional: quick local heuristics (used before calling the model).
  /// This can help you create "free" baseline plans or fill missing data later.
  static List<String> quickClarifyingQuestions({
    Map<String, dynamic>? dogProfile,
  }) {
    final questions = <String>[];

    if (dogProfile == null) {
      questions.add("What’s your dog’s breed (or mix), age, and weight?");
      questions.add("What’s the goal right now: weight loss, endurance, or just daily health?");
      return questions;
    }

    bool missing(String key) => !dogProfile.containsKey(key) || dogProfile[key] == null || dogProfile[key].toString().trim().isEmpty;

    if (missing('breed')) questions.add("What breed (or mix) is your dog?");
    if (missing('age_years')) questions.add("How old is your dog (in years)?");
    if (missing('weight_lbs')) questions.add("About how much does your dog weigh (in lbs)?");
    if (missing('goal')) questions.add("What’s the goal: weight loss, stamina, or general health?");

    return questions;
  }
}
