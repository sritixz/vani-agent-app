import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/integration_model.dart';
import 'package:vani_app/presentation/providers/integrations_provider.dart';

class CreateWhatsAppDialog extends ConsumerStatefulWidget {
  final WhatsAppConnection? connection; // null for create, non-null for edit

  const CreateWhatsAppDialog({
    super.key,
    this.connection,
  });

  @override
  ConsumerState<CreateWhatsAppDialog> createState() =>
      _CreateWhatsAppDialogState();
}

class _CreateWhatsAppDialogState extends ConsumerState<CreateWhatsAppDialog> {
  final _formKey = GlobalKey<FormState>();
  final _businessPhoneIdController = TextEditingController();
  final _apiTokenController = TextEditingController();
  final _businessAccountIdController = TextEditingController();
  final _appIdController = TextEditingController();
  final _appSecretController = TextEditingController();
  bool _isActive = true;
  bool _whatsappAgentEnabled = false;
  bool _isLoading = false;
  bool _obscureToken = true;
  bool _obscureSecret = true;

  @override
  void initState() {
    super.initState();
    if (widget.connection != null) {
      // Edit mode - populate fields
      _businessPhoneIdController.text = widget.connection!.businessPhoneId;
      _apiTokenController.text = widget.connection!.apiToken;
      _businessAccountIdController.text =
          widget.connection!.businessAccountId ?? '';
      _appIdController.text = widget.connection!.appId ?? '';
      _appSecretController.text = widget.connection!.appSecret ?? '';
      _isActive = widget.connection!.isActive;
      _whatsappAgentEnabled = widget.connection!.whatsappAgentEnabled;
    }
  }

  @override
  void dispose() {
    _businessPhoneIdController.dispose();
    _apiTokenController.dispose();
    _businessAccountIdController.dispose();
    _appIdController.dispose();
    _appSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.connection != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat_bubble,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? 'Edit WhatsApp Connection'
                                  : 'WhatsApp Business API',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enter your Meta WhatsApp Cloud API credentials',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.mediumGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Business Phone ID
                  const Text(
                    'BUSINESS PHONE ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _businessPhoneIdController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 123456789012345',
                      hintStyle: const TextStyle(color: AppTheme.mediumGrey),
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
                        borderSide:
                            const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey.withOpacity(0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Business Phone ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // API Access Token
                  const Text(
                    'API ACCESS TOKEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiTokenController,
                    obscureText: _obscureToken,
                    decoration: InputDecoration(
                      hintText: '••••••••••••••',
                      hintStyle: const TextStyle(color: AppTheme.mediumGrey),
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
                        borderSide:
                            const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey.withOpacity(0.3),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureToken
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureToken = !_obscureToken;
                          });
                        },
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'API Access Token is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Business Account ID
                  const Text(
                    'WHATSAPP BUSINESS ACCOUNT ID (required to load templates)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _businessAccountIdController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 123456789012345',
                      hintStyle: const TextStyle(color: AppTheme.mediumGrey),
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
                        borderSide:
                            const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Webhook Security Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningOrange.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.warningOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Required for Webhook Security',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkGrey,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'App ID and App Secret are ',
                              ),
                              TextSpan(
                                text: 'required to receive incoming messages',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' via webhook. Without these, Meta\'s webhook signature verification will fail. Sending messages works without them.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta App ID
                  const Text(
                    'META APP ID *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _appIdController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 3478022413825768',
                      hintStyle: const TextStyle(color: AppTheme.mediumGrey),
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
                        borderSide:
                            const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meta App Secret
                  const Text(
                    'META APP SECRET *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _appSecretController,
                    obscureText: _obscureSecret,
                    decoration: InputDecoration(
                      hintText: 'From App Dashboard → Settings → Basic',
                      hintStyle: const TextStyle(color: AppTheme.mediumGrey),
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
                        borderSide:
                            const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey.withOpacity(0.3),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecret
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureSecret = !_obscureSecret;
                          });
                        },
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings
                  if (isEdit) ...[
                    SwitchListTile(
                      title: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Enable or disable this connection',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppTheme.primaryGreen,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text(
                        'WhatsApp AI Agent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'Enable AI-powered automatic responses',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _whatsappAgentEnabled,
                      onChanged: (value) {
                        setState(() {
                          _whatsappAgentEnabled = value;
                        });
                      },
                      activeColor: AppTheme.primaryGreen,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppTheme.borderGrey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  isEdit ? 'Update' : 'Save & Verify',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.surfaceCard,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isEdit = widget.connection != null;

      if (isEdit) {
        // Update existing connection
        final success =
            await ref.read(integrationsProvider.notifier).updateWhatsAppConnection(
                  connectionId: widget.connection!.id,
                  businessPhoneId: _businessPhoneIdController.text.trim(),
                  apiToken: _apiTokenController.text.trim(),
                  businessAccountId: _businessAccountIdController.text.trim().isEmpty
                      ? null
                      : _businessAccountIdController.text.trim(),
                  appId: _appIdController.text.trim().isEmpty
                      ? null
                      : _appIdController.text.trim(),
                  appSecret: _appSecretController.text.trim().isEmpty
                      ? null
                      : _appSecretController.text.trim(),
                  isActive: _isActive,
                  whatsappAgentEnabled: _whatsappAgentEnabled,
                );

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp connection updated successfully'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ref.read(integrationsProvider).error ??
                      'Failed to update connection',
                ),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
      } else {
        // Create new connection
        final request = CreateWhatsAppConnectionRequest(
          businessPhoneId: _businessPhoneIdController.text.trim(),
          apiToken: _apiTokenController.text.trim(),
          businessAccountId: _businessAccountIdController.text.trim().isEmpty
              ? null
              : _businessAccountIdController.text.trim(),
          appId: _appIdController.text.trim().isEmpty
              ? null
              : _appIdController.text.trim(),
          appSecret: _appSecretController.text.trim().isEmpty
              ? null
              : _appSecretController.text.trim(),
        );

        final connection = await ref
            .read(integrationsProvider.notifier)
            .createWhatsAppConnection(request);

        if (mounted) {
          if (connection != null) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('WhatsApp connection created successfully'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ref.read(integrationsProvider).error ??
                      'Failed to create connection',
                ),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
