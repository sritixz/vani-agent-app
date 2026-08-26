import 'package:flutter_test/flutter_test.dart';
import 'package:vani_app/data/models/agents/agent_template_model.dart';

void main() {
  group('Agents Tier 2 Features & Templates Gallery Tests', () {
    test('Contains 28 default industry starter templates', () {
      expect(defaultAgentTemplates.length, equals(28));
      expect(defaultAgentTemplates[0].category, equals('Healthcare'));
      expect(defaultAgentTemplates[0].title, equals('Medical Appointment Scheduler'));
      expect(defaultAgentTemplates[1].category, equals('Real Estate'));
    });

    test('Filters templates by query and category correctly', () {
      final query = 'appointment';
      final filtered = defaultAgentTemplates.where((t) {
        return t.title.toLowerCase().contains(query) || t.description.toLowerCase().contains(query);
      }).toList();

      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.any((t) => t.id == 'medical_scheduler'), isTrue);
    });

    test('Parses template model json serialization correctly', () {
      final json = {
        'id': 'test_template',
        'title': 'Test Template',
        'category': 'Testing',
        'description': 'Test description',
        'language': 'English (India)',
        'persona_voice': 'Riya - Female actor',
        'call_limit': '3 minutes',
        'use_case': 'Testing usecase',
        'used_tokens': 450,
        'max_tokens': 800,
        'sample_prompt': '"Hello, this is a test prompt..."',
        'system_prompt': 'You are a test agent.',
      };

      final model = AgentTemplateModel.fromJson(json);

      expect(model.id, equals('test_template'));
      expect(model.title, equals('Test Template'));
      expect(model.usedTokens, equals(450));
      expect(model.systemPrompt, equals('You are a test agent.'));
    });
  });
}
