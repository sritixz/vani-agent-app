import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/models/calls/call_history_model.dart';
import 'package:vani_app/presentation/providers/calls_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load call history when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(callsProvider.notifier).loadCallHistory(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callsState = ref.watch(callsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(callsProvider.notifier).loadCallHistory(refresh: true);
          },
          child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Call Logs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review and manage recent agent interactions.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.mediumGrey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search numbers or notes...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.mediumGrey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.borderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (callsState.isLoading && callsState.callHistory.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (callsState.error != null && callsState.callHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text(
                            'Error: ${callsState.error}',
                            style: const TextStyle(color: AppTheme.errorRed),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(callsProvider.notifier).loadCallHistory(refresh: true);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (callsState.callHistory.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No call history found',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: callsState.callHistory.length,
                    itemBuilder: (context, index) {
                      final call = callsState.callHistory[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCallLogCard(call),
                      );
                    },
                  ),
                if (callsState.hasMore && callsState.callHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: callsState.isLoadingMore
                          ? null
                          : () {
                              ref.read(callsProvider.notifier).loadCallHistory();
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderGrey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: callsState.isLoadingMore
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Load More Calls',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCallLogCard(CallHistoryModel call) {
    final statusIcon = _getStatusIcon(call.status);
    final statusColor = _getStatusColor(call.status);
    final statusLabel = _getStatusLabel(call.status);
    final duration = _formatDuration(call.durationSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.phoneNumber ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(call.startedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (call.recordingAvailable == true)
                IconButton(
                  icon: const Icon(
                    Icons.play_arrow,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  tooltip: 'Play Recording',
                  onPressed: () async {
                    _handleDownloadRecording(call.id);
                  },
                ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppTheme.mediumGrey,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'regenerate') {
                    _handleRegenerateSummary(call.id);
                  } else if (value == 'download') {
                    _handleDownloadRecording(call.id, force: true);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: AppTheme.darkGrey),
                        SizedBox(width: 8),
                        Text('Regenerate Summary'),
                      ],
                    ),
                  ),
                  if (call.recordingAvailable == true)
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 18, color: AppTheme.darkGrey),
                          SizedBox(width: 8),
                          Text('Force Download Recording'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mediumGrey,
                ),
              ),
              if (call.callType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    call.callType!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
            ],
          ),
          if (call.summary != null || call.humanNotesText != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showNotesDialog(call);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderGrey),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  'View Notes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNotesDialog(CallHistoryModel call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Call Notes - ${call.phoneNumber ?? "Unknown"}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (call.summary != null) ...[
                const Text(
                  'Summary:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(call.summary!),
                const SizedBox(height: 16),
              ],
              if (call.humanNotesText != null) ...[
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(call.humanNotesText!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadRecording(String callId, {bool force = false}) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Downloading recording...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final result = await ref.read(callsProvider.notifier).downloadRecording(callId, force: force);
      
      // Dismiss loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (result != null && mounted) {
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String?;
        final s3Url = result['s3_recording_url'] as String?;
        final error = result['error'] as String?;

        if (success && s3Url != null) {
          final uri = Uri.tryParse(s3Url);
          if (uri != null) {
            canLaunchUrl(uri).then((canLaunch) {
              if (canLaunch) launchUrl(uri, mode: LaunchMode.externalApplication);
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Recording URL generated successfully'),
              backgroundColor: AppTheme.successGreen,
              action: SnackBarAction(
                label: 'Play Audio',
                textColor: Colors.white,
                onPressed: () async {
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? message ?? 'Failed to download recording'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download recording'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleRegenerateSummary(String callId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Summary'),
        content: const Text(
          'This will regenerate the AI summary, sentiment, and analysis for this call. '
          'The existing summary will be replaced. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Regenerating summary...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final result = await ref.read(callsProvider.notifier).regenerateSummary(callId);
      
      // Dismiss loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (result != null) {
          final success = result['success'] as bool? ?? false;
          final message = result['message'] as String?;
          final error = result['error'] as String?;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message ?? 'Summary regenerated successfully'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? message ?? 'Failed to regenerate summary'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to regenerate summary'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'in_progress':
        return Icons.phone_in_talk;
      case 'no_answer':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.successGreen;
      case 'failed':
        return AppTheme.errorRed;
      case 'in_progress':
        return AppTheme.primaryGreen;
      case 'no_answer':
        return AppTheme.warningOrange;
      default:
        return AppTheme.mediumGrey;
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'Unknown';
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '0m 0s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }
}
