import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/integration_model.dart';
import 'package:vani_app/presentation/providers/integrations_provider.dart';

class CreateMetaDialog extends ConsumerStatefulWidget {
  final MetaConnection? connection; // null for create, non-null for edit

  const CreateMetaDialog({
    super.key,
    this.connection,
  });

  @override
  ConsumerState<CreateMetaDialog> createState() => _CreateMetaDialogState();
}

class _CreateMetaDialogState extends ConsumerState<CreateMetaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _appIdController = TextEditingController();
  final _appSecretController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _pageIdController = TextEditingController();
  final _adAccountIdController = TextEditingController();
  final _instagramActorIdController = TextEditingController();
  final _businessIdController = TextEditingController();
  final _pixelIdController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  bool _obscureSecret = true;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    if (widget.connection != null) {
      // Edit mode - populate fields
      _appIdController.text = widget.connection!.appId;
      _appSecretController.text = widget.connection!.appSecret;
      _accessTokenController.text = widget.connection!.accessToken;
      _pageIdController.text = widget.connection!.pageId ?? '';
      _adAccountIdController.text = widget.connection!.adAccountId ?? '';
      _instagramActorIdController.text =
          widget.connection!.instagramActorId ?? '';
      _businessIdController.text = widget.connection!.businessId ?? '';
      _pixelIdController.text = widget.connection!.pixelId ?? '';
      _isActive = widget.connection!.isActive;
    }
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _appSecretController.dispose();
    _accessTokenController.dispose();
    _pageIdController.dispose();
    _adAccountIdController.dispose();
    _instagramActorIdController.dispose();
    _businessIdController.dispose();
    _pixelIdController.dispose();
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
                          color: const Color(0x1A1877F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.facebook,
                          color: Color(0xFF1877F2),
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
                                  ? 'Edit Meta Connection'
                                  : 'Meta (Facebook) API',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enter your Meta Business API credentials',
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

                  // App ID
                  const Text(
                    'APP ID *',
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
                        return 'App ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // App Secret
                  const Text(
                    'APP SECRET *',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'App Secret is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Access Token
                  const Text(
                    'ACCESS TOKEN *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _accessTokenController,
                    obscureText: _obscureToken,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Long-lived access token',
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
                        return 'Access Token is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Optional Fields Section
                  const Text(
                    'OPTIONAL FIELDS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add these for specific Meta services',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Page ID
                  const Text(
                    'PAGE ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pageIdController,
                    decoration: InputDecoration(
                      hintText: 'Facebook Page ID',
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

                  // Ad Account ID
                  const Text(
                    'AD ACCOUNT ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _adAccountIdController,
                    decoration: InputDecoration(
                      hintText: 'e.g. act_123456789',
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

                  // Instagram Actor ID
                  const Text(
                    'INSTAGRAM ACTOR ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _instagramActorIdController,
                    decoration: InputDecoration(
                      hintText: 'Instagram Business Account ID',
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

                  // Business ID
                  const Text(
                    'BUSINESS ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _businessIdController,
                    decoration: InputDecoration(
                      hintText: 'Meta Business Manager ID',
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

                  // Pixel ID
                  const Text(
                    'PIXEL ID',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pixelIdController,
                    decoration: InputDecoration(
                      hintText: 'Facebook Pixel ID',
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
                            backgroundColor: const Color(0xFF1877F2),
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
            await ref.read(integrationsProvider.notifier).updateMetaConnection(
                  connectionId: widget.connection!.id,
                  appId: _appIdController.text.trim(),
                  appSecret: _appSecretController.text.trim(),
                  accessToken: _accessTokenController.text.trim(),
                  pageId: _pageIdController.text.trim().isEmpty
                      ? null
                      : _pageIdController.text.trim(),
                  adAccountId: _adAccountIdController.text.trim().isEmpty
                      ? null
                      : _adAccountIdController.text.trim(),
                  instagramActorId:
                      _instagramActorIdController.text.trim().isEmpty
                          ? null
                          : _instagramActorIdController.text.trim(),
                  businessId: _businessIdController.text.trim().isEmpty
                      ? null
                      : _businessIdController.text.trim(),
                  pixelId: _pixelIdController.text.trim().isEmpty
                      ? null
                      : _pixelIdController.text.trim(),
                  isActive: _isActive,
                );

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meta connection updated successfully'),
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
        final request = CreateMetaConnectionRequest(
          appId: _appIdController.text.trim(),
          appSecret: _appSecretController.text.trim(),
          accessToken: _accessTokenController.text.trim(),
          pageId: _pageIdController.text.trim().isEmpty
              ? null
              : _pageIdController.text.trim(),
          adAccountId: _adAccountIdController.text.trim().isEmpty
              ? null
              : _adAccountIdController.text.trim(),
          instagramActorId: _instagramActorIdController.text.trim().isEmpty
              ? null
              : _instagramActorIdController.text.trim(),
          businessId: _businessIdController.text.trim().isEmpty
              ? null
              : _businessIdController.text.trim(),
          pixelId: _pixelIdController.text.trim().isEmpty
              ? null
              : _pixelIdController.text.trim(),
        );

        final connection = await ref
            .read(integrationsProvider.notifier)
            .createMetaConnection(request);

        if (mounted) {
          if (connection != null) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meta connection created successfully'),
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
