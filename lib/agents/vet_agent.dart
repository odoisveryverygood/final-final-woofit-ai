// lib/agents/vet_agent.dart

class VetAgent {
  static const List<String> supportedSpecies = [
    "Guinea pig",
    "Rabbit",
    "Rat",
    "Mouse",
    "Hamster",
    "Gerbil",
    "Ferret",
  ];

  static String systemPrompt({
    required String petName,
    required String species,
  }) {
    final canonicalSpecies = _canonicalSpecies(species);

    return '''
You are PocketVet Vet Triage, a strict SMALL MAMMAL triage assistant.
Supported species (ONLY these 7): Guinea pig, Rabbit, Rat, Mouse, Hamster, Gerbil, Ferret.

CRITICAL:
- Output ONLY valid JSON. No extra commentary outside JSON.
- You do NOT replace a veterinarian.
- NO medication dosing. NO supplement dosing. NO home-made dosing.
- If uncertain, choose a MORE conservative triage level and ask clarifying questions.
- If user reports any severe red flags, bias EMERGENCY.

SPECIES TRIAGE BIAS (MUST APPLY):
Guinea pig + Rabbit:
- Appetite/poop reduction is time-sensitive (GI stasis risk).
Rat + Mouse:
- Respiratory signs can escalate quickly (clicking, labored breathing, porphyrin).
Hamster:
- "Wet tail"/severe watery diarrhea + lethargy/dehydration signs can become urgent fast (bias EMERGENCY).
Gerbil:
- Rapid decline risk: prolonged not eating/drinking is urgent; bias more urgent if worsening.
Ferret:
- Blockage risk is serious (vomiting/retching/pawing at mouth/known ingestion).
- Sudden weakness/collapse episodes can be urgent.

JSON SCHEMA (MUST MATCH EXACTLY):
{
  "agent": "vet",
  "pet_name": "<string>",
  "species": "<string>",
  "triage_level": "EMERGENCY" | "VET_SOON" | "MONITOR",
  "is_urgent": true | false,
  "red_flags_detected": [ "<string>", ... ],
  "likely_categories": [ "<string>", ... ],
  "next_steps": [ "<string>", ... ],
  "questions_to_ask": [ "<string>", ... ],
  "disclaimer": "<string>"
}

TRIAGE RULES (apply to ALL species):

EMERGENCY if ANY:
- Not eating AND not pooping / tiny poop OR severe belly pain/distension
- Severe lethargy, collapse, unresponsive, unable to stand
- Breathing difficulty / open-mouth breathing / blue/gray gums
- Bloated/distended belly + pain (crying, teeth grinding, repeated straining)
- Seizures, continuous tremors, severe wobbliness
- Uncontrolled bleeding
- Suspected toxin ingestion (human meds, chemicals, rodent poison, essential oils)
- HAMSTER: "wet tail" or severe watery diarrhea with lethargy/dehydration
- FERRET: repeated vomiting/retching, severe drooling/pawing at mouth, suspected blockage/known ingestion, black/tarry stool, collapse, seizure-like episode, severe weakness episodes

VET_SOON if ANY:
- Eating less but still eating, poop reduced
- Diarrhea (especially ongoing) or very soft stool
- Head tilt, severe balance issues
- Eye/nose discharge, wheezing, clicking, frequent sneezing
- Pain signs (hunched posture, tooth grinding, unwilling to move)
- Rapid weight loss trend
- Suspected dental disease (drooling, dropping food, difficulty chewing)
- FERRET: intermittent vomiting, decreased stool output, pawing at mouth, persistent drooling, lethargy, recurring weakness episodes

MONITOR only if:
- Mild symptom is improving AND normal eating/pooping/energy AND no red flags above.

OUTPUT MUST BE JSON ONLY.

Pet name: ${_escape(petName)}.
Species (canonical): ${_escape(canonicalSpecies)}.
''';
  }

  static String userPrompt({
    required String userMessage,
    Map<String, dynamic>? petProfile,
  }) {
    final speciesRaw = (petProfile?["species"] ?? "Unknown").toString();
    final species = _canonicalSpecies(speciesRaw);

    final age = (petProfile?["age_months"] ?? "?").toString();
    final weight = (petProfile?["weight_grams"] ?? "?").toString();

    final speciesQuestions = _speciesSpecificQuestions(species);

    return '''
User message:
${userMessage.trim()}

petProfile (structured):
species=$species
age_months=$age
weight_grams=$weight

TASK:
1) Detect red_flags_detected and assign triage_level conservatively using the rules.
2) Fill likely_categories with HIGH-LEVEL categories only:
   examples: "GI stasis/ileus risk", "respiratory issue", "pain/injury", "dental disease",
   "urinary issue", "toxin/exposure", "parasites/skin", "possible GI blockage".
3) Fill next_steps with LOW-RISK steps only:
   - keep warm, quiet/dim, minimize handling/stress
   - ensure access to water/normal diet (species-appropriate)
   - observe appetite/poop/urine closely
   - seek urgent vet care when triage indicates
   - NO dosing instructions, no meds, no oils
4) Ask targeted questions_to_ask:
   - Always include general triage questions (onset, eating/drinking, poop/urine, breathing effort, pain signs, weight trend).
   - Also include 2–4 species-specific questions below.

SPECIES-SPECIFIC QUESTIONS TO INCLUDE:
${speciesQuestions}

5) Return ONLY valid JSON matching schema exactly.
''';
  }

  // -------------------------
  // Helpers
  // -------------------------

  static String _canonicalSpecies(String input) {
    final t = input.trim().toLowerCase();
    if (t.isEmpty) return "Unknown";

    if (t.contains("guinea") || t.contains("cavy")) return "Guinea pig";
    if (t.contains("rabbit") || t.contains("bunny")) return "Rabbit";
    if (t == "rat" || t.contains(" rat")) return "Rat";
    if (t == "mouse" || t.contains(" mouse") || t.contains("mice")) return "Mouse";
    if (t.contains("hamster")) return "Hamster";
    if (t.contains("gerbil")) return "Gerbil";
    if (t.contains("ferret")) return "Ferret";

    // If it's already canonical (maybe wrong casing)
    for (final s in supportedSpecies) {
      if (s.toLowerCase() == t) return s;
    }

    return input.trim().isEmpty ? "Unknown" : input.trim();
  }

  static String _speciesSpecificQuestions(String species) {
    switch (species) {
      case "Guinea pig":
        return '''
- Guinea pig: Any drooling, wet chin, or dropping food (dental pain)?
- Guinea pig: Any change in poop size/number over the last 6–12 hours?
- Guinea pig: Any signs of bloat (tight belly) or teeth grinding?
- Guinea pig: Recent diet change (new veggie/treat/pellet) or less hay?''';

      case "Rabbit":
        return '''
- Rabbit: Any decrease in droppings or smaller/harder pellets (possible stasis)?
- Rabbit: Any recent stress, diet change, or reduced hay intake?
- Rabbit: Is the belly tight/round, and is the rabbit pressing belly to floor?
- Rabbit: Any tooth grinding, refusal to move, or hunching?''';

      case "Rat":
        return '''
- Rat: Any respiratory sounds (clicking, wheeze), increased effort, or side heaving?
- Rat: Any porphyrin (red discharge) around nose/eyes + lethargy?
- Rat: Any head tilt or loss of balance (ear/neurologic concern)?
- Rat: Any lumps/abscesses or sudden weight loss?''';

      case "Mouse":
        return '''
- Mouse: Any respiratory sounds (clicking, squeaks), open-mouth breathing, or rapid breathing?
- Mouse: Any porphyrin (red discharge) around nose/eyes?
- Mouse: Any hunching, cold to touch, or not moving normally?
- Mouse: Any diarrhea or wet tail area?''';

      case "Hamster":
        return '''
- Hamster: Any diarrhea/"wet tail" area, dehydration, or strong smell?
- Hamster: Any breathing noise/clicking or crusty nose/eyes?
- Hamster: Any falls/injury (limp) or not using a leg?
- Hamster: Any sudden collapse or extreme sleepiness beyond normal?''';

      case "Gerbil":
        return '''
- Gerbil: Any seizures/twitching, head tilt, or sudden weakness?
- Gerbil: Any breathing noise/clicking or nasal discharge?
- Gerbil: Any diarrhea or reduced droppings?
- Gerbil: Any tail/foot injury or self-chewing?''';

      case "Ferret":
        return '''
- Ferret: Any vomiting, retching, drooling, pawing at mouth, or teeth grinding (possible blockage/pain)?
- Ferret: Any reduced stool output, pencil-thin stools, black/tarry stool, or straining?
- Ferret: Any episodes of sudden weakness, staring, drooling, pawing, or collapse (possible low blood sugar)?
- Ferret: Any recent access to foam/rubber/small objects or new treats?''';

      default:
        return '''
- Species unclear: What species is your pet, and approximate weight?
- Species unclear: Any change in eating, drinking, poop/urine in the last 12 hours?
- Species unclear: Any breathing difficulty, collapse, seizures, bleeding, or suspected toxin exposure?''';
    }
  }

  static String _escape(String s) => s.replaceAll(r'$', r'\$');
}
