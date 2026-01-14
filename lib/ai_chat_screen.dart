// lib/ai_chat_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agents/agent_controller.dart';
import 'agents/openai_client.dart';
import 'agents/species.dart';
import 'pro_access.dart';
import 'secrets.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _text = TextEditingController();
  bool _loading = false;

  final List<Map<String, String>> _messages = [];
  late final AgentController _agent;

  // ===== Pro persistent memory =====
  static const String _kPrefChatMessages = 'pv_pro_chat_messages_v1';
  static const int _kMaxStoredMessages = 50;

  // ===== Pro pet profile =====
  static const String _kPrefPetProfile = 'pv_pro_pet_profile_v1';

  // Allowed plan lengths (Option B)
  static const List<int> _planDayOptions = [5, 7];

  // Default profile (used if nothing saved yet)
  Map<String, dynamic> petProfile = {
    "species": "Guinea pig",
    "name": "",
    "age_months": 8,
    "weight_grams": 900,
    "goal": "general health",
    "diet": "",
    "housing": "",
    "plan_days": 5, // ✅ Option B default
  };

  @override
  void initState() {
    super.initState();
    _agent = AgentController(
      openAIClient: OpenAIClient(apiKey: openAIApiKey),
    );

    _loadProMemoryIfEnabled();
    _loadPetProfileIfEnabled();
  }

  // ===============================
  // Pro memory helpers
  // ===============================
  Future<void> _loadProMemoryIfEnabled() async {
    if (!ProAccess.isPro) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPrefChatMessages);
    if (stored == null || stored.isEmpty) return;

    try {
      final decoded = jsonDecode(stored);
      if (decoded is List) {
        final restored = decoded
            .whereType<Map>()
            .map<Map<String, String>>(
              (m) => m.map((k, v) => MapEntry(k.toString(), v.toString())),
            )
            .toList();

        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(restored);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProMemoryIfEnabled() async {
    if (!ProAccess.isPro) return;

    final prefs = await SharedPreferences.getInstance();
    final trimmed = _messages.length <= _kMaxStoredMessages
        ? _messages
        : _messages.sublist(_messages.length - _kMaxStoredMessages);

    try {
      await prefs.setString(_kPrefChatMessages, jsonEncode(trimmed));
    } catch (_) {}
  }

  Future<void> _clearProMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefChatMessages);
  }

  // ===============================
  // Pro pet profile helpers
  // ===============================
  int _normalizePlanDays(dynamic v) {
    final n = (v is int) ? v : int.tryParse(v?.toString() ?? "");
    if (n == 7) return 7;
    return 5; // default safe
  }

  Future<void> _loadPetProfileIfEnabled() async {
    if (!ProAccess.isPro) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPrefPetProfile);
    if (stored == null || stored.isEmpty) return;

    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map) {
        if (!mounted) return;

        final loaded = decoded.cast<String, dynamic>();

        // normalize species to canonical supported values
        final raw = (loaded["species"] ?? "Guinea pig").toString();
        loaded["species"] = Species.normalize(raw);

        // normalize plan_days
        loaded["plan_days"] = _normalizePlanDays(loaded["plan_days"]);

        setState(() {
          petProfile = loaded;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePetProfileIfEnabled() async {
    if (!ProAccess.isPro) return;

    // Normalize before saving
    petProfile["species"] = Species.normalize((petProfile["species"] ?? "").toString());
    petProfile["plan_days"] = _normalizePlanDays(petProfile["plan_days"]);

    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kPrefPetProfile, jsonEncode(petProfile));
    } catch (_) {}
  }

  Future<void> _clearPetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefPetProfile);
  }

  // ===============================
  // Pet profile UI
  // ===============================
  Future<void> _editPetProfileDialog() async {
    if (!ProAccess.isPro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pet Profile is a Pro feature (for now).")),
      );
      return;
    }

    String selectedSpecies =
        Species.normalize((petProfile["species"] ?? "Guinea pig").toString());

    int selectedPlanDays = _normalizePlanDays(petProfile["plan_days"]);

    final nameCtrl = TextEditingController(text: (petProfile["name"] ?? "").toString());
    final ageCtrl = TextEditingController(text: (petProfile["age_months"] ?? "").toString());
    final weightCtrl =
        TextEditingController(text: (petProfile["weight_grams"] ?? "").toString());
    final goalCtrl = TextEditingController(text: (petProfile["goal"] ?? "").toString());
    final dietCtrl = TextEditingController(text: (petProfile["diet"] ?? "").toString());
    final housingCtrl = TextEditingController(text: (petProfile["housing"] ?? "").toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text("Edit Pet Profile (Pro)"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSpecies,
                      items: Species.supported
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setLocal(() => selectedSpecies = v ?? selectedSpecies),
                      decoration: const InputDecoration(labelText: "Species"),
                    ),
                    const SizedBox(height: 10),

                    // ✅ NEW: Plan length control (Option B)
                    DropdownButtonFormField<int>(
                      value: selectedPlanDays,
                      items: _planDayOptions
                          .map((d) => DropdownMenuItem(value: d, child: Text("$d days")))
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => selectedPlanDays = v ?? selectedPlanDays),
                      decoration: const InputDecoration(labelText: "Plan length"),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Name (optional)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age (months)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Weight (grams)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: goalCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            "Goal (bonding / enrichment / weight / stress / habitat / general health)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dietCtrl,
                      decoration: const InputDecoration(labelText: "Diet (optional)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: housingCtrl,
                      decoration: const InputDecoration(labelText: "Housing (optional)"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final age = int.tryParse(ageCtrl.text.trim());
      final weight = int.tryParse(weightCtrl.text.trim());

      setState(() {
        petProfile = {
          "species": Species.normalize(selectedSpecies),
          "plan_days": _normalizePlanDays(selectedPlanDays),
          "name": nameCtrl.text.trim(),
          "age_months": age ?? (petProfile["age_months"] ?? 0),
          "weight_grams": weight ?? (petProfile["weight_grams"] ?? 0),
          "goal": goalCtrl.text.trim().isEmpty ? "general health" : goalCtrl.text.trim(),
          "diet": dietCtrl.text.trim(),
          "housing": housingCtrl.text.trim(),
        };
      });

      await _savePetProfileIfEnabled();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved pet profile (Pro).")),
      );
    }
  }

  String _profileSummary() {
    final species = Species.normalize((petProfile["species"] ?? "Guinea pig").toString());
    final name = (petProfile["name"] ?? "").toString().trim();
    final age = (petProfile["age_months"] ?? "?").toString();
    final w = (petProfile["weight_grams"] ?? "?").toString();
    final goal = (petProfile["goal"] ?? "general health").toString();
    final planDays = _normalizePlanDays(petProfile["plan_days"]);

    final n = name.isEmpty ? "" : "$name • ";
    return "${n}${species}, ${age}mo, ${w}g • Goal: $goal • Plan: ${planDays}d";
  }

  // ===============================
  // Chat send logic
  // ===============================
  Future<void> _send() async {
    final msg = _text.text.trim();
    if (msg.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _messages.add({"role": "user", "text": msg});
      _text.clear();
    });

    await _saveProMemoryIfEnabled();

    try {
      // Normalize before passing to agent layer
      petProfile["species"] = Species.normalize((petProfile["species"] ?? "").toString());
      petProfile["plan_days"] = _normalizePlanDays(petProfile["plan_days"]);

      final resp = await _agent.handleUserMessage(
        msg,
        history: _messages,
        petProfile: petProfile,
      );

      setState(() {
        final header = "${resp.agentLabel}${resp.isUrgent ? " (URGENT)" : ""}";
        _messages.add({
          "role": "assistant",
          "text": "$header\n\n${resp.text}",
        });
      });

      await _saveProMemoryIfEnabled();
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "text": "Error: $e"});
      });
      await _saveProMemoryIfEnabled();
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PocketVet"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                ProAccess.isPro ? "PRO" : "FREE",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            tooltip: "Edit Pet Profile",
            icon: const Icon(Icons.pets_outlined),
            onPressed: _editPetProfileDialog,
          ),
          IconButton(
            tooltip: ProAccess.isPro ? 'Pro ON' : 'Pro OFF',
            icon: Icon(ProAccess.isPro ? Icons.workspace_premium : Icons.lock_outline),
            onPressed: () async {
              setState(() => ProAccess.isPro = !ProAccess.isPro);

              if (ProAccess.isPro) {
                await _loadProMemoryIfEnabled();
                await _loadPetProfileIfEnabled();
              } else {
                setState(() {
                  _messages.clear();
                });
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ProAccess.isPro ? "PRO enabled" : "PRO disabled")),
              );
            },
          ),
          IconButton(
            tooltip: 'Force save (debug)',
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              await _saveProMemoryIfEnabled();
              await _savePetProfileIfEnabled();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ProAccess.isPro
                        ? "Saved ${_messages.length} msgs + profile."
                        : "Pro is OFF — nothing saved.",
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Clear saved memory',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _clearProMemory();
              await _clearPetProfile();
              if (!mounted) return;
              setState(() => _messages.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cleared saved memory + profile.")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Text(
              ProAccess.isPro
                  ? "Pet Profile (Pro): ${_profileSummary()}"
                  : "Pet Profile: (Pro feature — toggle PRO to persist profile)",
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(m["text"] ?? ""),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: "Ask about diet, behavior, habitat, or symptoms…",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loading ? null : _send,
                  child: Text(_loading ? "..." : "Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
