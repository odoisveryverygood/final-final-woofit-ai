// lib/agents/agent_router.dart
// AGENT INTERFACE LOCKED
// Changes require:
// - Test update
// - Version bump
// - Analytics review

enum AgentType { trainer, meal, vet }

class AgentRouter {
  // -------------------------
  // Public API
  // -------------------------

  /// Decide which agent should handle the message.
  /// Safety-first: VET overrides everything when red flags are present.
  ///
  /// Optional: pass species to boost correct routing (especially ferret diet questions).
  static AgentType route(String text, {String? species}) {
    final t = _norm(text);

    // 1) Hard safety override -> VET (must win even if user tries to force MEAL)
    if (_hasVetRedFlags(t)) return AgentType.vet;

    // 2) User explicitly requests an agent (only after safety)
    final forced = _forcedAgent(t);
    if (forced != null) return forced;

    // 3) Score-based intent routing (MEAL vs TRAINER)
    final s = (species ?? "").toLowerCase();
    final isFerret = s.contains("ferret");

    final mealScore = _mealIntentScore(t, isFerret: isFerret);
    final trainerScore = _trainerIntentScore(t);

    // If message strongly looks like meal/nutrition and not clearly routine/enrichment -> MEAL
    // Otherwise default to TRAINER.
    if (mealScore >= trainerScore + 2) return AgentType.meal;

    return AgentType.trainer;
  }

  /// Secondary urgency signal for UI highlighting (conservative).
  static bool isUrgent(String text) {
    final t = _norm(text);

    // Immediate urgent patterns
    if (_hasUrgentVetSignals(t)) return true;

    // Combo urgency: not eating + pain/poop signals
    final notEating = _anyContains(t, const [
      "not eating",
      "won't eat",
      "wont eat",
      "refusing food",
      "stopped eating",
      "not drinking",
      "won't drink",
      "wont drink",
    ]);

    final poopOrPain = _anyContains(t, const [
      "not pooping",
      "no poop",
      "no droppings",
      "tiny poop",
      "small poop",
      "hunched",
      "teeth grinding",
      "tooth grinding",
      "bloated",
      "bloat",
      "distended",
      "hard belly",
      "belly hard",
      "swollen belly",
      "crying",
      "screaming",
    ]);

    if (notEating && poopOrPain) return true;

    return false;
  }

  // -------------------------
  // Forced agent (explicit intent)
  // -------------------------

  static AgentType? _forcedAgent(String t) {
    // Vet forced
    if (_anyContains(t, const [
      "use vet",
      "vet agent",
      "triage this",
      "triage",
      "is this an emergency",
      "emergency?",
      "should i go to vet",
      "should i take to vet",
      "needs a vet",
      "urgent vet",
    ])) {
      return AgentType.vet;
    }

    // Meal forced
    if (_anyContains(t, const [
      "use meal",
      "meal agent",
      "nutrition agent",
      "diet plan",
      "feeding plan",
      "what should i feed",
      "how much should i feed",
      "portion plan",
    ])) {
      return AgentType.meal;
    }

    // Trainer forced
    if (_anyContains(t, const [
      "use trainer",
      "trainer agent",
      "care routine",
      "routine plan",
      "enrichment plan",
      "training plan",
      "daily routine",
      "weekly routine",
    ])) {
      return AgentType.trainer;
    }

    return null;
  }

  // -------------------------
  // Safety detection
  // -------------------------

  static bool _hasVetRedFlags(String t) {
    // High-signal red flags. If these appear, always route to VET.

    const core = [
      // Appetite / GI
      "not eating",
      "won't eat",
      "wont eat",
      "refusing food",
      "stopped eating",
      "not drinking",
      "won't drink",
      "wont drink",
      "not pooping",
      "no poop",
      "no droppings",
      "tiny poop",
      "small poop",
      "diarrhea",
      "watery poop",
      "runny poop",
      "soft stool",
      "constipation",
      "bloated",
      "bloat",
      "distended",
      "swollen belly",
      "hard belly",
      "belly hard",
      "hunched",
      "teeth grinding",
      "tooth grinding",
      "gi stasis",
      "stasis",

      // Breathing / collapse / neuro
      "trouble breathing",
      "can't breathe",
      "cant breathe",
      "open mouth breathing",
      "open-mouth breathing",
      "gasping",
      "wheezing",
      "collapse",
      "collapsed",
      "faint",
      "fainted",
      "seizure",
      "seizing",
      "tremor",
      "tremors",
      "unresponsive",
      "head tilt",
      "circling",
      "loss of balance",

      // Pain / injury
      "limp",
      "limping",
      "pain",
      "hurt",
      "injury",
      "won't move",
      "wont move",
      "dragging",
      "fracture",
      "swelling",

      // Dental
      "drooling",
      "slobber",
      "wet chin",
      "malocclusion",
      "overgrown incisors",
      "dropping food",
      "can't chew",
      "cant chew",
      "choking",
      "gagging",

      // Skin / infection / discharge
      "mites",
      "lice",
      "bald spot",
      "hair loss",
      "itching",
      "scratching",
      "scabs",
      "crusty",
      "rash",
      "wound",
      "abscess",
      "eye discharge",
      "crusty eye",
      "red eye",
      "nose discharge",
      "snot",
      "sneezing",

      // Blood / urinary
      "blood",
      "bleeding",
      "bloody",
      "blood in urine",
      "bloody urine",
      "can't pee",
      "cant pee",
      "not peeing",
      "painful urination",

      // Toxins
      "poison",
      "toxin",
      "toxic",
      "ingested",
      "bleach",
      "cleaner",
      "essential oil",
      "insecticide",
      "pesticide",
      "human medicine",
      "ibuprofen",
      "acetaminophen",
      "tylenol",
      "chocolate",
      "xylitol",
    ];

    const speciesBias = [
      // Hamster
      "wet tail",

      // Ferret blockage patterns
      "blockage",
      "foreign object",
      "ate foam",
      "ate rubber",
      "ate plastic",
      "string in mouth",
      "pawing at mouth",
      "retching",
      "dry heaving",
      "vomiting",
      "threw up",
    ];

    return _anyContains(t, core) || _anyContains(t, speciesBias);
  }

  static bool _hasUrgentVetSignals(String t) {
    const urgent = [
      "unresponsive",
      "collapse",
      "collapsed",
      "seizure",
      "seizing",
      "can't breathe",
      "cant breathe",
      "open mouth breathing",
      "open-mouth breathing",
      "gasping",
      "uncontrolled bleeding",
      "blood in urine",
      "bloody urine",
      "gi stasis",
      "stasis",
      "wet tail",
      "poison",
      "toxin",
      "toxic",
      "bleach",
      "essential oil",
      "ibuprofen",
      "acetaminophen",
      "tylenol",
      "xylitol",
    ];
    return _anyContains(t, urgent);
  }

  // -------------------------
  // Intent scoring (Meal vs Trainer)
  // -------------------------

  static int _mealIntentScore(String t, {required bool isFerret}) {
    int score = 0;

    // Strong “asking if safe to eat / feed” patterns
    const strongPatterns = [
      "can my",
      "can i give",
      "is it safe",
      "safe to eat",
      "safe for my",
      "what should i feed",
      "what do i feed",
      "how much should i feed",
      "how much do i feed",
      "portion",
      "portions",
      "grams",
      "meal plan",
      "feeding plan",
      "nutrition",
      "diet plan",
      "diet",
      "food",
      "feed",
      "feeding",
      "treat",
      "treats",
    ];

    // High-signal food category words
    const foodCategory = [
      "fruit",
      "fruits",
      "vegetable",
      "vegetables",
      "veggie",
      "veggies",
      "greens",
      "salad",
      "berry",
      "berries",
      "seed",
      "seeds",
      "nuts",
      "nut",
      "grain",
      "grains",
      "bread",
      "rice",
      "pasta",
      "cereal",
      "milk",
      "cheese",
      "yogurt",
      "dairy",
      "chicken",
      "beef",
      "turkey",
      "fish",
      "egg",
      "meat",
      "kibble",
      "ferret food",
      "cat food",
      "dog food",
      "pellets",
      "hay",
      "timothy",
      "orchard",
      "alfalfa",
      "water",
    ];

    // Big produce + common foods lexicon (helps “can my pet eat X?” route to MEAL)
    const produce = [
      // Fruits
      "strawberry", "strawberries", "banana", "apple", "apples", "pear", "pears",
      "grape", "grapes", "raisin", "raisins", "blueberry", "blueberries",
      "raspberry", "raspberries", "blackberry", "blackberries",
      "cranberry", "cranberries", "cherry", "cherries", "watermelon",
      "cantaloupe", "honeydew", "melon", "mango", "papaya", "pineapple",
      "orange", "oranges", "tangerine", "clementine", "lemon", "lime", "kiwi",
      "peach", "peaches", "nectarine", "plum", "plums", "apricot", "apricots",
      "pomegranate", "fig", "figs", "date", "dates", "coconut", "avocado",
      "tomato", "tomatoes",

      // Veggies / greens
      "carrot", "carrots", "celery", "cucumber", "cucumbers", "lettuce",
      "romaine", "iceberg", "spinach", "kale", "arugula", "cabbage",
      "bok choy", "choy", "broccoli", "cauliflower", "zucchini", "squash",
      "pumpkin", "sweet potato", "potato", "potatoes", "yam", "yams",
      "bell pepper", "pepper", "peppers", "onion", "onions", "garlic",
      "corn", "peas", "bean", "beans", "green beans", "lentils",
      "chickpeas",

      // Herbs
      "cilantro", "parsley", "basil", "mint", "oregano", "thyme", "rosemary", "dill",

      // Common “human snacks”
      "bread", "cracker", "crackers", "chip", "chips", "cookie", "cookies",
      "cake", "candy", "chocolate", "honey", "peanut butter",
      "almond", "walnut", "cashew", "peanut", "popcorn", "granola",
      "oat", "oats", "cereal", "rice", "pasta", "noodles",
    ];

    for (final k in strongPatterns) {
      if (t.contains(k)) score += 2;
    }
    for (final k in foodCategory) {
      if (t.contains(k)) score += 2;
    }
    for (final k in produce) {
      if (t.contains(k)) score += 3;
    }

    // If the user is clearly asking for routine/enrichment/behavior, downweight meal
    if (_looksLikeRoutineRequest(t)) score -= 3;

    // If they explicitly ask for food safety and also mention a food item, boost heavily
    final foodQuestion = _anyContains(t, const [
      "can my",
      "can i give",
      "is it safe",
      "safe to eat",
      "safe for my",
    ]);
    if (foodQuestion && (_anyContains(t, foodCategory) || _anyContains(t, produce))) {
      score += 4;
    }

    // Ferret-specific: plant food questions should reliably go MEAL
    if (isFerret &&
        (_anyContains(t, produce) ||
            _anyContains(t, const ["fruit", "vegetable", "veggies", "greens"]))) {
      score += 4;
    }

    return score;
  }

  static int _trainerIntentScore(String t) {
    int score = 0;

    const strong = [
      "routine",
      "daily routine",
      "weekly routine",
      "schedule",
      "plan",
      "7-day",
      "7 day",
      "enrichment",
      "bonding",
      "stress",
      "habitat",
      "cage setup",
      "setup",
      "socialize",
      "taming",
      "handle",
      "handling",
      "playtime",
      "exercise",
      "training",
      "activities",
      "bored",
      "boredom",
      "chewing",
      "biting",
      "aggressive",
      "behavior",
      "zoomies",
      "litter",
      "cleaning",
      "deep clean",
      "hide",
      "hides",
      "tunnel",
      "tunnels",
      "toy",
      "toys",
    ];

    for (final k in strong) {
      if (t.contains(k)) score += 2;
    }

    // If short and vague, default trainer slightly
    if (t.split(" ").length <= 6) score += 1;

    // If explicitly asking food/portions, reduce trainer
    if (_anyContains(t, const [
      "how much",
      "what should i feed",
      "diet plan",
      "feeding plan",
      "safe to eat",
      "can i give",
      "can my",
    ])) {
      score -= 3;
    }

    return score;
  }

  static bool _looksLikeRoutineRequest(String t) {
    return _anyContains(t, const [
      "routine",
      "weekly",
      "daily",
      "enrichment",
      "bonding",
      "stress",
      "habitat",
      "exercise",
      "activities",
      "plan",
      "schedule",
      "training",
      "behavior",
      "cage",
      "setup",
      "cleaning",
    ]);
  }

  // -------------------------
  // Tiny text utils
  // -------------------------

  static String _norm(String s) {
    final lowered = s.toLowerCase().trim();
    return lowered.replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _anyContains(String t, List<String> keywords) {
    for (final k in keywords) {
      if (t.contains(k)) return true;
    }
    return false;
  }
}
