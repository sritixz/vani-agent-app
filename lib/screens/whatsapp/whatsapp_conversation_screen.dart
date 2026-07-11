import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/presentation/providers/whatsapp_provider.dart';
import 'package:vani_app/models/whatsapp_conversation_model.dart';
import 'package:vani_app/utils/date_time_utils.dart';
import 'package:intl/intl.dart';

class WhatsAppConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const WhatsAppConversationScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<WhatsAppConversationScreen> createState() =>
      _WhatsAppConversationScreenState();
}

class _WhatsAppConversationScreenState
    extends ConsumerState<WhatsAppConversationScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(whatsappProvider.notifier).loadConversation(widget.conversationId);
      final conv = ref.read(whatsappProvider).selectedConversation;
      if (conv != null) {
        ref.read(whatsappProvider.notifier).loadTemplates(conv.connectionId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final whatsappState = ref.watch(whatsappProvider);
    final conversation = whatsappState.selectedConversation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: conversation != null
            ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        conversation.initials,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.surfaceCard,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.displayNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        Row(
                          children: [
                            if (conversation.inFreeWindow)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Free Window',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ),
                            if (conversation.aiEnabled)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AI Enabled',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Text('Loading...'),
        actions: [
          if (conversation != null)
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: () {
                _showSettingsDialog(conversation);
              },
              color: AppTheme.mediumGrey,
            ),
        ],
      ),
      body: conversation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Messages
                Expanded(
                  child: _buildMessagesList(conversation),
                ),
                // Message Input
                if (conversation.inFreeWindow)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      border: Border(
                        top: BorderSide(color: AppTheme.borderGrey),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: AppTheme.borderGrey),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(conversation.id),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: whatsappState.isSendingMessage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            onPressed: whatsappState.isSendingMessage
                                ? null
                                : () => _sendMessage(conversation.id),
                            color: AppTheme.primaryGreen,
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withOpacity(0.1),
                      border: Border(
                        top: BorderSide(color: AppTheme.borderGrey),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.warningOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Free messaging window closed. Use templates to send messages.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Extract text content from a message map, trying multiple common field names
  String _extractMessageText(Map<String, dynamic> message) {
    // Direct top-level fields
    if (message['text'] is String && (message['text'] as String).isNotEmpty) {
      return message['text'] as String;
    }
    if (message['body'] is String && (message['body'] as String).isNotEmpty) {
      return message['body'] as String;
    }
    if (message['content'] is String && (message['content'] as String).isNotEmpty) {
      return message['content'] as String;
    }
    if (message['message'] is String && (message['message'] as String).isNotEmpty) {
      return message['message'] as String;
    }
    if (message['message_text'] is String && (message['message_text'] as String).isNotEmpty) {
      return message['message_text'] as String;
    }

    // Nested structures: text.body, body.text, content.text
    if (message['text'] is Map) {
      final textMap = message['text'] as Map;
      if (textMap['body'] is String) return textMap['body'] as String;
    }
    if (message['body'] is Map) {
      final bodyMap = message['body'] as Map;
      if (bodyMap['text'] is String) return bodyMap['text'] as String;
    }
    if (message['content'] is Map) {
      final contentMap = message['content'] as Map;
      if (contentMap['text'] is String) return contentMap['text'] as String;
      if (contentMap['body'] is String) return contentMap['body'] as String;
    }

    // Template messages
    if (message['template'] is Map) {
      final tmpl = message['template'] as Map;
      return '[Template: ${tmpl['name'] ?? 'message'}]';
    }
    if (message['type'] == 'template') {
      return '[Template message]';
    }

    // Fallback: show message type if available
    if (message['type'] is String) {
      return '[${message['type']} message]';
    }

    return '';
  }

  /// Extract direction from a message map
  bool _isMessageOutbound(Map<String, dynamic> message) {
    final direction = message['direction']?.toString().toLowerCase();
    if (direction == 'outbound' || direction == 'out' || direction == 'sent') {
      return true;
    }
    // Some APIs use 'type' for direction
    final type = message['type']?.toString().toLowerCase();
    if (type == 'outbound' || type == 'sent') return true;
    // Some APIs use 'from' vs 'to' or 'sender'
    final sender = message['sender']?.toString().toLowerCase();
    if (sender == 'business' || sender == 'bot' || sender == 'agent') return true;

    return false;
  }

  /// Extract timestamp from a message map
  String _extractTimestamp(Map<String, dynamic> message) {
    // Try various timestamp field names
    final tsFields = ['timestamp', 'created_at', 'sent_at', 'time', 'date'];
    for (final field in tsFields) {
      if (message[field] != null) {
        try {
          final dt = DateTime.parse(message[field].toString());
          return _formatMessageTime(dt);
        } catch (_) {
          // If it's a unix timestamp (number)
          if (message[field] is num) {
            final dt = DateTime.fromMillisecondsSinceEpoch(
              (message[field] as num).toInt() * 1000,
            );
            return _formatMessageTime(dt);
          }
        }
      }
    }
    return '';
  }

  Widget _buildMessagesList(WhatsAppConversationDetail conversation) {
    if (conversation.messages.isEmpty) {
      return _buildEmptyWithTemplates(conversation);
    }

    // Debug: print first message structure to help diagnose
    if (conversation.messages.isNotEmpty) {
      debugPrint('=== WhatsApp Message Structure ===');
      debugPrint('First message keys: ${conversation.messages.first.keys.toList()}');
      debugPrint('First message: ${conversation.messages.first}');
      debugPrint('=================================');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: conversation.messages.length,
      itemBuilder: (context, index) {
        final message =
            conversation.messages[conversation.messages.length - 1 - index];
        final isOutbound = _isMessageOutbound(message);
        final messageText = _extractMessageText(message);
        final timeText = _extractTimestamp(message);

        return Align(
          alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isOutbound ? AppTheme.primaryGreen : AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (messageText.isNotEmpty)
                  Text(
                    messageText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isOutbound ? Colors.white : AppTheme.darkGrey,
                    ),
                  )
                else
                  Text(
                    '[Message]',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isOutbound
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.mediumGrey,
                    ),
                  ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isOutbound
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildEmptyWithTemplates(WhatsAppConversationDetail conversation) {
    final whatsappState = ref.watch(whatsappProvider);
    final templates = whatsappState.templates;
    final isLoadingTemplates = whatsappState.isLoadingTemplates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.chat_outlined,
            size: 56,
            color: AppTheme.mediumGrey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a template message to start the conversation',
            style: TextStyle(fontSize: 14, color: AppTheme.mediumGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isLoadingTemplates)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (templates.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No approved templates found. Create templates in your Meta Business Suite.',
                style: TextStyle(fontSize: 13, color: AppTheme.mediumGrey),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggested Templates (${templates.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mediumGrey,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...templates.map((t) => _buildTemplateCard(t, conversation.id)),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, String conversationId) {
    final name = template['name'] ?? 'Unnamed';
    final language = template['language'] ?? '';
    final category = template['category'] ?? '';
    final status = template['status'] ?? '';
    final components = template['components'] as List<dynamic>? ?? [];

    // Extract body text from components
    String bodyText = '';
    for (final comp in components) {
      if (comp is Map && comp['type'] == 'BODY') {
        bodyText = comp['text'] ?? '';
        break;
      }
    }

    return GestureDetector(
      onTap: () => _sendTemplateMessage(conversationId, template),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            if (bodyText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bodyText,
                style: const TextStyle(fontSize: 13, color: AppTheme.mediumGrey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (category.isNotEmpty)
                  Text(
                    category,
                    style: const TextStyle(fontSize: 11, color: AppTheme.inactiveGrey),
                  ),
                const Spacer(),
                const Icon(Icons.send, size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 4),
                const Text(
                  'Tap to send',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTemplateMessage(String conversationId, Map<String, dynamic> template) async {
    final request = SendMessageRequest(
      messageType: 'template',
      templateName: template['name'],
      languageCode: template['language'] ?? 'en',
    );

    final success = await ref.read(whatsappProvider.notifier).sendMessage(
      conversationId: conversationId,
      request: request,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(whatsappProvider).error ?? 'Failed to send template'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _sendMessage(String conversationId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final request = SendMessageRequest(
      messageType: 'text',
      text: text,
    );

    final success = await ref.read(whatsappProvider.notifier).sendMessage(
          conversationId: conversationId,
          request: request,
        );

    if (success) {
      _messageController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                ref.read(whatsappProvider).error ?? 'Failed to send message'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showSettingsDialog(WhatsAppConversationDetail conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('AI Enabled'),
              subtitle: const Text('Enable AI responses for this conversation'),
              value: conversation.aiEnabled,
              onChanged: (value) {
                ref.read(whatsappProvider.notifier).updateConversationSettings(
                      conversationId: conversation.id,
                      aiEnabled: value,
                    );
                Navigator.pop(context);
              },
            ),
          ],
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

  String _formatMessageTime(DateTime dateTime) {
    // Convert UTC to IST (GMT+5:30)
    final istDateTime = DateTimeUtils.toIST(dateTime);
    return DateFormat('HH:mm').format(istDateTime);
  }
}
