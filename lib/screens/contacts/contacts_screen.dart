import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/config/theme.dart';
import 'package:vani_app/data/services/contacts_api_service.dart';
import 'package:vani_app/models/contact_model.dart';
import 'package:vani_app/providers/contacts_provider.dart';
import 'package:vani_app/providers/saved_lists_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _selectedFilter = 'All';
  final Set<String> _selectedPhoneNumbers = {};
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

  void _showSavedListsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final savedLists = ref.watch(savedListsProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Saved Contact Lists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (savedLists.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No saved contact lists yet', style: TextStyle(color: AppTheme.mediumGrey)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: savedLists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final list = savedLists[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderGrey),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.contacts, size: 20, color: Colors.purple),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                                      if (list.description.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(list.description, style: const TextStyle(fontSize: 10, color: AppTheme.mediumGrey)),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${list.phoneNumbers.length} contacts',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Preview Contact List',
                                      icon: const Icon(Icons.visibility_outlined, color: AppTheme.darkGrey, size: 20),
                                      onPressed: () => _showPreviewListModal(list),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit Contact List',
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditListModal(list),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Contact List',
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed, size: 20),
                                      onPressed: () {
                                        ref.read(savedListsProvider.notifier).deleteList(list.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Deleted list "${list.name}"')),
                                        );
                                      },
                                    ),
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
          },
        );
      },
    );
  }

  void _showPreviewListModal(SavedContactList list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list_alt, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          Text(list.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text('${list.phoneNumbers.length} contacts', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('Saved contact list', style: TextStyle(fontSize: 11, color: AppTheme.mediumGrey)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search this list by name, phone or email...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.mediumGrey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: list.phoneNumbers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final phone = list.phoneNumbers[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkGrey)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(4)),
                                child: const Text('New', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('OUTCOME', style: TextStyle(fontSize: 9, color: AppTheme.mediumGrey)),
                              Text('● Neutral', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.darkGrey)),
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
      },
    );
  }

  void _showEditListModal(SavedContactList list) {
    final nameController = TextEditingController(text: list.name);
    final descController = TextEditingController(text: list.description);
    final phoneNumbers = List<String>.from(list.phoneNumbers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit Contact List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'List Name *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CONTACTS (${phoneNumbers.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.mediumGrey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: phoneNumbers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final phone = phoneNumbers[idx];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGrey,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderGrey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                onPressed: () {
                                  setModalState(() {
                                    phoneNumbers.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          ref.read(savedListsProvider.notifier).deleteList(list.id);
                          ref.read(savedListsProvider.notifier).addList(
                                name: name,
                                description: descController.text.trim(),
                                phoneNumbers: phoneNumbers.isNotEmpty ? phoneNumbers : ['+917337592673'],
                              );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Updated list "$name"'), backgroundColor: AppTheme.primaryGreen),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateListDialog() {
    final listNameController = TextEditingController();
    final listDescriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.playlist_add, color: Colors.purple),
              SizedBox(width: 8),
              Text('Create Contact List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Colors.purple),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedPhoneNumbers.isEmpty
                              ? 'Select contacts, then save them as a list'
                              : 'Saving ${_selectedPhoneNumbers.length} selected contacts as a list',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: listNameController,
                  decoration: const InputDecoration(
                    labelText: 'List Name *',
                    hintText: 'e.g. Q3 High Intent Real Estate Leads',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a list name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: listDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Target audience criteria or notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final name = listNameController.text.trim();
                  final desc = listDescriptionController.text.trim();
                  final selectedList = _selectedPhoneNumbers.toList();

                  ref.read(savedListsProvider.notifier).addList(
                        name: name,
                        description: desc,
                        phoneNumbers: selectedList.isNotEmpty ? selectedList : ['+917337592673'],
                      );

                  Navigator.of(ctx).pop();

                  setState(() {
                    _selectedPhoneNumbers.clear();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact List "$name" created with ${selectedList.isNotEmpty ? selectedList.length : 1} contacts!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create List', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
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
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showSavedListsDialog,
                          icon: const Icon(Icons.list_alt, size: 16, color: Colors.purple),
                          label: const Text('Lists', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.purple),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showCreateListDialog,
                          icon: const Icon(Icons.playlist_add, size: 16),
                          label: Text(
                            _selectedPhoneNumbers.isNotEmpty
                                ? 'Create List (${_selectedPhoneNumbers.length})'
                                : 'Create List',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_selectedPhoneNumbers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedPhoneNumbers.length} contacts selected',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPhoneNumbers.clear();
                                  _selectedPhoneNumbers.addAll(
                                    contactsState.contacts.map((c) => c.phoneNumber),
                                  );
                                });
                              },
                              child: const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPhoneNumbers.clear();
                                });
                              },
                              child: const Text('Clear', style: TextStyle(fontSize: 12, color: AppTheme.mediumGrey)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
                      _buildFilterChip('Junk / DNC', _selectedFilter == 'Junk / DNC'),
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
    final isSelected = _selectedPhoneNumbers.contains(contact.phoneNumber);
    final statusColor = _getStatusColor(contact.status);
    final statusLabel = _getStatusLabel(contact.status);
    final avatarColor = _getAvatarColor(contact.phoneNumber.hashCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.withOpacity(0.04) : Colors.white,
        border: Border.all(
          color: isSelected ? Colors.purple : AppTheme.borderGrey,
          width: isSelected ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: Colors.purple,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedPhoneNumbers.add(contact.phoneNumber);
                } else {
                  _selectedPhoneNumbers.remove(contact.phoneNumber);
                }
              });
            },
          ),
          const SizedBox(width: 4),
          Container(
            width: 44,
            height: 44,
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
