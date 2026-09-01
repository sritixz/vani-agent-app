import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/models/calls/call_history_model.dart';

class AICallAnalysisDialog extends StatelessWidget {
  final CallHistoryModel? call;
  final String? phoneNumber;
  final String? campaignName;
  final String? sentiment;
  final String? outcome;
  final String? summary;
  final String? transcript;
  final Map<String, dynamic>? jsonOutput;

  const AICallAnalysisDialog({
    super.key,
    this.call,
    this.phoneNumber,
    this.campaignName,
    this.sentiment,
    this.outcome,
    this.summary,
    this.transcript,
    this.jsonOutput,
  });

  static void show(
    BuildContext context, {
    CallHistoryModel? call,
    String? phoneNumber,
    String? campaignName,
    String? sentiment,
    String? outcome,
    String? summary,
    String? transcript,
    Map<String, dynamic>? jsonOutput,
  }) {
    Map<String, dynamic>? parsedJson = jsonOutput;
    if (parsedJson == null && call?.jsonOutput != null && call!.jsonOutput!.isNotEmpty) {
      try {
        parsedJson = jsonDecode(call.jsonOutput!) as Map<String, dynamic>;
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => AICallAnalysisDialog(
        call: call,
        phoneNumber: phoneNumber ?? call?.phoneNumber,
        campaignName: campaignName ?? call?.campaignName ?? call?.campaignId,
        sentiment: sentiment ?? call?.sentiment,
        outcome: outcome ?? parsedJson?['outcome'] as String?,
        summary: summary ?? call?.summary,
        transcript: transcript ?? call?.transcript,
        jsonOutput: parsedJson,
      ),
    );
  }

  Color _getSentimentColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.orange;
    }
  }

  Color _getSentimentBgColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'positive':
        return Colors.green.withOpacity(0.1);
      case 'negative':
        return Colors.red.withOpacity(0.1);
      case 'neutral':
      default:
        return Colors.orange.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPhone = phoneNumber ?? call?.phoneNumber ?? '+917337592673';
    final displayCampaign = campaignName ?? call?.campaignName ?? call?.campaignId ?? 'Sales1';
    final displaySentiment = sentiment ?? call?.sentiment ?? 'neutral';
    final displayOutcome = outcome ??
        'The call is ongoing, and the user has not yet provided the necessary information.';
    final displaySummary = summary ??
        call?.summary ??
        'The user has not provided enough information to determine the type of event they are planning. The agent is asking for clarification.';
    final displayTranscript = transcript ??
        call?.transcript ??
        '''Assistant: Hello, how can I help you today?
User: Yes, tell me.
Assistant: Great! Could you tell me what type of event you're planning? Like, is it a wedding, corporate event, or something else?''';

    final Map<String, dynamic> displayJson = jsonOutput ?? {
      "key_points": [
        "The user has not specified the type of event.",
        "The agent is asking for details about the event."
      ],
      "action_items": [
        "User needs to specify the type of event."
      ],
      "outcome": displayOutcome,
      "amd_analysis": {
        "answer_category": "unknown",
        "amd_subcategory": null,
        "confidence": "low",
        "evidence": [],
        "reason": "The user's response 'Yes, tell me.' is too brief and lacks context to determine if it's human or automated."
      }
    };

    final jsonPretty = const JsonEncoder.withIndent('  ').convert(displayJson);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Call Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$displayPhone • Campaign: $displayCampaign',
                          style: const TextStyle(
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

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. SENTIMENT
                    const Row(
                      children: [
                        Icon(Icons.sentiment_satisfied_alt, size: 16, color: AppTheme.darkGrey),
                        SizedBox(width: 6),
                        Text(
                          'SENTIMENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSentimentBgColor(displaySentiment),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displaySentiment.toLowerCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getSentimentColor(displaySentiment),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. OUTCOME
                    const Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 16, color: AppTheme.darkGrey),
                        SizedBox(width: 6),
                        Text(
                          'OUTCOME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
                      ),
                      child: Text(
                        displayOutcome,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkGrey,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. AI SUMMARY
                    const Row(
                      children: [
                        Icon(Icons.description_outlined, size: 16, color: AppTheme.darkGrey),
                        SizedBox(width: 6),
                        Text(
                          'AI SUMMARY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
                      ),
                      child: Text(
                        displaySummary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkGrey,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. TRANSCRIPT
                    const Row(
                      children: [
                        Icon(Icons.article_outlined, size: 16, color: AppTheme.darkGrey),
                        SizedBox(width: 6),
                        Text(
                          'TRANSCRIPT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
                      ),
                      child: SelectableText(
                        displayTranscript,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.darkGrey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. JSON OUTPUT
                    const Row(
                      children: [
                        Icon(Icons.code, size: 16, color: AppTheme.darkGrey),
                        SizedBox(width: 6),
                        Text(
                          'JSON OUTPUT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderGrey),
                      ),
                      child: SelectableText(
                        jsonPretty,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF0F172A),
                          height: 1.4,
                        ),
                      ),
                    ),
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
