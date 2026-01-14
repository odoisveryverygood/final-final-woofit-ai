import 'package:flutter_test/flutter_test.dart';
import 'package:PocketVet/agents/agent_router.dart';

void main() {
  group('AgentRouter.route() — safety + intent', () {
    test('Routes to VET on obvious emergency red flags', () {
      expect(
        AgentRouter.route("my guinea pig is not eating and not pooping",
            species: "Guinea pig"),
        AgentType.vet,
      );
      expect(
        AgentRouter.route("my rabbit is bloated and hunched",
            species: "Rabbit"),
        AgentType.vet,
      );
      expect(
        AgentRouter.route("my ferret is retching and pawing at mouth",
            species: "Ferret"),
        AgentType.vet,
      );
      expect(
        AgentRouter.route("my hamster has wet tail and is lethargic",
            species: "Hamster"),
        AgentType.vet,
      );
    });

    test('Routes to MEAL on clear nutrition questions (no red flags)', () {
      expect(
        AgentRouter.route("what should I feed my guinea pig daily",
            species: "Guinea pig"),
        AgentType.meal,
      );
      expect(
        AgentRouter.route("how much pellets should my rabbit get",
            species: "Rabbit"),
        AgentType.meal,
      );
      expect(
        AgentRouter.route("can my rat eat strawberries",
            species: "Rat"),
        AgentType.meal,
      );
    });

    test('Defaults to TRAINER on routine/enrichment questions (no red flags)', () {
      expect(
        AgentRouter.route("make a weekly enrichment routine for my ferret",
            species: "Ferret"),
        AgentType.trainer,
      );
      expect(
        AgentRouter.route("my gerbil is bored give activities",
            species: "Gerbil"),
        AgentType.trainer,
      );
      expect(
        AgentRouter.route("bonding plan for a shy guinea pig",
            species: "Guinea pig"),
        AgentType.trainer,
      );
    });

    test('Forced agent requests override intent (still allow vet override internally)', () {
      expect(
        AgentRouter.route("use meal agent: build a diet plan",
            species: "Guinea pig"),
        AgentType.meal,
      );
      expect(
        AgentRouter.route("use trainer agent: build a routine",
            species: "Rabbit"),
        AgentType.trainer,
      );
      expect(
        AgentRouter.route("use vet agent: triage this",
            species: "Rat"),
        AgentType.vet,
      );
    });
  });

  group('AgentRouter.isUrgent()', () {
    test('Marks urgent on high-signal emergency phrases', () {
      expect(AgentRouter.isUrgent("my pet is unresponsive"), true);
      expect(AgentRouter.isUrgent("cant breathe open mouth breathing"), true);
      expect(AgentRouter.isUrgent("seizing right now"), true);
      expect(AgentRouter.isUrgent("blood in urine"), true);
      expect(AgentRouter.isUrgent("toxic cleaner ingestion"), true);
      expect(AgentRouter.isUrgent("wet tail and dehydrated"), true);
    });

    test('Not eating + poop/pain combo should be urgent', () {
      expect(AgentRouter.isUrgent("not eating and hunched, teeth grinding"), true);
      expect(AgentRouter.isUrgent("won't eat and no poop"), true);
    });

    test('Non-urgent normal questions are false', () {
      expect(AgentRouter.isUrgent("what toys are good for enrichment"), false);
      expect(AgentRouter.isUrgent("how often should I clean the cage"), false);
    });
  });
}
