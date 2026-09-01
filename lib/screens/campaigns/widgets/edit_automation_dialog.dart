import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/campaigns_api_service.dart';
import 'package:vani_app/models/campaign_model.dart';

class EditAutomationDialog extends ConsumerStatefulWidget {
  final Campaign campaign;

  const EditAutomationDialog({super.key, required this.campaign});

  static Future<bool?> show(BuildContext context, Campaign campaign) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => EditAutomationDialog(campaign: campaign),
    );
  }

  @override
  ConsumerState<EditAutomationDialog> createState() => _EditAutomationDialogState();
}

class _EditAutomationDialogState extends ConsumerState<EditAutomationDialog> {
  late bool _autoFollowupCall;
  late bool _sendWhatsappMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoFollowupCall = widget.campaign.autoFollowupEnabled;
    _sendWhatsappMessage = widget.campaign.whatsappAutomationEnabled;
  }

  Future<void> _saveAutomationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(campaignsApiServiceProvider);
      await service.updateCampaign(
        widget.campaign.id,
        {
          'auto_followup_enabled': _autoFollowupCall,
          'autoFollowupEnabled': _autoFollowupCall,
          'whatsapp_automation_enabled': _sendWhatsappMessage,
          'whatsappAutomationEnabled': _sendWhatsappMessage,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Automation settings saved successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving automation settings: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Automation Settings - ${widget.campaign.name}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.mediumGrey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle 1: Auto Followup Call
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_callback_outlined, size: 20, color: AppTheme.darkGrey),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Auto Followup Call',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ),
                  Switch(
                    value: _autoFollowupCall,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) {
                      setState(() {
                        _autoFollowupCall = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Toggle 2: Send WhatsApp Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.darkGrey),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Auto Follow-up for WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                      ),
                      Switch(
                        value: _sendWhatsappMessage,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) {
                          setState(() {
                            _sendWhatsappMessage = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_sendWhatsappMessage) ...[
                    const Divider(height: 20),
                    const SizedBox(height: 4),
                    const Text('Trigger: Send message automatically on call completion or unreached attempt', style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderGrey),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13, color: AppTheme.darkGrey, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAutomationSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Automation Settings',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
