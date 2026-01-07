// meal_agent.dart

class MealAgent {
  /// Strict Meal Agent system prompt.
  /// Output MUST be valid JSON and follow the schema exactly.
  static String systemPrompt({
    required String dogName,
  }) {
    return '''
You are WoofFit Meal Safety, a strict dog nutrition assistant.

NON-NEGOTIABLE RULES:
- Output ONLY valid JSON. No extra commentary outside JSON.
- Do NOT diagnose medical conditions.
- If food quantity is missing, ask for it and set estimated_calories and recommended_portion_grams to null.
- Assume the described food is for ONE MEAL unless explicitly stated otherwise.
- If the food is toxic, prioritize safety guidance and "urgent_actions".
- If uncertain, do NOT guess. Ask a clarifying question.

JSON SCHEMA (MUST MATCH EXACTLY):
{
  "agent": "meal",
  "dog_name": "<string>",
  "meal_name": "<string>",
  "is_toxic": <true|false>,
  "toxic_foods_detected": [ "<string>", ... ],
  "toxicity_notes": [ "<string>", ... ],
  "estimated_calories": <number|null>,
  "recommended_portion_grams": <number|null>,
  "safer_alternatives": [ "<string>", ... ],
  "urgent_actions": [ "<string>", ... ],
  "questions": [ "<string>", ... ]
}

Dog name: ${_escape(dogName)}.
''';
  }

  /// User prompt template with optional dogProfile.
  /// Keep dogProfile lightweight and structured when you have it.
  static String userPrompt({
    required String userMessage,
    Map<String, dynamic>? dogProfile,
  }) {
    final profileStr = dogProfile == null ? "null" : dogProfile.toString();

    return '''
User message:
${userMessage.trim()}

Context:
dogProfile=$profileStr

TASK:
1) Identify the meal_name from the message.
2) Detect any toxic foods for dogs. If toxic: set is_toxic=true, fill toxic_foods_detected, toxicity_notes, urgent_actions.
3) If NOT toxic: provide estimated_calories and recommended_portion_grams IF quantities are provided. If not provided, set them to null and ask questions.
4) Provide 1-3 safer_alternatives when relevant.
5) Always return ONLY valid JSON following the schema.
''';
  }

  /// Basic local toxicity keyword list.
  /// This is NOT exhaustive, but covers high-risk common toxins.
  /// The LLM will also reason, but you can use this for routing/guardrails later.
  static const Map<String, String> toxicFoods = {
    "grape": "Grapes/raisins can cause kidney failure in dogs.",
    "grapes": "Grapes/raisins can cause kidney failure in dogs.",
    "raisin": "Grapes/raisins can cause kidney failure in dogs.",
    "raisins": "Grapes/raisins can cause kidney failure in dogs.",
    "onion": "Onions (and related) can damage red blood cells in dogs.",
    "garlic": "Garlic (and related) can damage red blood cells in dogs.",
    "chocolate": "Chocolate contains theobromine/caffeine and can be toxic to dogs.",
    "xylitol": "Xylitol (birch sugar) can cause dangerous low blood sugar and liver damage.",
    "alcohol": "Alcohol is toxic to dogs.",
    "macadamia": "Macadamia nuts can cause weakness, vomiting, and tremors.",
    "caffeine": "Caffeine can be toxic to dogs.",
    "avocado": "Avocado can cause GI upset; risk varies, avoid.",
    "cooked bones": "Cooked bones can splinter and cause choking or internal injury.",
    "grapefruit": "Citrus can cause GI upset; avoid large amounts.",
  };

  /// Heuristic: does the message include a quantity?
  /// Not perfect; just helps you decide whether to ask.
  static bool seemsToIncludeQuantity(String text) {
    final t = text.toLowerCase();
    final quantityHints = [
      'cup',
      'cups',
      'tbsp',
      'tsp',
      'tablespoon',
      'teaspoon',
      'grams',
      'g ',
      'kg',
      'oz',
      'ounce',
      'ounces',
      'lbs',
      'pound',
      'pieces',
      'slices',
      'half',
      'quarter',
      '1 ',
      '2 ',
      '3 ',
      '4 ',
    ];
    return quantityHints.any((h) => t.contains(h));
  }

  /// If you want a conservative default portion suggestion when missing data,
  /// we still prefer asking rather than guessing.
  static List<String> defaultQuestionsIfMissing() {
    return const [
      "How much did your dog eat (rough amount: grams, cups, pieces, or a photo)?",
      "How big is your dog (weight in lbs) and what is their age?",
    ];
  }

  static String _escape(String s) {
    return s.replaceAll(r'$', r'\$');
  }
}
