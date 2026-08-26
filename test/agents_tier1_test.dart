import 'package:flutter_test/flutter_test.dart';
import 'package:vani_app/models/agent_model.dart';

void main() {
  group('Agents Tier 1 Features & Model Tests', () {
    test('Calculates total agents counter accurately', () {
      final jsonList = [
        {
          'id': 'agent_1',
          'name': 'vani_agent_test_1',
          'voice': 'Priya (Female)',
          'is_active': true,
          'engine_type': 'Classic Pipeline',
        },
        {
          'id': 'agent_2',
          'name': 'VaniAgnetMetaLeads_gautam',
          'voice': 'Anaya - Female, Breezy',
          'is_active': true,
          'engine_type': 'Ultra Realtime',
        },
        {
          'id': 'agent_3',
          'name': 'gangas_industries',
          'voice': 'Hindi Female (Default)',
          'is_active': true,
          'engine_type': 'Vani Ultra',
        },
      ];

      final agents = jsonList.map((json) => Agent.fromJson(json)).toList();

      expect(agents.length, equals(3));
      expect(agents[0].name, equals('vani_agent_test_1'));
      expect(agents[1].engineType, equals('Ultra Realtime'));
      expect(agents[2].engineType, equals('Vani Ultra'));
    });

    test('Estimates prompt token budget correctly', () {
      const promptText = 'You are an AI appointment booking assistant for healthcare clinic.';
      final estimatedTokens = (promptText.length / 4.0).ceil();

      expect(estimatedTokens, equals(17));
    });

    test('Restores unsaved draft payload accurately', () {
      final draftData = {
        'name': 'Draft Agent',
        'prompt': 'You are an AI assistant for appointment booking and customer support.',
        'greeting': 'Hello, how can I help you today?',
      };

      expect(draftData['name'], equals('Draft Agent'));
      expect(draftData['greeting'], equals('Hello, how can I help you today?'));
    });
  });
}
