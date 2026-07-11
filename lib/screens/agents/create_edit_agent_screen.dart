import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/agent_model.dart';
import 'package:vani_app/models/knowledge_base_model.dart';
import 'package:vani_app/presentation/providers/agents_provider.dart';
import 'package:vani_app/presentation/providers/phone_numbers_provider.dart';
import 'package:vani_app/presentation/providers/knowledge_provider.dart';
import 'package:vani_app/screens/agents/agent_analysis_config_screen.dart';

class CreateEditAgentScreen extends ConsumerStatefulWidget {
  final Agent? agent; // null for create, non-null for edit

  const CreateEditAgentScreen({super.key, this.agent});

  @override
  ConsumerState<CreateEditAgentScreen> createState() =>
      _CreateEditAgentScreenState();
}

class _CreateEditAgentScreenState extends ConsumerState<CreateEditAgentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _fixedGreetingController;
  late TextEditingController _variableGreetingController;
  late TextEditingController _agentPromptController;
  late TextEditingController _localFallbackPromptController;
  late TextEditingController _analysisPromptController;
  late TextEditingController _hardEndCallMinutesController;
  late TextEditingController _ttsSpeedController;
  late TextEditingController _simliFaceIdController;
  late TextEditingController _asrVocabularyController;
  late TextEditingController _vaniUltraPromptController;
  late TextEditingController _newKbNameController;
  late TextEditingController _newKbTextController;
  double _omniVoiceSpeechSpeed = 1.0;

  // Focus nodes to manage mutual exclusivity of greetings
  final FocusNode _fixedGreetingFocusNode = FocusNode();
  final FocusNode _variableGreetingFocusNode = FocusNode();

  // Form values
  String? _selectedPhoneNumberId;
  String _selectedVoice = 'alloy';
  String _selectedTtsLanguage = 'en';
  String _selectedTtsProvider = 'openai';
  String? _selectedGeminiLiveVoice = 'Puck';
  String? _selectedGeminiLiveLanguage = 'en-US';
  String _selectedGreetingType = 'fixed';
  bool _allowInterruptions = true;
  bool _backgroundMusic = false;
  bool _debugLogging = false;
  bool _isActive = true;
  bool _enableVideoAvatar = false;
  List<String> _transcriptionLanguages = ['en'];

  bool _isLoading = false;
  bool _isGeneratingAnalysis = false;
  bool _isGeneratingS2sPrompt = false;
  Map<String, dynamic>? _analysisConfig;

  // New fields for voice engine mapping
  String _selectedVoiceEngine = 'Classic Pipeline';

  // New fields for Call Analysis Mode
  String _analysisMode = 'default'; // 'default', 'structured', 'custom'

  // New fields for Knowledge Bases
  List<String> _selectedKnowledgeBaseIds = [];

  // Dropdown lists
  final List<String> _ttsProviders = [
    'pi_tts',
    'openai',
    'elevenlabs',
    'google',
    'azure',
    'inworld',
  ];
  final List<String> _voices = [
    'maya_female',
    'alloy',
    'echo',
    'fable',
    'onyx',
    'nova',
    'shimmer',
    'ashley',
  ];
  final List<String> _ttsLanguages = [
    'afrikaans',
    'en',
    'es',
    'fr',
    'de',
    'it',
    'pt',
    'hi',
    'ja',
    'ko',
    'zh',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values if editing
    _nameController = TextEditingController(text: widget.agent?.name ?? '');

    final greetingType = widget.agent?.greetingType ?? 'fixed';
    _selectedGreetingType = greetingType;

    _fixedGreetingController = TextEditingController(
      text: greetingType == 'fixed' ? widget.agent?.greetingLine ?? '' : '',
    );
    _variableGreetingController = TextEditingController(
      text: greetingType == 'variable' ? widget.agent?.greetingLine ?? '' : '',
    );

    _agentPromptController = TextEditingController(
      text: widget.agent?.agentPrompt ?? '',
    );
    _localFallbackPromptController = TextEditingController(
      text: widget.agent?.localFallbackPrompt ?? '',
    );
    _analysisPromptController = TextEditingController(
      text: widget.agent?.analysisPrompt ?? '',
    );
    _hardEndCallMinutesController = TextEditingController(
      text:
          widget.agent?.hardEndCallMinutes != null &&
              widget.agent!.hardEndCallMinutes > 0
          ? widget.agent!.hardEndCallMinutes.toString()
          : '',
    );
    _ttsSpeedController = TextEditingController(
      text: widget.agent?.ttsSpeed.toString() ?? '1.0',
    );
    _simliFaceIdController = TextEditingController(
      text: widget.agent?.simliFaceId ?? '',
    );
    _asrVocabularyController = TextEditingController(
      text: widget.agent?.asrVocabulary ?? '',
    );
    _newKbNameController = TextEditingController();
    _newKbTextController = TextEditingController();

    String initialS2sPrompt = '';
    if (widget.agent?.s2sPromptConfig != null) {
      initialS2sPrompt =
          (widget.agent!.s2sPromptConfig!['prompt'] ??
                  widget.agent!.s2sPromptConfig!['system_prompt'] ??
                  widget.agent!.s2sPromptConfig!['realtime_prompt'] ??
                  widget.agent!.s2sPromptConfig!['ultra_fast_prompt'] ??
                  widget.agent!.s2sPromptConfig!['ultra_fast_system_prompt'] ??
                  widget.agent!.s2sPromptConfig!['ultrafast_prompt'] ??
                  widget.agent!.s2sPromptConfig!['ultrafast_system_prompt'])
              as String? ??
          '';
    }
    _vaniUltraPromptController = TextEditingController(text: initialS2sPrompt);
    _omniVoiceSpeechSpeed = widget.agent?.ttsSpeed ?? 1.0;

    _selectedKnowledgeBaseIds = widget.agent?.knowledgeBaseIds ?? [];

    if (widget.agent != null) {
      _selectedPhoneNumberId = widget.agent!.phoneNumberId;
      _selectedVoice = widget.agent!.voice.toLowerCase();
      _selectedTtsLanguage = widget.agent!.ttsLanguage.toLowerCase();
      _selectedTtsProvider = widget.agent!.ttsProvider.toLowerCase();
      _selectedGeminiLiveVoice = widget.agent!.geminiLiveVoice ?? 'Puck';
      _selectedGeminiLiveLanguage = widget.agent!.geminiLiveLanguage ?? 'en-US';
      _allowInterruptions = widget.agent!.allowInterruptions;
      _backgroundMusic = widget.agent!.backgroundMusic;
      _debugLogging = widget.agent!.debugLogging;
      _isActive = widget.agent!.isActive;
      _enableVideoAvatar = widget.agent!.enableVideoAvatar;
      _transcriptionLanguages = widget.agent!.transcriptionLanguages ?? ['en'];
      _analysisConfig = widget.agent!.analysisConfig;

      _selectedVoiceEngine = widget.agent!.engineType;

      // Determine Analysis Mode
      if (_analysisConfig != null && _analysisConfig!.isNotEmpty) {
        _analysisMode = 'structured';
      } else if (_analysisPromptController.text.isNotEmpty) {
        _analysisMode = 'custom';
      } else {
        _analysisMode = 'default';
      }
    } else {
      // Set defaults for creation
      _selectedTtsProvider = 'pi_tts';
      _selectedVoice = 'maya_female';
      _selectedTtsLanguage = 'afrikaans';
    }

    // Set listeners for mutual exclusivity of greeting lines
    _fixedGreetingFocusNode.addListener(() {
      if (_fixedGreetingFocusNode.hasFocus) {
        setState(() {
          _selectedGreetingType = 'fixed';
        });
      }
    });

    _variableGreetingFocusNode.addListener(() {
      if (_variableGreetingFocusNode.hasFocus) {
        setState(() {
          _selectedGreetingType = 'variable';
        });
      }
    });

    _fixedGreetingController.addListener(() {
      if (_fixedGreetingController.text.isNotEmpty &&
          _variableGreetingController.text.isNotEmpty) {
        _variableGreetingController.clear();
      }
      if (_fixedGreetingController.text.isNotEmpty &&
          _selectedGreetingType != 'fixed') {
        setState(() {
          _selectedGreetingType = 'fixed';
        });
      }
      setState(() {}); // Rebuild for length counter
    });

    _variableGreetingController.addListener(() {
      if (_variableGreetingController.text.isNotEmpty &&
          _fixedGreetingController.text.isNotEmpty) {
        _fixedGreetingController.clear();
      }
      if (_variableGreetingController.text.isNotEmpty &&
          _selectedGreetingType != 'variable') {
        setState(() {
          _selectedGreetingType = 'variable';
        });
      }
      setState(() {}); // Rebuild for length counter
    });

    _agentPromptController.addListener(() {
      setState(() {}); // For token counter
    });

    _vaniUltraPromptController.addListener(() {
      setState(() {}); // For token counter
    });

    // Load phone numbers and knowledge bases
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phoneNumbersProvider.notifier).loadPhoneNumbers();
      ref.read(knowledgeProvider.notifier).loadKnowledgeBases();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fixedGreetingController.dispose();
    _variableGreetingController.dispose();
    _agentPromptController.dispose();
    _localFallbackPromptController.dispose();
    _analysisPromptController.dispose();
    _hardEndCallMinutesController.dispose();
    _ttsSpeedController.dispose();
    _simliFaceIdController.dispose();
    _asrVocabularyController.dispose();
    _vaniUltraPromptController.dispose();
    _newKbNameController.dispose();
    _newKbTextController.dispose();
    _fixedGreetingFocusNode.dispose();
    _variableGreetingFocusNode.dispose();
    super.dispose();
  }

  void _insertText(TextEditingController controller, String text) {
    final textValue = controller.text;
    final selection = controller.selection;

    if (selection.isValid && selection.start >= 0) {
      final start = selection.start;
      final end = selection.end;
      final newText = textValue.replaceRange(start, end, text);

      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start + text.length),
      );
    } else {
      // Append if no cursor selection
      controller.text = textValue + text;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }
  }

  void _clearDraft() {
    setState(() {
      _nameController.clear();
      _fixedGreetingController.clear();
      _variableGreetingController.clear();
      _agentPromptController.clear();
      _localFallbackPromptController.clear();
      _analysisPromptController.clear();
      _hardEndCallMinutesController.clear();
      _ttsSpeedController.text = '1.0';
      _simliFaceIdController.clear();

      _selectedPhoneNumberId = null;
      _selectedVoice = 'maya_female';
      _selectedTtsLanguage = 'afrikaans';
      _selectedTtsProvider = 'pi_tts';
      _selectedGeminiLiveVoice = 'Puck';
      _selectedGeminiLiveLanguage = 'en-US';
      _selectedGreetingType = 'fixed';
      _selectedVoiceEngine = 'Classic Pipeline';
      _analysisMode = 'default';
      _selectedKnowledgeBaseIds = [];
      _allowInterruptions = false;
      _backgroundMusic = false;
      _debugLogging = false;
      _isActive = true;
      _enableVideoAvatar = false;
      _analysisConfig = null;
    });
  }

  Future<void> _generateAnalysisPrompt() async {
    if (_agentPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an agent prompt first'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAnalysis = true);

    try {
      final analysisPrompt = await ref
          .read(agentsProvider.notifier)
          .generateAnalysisPrompt(_agentPromptController.text.trim());

      setState(() {
        _analysisPromptController.text = analysisPrompt;
        _isGeneratingAnalysis = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis prompt generated successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingAnalysis = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate analysis prompt: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String? _currentGreetingLine() {
    if (_selectedGreetingType == 'fixed' &&
        _fixedGreetingController.text.trim().isNotEmpty) {
      return _fixedGreetingController.text.trim();
    }
    if (_selectedGreetingType == 'variable' &&
        _variableGreetingController.text.trim().isNotEmpty) {
      return _variableGreetingController.text.trim();
    }
    return null;
  }

  Future<void> _generateS2sPrompt(String provider) async {
    if (_agentPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Classic Agent Prompt is empty'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isGeneratingS2sPrompt = true);

    try {
      final promptData = await ref
          .read(agentsProvider.notifier)
          .generateS2sSystemPrompt(
            provider: provider,
            agentPrompt: _agentPromptController.text.trim(),
            greetingLine: _currentGreetingLine(),
            greetingType: _selectedGreetingType,
            language: _selectedGeminiLiveLanguage ?? 'en-US',
            knowledgeBaseIds: _selectedKnowledgeBaseIds,
          );
      final systemPrompt = promptData['system_prompt'] as String? ?? '';
      if (systemPrompt.trim().isEmpty) {
        throw Exception('Generated realtime system prompt is empty');
      }

      setState(() {
        _vaniUltraPromptController.text = systemPrompt.trim();
        _isGeneratingS2sPrompt = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Realtime prompt generated successfully'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingS2sPrompt = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate realtime prompt: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _saveAgent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields before saving.'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Map Voice Engine details
      String? speechToSpeechProvider;
      String? geminiLiveVoice;
      String? geminiLiveLanguage;
      String ttsProvider = _selectedTtsProvider;
      String voice = _selectedVoice;
      String ttsLanguage = _selectedTtsLanguage;

      if (_selectedVoiceEngine == 'Vani Ultra') {
        speechToSpeechProvider = 'gemini_live';
        geminiLiveVoice = _selectedGeminiLiveVoice;
        geminiLiveLanguage = _selectedGeminiLiveLanguage;
        ttsProvider = 'google';
        voice = 'en-us-neural2-f';
        ttsLanguage = 'en-US';
      } else if (_selectedVoiceEngine == 'Ultra Realtime') {
        speechToSpeechProvider = 'openai_realtime';
        geminiLiveVoice = null;
        geminiLiveLanguage = null;
        ttsProvider = 'google';
        voice = 'en-us-neural2-f';
        ttsLanguage = 'en-US';
      } else {
        speechToSpeechProvider = null;
        geminiLiveVoice = null;
        geminiLiveLanguage = null;
      }

      // Map Greeting details
      String? greetingLine;
      if (_selectedGreetingType == 'fixed' &&
          _fixedGreetingController.text.trim().isNotEmpty) {
        greetingLine = _fixedGreetingController.text.trim();
      } else if (_selectedGreetingType == 'variable' &&
          _variableGreetingController.text.trim().isNotEmpty) {
        greetingLine = _variableGreetingController.text.trim();
      }

      // Map Analysis Config
      String? analysisPrompt;
      Map<String, dynamic>? analysisConfig;

      if (_analysisMode == 'default') {
        analysisPrompt = null;
        analysisConfig = null;
      } else if (_analysisMode == 'structured') {
        analysisPrompt = null;
        analysisConfig = _analysisConfig;
      } else if (_analysisMode == 'custom') {
        analysisPrompt = _analysisPromptController.text.trim().isEmpty
            ? null
            : _analysisPromptController.text.trim();
        analysisConfig = null;
      }

      final isRealtimeEngine =
          _selectedVoiceEngine == 'Vani Ultra' ||
          _selectedVoiceEngine == 'Ultra Realtime';
      final s2sConfigProvider = _selectedVoiceEngine == 'Ultra Realtime'
          ? 'openai_realtime'
          : 'gemini_live';
      final s2sGeneratorProvider = _selectedVoiceEngine == 'Ultra Realtime'
          ? 'openai'
          : 'gemini';
      final promptText = isRealtimeEngine
          ? _vaniUltraPromptController.text.trim()
          : _agentPromptController.text.trim();
      final agentPromptText = _agentPromptController.text.trim().isNotEmpty
          ? _agentPromptController.text.trim()
          : promptText;
      final realtimePromptConfig = {
        'provider': s2sConfigProvider,
        'generator_provider': s2sGeneratorProvider,
        'voice_engine': _selectedVoiceEngine,
        'engine_type': _selectedVoiceEngine,
        'prompt': promptText,
        'system_prompt': promptText,
        'systemPrompt': promptText,
        'realtime_prompt': promptText,
        'realtimePrompt': promptText,
        'ultra_fast_prompt': promptText,
        'ultra_fast_system_prompt': promptText,
        'ultrafast_prompt': promptText,
        'ultrafast_system_prompt': promptText,
        'native_speech_to_speech': {
          'provider': s2sConfigProvider,
          'system_prompt': promptText,
        },
        's2s': {'provider': s2sConfigProvider, 'system_prompt': promptText},
        if (_selectedVoiceEngine == 'Vani Ultra') ...{
          'gemini': {'provider': 'gemini', 'system_prompt': promptText},
          'gemini_live': {
            'provider': 'gemini_live',
            'system_prompt': promptText,
          },
        },
        if (_selectedVoiceEngine == 'Ultra Realtime') ...{
          'openai': {'provider': 'openai', 'system_prompt': promptText},
          'openai_realtime': {
            'provider': 'openai_realtime',
            'system_prompt': promptText,
          },
        },
        'ultra_fast': {
          'provider': s2sConfigProvider,
          'system_prompt': promptText,
        },
        'ultrafast': {
          'provider': s2sConfigProvider,
          'system_prompt': promptText,
        },
      };

      final agentData = {
        'name': _nameController.text.trim(),
        'voice_engine': _selectedVoiceEngine,
        'engine_type': _selectedVoiceEngine,
        'phone_number_id': _selectedPhoneNumberId,
        'voice': voice,
        'tts_language': ttsLanguage,
        'tts_provider': ttsProvider,
        'speech_to_speech_provider': speechToSpeechProvider,
        'gemini_live_voice': geminiLiveVoice,
        'gemini_live_language': geminiLiveLanguage,
        'greeting_type': _selectedGreetingType,
        'greeting_line': greetingLine,
        'agent_prompt': agentPromptText.isEmpty ? null : agentPromptText,
        'local_fallback_prompt':
            _localFallbackPromptController.text.trim().isEmpty
            ? null
            : _localFallbackPromptController.text.trim(),
        'analysis_prompt': analysisPrompt,
        'analysis_config': analysisConfig,
        'transcription_languages': _transcriptionLanguages,
        'knowledge_base_ids': _selectedKnowledgeBaseIds,
        'tts_speed': _selectedVoiceEngine == 'Vani Ultra'
            ? _omniVoiceSpeechSpeed
            : (double.tryParse(_ttsSpeedController.text) ?? 1.0),
        's2s_prompt_config': isRealtimeEngine ? realtimePromptConfig : {},
        'system_prompt': isRealtimeEngine ? promptText : null,
        'systemPrompt': isRealtimeEngine ? promptText : null,
        'realtime_prompt': isRealtimeEngine ? promptText : null,
        'realtimePrompt': isRealtimeEngine ? promptText : null,
        'ultra_fast_prompt': isRealtimeEngine ? promptText : null,
        'ultra_fast_system_prompt': isRealtimeEngine ? promptText : null,
        'ultrafast_prompt': isRealtimeEngine ? promptText : null,
        'ultrafast_system_prompt': isRealtimeEngine ? promptText : null,
        'asr_vocabulary':
            _selectedVoiceEngine == 'Vani Ultra' &&
                _asrVocabularyController.text.trim().isNotEmpty
            ? _asrVocabularyController.text.trim()
            : null,
        'allow_interruptions': _allowInterruptions,
        'background_music': _backgroundMusic,
        'debug_logging': _debugLogging,
        'is_frozen': widget.agent?.isFrozen ?? false,
        'hard_end_call_minutes':
            _hardEndCallMinutesController.text.trim().isEmpty
            ? null
            : (int.tryParse(_hardEndCallMinutesController.text.trim()) ?? 0),
        'is_active': _isActive,
        'enable_video_avatar': _enableVideoAvatar,
        'simli_face_id': _simliFaceIdController.text.trim().isEmpty
            ? null
            : _simliFaceIdController.text.trim(),
      };

      print('=== SAVE AGENT DEBUG ===');
      print('Is Editing: ${widget.agent != null}');
      print('Agent ID: ${widget.agent?.id}');
      print('Agent Data: $agentData');
      print('========================');

      if (isRealtimeEngine && promptText.isNotEmpty) {
        await ref
            .read(agentsProvider.notifier)
            .updatePromptGeneratorSystemPrompt(promptText);
      }

      if (widget.agent == null) {
        await ref.read(agentsProvider.notifier).createAgent(agentData);
      } else {
        await ref
            .read(agentsProvider.notifier)
            .updateAgent(widget.agent!.id, agentData);
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.agent == null
                  ? 'Agent created successfully'
                  : 'Agent updated successfully',
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('=== SAVE AGENT ERROR ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      setState(() => _isLoading = false);

      String errorMessage = 'Failed to save agent. Please try again.';
      try {
        // Try to extract the actual backend error message
        final dynamic err = e;
        if (err?.response?.data != null) {
          final data = err.response.data;
          if (data is Map) {
            errorMessage =
                data['detail']?.toString() ??
                data['message']?.toString() ??
                data['error']?.toString() ??
                errorMessage;
          } else if (data is String) {
            errorMessage = data;
          }
        } else {
          errorMessage = e
              .toString()
              .replaceAll('DioException [unknown]: ', '')
              .replaceAll('Exception: ', '');
        }
      } catch (_) {
        errorMessage = e
            .toString()
            .replaceAll('DioException [unknown]: ', '')
            .replaceAll('Exception: ', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showKnowledgeBaseSelection() {
    bool isCreatingNew = false;
    _newKbNameController.clear();
    _newKbTextController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final knowledgeState = ref.watch(knowledgeProvider);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isCreatingNew
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manage Knowledge Bases',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (knowledgeState.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(
                              color: Color(0xFF10B981),
                            ),
                          ),
                        )
                      else if (knowledgeState.knowledgeBases.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No knowledge bases found.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children: knowledgeState.knowledgeBases.map((kb) {
                              final isSelected = _selectedKnowledgeBaseIds
                                  .contains(kb.id);
                              return CheckboxListTile(
                                activeColor: const Color(0xFF10B981),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  kb.name,
                                  style: const TextStyle(
                                    color: AppTheme.darkGrey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (bool? checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      _selectedKnowledgeBaseIds.add(kb.id);
                                    } else {
                                      _selectedKnowledgeBaseIds.remove(kb.id);
                                    }
                                  });
                                  setState(
                                    () {},
                                  ); // Rebuild parent screen to update chips
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              isCreatingNew = true;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.borderGrey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add,
                            size: 16,
                            color: AppTheme.darkGrey,
                          ),
                          label: const Text(
                            'Create New Knowledge Base',
                            style: TextStyle(
                              color: AppTheme.darkGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Knowledge Base',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                isCreatingNew = false;
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      const Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _newKbNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter knowledge base name',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.borderGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.borderGrey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Text Content Field
                      const Text(
                        'Text Content',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _newKbTextController,
                        maxLines: 8,
                        minLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Enter your knowledge base content...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.borderGrey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.borderGrey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Footer Subtext
                      const Text(
                        'You can paste large amounts of content — it will be scrollable.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions Footer
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final name = _newKbNameController.text.trim();
                              final text = _newKbTextController.text.trim();
                              if (name.isEmpty || text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Name and Text Content are required',
                                    ),
                                    backgroundColor: Color(0xFFDC2626),
                                  ),
                                );
                                return;
                              }

                              try {
                                final newKb = await ref
                                    .read(knowledgeProvider.notifier)
                                    .createKnowledgeBase(name, text);
                                setModalState(() {
                                  _selectedKnowledgeBaseIds.add(newKb.id);
                                  isCreatingNew = false;
                                });
                                setState(
                                  () {},
                                ); // Rebuild parent screen to update chips
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Knowledge Base created successfully',
                                      ),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to create Knowledge Base: $e',
                                      ),
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Create Knowledge Base',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                isCreatingNew = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF1F5F9,
                              ), // slate-100
                              foregroundColor: const Color(
                                0xFF0F172A,
                              ), // slate-900
                              side: const BorderSide(color: AppTheme.borderGrey),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getTtsProviderName(String value) {
    switch (value) {
      case 'pi_tts':
        return 'Pi TTS';
      case 'openai':
        return 'OpenAI';
      case 'elevenlabs':
        return 'ElevenLabs';
      case 'google':
        return 'Google Cloud';
      case 'azure':
        return 'Microsoft Azure';
      case 'inworld':
        return 'Inworld';
      default:
        return value;
    }
  }

  String _getVoiceName(String value) {
    switch (value) {
      case 'maya_female':
        return 'Maya (Female)';
      default:
        return value[0].toUpperCase() + value.substring(1);
    }
  }

  String _getLanguageName(String value) {
    switch (value) {
      case 'afrikaans':
        return 'Afrikaans';
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
      case 'pt':
        return 'Portuguese';
      case 'hi':
        return 'Hindi';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'zh':
        return 'Chinese';
      default:
        return value.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumbersState = ref.watch(phoneNumbersProvider);
    final isEditing = widget.agent != null;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Voice Agent' : 'Create Voice Agent',
          style: const TextStyle(color: AppTheme.darkGrey),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Config Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agent Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Agent Name
                        _buildTextFieldLabel('Agent Name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an agent name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter agent name',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: AppTheme.lightGrey,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        _buildTextFieldLabel('Phone Number'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String?>(
                          value: _selectedPhoneNumberId,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.lightGrey,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                          hint: const Text(
                            'Select Phone Number',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Unassigned',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            ...phoneNumbersState.phoneNumbers.map((phone) {
                              return DropdownMenuItem<String?>(
                                value: phone.id,
                                child: Text(
                                  phone.phoneNumber ?? phone.id,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedPhoneNumberId = value);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Voice Engine Selection (Segmented Control style)
                        _buildTextFieldLabel('Voice Engine'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.borderGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildEngineTab('Classic Pipeline'),
                              _buildEngineTab('Vani Ultra'),
                              _buildEngineTab('Ultra Realtime'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Dynamic sections depending on selected voice engine
                        if (_selectedVoiceEngine == 'Classic Pipeline') ...[
                          // TTS Provider
                          _buildTextFieldLabel('TTS Provider'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedTtsProvider,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.lightGrey,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderGrey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderGrey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            items: _ttsProviders
                                .map(
                                  (provider) => DropdownMenuItem(
                                    value: provider,
                                    child: Text(
                                      _getTtsProviderName(provider),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null)
                                setState(() => _selectedTtsProvider = value);
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Per minutes charges depends on this value',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Row for TTS Language and Voice
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextFieldLabel('TTS Language'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _selectedTtsLanguage,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppTheme.lightGrey,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderGrey,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderGrey,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      items: _ttsLanguages
                                          .map(
                                            (lang) => DropdownMenuItem(
                                              value: lang,
                                              child: Text(
                                                _getLanguageName(lang),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null)
                                          setState(
                                            () => _selectedTtsLanguage = value,
                                          );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextFieldLabel('Voice'),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: _selectedVoice,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: AppTheme.lightGrey,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderGrey,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderGrey,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      items: _voices
                                          .map(
                                            (voice) => DropdownMenuItem(
                                              value: voice,
                                              child: Text(
                                                _getVoiceName(voice),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null)
                                          setState(
                                            () => _selectedVoice = value,
                                          );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Speed Control
                          _buildTextFieldLabel('TTS Speed'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _ttsSpeedController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter speed';
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return 'Enter valid speed';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '1.0',
                              filled: true,
                              fillColor: AppTheme.lightGrey,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderGrey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderGrey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ] else if (_selectedVoiceEngine == 'Vani Ultra') ...[
                          // Vani Ultra Realtime Configuration Card
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFAF9FF,
                              ), // Light purple background tint
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEDE9FE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Realtime Configuration',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(
                                          0xFF6D28D9,
                                        ), // Purple color
                                      ),
                                    ),
                                    _buildBadge(
                                      'Vani Ultra',
                                      const Color(0xFF6D28D9),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Row for SpeechGPU Language and Vani_TTS Voice
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildTextFieldLabel(
                                            'SpeechGPU Language',
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: _selectedGeminiLiveLanguage,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: AppTheme.lightGrey,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF6D28D9),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: 'en-IN',
                                                child: Text(
                                                  'English (India)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'en-US',
                                                child: Text(
                                                  'English (US)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'en-GB',
                                                child: Text(
                                                  'English (UK)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'hi-IN',
                                                child: Text(
                                                  'Hindi (India)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'es-ES',
                                                child: Text(
                                                  'Spanish (Spain)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null)
                                                setState(
                                                  () =>
                                                      _selectedGeminiLiveLanguage =
                                                          value,
                                                );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildTextFieldLabel(
                                            'Vani_TTS Voice',
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: _selectedGeminiLiveVoice,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: AppTheme.lightGrey,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF6D28D9),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: 'Puck',
                                                child: Text(
                                                  'English (Default)',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Aoede',
                                                child: Text(
                                                  'Maya (Female)',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Kore',
                                                child: Text(
                                                  'Kore (Female)',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Charon',
                                                child: Text(
                                                  'Charon (Male)',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Fenrir',
                                                child: Text(
                                                  'Fenrir (Male)',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null)
                                                setState(
                                                  () =>
                                                      _selectedGeminiLiveVoice =
                                                          value,
                                                );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // OmniVoice Speech Speed
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildTextFieldLabel(
                                          'OmniVoice Speech Speed ',
                                        ),
                                        const Text(
                                          '(0.5 - 2.0 · default 1.0)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _omniVoiceSpeechSpeed.toStringAsFixed(
                                            2,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkGrey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _omniVoiceSpeechSpeed = 1.0;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: const Color(0xFFCBD5E1),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              color: AppTheme.surfaceCard,
                                            ),
                                            child: const Text(
                                              'Reset',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFF7C3AED),
                                    inactiveTrackColor: const Color(0xFFE9D5FF),
                                    thumbColor: const Color(0xFF7C3AED),
                                    overlayColor: const Color(
                                      0xFF7C3AED,
                                    ).withOpacity(0.12),
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _omniVoiceSpeechSpeed,
                                    min: 0.5,
                                    max: 2.0,
                                    onChanged: (val) {
                                      setState(() {
                                        _omniVoiceSpeechSpeed = val;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Speech Recognition Keywords
                                Row(
                                  children: [
                                    _buildTextFieldLabel(
                                      'Speech Recognition Keywords ',
                                    ),
                                    const Text(
                                      '(optional · names, brands, jargon)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _asrVocabularyController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'e.g. This call is about Acme finance. Terms: KYC, EMI, SIP, Aadhaar, PAN, NEFT, RTGS.',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.lightGrey,
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderGrey,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderGrey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF7C3AED),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Primes the speech-to-text engine so domain names and jargon are transcribed more accurately. Keep it short — a framing sentence plus key terms (the model only reads the first ~800 characters).',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Vani Ultra Prompt Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEDE9FE),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Vani Ultra Prompt',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'Used only by native speech-to-speech calls. Generate from the Classic Agent Prompt, then edit freely.',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: _isGeneratingS2sPrompt
                                                ? null
                                                : () => _generateS2sPrompt(
                                                    'gemini',
                                                  ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFF3E8FF,
                                                ), // purple-100
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  if (_isGeneratingS2sPrompt)
                                                    const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                              0xFF7C3AED,
                                                            ),
                                                          ),
                                                    )
                                                  else
                                                    const Icon(
                                                      Icons.flash_on,
                                                      size: 12,
                                                      color: Color(0xFF7C3AED),
                                                    ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    _isGeneratingS2sPrompt
                                                        ? 'Generating'
                                                        : 'Generate from Classic',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF7C3AED),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          _buildVariableChip(
                                            '{contact_name}',
                                            _vaniUltraPromptController,
                                          ),
                                          _buildVariableChip(
                                            '{custom_instruction}',
                                            _vaniUltraPromptController,
                                          ),
                                          _buildVariableChip(
                                            '{{contact_name}}',
                                            _vaniUltraPromptController,
                                          ),
                                          _buildVariableChip(
                                            '{{custom_instruction}}',
                                            _vaniUltraPromptController,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Approx. tokens: ${(_vaniUltraPromptController.text.length ~/ 4)} / 3,000',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _vaniUltraPromptController,
                                        maxLines: 4,
                                        validator: (value) {
                                          if (_selectedVoiceEngine ==
                                                  'Vani Ultra' &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Vani Ultra prompt is required';
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Generate a realtime prompt from the Classic Agent Prompt, or write a compact provider-specific prompt here...',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'In realtime mode the selected provider handles the full speech conversation path.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7C3AED),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_selectedVoiceEngine ==
                            'Ultra Realtime') ...[
                          // Ultra Realtime Realtime Configuration Card
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFAF9FF,
                              ), // Light purple background tint
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEDE9FE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Realtime Configuration',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(
                                          0xFF6D28D9,
                                        ), // Purple color
                                      ),
                                    ),
                                    _buildBadge(
                                      'Ultra Realtime',
                                      const Color(0xFF6D28D9),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Row for Conversation Language and Select Voices
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildTextFieldLabel(
                                            'Conversation Language',
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            value: _selectedGeminiLiveLanguage,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: AppTheme.lightGrey,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF6D28D9),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: 'en-US',
                                                child: Text(
                                                  'English (US)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'en-IN',
                                                child: Text(
                                                  'English (India)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'en-GB',
                                                child: Text(
                                                  'English (UK)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'hi-IN',
                                                child: Text(
                                                  'Hindi (India)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'es-ES',
                                                child: Text(
                                                  'Spanish (Spain)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null)
                                                setState(
                                                  () =>
                                                      _selectedGeminiLiveLanguage =
                                                          value,
                                                );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildTextFieldLabel('Select Voices'),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            value: _selectedGeminiLiveVoice,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: AppTheme.lightGrey,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderGrey,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF6D28D9),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: 'Puck',
                                                child: Text(
                                                  'Puck (Default)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Charon',
                                                child: Text(
                                                  'Charon (Informative)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Kore',
                                                child: Text(
                                                  'Kore (Female)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Fenrir',
                                                child: Text(
                                                  'Fenrir (Male)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Aoede',
                                                child: Text(
                                                  'Aoede (Female)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Leda',
                                                child: Text(
                                                  'Leda (Female)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Orus',
                                                child: Text(
                                                  'Orus (Male)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const DropdownMenuItem(
                                                value: 'Zephyr',
                                                child: Text(
                                                  'Zephyr (Female)',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null)
                                                setState(
                                                  () =>
                                                      _selectedGeminiLiveVoice =
                                                          value,
                                                );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Puck - M, Charon - M, Kore - F, Fenrir - M, Aoede - F, Leda - F, Orus - M, Zephyr - F',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Ultra Realtime Prompt Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEDE9FE),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ultra Realtime Prompt',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'Used only by native speech-to-speech calls. Generate from the Classic Agent Prompt, then edit freely.',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: _isGeneratingS2sPrompt
                                                ? null
                                                : () => _generateS2sPrompt(
                                                    'openai',
                                                  ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFF3E8FF,
                                                ), // purple-100
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  if (_isGeneratingS2sPrompt)
                                                    const SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                              0xFF7C3AED,
                                                            ),
                                                          ),
                                                    )
                                                  else
                                                    const Icon(
                                                      Icons.flash_on,
                                                      size: 12,
                                                      color: Color(0xFF7C3AED),
                                                    ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    _isGeneratingS2sPrompt
                                                        ? 'Generating'
                                                        : 'Generate from Classic',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF7C3AED),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          _buildVariableChip(
                                            '{contact_name}',
                                            _vaniUltraPromptController,
                                          ),
                                          _buildVariableChip(
                                            '{custom_instruction}',
                                            _vaniUltraPromptController,
                                          ),
                                          _buildVariableChip(
                                            '{{contact_name}}',
                                            _vaniUltraPromptController,
                                          ),
                                          _buildVariableChip(
                                            '{{custom_instruction}}',
                                            _vaniUltraPromptController,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Approx. tokens: ${(_vaniUltraPromptController.text.length ~/ 4)} / 800',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _vaniUltraPromptController,
                                        maxLines: 4,
                                        validator: (value) {
                                          if (_selectedVoiceEngine ==
                                                  'Ultra Realtime' &&
                                              (value == null ||
                                                  value.trim().isEmpty)) {
                                            return 'Ultra Realtime prompt is required';
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Generate a realtime prompt from the Classic Agent Prompt, or write a compact provider-specific prompt here...',
                                          hintStyle: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'In realtime mode the selected provider handles the full speech conversation path.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7C3AED),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Attached Knowledge Base Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTextFieldLabel('Attached Knowledge Base'),
                            GestureDetector(
                              onTap: _showKnowledgeBaseSelection,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 12,
                                      color: Color(0xFF475569),
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Manage',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _showKnowledgeBaseSelection,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            child: _selectedKnowledgeBaseIds.isEmpty
                                ? const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Select knowledge bases...',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _selectedKnowledgeBaseIds.map((
                                      kbId,
                                    ) {
                                      final kbList = ref
                                          .watch(knowledgeProvider)
                                          .knowledgeBases;
                                      final kb = kbList.firstWhere(
                                        (k) => k.id == kbId,
                                        orElse: () => KnowledgeBase(
                                          id: kbId,
                                          name: 'Knowledge Base',
                                          userId: '',
                                          text: '',
                                          createdAt: '',
                                          updatedAt: '',
                                        ),
                                      );
                                      final kbName = kb.name;
                                      return Chip(
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: AppTheme.surfaceCard,
                                        side: const BorderSide(
                                          color: AppTheme.borderGrey,
                                        ),
                                        label: Text(
                                          kbName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF334155),
                                          ),
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedKnowledgeBaseIds.remove(
                                              kbId,
                                            );
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select which knowledge bases this agent should use. If none selected, the agent will not have specialized knowledge.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Greeting Line Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Greeting Line',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Set exactly one greeting — either Fixed or Variable. Fill one and leave the other empty.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fixed greeting
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedGreetingType == 'fixed'
                                ? AppTheme.lightGreen.withOpacity(0.4)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedGreetingType == 'fixed'
                                  ? AppTheme.primaryGreen.withOpacity(0.5)
                                  : AppTheme.borderGrey,
                              width: _selectedGreetingType == 'fixed' ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Fixed greeting',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${_fixedGreetingController.text.length}/100',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fixedGreetingController,
                                focusNode: _fixedGreetingFocusNode,
                                maxLines: 2,
                                maxLength: 100,
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => const SizedBox.shrink(),
                                decoration: const InputDecoration(
                                  hintText: 'Hello, how can I help you today?',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Spoken exactly as written and pre-recorded. Cannot contain variables like {contact_name}.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Variable greeting
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selectedGreetingType == 'variable'
                                ? AppTheme.lightGreen.withOpacity(0.4)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedGreetingType == 'variable'
                                  ? AppTheme.primaryGreen.withOpacity(0.5)
                                  : AppTheme.borderGrey,
                              width: _selectedGreetingType == 'variable'
                                  ? 1.5
                                  : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Variable greeting',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${_variableGreetingController.text.length}/100',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _variableGreetingController,
                                focusNode: _variableGreetingFocusNode,
                                maxLines: 2,
                                maxLength: 100,
                                buildCounter:
                                    (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      maxLength,
                                    }) => const SizedBox.shrink(),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Hello {contact_name}, this is Anushka calling...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildVariableChip(
                                    '{contact_name}',
                                    _variableGreetingController,
                                  ),
                                  _buildVariableChip(
                                    '{custom_instruction}',
                                    _variableGreetingController,
                                  ),
                                  _buildVariableChip(
                                    '{campaign_name}',
                                    _variableGreetingController,
                                  ),
                                  _buildVariableChip(
                                    '{phone_number}',
                                    _variableGreetingController,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Personalized per call. {...} placeholders are filled at call time (and removed cleanly if a value is empty).',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Classic Agent Prompt Card — only visible for Classic Pipeline
                  if (_selectedVoiceEngine == 'Classic Pipeline') ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderGrey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Classic Agent Prompt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildVariableChip(
                                '{contact_name}',
                                _agentPromptController,
                              ),
                              _buildVariableChip(
                                '{custom_instruction}',
                                _agentPromptController,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _agentPromptController,
                            maxLines: 6,
                            validator: (value) {
                              if (_selectedVoiceEngine == 'Classic Pipeline' &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Classic agent prompt is required';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Describe how your agent should behave...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.lightGrey,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderGrey,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderGrey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Used by the Classic Pipeline. Only the active mode\'s prompt is stored per agent.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Approx. tokens: ${(_agentPromptController.text.length ~/ 4)} / 3,000',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Call Analysis Configuration Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call Analysis Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Configure how call transcripts are analyzed. Choose default system analysis, structured fields (recommended), or custom prompts (advanced).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Custom Styled Radios
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnalysisRadioCard(
                                'default',
                                'Default',
                                'SYSTEM',
                                const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildAnalysisRadioCard(
                                'structured',
                                'Structured Fields',
                                'RECOMMENDED',
                                AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnalysisRadioCard(
                                'custom',
                                'Custom Prompt',
                                'ADVANCED',
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Contextual Panel
                        if (_analysisMode == 'default') ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // blue-50
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'System Default Analysis',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Uses the platform\'s built-in call analysis with standard fields: sentiment, summary, outcome, key points, and action items.\n\nNo configuration needed. The system will automatically analyze calls using proven analysis patterns.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_analysisMode == 'structured') ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9F5), // green-50
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD1FAE5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Structured Fields Configuration',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final config =
                                            await Navigator.push<
                                              Map<String, dynamic>
                                            >(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AgentAnalysisConfigScreen(
                                                      agentPrompt:
                                                          _agentPromptController
                                                              .text
                                                              .trim(),
                                                      existingConfig:
                                                          _analysisConfig,
                                                    ),
                                              ),
                                            );
                                        if (config != null && mounted) {
                                          setState(() {
                                            _analysisConfig = config;
                                          });
                                        }
                                      },
                                      child: Text(
                                        _analysisConfig != null
                                            ? 'Configure'
                                            : 'Setup',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _analysisConfig != null
                                      ? 'Custom fields rules configured. Includes ${_analysisConfig!['custom_fields']?.length ?? 0} custom fields.'
                                      : 'No structured rules defined yet. Click Setup to configure.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_analysisMode == 'custom') ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextFieldLabel('Analysis Prompt'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _analysisPromptController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText:
                                      'Analyze the conversation and provide insights...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.lightGrey,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderGrey,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.borderGrey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryGreen,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isGeneratingAnalysis
                                      ? null
                                      : _generateAnalysisPrompt,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppTheme.primaryGreen,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: _isGeneratingAnalysis
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.auto_awesome,
                                          size: 16,
                                          color: AppTheme.primaryGreen,
                                        ),
                                  label: Text(
                                    _isGeneratingAnalysis
                                        ? 'Generating...'
                                        : 'Generate Prompt',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Call Settings Switches
                  _buildSettingsCard(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearDraft,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            'Clear Draft',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveAgent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.surfaceCard,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'Update Voice Agent'
                                      : 'Create Voice Agent',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

  Widget _buildTextFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _buildEngineTab(String title) {
    final isSelected = _selectedVoiceEngine == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVoiceEngine = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: AppTheme.borderGrey)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.darkGrey
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariableChip(String variable, TextEditingController controller) {
    return GestureDetector(
      onTap: () {
        _insertText(controller, variable);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.borderGrey,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderGrey),
        ),
        child: Text(
          variable,
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisRadioCard(
    String value,
    String label,
    String badgeText,
    Color badgeColor,
  ) {
    final isSelected = _analysisMode == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _analysisMode = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : const Color(0xFFCBD5E1),
                  width: isSelected ? 4 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.darkGrey
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildBadge(badgeText, badgeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSwitchRow(
            'Allow Interruptions',
            'Disables interruption handling if turned on.',
            _allowInterruptions,
            (v) => setState(() => _allowInterruptions = v),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSettingsSwitchRow(
            'Background Music',
            'Enable music during calls.',
            _backgroundMusic,
            (v) => setState(() => _backgroundMusic = v),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSettingsSwitchRow(
            'Debug Logging',
            'Log detailed call timing data.',
            _debugLogging,
            (v) => setState(() => _debugLogging = v),
            badge: _buildBadge('DEV', Colors.orange),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSettingsSwitchRow(
            'Freeze Agent',
            'Cache TTS audio per sentence. Replays cached audio on similar responses.',
            widget.agent?.isFrozen ?? false,
            (v) {
              // Read-only or update via provider since isFrozen is a read-only beta flag
              // We'll update widget.agent parameters if applicable
            },
            badge: _buildBadge('BETA', Colors.blue),
            enabled: false,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Hard End Call
          _buildTextFieldLabel('Hard End Call (minutes)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _hardEndCallMinutesController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final intValue = int.tryParse(value);
                if (intValue == null || intValue < 0) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Leave empty for no limit',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppTheme.lightGrey,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
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
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Optional. If set, must be between 1 and 10 minutes.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Active Status Switch
          _buildSettingsSwitchRow(
            'Active Status',
            'Determines whether the voice agent is currently active and accepting calls.',
            _isActive,
            (v) => setState(() => _isActive = v),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Video Avatar Switch
          _buildSettingsSwitchRow(
            'Enable Video Avatar',
            'Show a video avatar during calls.',
            _enableVideoAvatar,
            (v) => setState(() => _enableVideoAvatar = v),
          ),

          if (_enableVideoAvatar) ...[
            const SizedBox(height: 12),
            _buildTextFieldLabel('Simli Face ID'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _simliFaceIdController,
              decoration: InputDecoration(
                hintText: 'Enter Simli face ID for video avatar',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppTheme.lightGrey,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
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
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsSwitchRow(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged, {
    Widget? badge,
    bool enabled = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 6), badge],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.white,
          activeTrackColor: AppTheme.primaryGreen,
          inactiveThumbColor: AppTheme.borderGrey,
          inactiveTrackColor: const Color(0xFFF1F5F9),
        ),
      ],
    );
  }
}
