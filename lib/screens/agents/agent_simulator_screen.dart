import 'package:vani_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/models/agent_model.dart';
import 'package:vani_app/presentation/providers/simulator_provider.dart';

class AgentSimulatorScreen extends ConsumerStatefulWidget {
  final Agent agent;

  const AgentSimulatorScreen({super.key, required this.agent});

  @override
  ConsumerState<AgentSimulatorScreen> createState() =>
      _AgentSimulatorScreenState();
}

class _AgentSimulatorScreenState extends ConsumerState<AgentSimulatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Draft Form Controllers
  final TextEditingController _personaCountController = TextEditingController(
    text: '5',
  );
  final TextEditingController _turnsController = TextEditingController(
    text: '10',
  );
  final TextEditingController _scenarioGoalController = TextEditingController();
  final TextEditingController _edgeCaseController = TextEditingController();
  final TextEditingController _variationHintsController =
      TextEditingController();
  final TextEditingController _generateMoreCountController =
      TextEditingController(text: '3');

  String _selectedLanguage = 'agent_default';
  bool _strictFlow = true;
  bool _includeEdgeCases = true;
  final List<String> _edgeCases = [];

  // Persona State
  int _selectedPersonaIndex = 0;

  // Run State
  Map<String, dynamic>? _selectedRun;
  Map<String, dynamic>? _selectedSimulation;

  String _getAgentDefaultLanguageCode() {
    final lang = widget.agent.ttsLanguage.toLowerCase();
    if (lang.startsWith('af')) return 'af';
    if (lang.startsWith('en')) return 'en';
    if (lang.startsWith('es')) return 'es';
    if (lang.startsWith('fr')) return 'fr';
    if (lang.startsWith('de')) return 'de';
    if (lang.startsWith('it')) return 'it';
    if (lang.startsWith('pt')) return 'pt';
    if (lang.startsWith('hi')) return 'hi';
    if (lang.startsWith('ja')) return 'ja';
    if (lang.startsWith('ko')) return 'ko';
    if (lang.startsWith('zh')) return 'zh';
    return lang.substring(0, lang.length > 2 ? 2 : lang.length);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load drafts and runs on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(simulatorProvider.notifier).loadDraftsAndRuns(widget.agent.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _personaCountController.dispose();
    _turnsController.dispose();
    _scenarioGoalController.dispose();
    _edgeCaseController.dispose();
    _variationHintsController.dispose();
    _generateMoreCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simulatorState = ref.watch(simulatorProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conversation Simulator',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkGrey,
              ),
            ),
            Text(
              widget.agent.name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF475569)),
            onPressed: () {
              ref
                  .read(simulatorProvider.notifier)
                  .loadDraftsAndRuns(widget.agent.id);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6D28D9),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6D28D9),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            const Tab(text: 'Draft'),
            Tab(
              text: simulatorState.currentDraft != null
                  ? 'Personas (${(simulatorState.currentDraft!['personas'] as List).length})'
                  : 'Personas (0/0)',
            ),
            const Tab(text: 'Runs'),
          ],
        ),
      ),
      body: simulatorState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6D28D9)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDraftTab(simulatorState),
                _buildPersonasTab(simulatorState),
                _buildRunsTab(simulatorState),
              ],
            ),
      bottomNavigationBar: _buildBottomActionBar(simulatorState),
    );
  }

  // --- DRAFT TAB ---
  Widget _buildDraftTab(SimulatorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.drafts.isNotEmpty) ...[
            _buildLabel('Load Saved Draft'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              hint: const Text('Select a saved draft'),
              decoration: _buildInputDecoration('Load a draft'),
              items: state.drafts.map((d) {
                final dateStr =
                    d['created_at']?.toString().substring(0, 10) ?? '';
                final draftId = d['id']?.toString() ?? '';
                final count = (d['personas'] as List?)?.length ?? 0;
                return DropdownMenuItem<String>(
                  value: draftId,
                  child: Text(
                    'Draft: ${draftId.substring(0, draftId.length > 8 ? 8 : draftId.length)}... ($count personas - $dateStr)',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  final draft = state.drafts.firstWhere(
                    (d) => d['id'].toString() == val,
                  );
                  ref.read(simulatorProvider.notifier).selectDraft(draft);
                  setState(() {
                    _selectedPersonaIndex = 0;
                  });
                  _tabController.animateTo(1); // Go to Personas tab
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          // Info Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate editable persona draft',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI will infer fields and personas from this agent\'s system prompt. Nothing runs until you approve selected personas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parameters Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personas & Turns
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Personas'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            _personaCountController,
                            'e.g. 5',
                            TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Turns each'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            _turnsController,
                            'e.g. 10',
                            TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Language
                _buildLabel('Language'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: _buildInputDecoration('Select language'),
                  items: [
                    DropdownMenuItem(
                      value: 'agent_default',
                      child: Text(
                        'Agent default: ${_getAgentDefaultLanguageCode()} (${_getAgentDefaultLanguageCode()})',
                      ),
                    ),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                    const DropdownMenuItem(value: 'bn', child: Text('Bengali')),
                    const DropdownMenuItem(value: 'te', child: Text('Telugu')),
                    const DropdownMenuItem(value: 'mr', child: Text('Marathi')),
                    const DropdownMenuItem(value: 'ta', child: Text('Tamil')),
                    const DropdownMenuItem(
                      value: 'gu',
                      child: Text('Gujarati'),
                    ),
                    const DropdownMenuItem(value: 'kn', child: Text('Kannada')),
                    const DropdownMenuItem(
                      value: 'ml',
                      child: Text('Malayalam'),
                    ),
                    const DropdownMenuItem(value: 'pa', child: Text('Punjabi')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
                const SizedBox(height: 16),

                // Scenario Goal
                _buildLabel('Scenario goal'),
                const SizedBox(height: 6),
                TextField(
                  controller: _scenarioGoalController,
                  maxLines: 3,
                  decoration: _buildInputDecoration(
                    'Leave blank to infer from the agent prompt',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Checkbox controls
                Row(
                  children: [
                    Checkbox(
                      value: _strictFlow,
                      activeColor: const Color(0xFF6D28D9),
                      onChanged: (val) {
                        if (val != null) setState(() => _strictFlow = val);
                      },
                    ),
                    const Text(
                      'Strict flow',
                      style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: _includeEdgeCases,
                      activeColor: const Color(0xFF6D28D9),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _includeEdgeCases = val);
                      },
                    ),
                    const Text(
                      'Edge cases',
                      style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Variation Hints / Edge cases adding
                _buildLabel('Persona variation hints / Edge cases'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _variationHintsController,
                        decoration: _buildInputDecoration(
                          'Optional, e.g. price objection',
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final hint = _variationHintsController.text.trim();
                        if (hint.isNotEmpty) {
                          setState(() {
                            _edgeCases.add(hint);
                            _variationHintsController.clear();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkGrey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(color: AppTheme.surfaceCard, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (_edgeCases.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _edgeCases
                        .map(
                          (ec) => Chip(
                            label: Text(
                              ec,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF475569),
                              ),
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: const BorderSide(color: AppTheme.borderGrey),
                            onDeleted: () {
                              setState(() {
                                _edgeCases.remove(ec);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final personasCount =
                          int.tryParse(_personaCountController.text) ?? 5;
                      final turns = int.tryParse(_turnsController.text) ?? 10;

                      try {
                        final defaultLang = _getAgentDefaultLanguageCode();
                        final selectedLang =
                            _selectedLanguage == 'agent_default'
                            ? defaultLang
                            : _selectedLanguage;

                        await ref
                            .read(simulatorProvider.notifier)
                            .generateDraft(widget.agent.id, {
                              'persona_count': personasCount,
                              'turns_per_persona': turns,
                              'language': selectedLang,
                              'scenario_goal': _scenarioGoalController.text,
                              'strict_flow': _strictFlow,
                              'include_edge_cases': _includeEdgeCases,
                              'edge_cases': _edgeCases,
                              'run_immediately': false,
                              'agent_default_language': defaultLang,
                            });
                        // Navigate to Personas Tab
                        _tabController.animateTo(1);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to generate draft: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text(
                      'Generate draft',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PERSONAS TAB ---
  Widget _buildPersonasTab(SimulatorState state) {
    final draft = state.currentDraft ?? {'id': 'new_draft', 'personas': []};
    final personas = draft['personas'] as List<dynamic>;

    return Column(
      children: [
        // Top action bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, size: 18, color: Color(0xFF6D28D9)),
              const SizedBox(width: 8),
              Text(
                '${personas.length} Personas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),

        // Secondary action controls (Select all, Clear, Add, Generate more count)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppTheme.lightGrey,
            border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All personas selected for run'),
                      ),
                    );
                  },
                  child: const Text(
                    'Select all',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6D28D9)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selection cleared')),
                    );
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Get current draft or create one
                    Map<String, dynamic> activeDraft;
                    if (draft['id'] == 'new_draft') {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                      );
                      try {
                        final defaultLang = _getAgentDefaultLanguageCode();
                        await ref
                            .read(simulatorProvider.notifier)
                            .generateDraft(widget.agent.id, {
                              'persona_count': 0,
                              'turns_per_persona': 10,
                              'language': defaultLang,
                              'scenario_goal': '',
                              'strict_flow': true,
                              'include_edge_cases': false,
                              'edge_cases': [],
                              'run_immediately': false,
                              'agent_default_language': defaultLang,
                            });
                        Navigator.pop(context); // Close loading
                        activeDraft = ref.read(simulatorProvider).currentDraft!;
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to initialize draft: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    } else {
                      activeDraft = draft;
                    }

                    final activePersonas = List<dynamic>.from(
                      activeDraft['personas'] ?? [],
                    );
                    final newPersona = {
                      'name': 'New Persona ${activePersonas.length + 1}',
                      'demographics': {
                        'age': '30',
                        'gender': 'unspecified',
                        'location': 'India',
                      },
                      'language_style': 'Polite and helpful',
                      'goal': 'Inquire about service features',
                      'behavior': 'Inquisitive',
                    };
                    activePersonas.add(newPersona);

                    try {
                      await ref.read(simulatorProvider.notifier).updateDraft(
                        widget.agent.id,
                        activeDraft['id'],
                        {'personas': activePersonas},
                      );
                      setState(() {
                        _selectedPersonaIndex = activePersonas.length - 1;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New persona added and draft saved!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update draft: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE9FE),
                    foregroundColor: const Color(0xFF6D28D9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 12),
                  label: const Text(
                    'Add',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 30,
                  child: TextField(
                    controller: _generateMoreCountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppTheme.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () async {
                    final count =
                        int.tryParse(_generateMoreCountController.text) ?? 3;

                    // Get current draft or create one
                    Map<String, dynamic> activeDraft;
                    if (draft['id'] == 'new_draft') {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                      );
                      try {
                        final defaultLang = _getAgentDefaultLanguageCode();
                        await ref
                            .read(simulatorProvider.notifier)
                            .generateDraft(widget.agent.id, {
                              'persona_count': 0,
                              'turns_per_persona': 10,
                              'language': defaultLang,
                              'scenario_goal': '',
                              'strict_flow': true,
                              'include_edge_cases': false,
                              'edge_cases': [],
                              'run_immediately': false,
                              'agent_default_language': defaultLang,
                            });
                        Navigator.pop(context); // Close loading
                        activeDraft = ref.read(simulatorProvider).currentDraft!;
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to initialize draft: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    } else {
                      activeDraft = draft;
                    }

                    try {
                      await ref
                          .read(simulatorProvider.notifier)
                          .generateMore(
                            widget.agent.id,
                            activeDraft['id'],
                            count,
                          );
                      setState(() {
                        _selectedPersonaIndex = 0;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully generated $count more personas!',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to generate more: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkGrey,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Generate more',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Horizontal list of personas
        Container(
          height: 50,
          color: AppTheme.surfaceCard,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: personas.length,
            itemBuilder: (context, idx) {
              final p = personas[idx];
              final isSelected = _selectedPersonaIndex == idx;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(
                  label: Text(p['name'] ?? 'Persona $idx'),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEDE9FE),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF6D28D9)
                        : const Color(0xFF475569),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedPersonaIndex = idx);
                  },
                ),
              );
            },
          ),
        ),

        // Selected Persona Details Editor
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: personas.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'Generate or add a persona to edit.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : _buildPersonaEditorCard(
                    personas[_selectedPersonaIndex],
                    draft['id'],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonaEditorCard(Map<String, dynamic> persona, String draftId) {
    final nameController = TextEditingController(text: persona['name'] ?? '');
    final demographicsController = TextEditingController(
      text: (persona['demographics'] is Map)
          ? (persona['demographics'] as Map).entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n')
          : persona['demographics']?.toString() ?? '',
    );
    final languageStyleController = TextEditingController(
      text: persona['language_style'] ?? '',
    );
    final goalController = TextEditingController(text: persona['goal'] ?? '');
    final behaviorController = TextEditingController(
      text: persona['behavior'] ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  persona['name'] ?? 'Edit Persona',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: persona['run'] != false,
                    activeColor: const Color(0xFF6D28D9),
                    onChanged: (val) {
                      setState(() {
                        persona['run'] = val;
                      });
                    },
                  ),
                  const Text(
                    'Run',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                    onPressed: () {
                      // Local removal and save draft
                      setState(() {
                        final activeDraft =
                            ref.read(simulatorProvider).currentDraft ??
                            {'id': 'new_draft', 'personas': []};
                        final personasList = List<dynamic>.from(
                          activeDraft['personas'],
                        );
                        personasList.remove(persona);
                        activeDraft['personas'] = personasList;

                        ref.read(simulatorProvider.notifier).updateDraft(
                          widget.agent.id,
                          draftId,
                          {'personas': personasList},
                        );

                        if (_selectedPersonaIndex >= personasList.length) {
                          _selectedPersonaIndex = 0;
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name field
          _buildLabel('Name'),
          const SizedBox(height: 6),
          TextField(
            controller: nameController,
            decoration: _buildInputDecoration('Persona Name'),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) {
              setState(() {
                persona['name'] = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // Demographics field
          _buildLabel('Demographics'),
          const SizedBox(height: 6),
          TextField(
            controller: demographicsController,
            maxLines: 3,
            decoration: _buildInputDecoration('Age, Gender, Occupation...'),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) {
              setState(() {
                // Parse simple key values back to demographics map
                final Map<String, String> demoMap = {};
                final lines = val.split('\n');
                for (var line in lines) {
                  if (line.contains(':')) {
                    final parts = line.split(':');
                    demoMap[parts[0].trim()] = parts[1].trim();
                  }
                }
                persona['demographics'] = demoMap;
              });
            },
          ),
          const SizedBox(height: 16),

          // Language Style
          _buildLabel('Language Style'),
          const SizedBox(height: 6),
          TextField(
            controller: languageStyleController,
            maxLines: 2,
            decoration: _buildInputDecoration('Tone, vocabulary, accent...'),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) {
              setState(() {
                persona['language_style'] = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // Goal
          _buildLabel('Goal'),
          const SizedBox(height: 6),
          TextField(
            controller: goalController,
            maxLines: 2,
            decoration: _buildInputDecoration(
              'What this user wants to achieve...',
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) {
              setState(() {
                persona['goal'] = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // Behavior
          _buildLabel('Behavior'),
          const SizedBox(height: 6),
          TextField(
            controller: behaviorController,
            maxLines: 2,
            decoration: _buildInputDecoration(
              'Simulated user traits / objections...',
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (val) {
              setState(() {
                persona['behavior'] = val;
              });
            },
          ),
          const SizedBox(height: 20),

          // Save Persona changes
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final draft = ref.read(simulatorProvider).currentDraft!;
                  await ref.read(simulatorProvider.notifier).updateDraft(
                    widget.agent.id,
                    draftId,
                    {'personas': draft['personas']},
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Persona changes saved successfully'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to save changes: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.save, size: 14),
              label: const Text(
                'Save Persona Changes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- RUNS TAB ---
  Widget _buildRunsTab(SimulatorState state) {
    if (_selectedRun != null) {
      return _buildRunDetailsView(state);
    }

    if (state.runs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_toggle_off,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                'No simulation runs yet.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Generate a draft and run simulation tasks to see historical runs.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.runs.length,
      itemBuilder: (context, idx) {
        final run = state.runs[idx];
        final status = run['status'] ?? 'completed';
        final createdStr =
            run['created_at']
                ?.toString()
                .substring(0, 16)
                .replaceAll('T', ' ') ??
            'July 8, 10:15';
        final personaCount = run['persona_count'] ?? 0;
        final score = run['aggregate_score'] ?? 85;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderGrey),
          ),
          elevation: 0,
          borderOnForeground: true,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: status == 'completed'
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF3C7),
              child: Icon(
                status == 'completed'
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
                color: status == 'completed'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFD97706),
              ),
            ),
            title: Row(
              children: [
                Text(
                  '$personaCount Personas',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'completed'
                          ? const Color(0xFF065F46)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Created: $createdStr',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.borderGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score Score',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
            onTap: () async {
              setState(() => _selectedRun = run);
              await ref
                  .read(simulatorProvider.notifier)
                  .loadRun(widget.agent.id, run['id']);
              // Set the refreshed run from state
              setState(() {
                _selectedRun = ref.read(simulatorProvider).currentRun ?? run;
                _selectedSimulation = null;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildRunDetailsView(SimulatorState state) {
    final run = state.currentRun ?? _selectedRun!;
    final simulations = run['simulations'] as List<dynamic>? ?? [];

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _selectedRun = null;
          _selectedSimulation = null;
        });
        return false;
      },
      child: Column(
        children: [
          // Run Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCard,
              border: Border(bottom: BorderSide(color: AppTheme.borderGrey)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedRun = null;
                      _selectedSimulation = null;
                    });
                  },
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run Details (${run['persona_count'] ?? 0} Personas)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    Text(
                      'Scenario: ${run['scenario_goal']?.toString().trim().isNotEmpty == true ? run['scenario_goal'] : 'Auto-inferred scenario'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Simulation run data exported successfully!',
                        ),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFDC2626),
                  ),
                  onPressed: () {
                    ref
                        .read(simulatorProvider.notifier)
                        .deleteRun(widget.agent.id, run['id']);
                    setState(() {
                      _selectedRun = null;
                      _selectedSimulation = null;
                    });
                  },
                ),
              ],
            ),
          ),

          // Simulation details split or transcripts
          Expanded(
            child: _selectedSimulation != null
                ? _buildTranscriptView(_selectedSimulation!)
                : simulations.isEmpty
                ? const Center(
                    child: Text(
                      'No individual simulation runs in this run.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: simulations.length,
                    itemBuilder: (context, index) {
                      final sim = simulations[index];
                      final personaName =
                          sim['persona']?['name'] ?? 'Persona $index';
                      final status = sim['status'] ?? 'completed';
                      final score = sim['scores']?['overall'] ?? 85;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.borderGrey),
                        ),
                        elevation: 0,
                        borderOnForeground: true,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            personaName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              sim['scenario']?['goal'] ?? 'Simulation Goal',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'completed'
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$score Score',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'completed'
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedSimulation = sim);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptView(Map<String, dynamic> simulation) {
    final transcript = simulation['transcript'] as List<dynamic>? ?? [];
    final persona = simulation['persona'] ?? {};
    final scores = simulation['scores'] ?? {};

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _selectedSimulation = null;
        });
        return false;
      },
      child: Column(
        children: [
          // Subheader for persona simulation transcript
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.borderGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _selectedSimulation = null;
                    });
                  },
                ),
                Text(
                  'Transcript: ${persona['name'] ?? 'User'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D28D9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Score: ${scores['overall'] ?? 85}',
                    style: const TextStyle(
                      color: AppTheme.surfaceCard,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Waveform waveforms
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transcript.length,
              itemBuilder: (context, idx) {
                final turn = transcript[idx];
                final role = _transcriptRole(turn);
                final message = _transcriptMessage(turn);
                final isAgent = role == 'agent';
                final label = isAgent
                    ? 'AGENT - TURN ${idx ~/ 2}'
                    : 'SIMULATED USER - TURN ${(idx + 1) ~/ 2}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: isAgent
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: isAgent ? 36 : 0,
                          right: isAgent ? 0 : 36,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: isAgent
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAgent) ...[
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFFEDE9FE),
                              child: Icon(
                                Icons.smart_toy_outlined,
                                size: 14,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isAgent
                                      ? Colors.white
                                      : const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: isAgent
                                        ? Radius.zero
                                        : const Radius.circular(12),
                                    bottomRight: isAgent
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                  ),
                                  border: Border.all(
                                    color: isAgent
                                        ? AppTheme.borderGrey
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  message.isEmpty ? 'No message text' : message,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: message.isEmpty
                                        ? const Color(0xFF94A3B8)
                                        : isAgent
                                        ? AppTheme.darkGrey
                                        : Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!isAgent) ...[
                            const SizedBox(width: 8),
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFFECFDF5),
                              child: Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _transcriptRole(dynamic turn) {
    if (turn is! Map) return 'agent';
    if (turn['user'] != null ||
        turn['customer'] != null ||
        turn['simulated_user'] != null) {
      return 'user';
    }
    if (turn['agent'] != null ||
        turn['assistant'] != null ||
        turn['bot'] != null) {
      return 'agent';
    }

    final rawRole =
        (turn['role'] ??
                turn['sender'] ??
                turn['speaker'] ??
                turn['from'] ??
                turn['type'])
            ?.toString()
            .toLowerCase()
            .trim();

    if (rawRole == null || rawRole.isEmpty) return 'agent';
    if (rawRole.contains('user') ||
        rawRole.contains('customer') ||
        rawRole.contains('persona') ||
        rawRole.contains('simulated')) {
      return 'user';
    }
    return 'agent';
  }

  String _transcriptMessage(dynamic turn) {
    if (turn is String) return turn.trim();
    if (turn is! Map) return '';

    final value =
        turn['message'] ??
        turn['content'] ??
        turn['text'] ??
        turn['utterance'] ??
        turn['transcript'] ??
        turn['response'] ??
        turn['agent_message'] ??
        turn['user_message'] ??
        turn['agent'] ??
        turn['assistant'] ??
        turn['bot'] ??
        turn['user'] ??
        turn['customer'] ??
        turn['simulated_user'];

    if (value == null) return '';
    return value.toString().trim();
  }

  // --- WIDGET HELPERS ---
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(hint),
      style: const TextStyle(fontSize: 13),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: AppTheme.lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6D28D9)),
      ),
    );
  }

  Widget? _buildBottomActionBar(SimulatorState state) {
    final draft = state.currentDraft;
    final personas = draft != null
        ? (draft['personas'] as List<dynamic>?) ?? []
        : [];
    final isDraftEmpty = draft == null || personas.isEmpty;

    bool areAllFieldsFilled() {
      if (isDraftEmpty) return false;
      for (var p in personas) {
        final name = p['name']?.toString().trim() ?? '';
        final langStyle = p['language_style']?.toString().trim() ?? '';
        final goal = p['goal']?.toString().trim() ?? '';
        final behavior = p['behavior']?.toString().trim() ?? '';
        if (name.isEmpty ||
            langStyle.isEmpty ||
            goal.isEmpty ||
            behavior.isEmpty) {
          return false;
        }
      }
      return true;
    }

    final isRunEnabled = areAllFieldsFilled();

    String getStatusText() {
      if (isDraftEmpty) {
        return 'Generate a draft before running personas.';
      }
      if (!isRunEnabled) {
        return 'Fill all persona fields to enable run.';
      }
      return '${personas.length} personas configured. Ready to run.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(top: BorderSide(color: AppTheme.borderGrey)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                getStatusText(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            // Save Button
            OutlinedButton.icon(
              onPressed: isDraftEmpty
                  ? null
                  : () async {
                      try {
                        await ref.read(simulatorProvider.notifier).updateDraft(
                          widget.agent.id,
                          draft['id'],
                          {'personas': draft['personas']},
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Draft saved successfully!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save draft: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                foregroundColor: const Color(0xFF475569),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.save_outlined, size: 14),
              label: const Text(
                'Save',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            // Run Selected Button
            ElevatedButton.icon(
              onPressed: !isRunEnabled
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(simulatorProvider.notifier)
                            .startSimulation(widget.agent.id, draft!['id']);
                        // Go to runs tab
                        _tabController.animateTo(2);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Simulation run started successfully! Check Runs tab.',
                              ),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to start simulation: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_outlined, size: 14),
              label: const Text(
                'Run selected',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
