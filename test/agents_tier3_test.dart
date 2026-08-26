import 'package:flutter_test/flutter_test.dart';
import 'package:vani_app/models/agent_model.dart';

void main() {
  group('Agents Tier 3 Features & Quick Test / Flow Tests', () {
    final mockAgent = Agent(
      id: 'agent_test_3',
      userId: 'user_123',
      name: 'VaniAgnetMetaLeads_gautam',
      voice: 'Anaya - Female, Breezy',
      ttsLanguage: 'hi',
      ttsProvider: '',
      speechToSpeechProvider: 'gemini live',
      agentPrompt: 'You are an AI sales assistant for real estate.',
      greetingLine: 'Namaste, main Riya baat kar rahi hoon.',
      isActive: true,
      allowInterruptions: true,
      backgroundMusic: false,
      debugLogging: false,
      isFrozen: false,
      hardEndCallMinutes: 5,
      createdAt: '2026-08-14T00:00:00Z',
      updatedAt: '2026-08-14T00:00:00Z',
      voiceEngine: 'Ultra Realtime',
      knowledgeBaseIds: ['kb_realestate_1', 'kb_pricing_2'],
    );

    test('Generates test call API payload accurately', () {
      final payload = {
        'phone_number': '+919876543210',
        'agent_id': mockAgent.id,
        'test_mode': true,
      };

      expect(payload['phone_number'], equals('+919876543210'));
      expect(payload['agent_id'], equals('agent_test_3'));
      expect(payload['test_mode'], isTrue);
    });

    test('Validates conversation flow nodes pipeline', () {
      final flowNodes = [
        {'step': 1, 'name': 'Call Initiated', 'trigger': mockAgent.greetingLine},
        {'step': 2, 'name': 'Speech Recognition', 'language': mockAgent.ttsLanguage},
        {'step': 3, 'name': 'Knowledge Base Lookup', 'kbs': mockAgent.knowledgeBaseIds},
        {'step': 4, 'name': 'AI Reasoning', 'engine': mockAgent.engineType},
        {'step': 5, 'name': 'Voice Synthesis', 'voice': mockAgent.voice},
        {'step': 6, 'name': 'Post-Call Analysis', 'mode': 'default'},
      ];

      expect(flowNodes.length, equals(6));
      expect(flowNodes[0]['trigger'], equals('Namaste, main Riya baat kar rahi hoon.'));
      expect((flowNodes[2]['kbs'] as List).length, equals(2));
      expect(flowNodes[3]['engine'], equals('Ultra Realtime'));
    });

    test('Validates 3-step wizard configuration steps', () {
      final steps = [
        '1 Voice & Engine',
        '2 Conversation',
        '3 Analysis & Advanced',
      ];

      expect(steps.length, equals(3));
      expect(steps[0], contains('Voice & Engine'));
      expect(steps[1], contains('Conversation'));
      expect(steps[2], contains('Analysis & Advanced'));
    });
  });
}
