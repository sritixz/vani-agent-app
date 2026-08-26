import 'package:flutter/material.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/models/agents/agent_template_model.dart';
import 'package:vani_app/screens/agents/create_edit_agent_screen.dart';

class BrowseTemplatesScreen extends StatefulWidget {
  const BrowseTemplatesScreen({super.key});

  @override
  State<BrowseTemplatesScreen> createState() => _BrowseTemplatesScreenState();
}

class _BrowseTemplatesScreenState extends State<BrowseTemplatesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedLanguage = 'English (India)';

  final List<String> _categories = [
    'All',
    'Healthcare',
    'Real Estate',
    'E-commerce',
    'Human Resources',
    'Hospitality',
    'Automotive',
    'Education',
    'Travel',
    'Dental Care',
    'Events',
    'Financial Services',
    'Optical Retail',
    'Field Services',
    'Agriculture',
    'Pharmaceutical',
    'Creative Services',
    'Coaching & Training',
    'Heavy Equipment',
    'Diagnostics',
    'Insurance',
    'Student Housing',
    'Religious Services',
    'D2C Commerce',
    'Payments',
    'Logistics',
    'Solar Energy',
    'Distribution',
    'Citizen Services',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AgentTemplateModel> get _filteredTemplates {
    final query = _searchController.text.toLowerCase().trim();
    return defaultAgentTemplates.where((t) {
      final matchesCategory = _selectedCategory == 'All' || t.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query) ||
          t.useCase.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _filteredTemplates;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkGrey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Realtime Templates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGrey,
              ),
            ),
            Text(
              'Realtime starters with Roman-script Indian language variants',
              style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search & Filter Controls Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: Column(
                    children: [
                      // Search Input
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search templates...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.mediumGrey, size: 20),
                          filled: true,
                          fillColor: AppTheme.lightGrey,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dropdown Filters Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedLanguage,
                              decoration: InputDecoration(
                                labelText: 'Language',
                                filled: true,
                                fillColor: AppTheme.lightGrey,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'English (India)', child: Text('English (India)', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedLanguage = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                filled: true,
                                fillColor: AppTheme.lightGrey,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category Chips Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.take(10).map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.darkGrey)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          backgroundColor: AppTheme.surfaceCard,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Results Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${templates.length} templates',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Templates Grid / List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTemplateCard(template),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(AgentTemplateModel template) {
    final pct = (template.usedTokens / template.maxTokens).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Tag & Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  template.category,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mediumGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            template.description,
            style: const TextStyle(fontSize: 12, color: AppTheme.mediumGrey),
          ),
          const SizedBox(height: 12),

          // Metadata Grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Language', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
                    Text(template.language, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Persona & voice', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
                    Text(template.personaVoice, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Call limit', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
                    Text(template.callLimit, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Use case', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
                    Text(template.useCase, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Token Budget Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prompt budget', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
              Text('${template.usedTokens} / ${template.maxTokens}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppTheme.lightGrey,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),

          // Sample Prompt Snippet & "Use ->" Button Row
          Row(
            children: [
              Expanded(
                child: Text(
                  template.samplePrompt,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.mediumGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEditAgentScreen(template: template),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                label: const Text('Use', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
