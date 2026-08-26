import 'package:flutter_test/flutter_test.dart';
import 'package:vani_app/data/models/calls/call_statistics_model.dart';
import 'package:vani_app/data/models/subscriptions/subscription_model.dart';

void main() {
  group('CallStatisticsModel Tier 1 & Tier 2 Tests', () {
    test('Parses total credits spent and getters correctly', () {
      final json = {
        'total_calls': 12251,
        'total_minutes': '2092.85',
        'total_credits_spent': '145.20',
        'average_duration_seconds': 44,
        'calls_by_type': {
          'campaign': 11812,
          'web_test': 184,
          'send_call': 124,
          'inbound': 113,
          'web_widget': 18,
        },
        'calls_by_status': {
          'completed': 2834,
          'no_answer': 5932,
          'failed': 814,
          'busy': 511,
          'in_progress': 2,
        },
      };

      final stats = CallStatisticsModel.fromJson(json);

      expect(stats.totalCalls, equals(12251));
      expect(stats.totalMinutesAsDouble, equals(2092.85));
      expect(stats.totalCreditsSpentAsDouble, equals(145.20));
      expect(stats.averageDurationSeconds, equals(44));
      expect(stats.callsByType?['campaign'], equals(11812));
      expect(stats.callsByStatus?['completed'], equals(2834));
    });
  });

  group('CurrentSubscriptionModel Sub-Metrics Tests', () {
    test('Parses concurrency and plan sub-metrics correctly', () {
      final json = {
        'id': 'sub_123',
        'tier_id': 'growth',
        'tier_name': 'Growth',
        'status': 'active',
        'concurrency': 3,
        'web_tests': '300/300',
        'minutes_used': 447.66,
        'calls_this_period': 652,
        'reset_date': '1 Sep',
      };

      final sub = CurrentSubscriptionModel.fromJson(json);

      expect(sub.tierName, equals('Growth'));
      expect(sub.status, equals('active'));
      expect(sub.concurrency, equals(3));
      expect(sub.webTests, equals('300/300'));
      expect(sub.minutesUsed, equals(447.66));
      expect(sub.callsThisPeriod, equals(652));
      expect(sub.resetDate, equals('1 Sep'));
    });
  });
}
