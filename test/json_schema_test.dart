import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Meal JSON schema', () {
    test('Has required keys + correct nested structure', () {
      final j = <String, dynamic>{
        "agent": "meal",
        "pet_name": "Noodle",
        "species": "Guinea pig",
        "meal_name": "Daily base diet",
        "needs_vet_triage": false,
        "red_flags_detected": <String>[],
        "diet_quality_notes": <String>["Looks okay overall"],
        "safe_core_structure": <String>["Unlimited hay", "Plain pellets", "Leafy greens"],
        "suggested_portion_ranges": <String, dynamic>{
          "hay": "Unlimited",
          "pellets": "15–25g/day",
          "veggies": "1 cup/day",
          "fruit_treats": "1–2 tsp 1–2x/week",
        },
        "unsafe_items_detected": <String>[],
        "safer_alternatives": <String>[],
        "urgent_actions": <String>[],
        "questions": <String>["What pellet brand are you using?"],
      };

      // top-level required keys
      for (final k in [
        "agent",
        "pet_name",
        "species",
        "meal_name",
        "needs_vet_triage",
        "red_flags_detected",
        "diet_quality_notes",
        "safe_core_structure",
        "suggested_portion_ranges",
        "unsafe_items_detected",
        "safer_alternatives",
        "urgent_actions",
        "questions",
      ]) {
        expect(j.containsKey(k), true, reason: 'Missing key: $k');
      }

      expect(j["agent"], "meal");
      expect(j["needs_vet_triage"] is bool, true);

      // list fields
      for (final k in [
        "red_flags_detected",
        "diet_quality_notes",
        "safe_core_structure",
        "unsafe_items_detected",
        "safer_alternatives",
        "urgent_actions",
        "questions",
      ]) {
        expect(j[k] is List, true, reason: '$k must be a List');
      }

      // nested object
      expect(j["suggested_portion_ranges"] is Map, true);
      final p = (j["suggested_portion_ranges"] as Map);
      for (final k in ["hay", "pellets", "veggies", "fruit_treats"]) {
        expect(p.containsKey(k), true, reason: 'Missing portion key: $k');
        // allow String or null
        expect(p[k] == null || p[k] is String, true, reason: '$k must be String|null');
      }
    });
  });

  group('Vet JSON schema', () {
    test('Has required keys + triage enums', () {
      final j = <String, dynamic>{
        "agent": "vet",
        "pet_name": "Miso",
        "species": "Ferret",
        "triage_level": "VET_SOON",
        "is_urgent": true,
        "red_flags_detected": <String>["retching", "pawing at mouth"],
        "likely_categories": <String>["possible GI blockage"],
        "next_steps": <String>["Keep warm and quiet", "Seek urgent vet care"],
        "questions_to_ask": <String>["When did this start?", "Any known ingestion?"],
        "disclaimer": "This does not replace a veterinarian.",
      };

      for (final k in [
        "agent",
        "pet_name",
        "species",
        "triage_level",
        "is_urgent",
        "red_flags_detected",
        "likely_categories",
        "next_steps",
        "questions_to_ask",
        "disclaimer",
      ]) {
        expect(j.containsKey(k), true, reason: 'Missing key: $k');
      }

      expect(j["agent"], "vet");
      expect(j["is_urgent"] is bool, true);

      // triage enum
      final triage = j["triage_level"];
      expect(
        triage == "EMERGENCY" || triage == "VET_SOON" || triage == "MONITOR",
        true,
        reason: 'Invalid triage_level: $triage',
      );

      // list fields
      for (final k in [
        "red_flags_detected",
        "likely_categories",
        "next_steps",
        "questions_to_ask",
      ]) {
        expect(j[k] is List, true, reason: '$k must be a List');
      }

      expect(j["disclaimer"] is String, true);
    });
  });
}
