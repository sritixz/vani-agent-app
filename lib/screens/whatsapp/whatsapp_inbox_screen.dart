import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/whatsapp_conversation_model.dart';
import 'package:vani_app/presentation/providers/whatsapp_provider.dart';
import 'package:vani_app/screens/whatsapp/whatsapp_conversation_screen.dart';
import 'package:vani_app/utils/date_time_utils.dart';
import 'package:intl/intl.dart';

enum InboxFilter { all, open24h, closed }

// Lead status colors
class LeadStatusColors {
  static Color getColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return const Color(0xFF6B7280); // Gray
      case LeadStatus.attempting:
        return const Color(0xFFFBBF24); // Yellow
      case LeadStatus.connected:
        return const Color(0xFF3B82F6); // Blue
      case LeadStatus.interested:
        return const Color(0xFF10B981); // Green
      case LeadStatus.qualified:
        return const Color(0xFF8B5CF6); // Purple
      case LeadStatus.converted:
        return const Color(0xFF059669); // Teal/Green
      case LeadStatus.notInterested:
        return const Color(0xFFEF4444); // Red
      case LeadStatus.junkDnc:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

class WhatsAppInboxScreen extends ConsumerStatefulWidget {
  const WhatsAppInboxScreen({super.key});

  @override
  ConsumerState<WhatsAppInboxScreen> createState() => _WhatsAppInboxScreenState();
}

class _WhatsAppInboxScreenState extends ConsumerState<WhatsAppInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  InboxFilter _selectedFilter = InboxFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIntegrationAndLoad();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkIntegrationAndLoad() async {
    // First check if integration exists
    await ref.read(whatsappProvider.notifier).checkIntegrationStatus();
    
    final hasIntegration = ref.read(whatsappProvider).hasIntegration;
    
    if (!hasIntegration && mounted) {
      // No integration, redirect to integrations page
      Navigator.pushReplacementNamed(context, '/integrations');
      return;
    }
    
    // Integration exists, load conversations
    ref.read(whatsappProvider.notifier).loadConversations();
  }

  /// Apply search query and filter to conversations
  List<WhatsAppConversation> _getFilteredConversations(List<WhatsAppConversation> conversations) {
    return conversations.where((conv) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final number = conv.contactNumber.toLowerCase();
        final displayNum = conv.displayNumber.toLowerCase();
        if (!number.contains(_searchQuery) && !displayNum.contains(_searchQuery)) {
          return false;
        }
      }

      // Apply status filter
      switch (_selectedFilter) {
        case InboxFilter.all:
          return true;
        case InboxFilter.open24h:
          return conv.inFreeWindow;
        case InboxFilter.closed:
          return !conv.inFreeWindow;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final whatsappState = ref.watch(whatsappProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'WhatsApp Inbox',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              ref.read(whatsappProvider.notifier).loadConversations();
            },
            color: AppTheme.mediumGrey,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar and filter chips
            _buildSearchAndFilters(),
            // Conversation list
            Expanded(
              child: _buildConversationsList(whatsappState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppTheme.surfaceCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search phone number...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppTheme.inactiveGrey,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.inactiveGrey,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppTheme.mediumGrey,
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.lightGrey,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              _buildFilterChip('All', InboxFilter.all),
              const SizedBox(width: 8),
              _buildFilterChip('24h Open', InboxFilter.open24h),
              const SizedBox(width: 8),
              _buildFilterChip('Closed', InboxFilter.closed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, InboxFilter filter) {
    final isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.mediumGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList(WhatsAppState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading conversations',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(whatsappProvider.notifier).loadConversations();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: AppTheme.mediumGrey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start a conversation to see it here',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final filteredConversations = _getFilteredConversations(state.conversations);

    if (filteredConversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 48,
                color: AppTheme.mediumGrey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'No matching conversations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term or filter'
                    : 'No conversations match the selected filter',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WhatsAppConversationScreen(
                  conversationId: conversation.id,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGrey),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      conversation.initials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.surfaceCard,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.displayNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                          ),
                          if (conversation.lastMessageAt != null)
                            Text(
                              _formatTime(conversation.lastMessageAt!),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Last message or tags
                      if (conversation.tags.isNotEmpty)
                        Text(
                          conversation.tags.join(', '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.mediumGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          conversation.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: conversation.lastMessage != null
                                ? AppTheme.mediumGrey
                                : AppTheme.mediumGrey.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      // Status badges row
                      Row(
                        children: [
                          // Window status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: conversation.inFreeWindow
                                  ? AppTheme.primaryGreen.withOpacity(0.1)
                                  : AppTheme.mediumGrey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              conversation.inFreeWindow ? '24h open' : 'Closed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: conversation.inFreeWindow
                                    ? AppTheme.primaryGreen
                                    : AppTheme.mediumGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Lead status dropdown (prevent tap propagation)
                          GestureDetector(
                            onTap: () {}, // Prevent row tap
                            child: _buildLeadStatusDropdown(conversation),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    // Convert UTC to IST (GMT+5:30)
    final istDateTime = DateTimeUtils.toIST(dateTime);
    final now = DateTime.now();
    final difference = now.difference(istDateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(istDateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(istDateTime);
    } else {
      return DateFormat('dd/MM/yy').format(istDateTime);
    }
  }

  Widget _buildLeadStatusDropdown(WhatsAppConversation conversation) {
    final statusColor = LeadStatusColors.getColor(conversation.leadStatus);

    return PopupMenuButton<LeadStatus>(
      onSelected: (LeadStatus newStatus) {
        ref.read(whatsappProvider.notifier).updateLeadStatus(
              conversationId: conversation.id,
              status: newStatus,
            );
      },
      offset: const Offset(0, 35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (BuildContext context) {
        return LeadStatus.values.map((LeadStatus status) {
          final color = LeadStatusColors.getColor(status);
          return PopupMenuItem<LeadStatus>(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  status.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              conversation.leadStatus.displayName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGrey,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppTheme.mediumGrey,
            ),
          ],
        ),
      ),
    );
  }
}

