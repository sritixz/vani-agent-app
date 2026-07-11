import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/integration_model.dart';
import 'package:vani_app/presentation/providers/integrations_provider.dart';

class CreateMetaScreen extends ConsumerStatefulWidget {
  final MetaConnection? connection; // null for create, non-null for edit

  const CreateMetaScreen({
    super.key,
    this.connection,
  });

  @override
  ConsumerState<CreateMetaScreen> createState() => _CreateMetaScreenState();
}

class _CreateMetaScreenState extends ConsumerState<CreateMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appIdController = TextEditingController();
  final _appSecretController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _pageIdController = TextEditingController();
  final _adAccountIdController = TextEditingController();
  final _instagramActorIdController = TextEditingController();
  final _businessIdController = TextEditingController();
  final _pixelIdController = TextEditingController();
  final _tokenTypeController = TextEditingController();
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
      _tokenTypeController.text = widget.connection!.tokenType ?? '';
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
    _tokenTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.connection != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Meta Connection' : 'Meta Business Integration',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: AppTheme.darkGrey,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.borderGrey,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x1A1877F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0x331877F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.facebook,
                            color: Color(0xFF1877F2),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta Business Integration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Connect your Meta Business account to access Facebook, Instagram, and advertising features.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mediumGrey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App ID
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
                      hintText: 'e.g. 1234567890123456',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'App ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // App Secret
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                  const SizedBox(height: 20),

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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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

                  // Optional Fields Section Header
                  const Text(
                    'OPTIONAL CONFIGURATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'These fields are optional but recommended for full functionality',
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
                      hintText: 'Facebook Page ID (optional)',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      hintText: 'e.g. act_1234567890 (optional)',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      hintText: 'Instagram Business Account ID (optional)',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      hintText: 'Meta Business Manager ID (optional)',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      hintText: 'Facebook Pixel ID (optional)',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Token Type
                  const Text(
                    'TOKEN TYPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tokenTypeController,
                    decoration: InputDecoration(
                      hintText: 'e.g. user, page, system (optional)',
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
                            const BorderSide(color: AppTheme.primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Where to Find These Values Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHERE TO FIND THESE VALUES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mediumGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          '• App ID & App Secret',
                          'Meta Developer Portal → Your App → Settings → Basic',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          '• Access Token',
                          'Meta Developer Portal → Tools → Access Token Tool (select appropriate permissions)',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          '• Page ID',
                          'Facebook Page → About → Page ID (scroll down)',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          '• Ad Account ID',
                          'Meta Business Manager → Business Settings → Accounts → Ad Accounts',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          '• Instagram Actor ID',
                          'Meta Business Manager → Business Settings → Accounts → Instagram Accounts',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          '• Business ID',
                          'Meta Business Manager → Business Settings → Business Info',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          '• Pixel ID',
                          'Meta Events Manager → Data Sources → Select your Pixel',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Settings
                  if (isEdit) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderGrey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
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
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Save Button
                  SizedBox(
                    width: double.infinity,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEdit ? 'Update Connection' : 'Save & Verify',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.surfaceCard,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
        final success = await ref
            .read(integrationsProvider.notifier)
            .updateMetaConnection(
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
              instagramActorId: _instagramActorIdController.text.trim().isEmpty
                  ? null
                  : _instagramActorIdController.text.trim(),
              businessId: _businessIdController.text.trim().isEmpty
                  ? null
                  : _businessIdController.text.trim(),
              pixelId: _pixelIdController.text.trim().isEmpty
                  ? null
                  : _pixelIdController.text.trim(),
              tokenType: _tokenTypeController.text.trim().isEmpty
                  ? null
                  : _tokenTypeController.text.trim(),
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
          tokenType: _tokenTypeController.text.trim().isEmpty
              ? null
              : _tokenTypeController.text.trim(),
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

  Widget _buildInfoItem(String title, String description) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.darkGrey,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' — '),
          TextSpan(text: description),
        ],
      ),
    );
  }
}
