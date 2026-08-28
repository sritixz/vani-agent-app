import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/contacts_api_service.dart';
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
  Timer? _searchDebounce;
  
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
    _searchDebounce?.cancel();
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

  Future<void> _importCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading ${file.name}...')),
        );

        final service = ref.read(contactsApiServiceProvider);
        await service.bulkUploadContacts(file);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacts CSV imported successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          _loadContacts();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing CSV: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _showAddContactDialog() async {
    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final tagController = TextEditingController();
    final noteController = TextEditingController();
    String selectedStatus = 'new';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add New Contact / Lead',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(modalContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (E.164) *',
                          hintText: '+919876543210',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (!val.trim().startsWith('+') || val.trim().length < 8) {
                            return 'Enter valid phone with country code (e.g. +91...)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Name',
                          hintText: 'John Doe',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'john@example.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Lead Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'new', child: Text('New Lead')),
                          DropdownMenuItem(value: 'attempting', child: Text('Attempting')),
                          DropdownMenuItem(value: 'connected', child: Text('Connected')),
                          DropdownMenuItem(value: 'junk_dnc', child: Text('Do Not Call')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                          hintText: 'VIP, RealEstate, Warm',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          hintText: 'Initial consultation lead info',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSubmitting = true);

                                  final tagsList = tagController.text
                                      .split(',')
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();

                                  final success = await ref
                                      .read(contactsProvider.notifier)
                                      .addContact(
                                        phoneNumber: phoneController.text.trim(),
                                        contactName: nameController.text.trim(),
                                        email: emailController.text.trim(),
                                        leadStatus: selectedStatus,
                                        tags: tagsList,
                                        note: noteController.text.trim(),
                                      );

                                  if (mounted) {
                                    Navigator.pop(modalContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? 'Contact added successfully!'
                                            : 'Failed to add contact'),
                                        backgroundColor: success
                                            ? AppTheme.successGreen
                                            : AppTheme.errorRed,
                                      ),
                                    );
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Contact', style: TextStyle(fontSize: 16)),
                        ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contacts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateListDialog,
                      icon: const Icon(Icons.playlist_add, size: 18),
                      label: const Text('Create List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                      if (mounted) {
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
                      _buildFilterChip('New Lead', _selectedFilter == 'New Lead'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Attempting', _selectedFilter == 'Attempting'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Connected', _selectedFilter == 'Connected'),
                      const SizedBox(width: 8),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_csv_btn',
            onPressed: _importCsvFile,
            backgroundColor: AppTheme.surfaceCard,
            foregroundColor: AppTheme.darkGrey,
            icon: const Icon(Icons.upload_file, color: AppTheme.primaryGreen),
            label: const Text('Import CSV', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add_contact_btn',
            onPressed: _showAddContactDialog,
            backgroundColor: AppTheme.primaryGreen,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
