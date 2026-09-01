import 'package:flutter/material.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/campaign_model.dart';

class DialingConfigDialog extends StatelessWidget {
  final Campaign campaign;

  const DialingConfigDialog({super.key, required this.campaign});

  static void show(BuildContext context, Campaign campaign) {
    showDialog(
      context: context,
      builder: (ctx) => DialingConfigDialog(campaign: campaign),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> settings = {
      'Max attempts per day': campaign.maxAttemptsPerDay.toString(),
      'Max campaign days': campaign.maxCampaignDays.toString(),
      'Max qualification rounds': campaign.maxQualificationRounds.toString(),
      'No-answer cooldown (min)': campaign.noAnswerCooldownMinutes.toString(),
      'Call window start (hour)': campaign.callWindowStart > 0 ? campaign.callWindowStart.toString() : '—',
      'Call window end (hour)': campaign.callWindowEnd > 0 ? campaign.callWindowEnd.toString() : '—',
      'Short-call threshold (s)': campaign.shortCallThresholdSeconds.toString(),
      'Long-call threshold (s)': campaign.longCallThresholdSeconds.toString(),
      'Number rotation strategy': campaign.numberRotationStrategy,
      'GSheet sync interval (min)': campaign.gsheetSyncIntervalMinutes.toString(),
      'Retries': campaign.retries.toString(),
    };

    final List<Map<String, dynamic>> changeHistory = [
      {
        'action': 'CREATED',
        'timestamp': campaign.createdAt,
        'user': 'sritizsahu07@gmail.com',
        'diffs': [
          {'field': 'Max attempts per day', 'old': '—', 'new': campaign.maxAttemptsPerDay.toString()},
          {'field': 'Max campaign days', 'old': '—', 'new': campaign.maxCampaignDays.toString()},
          {'field': 'Max qualification rounds', 'old': '—', 'new': campaign.maxQualificationRounds.toString()},
          {'field': 'No-answer cooldown (min)', 'old': '—', 'new': campaign.noAnswerCooldownMinutes.toString()},
        ]
      }
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.tune, size: 20, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dialing Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Current settings and full change history',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.mediumGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Current Settings
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Current Settings',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grid Layout of 11 Parameters
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.3,
                      ),
                      itemCount: settings.length,
                      itemBuilder: (context, index) {
                        final entry = settings.entries.elementAt(index);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderGrey.withOpacity(0.6)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.mediumGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Change History
                    const Row(
                      children: [
                        Icon(Icons.history, size: 18, color: AppTheme.darkGrey),
                        SizedBox(width: 8),
                        Text(
                          'Change History',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...changeHistory.map((item) {
                      final diffs = item['diffs'] as List<Map<String, String>>;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['action'] as String,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  item['timestamp'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.mediumGrey,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  item['user'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.mediumGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...diffs.map((diff) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '${diff['field']}: ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.mediumGrey,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        diff['old']!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Text(' → ', style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightGreen,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        diff['new']!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Footer Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderGrey)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
