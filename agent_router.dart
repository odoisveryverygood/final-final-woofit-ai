// lib/agents/agent_router.dart

enum AgentType {
  trainer,
  meal,
  vet,
}

class AgentRouter {
  static AgentType route({
    required String message,
    bool hasImage = false,
  }) {
    final text = message.toLowerCase();

    // 🔴 Vet keywords (highest priority)
    const vetKeywords = [
      'rash',
      'limp',
      'vomit',
      'diarrhea',
      'poop',
      'bleeding',
      'swelling',
      'eye',
      'ear',
      'infection',
      'pain',
      'injury',
      'sick',
      'itch',
      'itching',
    ];

    // 🟡 Meal keywords
    const mealKeywords = [
      'food',
      'eat',
      'eating',
      'calories',
      'treat',
      'snack',
      'diet',
      'nutrition',
      'portion',
      'chicken',
      'beef',
      'rice',
      'grapes',
      'onion',
      'chocolate',
    ];

    // 🟢 Trainer keywords
    const trainerKeywords = [
      'walk',
      'run',
      'exercise',
      'fitness',
      'workout',
      'steps',
      'activity',
      'calorie burn',
      'training',
    ];

    bool containsAny(List<String> keywords) {
      return keywords.any((k) => text.contains(k));
    }

    // 🔴 Image + symptom → Vet
    if (hasImage && containsAny(vetKeywords)) {
      return AgentType.vet;
    }

    // 🟡 Image + food → Meal
    if (hasImage && containsAny(mealKeywords)) {
      return AgentType.meal;
    }

    // 🔴 Vet text only
    if (containsAny(vetKeywords)) {
      return AgentType.vet;
    }

    // 🟡 Meal text only
    if (containsAny(mealKeywords)) {
      return AgentType.meal;
    }

    // 🟢 Trainer
    if (containsAny(trainerKeywords)) {
      return AgentType.trainer;
    }

    // ❓ Fallback
    return AgentType.trainer;
  }
}
