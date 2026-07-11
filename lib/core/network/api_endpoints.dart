class ApiEndpoints {
  // Auth Endpoints
  static const String signup = '/api/auth/signup';
  static const String login = '/api/auth/login';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String logout = '/api/auth/logout';
  static const String sendCall = '/api/auth/send-call';
  static const String testCalls = '/api/auth/test-calls';
  static const String googleAuthUrl = '/api/auth/google/url';
  static const String googleCallback = '/api/auth/google/callback';
  static const String verifyPhone = '/api/auth/verify-phone';
  static const String setPhone = '/api/auth/set-phone';

  // Calls Endpoints
  static const String callHistory = '/api/calls/history';
  static const String callStatistics = '/api/calls/statistics';
  static const String callContacts = '/api/calls/contacts';
  static const String validateCall = '/api/calls/validate';
  static String downloadRecording(String callId) =>
      '/api/calls/$callId/download-recording';
  static String regenerateSummary(String callId) =>
      '/api/calls/$callId/regenerate-summary';

  // Contacts Endpoints
  static const String contacts = '/api/calls/contacts';
  static String updateContactStatus(String phoneNumber) =>
      '/api/calls/contacts/$phoneNumber/status';

  // Phone Numbers Endpoints
  static const String availablePhoneNumbers = '/api/phone-numbers/available';
  static const String phoneNumbers = '/api/phone-numbers';
  static String phoneNumber(String phoneId) => '/api/phone-numbers/$phoneId';
  static String updateInboundAgent(String phoneId) =>
      '/api/phone-numbers/$phoneId/inbound-agent';

  // Credits Endpoints
  static const String creditBalance = '/api/credits/balance';
  static const String creditTransactions = '/api/credits/transactions';
  static const String purchaseCredits = '/api/credits/purchase';
  static const String verifyPayment = '/api/credits/verify-payment';

  // Subscriptions Endpoints
  static const String subscriptionTiers = '/api/subscriptions/tiers';
  static const String currentSubscription = '/api/subscriptions/current';
  static const String changeTier = '/api/subscriptions/change-tier';
  static const String upgradeTier = '/api/billing/upgrade-tier';
  static const String verifyTierUpgrade = '/api/billing/verify-tier-upgrade';

  // User Endpoints
  static const String userStatus = '/api/user/status';
  static const String assignDemoNumber = '/api/user/assign-demo-number';

  // Config Endpoints
  static const String ttsProviders = '/api/config/tts/providers';
  static const String ttsConfig = '/api/config/tts';

  // Platform Agent (AI Assistant) Endpoints
  static const String runAgent = '/api/platform-agent/run';
  static const String conversations = '/api/platform-agent/conversations';
  static String conversation(String conversationId) =>
      '/api/platform-agent/conversations/$conversationId';

  // Agents Endpoints
  static const String agents = '/api/agents';
  static String agent(String agentId) => '/api/agents/$agentId';
  static const String generateAnalysisConfig =
      '/api/agents/generate-analysis-config';
  static const String generateAnalysisPrompt =
      '/api/agents/generate-analysis-prompt';
  static const String generateS2sSystemPrompt =
      '/api/agents/generate-s2s-system-prompt';
  static const String promptGeneratorSettings =
      '/api/agents/prompt-generator-settings';

  // Knowledge Endpoints
  static const String knowledge = '/api/knowledge';

  // Campaigns Endpoints
  static const String campaigns = '/api/campaigns';
  static String campaign(String campaignId) => '/api/campaigns/$campaignId';
  static String campaignGsheetHeaders(String campaignId) =>
      '/api/campaigns/$campaignId/gsheet-headers';
  static String campaignNumbers(String campaignId) =>
      '/api/campaigns/$campaignId/numbers';

  // WhatsApp Endpoints
  static const String whatsappConversations = '/api/whatsapp/conversations';
  static String whatsappConversation(String conversationId) =>
      '/api/whatsapp/conversations/$conversationId';
  static String whatsappConversationSettings(String conversationId) =>
      '/api/whatsapp/conversations/$conversationId/settings';
  static String whatsappConversationLeadStatus(String conversationId) =>
      '/api/whatsapp/conversations/$conversationId/lead-status';
  static String whatsappSendMessage(String conversationId) =>
      '/api/whatsapp/conversations/$conversationId/send';
  static const String whatsappBulkSend = '/api/whatsapp/bulk-send';
  static const String whatsappWebhookConfig = '/api/whatsapp/webhook-config';
  static const String whatsappWebhook = '/api/whatsapp/webhook';

  // Integrations Endpoints - Meta
  static const String metaConnections = '/api/integrations/meta';
  static String metaConnection(String connectionId) =>
      '/api/integrations/meta/$connectionId';
  static String validateMetaConnection(String connectionId) =>
      '/api/integrations/meta/$connectionId/validate';

  // Integrations Endpoints - WhatsApp
  static const String whatsappConnections = '/api/integrations/whatsapp';
  static String whatsappConnection(String connectionId) =>
      '/api/integrations/whatsapp/$connectionId';
  static String validateWhatsAppConnection(String connectionId) =>
      '/api/integrations/whatsapp/$connectionId/validate';
  static String whatsappTemplates(String connectionId) =>
      '/api/integrations/whatsapp/$connectionId/templates';

  // Meta Ads Endpoints - OAuth
  static const String metaAdsOAuthSelect = '/api/ads/meta/oauth/select';
  static const String metaAdsOAuthDisconnect = '/api/ads/meta/oauth/disconnect';

  // Meta Ads Endpoints - Assets
  static const String metaAdsAssets = '/api/ads/meta/ad-assets';
  static const String metaAdsUploadAsset = '/api/ads/meta/upload-asset';

  // Meta Ads Endpoints - Lead Forms
  static const String metaAdsLeadForms = '/api/ads/meta/lead-forms';

  // Meta Ads Endpoints - Account & Campaigns
  static const String metaAdsAccountOverview = '/api/ads/meta/account-overview';
  static String metaAdsCampaignStatus(String campaignId) =>
      '/api/ads/meta/campaigns/$campaignId/status';
  static String metaAdsAdsetStatus(String adsetId) =>
      '/api/ads/meta/adsets/$adsetId/status';

  // Meta Ads Endpoints - Targeting
  static const String metaAdsInterestSearch = '/api/ads/meta/interest-search';
  static const String metaAdsGeoSearch = '/api/ads/meta/geo-search';

  // Meta Ads Endpoints - Drafts
  static String metaAdsDraftPublish(String draftId) =>
      '/api/ads/meta/drafts/$draftId/publish';

  // Meta Ads Endpoints - Leadgen Webhook
  static const String metaAdsLeadgenWebhookInfo =
      '/api/ads/meta/leadgen/webhook-info';
  static const String metaAdsLeadgenWebhookVerifyToken =
      '/api/ads/meta/leadgen/webhook-verify-token';
  static const String metaAdsLeadgenWebhook = '/api/ads/meta/leadgen/webhook';
  static const String metaAdsLeadgenSync = '/api/ads/meta/leadgen/sync';

  // Meta Ads Endpoints - Leadgen Polling
  static const String metaAdsLeadgenPollingConfigs =
      '/api/ads/meta/leadgen/polling-configs';
  static String metaAdsLeadgenPollingConfig(String configId) =>
      '/api/ads/meta/leadgen/polling-configs/$configId';
}
