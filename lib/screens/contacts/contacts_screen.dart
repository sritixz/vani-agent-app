import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/models/contact_model.dart';
import 'package:vani_app/providers/contacts_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Load contacts on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
    
    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  void _loadContacts() {
    final leadStatus = _getLeadStatusFilter();
    ref.read(contactsProvider.notifier).refreshContacts(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      leadStatus: leadStatus,
    );
  }

  void _loadMore() {
    final leadStatus = _getLeadStatusFilter();
    ref.read(contactsProvider.notifier).loadMore(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      leadStatus: leadStatus,
    );
  }

  Future<void> _showStatusUpdateDialog(Contact contact) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildStatusBottomSheet(contact),
    );

    if (result != null && mounted) {
      // Update the contact status
      await ref.read(contactsProvider.notifier).updateContactStatus(
        phoneNumber: contact.phoneNumber,
        leadStatus: result,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_getStatusLabelFromApi(result)}'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  String _getStatusLabelFromApi(String apiStatus) {
    switch (apiStatus) {
      case 'new':
        return 'New Lead';
      case 'attempting':
        return 'Attempting';
      case 'connected':
        return 'Connected';
      case 'junk_dnc':
        return 'Do Not Call';
      default:
        return apiStatus;
    }
  }

  Widget _buildStatusBottomSheet(Contact contact) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Update Status',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                contact.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildStatusOption(
                'New Lead',
                'new',
                AppTheme.primaryGreen,
                Icons.fiber_new,
                contact.status == ContactStatus.newLead,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                'Attempting',
                'attempting',
                AppTheme.warningOrange,
                Icons.phone_in_talk,
                contact.status == ContactStatus.attempting,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                'Connected',
                'connected',
                AppTheme.successGreen,
                Icons.check_circle,
                contact.status == ContactStatus.connected,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                'Do Not Call',
                'junk_dnc',
                AppTheme.errorRed,
                Icons.block,
                contact.status == ContactStatus.doNotCall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : AppTheme.borderGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppTheme.darkGrey,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  String? _getLeadStatusFilter() {
    switch (_selectedFilter) {
      case 'New Leads':
        return 'new';
      case 'Attempting':
        return 'attempting';
      case 'Connected':
        return 'connected';
      case 'Do Not Call':
        return 'junk_dnc';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadContacts();
          },
          child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contacts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchController.text == value) {
                        _loadContacts();
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, status, or tag...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.mediumGrey,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.mediumGrey),
                            onPressed: () {
                              _searchController.clear();
                              _loadContacts();
                            },
                          )
                        : null,
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
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGreen,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedFilter == 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('New Leads', _selectedFilter == 'New Leads'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Attempting', _selectedFilter == 'Attempting'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Connected', _selectedFilter == 'Connected'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Do Not Call', _selectedFilter == 'Do Not Call'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Error message
                if (contactsState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            contactsState.error!,
                            style: const TextStyle(color: AppTheme.errorRed),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.errorRed),
                          onPressed: () {
                            ref.read(contactsProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                  ),
                
                // Loading indicator for initial load
                if (contactsState.isLoading && contactsState.contacts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  )
                
                // Empty state
                else if (contactsState.contacts.isEmpty && !contactsState.isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.contacts_outlined,
                            size: 64,
                            color: AppTheme.mediumGrey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No contacts found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.mediumGrey.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isNotEmpty || _selectedFilter != 'All'
                                ? 'Try adjusting your filters'
                                : 'Start by adding your first contact',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.mediumGrey.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                
                // Contacts list
                else
                  Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: contactsState.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contactsState.contacts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildContactCard(contact),
                          );
                        },
                      ),
                      
                      // Loading indicator for pagination
                      if (contactsState.isLoading && contactsState.contacts.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      
                      // Pagination info
                      if (contactsState.contacts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Showing ${contactsState.contacts.length} of ${contactsState.total} contacts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                            textAlign: TextAlign.center,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add contact screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add contact feature coming soon')),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_selectedFilter != label) {
          setState(() {
            _selectedFilter = label;
          });
          _loadContacts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.darkGrey,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFFFF9999),
      const Color(0xFFFFB366),
      const Color(0xFF99CCFF),
      const Color(0xFFCCCCCC),
      const Color(0xFF99E6B3),
      const Color(0xFFFFCC99),
      const Color(0xFFCC99FF),
      const Color(0xFFFF99CC),
    ];
    return colors[index % colors.length];
  }

  Widget _buildContactCard(Contact contact) {
    final statusColor = _getStatusColor(contact.status);
    final statusLabel = _getStatusLabel(contact.status);
    final avatarColor = _getAvatarColor(contact.phoneNumber.hashCode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                contact.initials,
                style: const TextStyle(
                  fontSize: 16,
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
                  contact.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showStatusUpdateDialog(contact),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                      Icon(
                        Icons.edit,
                        size: 12,
                        color: statusColor.withOpacity(0.7),
                      ),
                      if (contact.totalCalls > 0) ...[
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                        Text(
                          '${contact.totalCalls} call${contact.totalCalls != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mediumGrey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (contact.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: contact.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.phone_outlined,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            onPressed: () {
              // TODO: Implement call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${contact.displayName}...')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              contact.notesCount > 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: contact.notesCount > 0 ? AppTheme.primaryGreen : AppTheme.borderGrey,
              size: 20,
            ),
            onPressed: () {
              // TODO: Navigate to contact details/notes
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('View notes for ${contact.displayName}')),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.newLead:
        return AppTheme.primaryGreen;
      case ContactStatus.attempting:
        return AppTheme.warningOrange;
      case ContactStatus.connected:
        return AppTheme.successGreen;
      case ContactStatus.doNotCall:
        return AppTheme.errorRed;
    }
  }

  String _getStatusLabel(ContactStatus status) {
    switch (status) {
      case ContactStatus.newLead:
        return 'New Lead';
      case ContactStatus.attempting:
        return 'Attempting';
      case ContactStatus.connected:
        return 'Connected';
      case ContactStatus.doNotCall:
        return 'Do Not Call';
    }
  }
}
