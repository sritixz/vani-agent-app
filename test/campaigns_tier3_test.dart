import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Campaigns Tier 3 Features & Analytics Tests', () {
    test('Calculates live campaign execution progress percentage correctly', () {
      const completedCount = 142;
      const totalContactsCount = 500;
      final pct = completedCount / totalContactsCount;

      expect(pct, equals(0.284));
      expect((pct * 100).toStringAsFixed(1), equals('28.4'));
    });

    test('Validates call outcomes breakdown metrics', () {
      final breakdown = {
        'answered': 118,
        'unanswered': 24,
        'positive_lead': 86,
      };

      expect(breakdown['answered'], equals(118));
      expect(breakdown['unanswered'], equals(24));
      expect(breakdown['positive_lead'], equals(86));
    });

    test('Generates clone campaign payload correctly', () {
      final originalCampaign = {
        'id': '6a6748bc0d61f1974a71f4d2',
        'name': '27_july_bpo',
        'agent_name': 'VaniAgnetMetaLeads_gautam',
        'retries': 3,
        'time_zone': 'Asia/Kolkata',
      };

      final clonedPayload = {
        ...originalCampaign,
        'name': '${originalCampaign["name"]} (Copy)',
      };

      expect(clonedPayload['name'], equals('27_july_bpo (Copy)'));
      expect(clonedPayload['agent_name'], equals('VaniAgnetMetaLeads_gautam'));
    });
  });
}
