// lib/agents/openai_client.dart
// AGENT INTERFACE LOCKED
// Changes require:
// - Test update
// - Version bump
// - Analytics review

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIClient {
  final String apiKey;
  final String model;

  OpenAIClient({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
  });

  Future<String> generateText({
    required String systemPrompt,
    required String userPrompt,
    int maxOutputTokens = 700,
    double? temperature,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/responses');

    final body = <String, dynamic>{
      "model": model,
      "input": [
        {
          "role": "system",
          "content": [
            {"type": "input_text", "text": systemPrompt}
          ]
        },
        {
          "role": "user",
          "content": [
            {"type": "input_text", "text": userPrompt}
          ]
        }
      ],
      "max_output_tokens": maxOutputTokens,
    };

    if (temperature != null) body["temperature"] = temperature;

    final resp = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("OpenAI error ${resp.statusCode}: ${resp.body}");
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    // ✅ Prefer the convenience field if present
    final ot = data["output_text"];
    if (ot is String && ot.trim().isNotEmpty) return ot.trim();

    // ✅ Fallback: parse output array
    final output = data["output"];
    if (output is! List) {
      throw Exception("OpenAI response missing output: ${resp.body}");
    }

    final buffer = StringBuffer();

    for (final item in output) {
      if (item is Map && item["content"] is List) {
        for (final c in (item["content"] as List)) {
          if (c is Map) {
            final type = c["type"];
            final text = c["text"];
            if ((type == "output_text" || type == "text") && text is String) {
              buffer.write(text);
            }
          }
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw Exception("OpenAI returned empty text: ${resp.body}");
    }
    return text;
  }
}

