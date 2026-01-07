import 'dart:convert';

import 'agent_router.dart';
import 'trainer_agent.dart';
import 'meal_agent.dart';
import 'vet_agent.dart';
import 'openai_client.dart';

/// A unified response your UI can render without guessing.
class AgentResponse {
  final AgentType agent;
  final String message; // user-facing text (for trainer) or short summary (meal/vet)
  final Map<String, dynamic>? data; // parsed JSON for structured agents
  final String raw; // raw model output (useful for debugging)

  AgentResponse({
    required this.agent,
    required this.message,
    required this.raw,
    this.data,
  });
}

class AgentController {
  final OpenAIClient openAIClient;

  AgentController({required this.openAIClient});

  /// Main entry point your UI should call.
  ///
  /// - dogName: used in prompts (defaults to "your dog")
  /// - dogProfile/recentActivity: optional context; safe to pass null for now
  Future<AgentResponse> handleMessage({
    required String userMessage,
    String dogName = "your dog",
    bool hasImage = false,
    Map<String, dynamic>? dogProfile,
    Map<String, dynamic>? recentActivity,
    String? visionSummary, // Task 6 later
  }) async {
    final agentType = AgentRouter.route(message: userMessage, hasImage: hasImage);

    switch (agentType) {
      case AgentType.trainer:
        return _handleTrainer(
          userMessage: userMessage,
          dogName: dogName,
          dogProfile: dogProfile,
          recentActivity: recentActivity,
        );

      case AgentType.meal:
        return _handleMeal(
          userMessage: userMessage,
          dogName: dogName,
          dogProfile: dogProfile,
        );

      case AgentType.vet:
        return _handleVet(
          userMessage: userMessage,
          dogName: dogName,
          dogProfile: dogProfile,
          recentActivity: recentActivity,
          visionSummary: visionSummary,
        );
    }
  }

  // -------------------------
  // Trainer (text + TRAINER_JSON block)
  // -------------------------
  Future<AgentResponse> _handleTrainer({
    required String userMessage,
    required String dogName,
    Map<String, dynamic>? dogProfile,
    Map<String, dynamic>? recentActivity,
  }) async {
    final system = TrainerAgent.systemPrompt(dogName: dogName);
    final user = TrainerAgent.userPrompt(
      userMessage: userMessage,
      dogProfile: dogProfile,
      recentActivity: recentActivity,
    );

    final raw = await openAIClient.generateText(
      systemPrompt: system,
      userPrompt: user,
      maxOutputTokens: 900,
    );

    // Extract TRAINER_JSON if present, otherwise just return raw text as message.
    final extracted = _extractLabeledJson(raw, label: "TRAINER_JSON");
    if (extracted == null) {
      return AgentResponse(
        agent: AgentType.trainer,
        message: raw.trim(),
        raw: raw,
        data: null,
      );
    }

    final parsed = _safeJsonDecodeMap(extracted);
    // Try to remove the JSON block from the visible message
    final cleanedMessage = _removeLabeledJsonBlock(raw, label: "TRAINER_JSON").trim();

    return AgentResponse(
      agent: AgentType.trainer,
      message: cleanedMessage.isEmpty ? "Here’s a plan for today." : cleanedMessage,
      raw: raw,
      data: parsed,
    );
  }

  // -------------------------
  // Meal (STRICT JSON only)
  // -------------------------
  Future<AgentResponse> _handleMeal({
    required String userMessage,
    required String dogName,
    Map<String, dynamic>? dogProfile,
  }) async {
    final system = MealAgent.systemPrompt(dogName: dogName);
    final user = MealAgent.userPrompt(userMessage: userMessage, dogProfile: dogProfile);

    final raw = await openAIClient.generateText(
      systemPrompt: system,
      userPrompt: user,
      maxOutputTokens: 700,
    );

    final parsed = _safeJsonDecodeMap(raw);

    // Guardrail: must declare correct agent
    if (parsed["agent"] != "meal") {
      throw Exception("Meal agent returned invalid JSON (agent mismatch): $raw");
    }

    final isToxic = parsed["is_toxic"] == true;
    final summary = isToxic
        ? "⚠️ Potentially toxic food detected. Review urgent actions."
        : "Meal analysis ready.";

    return AgentResponse(
      agent: AgentType.meal,
      message: summary,
      raw: raw,
      data: parsed,
    );
  }

  // -------------------------
  // Vet (STRICT JSON only)
  // -------------------------
  Future<AgentResponse> _handleVet({
    required String userMessage,
    required String dogName,
    Map<String, dynamic>? dogProfile,
    Map<String, dynamic>? recentActivity,
    String? visionSummary,
  }) async {
    final system = VetAgent.systemPrompt(dogName: dogName);
    final user = VetAgent.userPrompt(
      userMessage: userMessage,
      dogProfile: dogProfile,
      recentActivity: recentActivity,
      visionSummary: visionSummary,
    );

    final raw = await openAIClient.generateText(
      systemPrompt: system,
      userPrompt: user,
      maxOutputTokens: 850,
    );

    final parsed = _safeJsonDecodeMap(raw);

    if (parsed["agent"] != "vet") {
      throw Exception("Vet agent returned invalid JSON (agent mismatch): $raw");
    }

    final risk = (parsed["risk_level"] ?? "").toString();
    final summary = risk == "urgent"
        ? "🚨 Urgent risk flagged. Review when-to-see-vet guidance now."
        : "Vet triage summary ready.";

    return AgentResponse(
      agent: AgentType.vet,
      message: summary,
      raw: raw,
      data: parsed,
    );
  }

  // -------------------------
  // Helpers
  // -------------------------

  /// Extracts JSON after a label like:
  /// TRAINER_JSON
  /// { ... }
  /// Also supports code-fenced ```json blocks after the label.
  String? _extractLabeledJson(String raw, {required String label}) {
    final idx = raw.indexOf(label);
    if (idx == -1) return null;

    final after = raw.substring(idx + label.length);

    // If there's a fenced block, grab inside it.
    final fenceIdx = after.indexOf('```');
    if (fenceIdx != -1) {
      final afterFence = after.substring(fenceIdx + 3);
      final endFence = afterFence.indexOf('```');
      if (endFence != -1) {
        final inside = afterFence.substring(0, endFence).trim();
        // Sometimes starts with "json"
        if (inside.toLowerCase().startsWith('json')) {
          return inside.substring(4).trim();
        }
        return inside;
      }
    }

    // Otherwise, find the first { ... } block
    final firstBrace = after.indexOf('{');
    if (firstBrace == -1) return null;

    final jsonCandidate = after.substring(firstBrace).trim();
    // Try to balance braces (simple scan)
    int depth = 0;
    for (int i = 0; i < jsonCandidate.length; i++) {
      final ch = jsonCandidate[i];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (depth == 0) {
        return jsonCandidate.substring(0, i + 1);
      }
    }
    return null;
  }

  String _removeLabeledJsonBlock(String raw, {required String label}) {
    final idx = raw.indexOf(label);
    if (idx == -1) return raw;
    return raw.substring(0, idx);
  }

  Map<String, dynamic> _safeJsonDecodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      throw Exception("JSON is not an object");
    } catch (e) {
      throw Exception("Failed to parse JSON: $e\nRaw:\n$raw");
    }
  }
}
