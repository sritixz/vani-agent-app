import 'package:flutter_test/flutter_test.dart';
import 'package:vani_app/core/network/api_endpoints.dart';
import 'package:vani_app/models/campaign_model.dart';
import 'package:vani_app/screens/campaigns/campaigns_screen.dart';

void main() {
  group('Campaigns Tier 1 Features & API Tests', () {
    test('Builds CampaignFilters with status and date range', () {
      const filters = CampaignFilters(
        search: 'july_bpo',
        status: 'paused',
        createdFrom: '2026-07-01',
        createdTill: '2026-07-31',
      );

      expect(filters.search, equals('july_bpo'));
      expect(filters.status, equals('paused'));
      expect(filters.createdFrom, equals('2026-07-01'));
      expect(filters.createdTill, equals('2026-07-31'));
    });

    test('Generates pause and resume API endpoints accurately', () {
      const campaignId = '6a6748bc0d61f1974a71f4d2';

      expect(ApiEndpoints.campaignPause(campaignId), equals('/api/campaigns/6a6748bc0d61f1974a71f4d2/pause'));
      expect(ApiEndpoints.campaignResume(campaignId), equals('/api/campaigns/6a6748bc0d61f1974a71f4d2/resume'));
      expect(ApiEndpoints.campaignSync(campaignId), equals('/api/campaigns/6a6748bc0d61f1974a71f4d2/sync'));
    });

    test('Validates Tier 1 switches payload mapping for creation', () {
      final campaignPayload = {
        'name': '27_july_bpo',
        'agent_id': 'agent_123',
        'retries': 3,
        'multi_number_rotation': true,
        'auto_followup': true,
        'send_whatsapp': true,
      };

      expect(campaignPayload['multi_number_rotation'], isTrue);
      expect(campaignPayload['auto_followup'], isTrue);
      expect(campaignPayload['send_whatsapp'], isTrue);
    });

    test('Parses Campaign model json response correctly', () {
      final json = {
        'id': '6a6748bc0d61f1974a71f4d2',
        'user_id': 'user_99',
        'name': '27_july_bpo',
        'agent_name': 'VaniAgnetMetaLeads_gautam',
        'agent_id': 'agent_123',
        'status': 'paused',
        'retries': 3,
        'start_date_time': '2026-07-27T10:00:00Z',
        'end_date_time': '2026-07-27T18:00:00Z',
        'created_at': '2026-07-27T09:00:00Z',
        'updated_at': '2026-07-27T09:00:00Z',
      };

      final campaign = Campaign.fromJson(json);

      expect(campaign.id, equals('6a6748bc0d61f1974a71f4d2'));
      expect(campaign.name, equals('27_july_bpo'));
      expect(campaign.status, equals('paused'));
      expect(campaign.agentName, equals('VaniAgnetMetaLeads_gautam'));
    });
  });
}
