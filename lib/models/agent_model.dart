class Agent {
  final String id;
  final String userId;
  final String name;
  final String? phoneNumberId;
  final String voice;
  final String ttsLanguage;
  final String ttsProvider;
  final String? speechToSpeechProvider;
  final String? voiceEngine;
  final String? geminiLiveVoice;
  final String? geminiLiveLanguage;
  final String greetingType;
  final String? greetingLine;
  final String? agentPrompt;
  final Map<String, dynamic>? s2sPromptConfig;
  final String? localFallbackPrompt;
  final String? analysisPrompt;
  final Map<String, dynamic>? analysisConfig;
  final List<String>? transcriptionLanguages;
  final List<String>? knowledgeBaseIds;
  final double ttsSpeed;
  final bool hasTtsSpeed;
  final int? ttsNumStep;
  final bool allowInterruptions;
  final bool backgroundMusic;
  final bool debugLogging;
  final bool isFrozen;
  final double cacheHitRate;
  final int hardEndCallMinutes;
  final bool isActive;
  final bool enableVideoAvatar;
  final String? simliFaceId;
  final String? asrVocabulary;
  final String createdAt;
  final String updatedAt;

  Agent({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumberId,
    required this.voice,
    required this.ttsLanguage,
    required this.ttsProvider,
    this.speechToSpeechProvider,
    this.voiceEngine,
    this.geminiLiveVoice,
    this.geminiLiveLanguage,
    this.greetingType = 'fixed',
    this.greetingLine,
    this.agentPrompt,
    this.s2sPromptConfig,
    this.localFallbackPrompt,
    this.analysisPrompt,
    this.analysisConfig,
    this.transcriptionLanguages,
    this.knowledgeBaseIds,
    this.ttsSpeed = 1.0,
    this.hasTtsSpeed = false,
    this.ttsNumStep,
    required this.allowInterruptions,
    required this.backgroundMusic,
    required this.debugLogging,
    required this.isFrozen,
    this.cacheHitRate = 0,
    required this.hardEndCallMinutes,
    required this.isActive,
    this.enableVideoAvatar = false,
    this.simliFaceId,
    this.asrVocabulary,
    required this.createdAt,
    required this.updatedAt,
  });

  String get engineType {
    String normalize(Object? value) =>
        value?.toString().toLowerCase().trim().replaceAll('_', ' ').replaceAll('-', ' ') ?? '';

    // 1. Check direct ttsProvider to identify Classic Pipeline agents
    if (ttsProvider != null && ttsProvider.trim().isNotEmpty) {
      return 'Classic Pipeline';
    }

    // Since ttsProvider is null/empty, this is an S2S agent (Vani Ultra or Ultra Realtime)
    
    // 2. Check speechToSpeechProvider
    final s2sProviderStr = normalize(speechToSpeechProvider);
    if (s2sProviderStr == 'speechgpu' || s2sProviderStr == 'gpu') {
      return 'Vani Ultra';
    }
    if (s2sProviderStr == 'gemini' || s2sProviderStr == 'gemini live') {
      return 'Ultra Realtime';
    }

    // 3. Check direct voiceEngine
    final engineStr = normalize(voiceEngine);
    if (engineStr == 'vani ultra' || engineStr == 'speechgpu') {
      return 'Vani Ultra';
    }
    if (engineStr == 'ultra realtime' || engineStr == 'gemini' || engineStr == 'gemini live') {
      return 'Ultra Realtime';
    }

    // 4. Check s2sPromptConfig maps
    if (s2sPromptConfig != null) {
      final speechGpuConfig = s2sPromptConfig!['speechgpu'];
      final geminiConfig = s2sPromptConfig!['gemini'];

      if (speechGpuConfig is Map) {
        final hasPrompt = speechGpuConfig['system_prompt']?.toString().isNotEmpty ?? false;
        final isEdited = speechGpuConfig['user_edited'] == true;
        if (isEdited || hasPrompt) {
          return 'Vani Ultra';
        }
      }

      if (geminiConfig is Map) {
        final hasPrompt = geminiConfig['system_prompt']?.toString().isNotEmpty ?? false;
        final isEdited = geminiConfig['user_edited'] == true;
        if (isEdited || hasPrompt) {
          return 'Ultra Realtime';
        }
      }

      final configProvider = normalize(s2sPromptConfig!['provider'] ??
          s2sPromptConfig!['s2s']?['provider'] ??
          s2sPromptConfig!['native_speech_to_speech']?['provider']);
      if (configProvider == 'speechgpu' || configProvider == 'gpu') {
        return 'Vani Ultra';
      }
      if (configProvider == 'gemini' || configProvider == 'gemini live') {
        return 'Ultra Realtime';
      }
    }

    // 5. Fallback for older S2S agents where all S2S config fields are null/missing
    return 'Vani Ultra';
  }

  factory Agent.fromJson(Map<String, dynamic> json) {
    final rawTtsNumStep =
        json['tts_num_step'] ?? json['ttsNumStep'] ?? json['tts_num_steps'];
    final rawTtsSpeed = json['tts_speed'] ?? json['ttsSpeed'];

    return Agent(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumberId: json['phone_number_id'] as String?,
      voice: json['voice'] as String? ?? '',
      ttsLanguage: json['tts_language'] as String? ?? '',
      ttsProvider: json['tts_provider'] as String? ?? '',
      speechToSpeechProvider:
          (json['speech_to_speech_provider'] ??
                  json['speechToSpeechProvider'] ??
                  json['speech_to_speech'] ??
                  json['speechToSpeech'] ??
                  json['s2s_provider'] ??
                  json['s2sProvider'] ??
                  json['provider'])
              as String?,
      voiceEngine:
          (json['voice_engine'] ??
                  json['voiceEngine'] ??
                  json['engine_type'] ??
                  json['engineType'] ??
                  json['agent_type'] ??
                  json['agentType'] ??
                  json['type'])
              as String?,
      geminiLiveVoice: json['gemini_live_voice'] as String?,
      geminiLiveLanguage: json['gemini_live_language'] as String?,
      greetingType: json['greeting_type'] as String? ?? 'fixed',
      greetingLine: json['greeting_line'] as String?,
      agentPrompt: json['agent_prompt'] as String?,
      s2sPromptConfig: (json['s2s_prompt_config'] ?? json['s2sPromptConfig']) as Map<String, dynamic>?,
      localFallbackPrompt: json['local_fallback_prompt'] as String?,
      analysisPrompt: json['analysis_prompt'] as String?,
      analysisConfig: json['analysis_config'] as Map<String, dynamic>?,
      transcriptionLanguages:
          (json['transcription_languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      knowledgeBaseIds: (json['knowledge_base_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      ttsSpeed: (rawTtsSpeed as num?)?.toDouble() ?? 1.0,
      hasTtsSpeed: rawTtsSpeed != null,
      ttsNumStep: rawTtsNumStep is num ? rawTtsNumStep.toInt() : null,
      allowInterruptions: json['allow_interruptions'] as bool? ?? false,
      backgroundMusic: json['background_music'] as bool? ?? false,
      debugLogging: json['debug_logging'] as bool? ?? false,
      isFrozen: json['is_frozen'] as bool? ?? false,
      cacheHitRate: (json['cache_hit_rate'] as num?)?.toDouble() ?? 0,
      hardEndCallMinutes: json['hard_end_call_minutes'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      enableVideoAvatar: json['enable_video_avatar'] as bool? ?? false,
      simliFaceId: json['simli_face_id'] as String?,
      asrVocabulary: json['asr_vocabulary'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number_id': phoneNumberId,
      'voice': voice,
      'tts_language': ttsLanguage,
      'tts_provider': ttsProvider,
      'speech_to_speech_provider': speechToSpeechProvider,
      'voice_engine': voiceEngine,
      'gemini_live_voice': geminiLiveVoice,
      'gemini_live_language': geminiLiveLanguage,
      'greeting_type': greetingType,
      'greeting_line': greetingLine,
      'agent_prompt': agentPrompt,
      's2s_prompt_config': s2sPromptConfig,
      'local_fallback_prompt': localFallbackPrompt,
      'analysis_prompt': analysisPrompt,
      'analysis_config': analysisConfig,
      'transcription_languages': transcriptionLanguages,
      'knowledge_base_ids': knowledgeBaseIds,
      if (hasTtsSpeed) 'tts_speed': ttsSpeed,
      'tts_num_step': ttsNumStep,
      'allow_interruptions': allowInterruptions,
      'background_music': backgroundMusic,
      'debug_logging': debugLogging,
      'is_frozen': isFrozen,
      'cache_hit_rate': cacheHitRate,
      'hard_end_call_minutes': hardEndCallMinutes,
      'is_active': isActive,
      'enable_video_avatar': enableVideoAvatar,
      'simli_face_id': simliFaceId,
      'asr_vocabulary': asrVocabulary,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Agent copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumberId,
    String? voice,
    String? ttsLanguage,
    String? ttsProvider,
    String? speechToSpeechProvider,
    String? voiceEngine,
    String? geminiLiveVoice,
    String? geminiLiveLanguage,
    String? greetingType,
    String? greetingLine,
    String? agentPrompt,
    Map<String, dynamic>? s2sPromptConfig,
    String? localFallbackPrompt,
    String? analysisPrompt,
    Map<String, dynamic>? analysisConfig,
    List<String>? transcriptionLanguages,
    List<String>? knowledgeBaseIds,
    double? ttsSpeed,
    bool? hasTtsSpeed,
    int? ttsNumStep,
    bool? allowInterruptions,
    bool? backgroundMusic,
    bool? debugLogging,
    bool? isFrozen,
    double? cacheHitRate,
    int? hardEndCallMinutes,
    bool? isActive,
    bool? enableVideoAvatar,
    String? simliFaceId,
    String? asrVocabulary,
    String? createdAt,
    String? updatedAt,
  }) {
    return Agent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      voice: voice ?? this.voice,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      speechToSpeechProvider:
          speechToSpeechProvider ?? this.speechToSpeechProvider,
      voiceEngine: voiceEngine ?? this.voiceEngine,
      geminiLiveVoice: geminiLiveVoice ?? this.geminiLiveVoice,
      geminiLiveLanguage: geminiLiveLanguage ?? this.geminiLiveLanguage,
      greetingType: greetingType ?? this.greetingType,
      greetingLine: greetingLine ?? this.greetingLine,
      agentPrompt: agentPrompt ?? this.agentPrompt,
      s2sPromptConfig: s2sPromptConfig ?? this.s2sPromptConfig,
      localFallbackPrompt: localFallbackPrompt ?? this.localFallbackPrompt,
      analysisPrompt: analysisPrompt ?? this.analysisPrompt,
      analysisConfig: analysisConfig ?? this.analysisConfig,
      transcriptionLanguages:
          transcriptionLanguages ?? this.transcriptionLanguages,
      knowledgeBaseIds: knowledgeBaseIds ?? this.knowledgeBaseIds,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      hasTtsSpeed: hasTtsSpeed ?? this.hasTtsSpeed,
      ttsNumStep: ttsNumStep ?? this.ttsNumStep,
      allowInterruptions: allowInterruptions ?? this.allowInterruptions,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      debugLogging: debugLogging ?? this.debugLogging,
      isFrozen: isFrozen ?? this.isFrozen,
      cacheHitRate: cacheHitRate ?? this.cacheHitRate,
      hardEndCallMinutes: hardEndCallMinutes ?? this.hardEndCallMinutes,
      isActive: isActive ?? this.isActive,
      enableVideoAvatar: enableVideoAvatar ?? this.enableVideoAvatar,
      simliFaceId: simliFaceId ?? this.simliFaceId,
      asrVocabulary: asrVocabulary ?? this.asrVocabulary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
