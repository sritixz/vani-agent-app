import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vani_app/data/services/contacts_api_service.dart';
import 'package:vani_app/models/contact_model.dart';

// State class for contacts
class ContactsState {
  final List<Contact> contacts;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int total;
  final bool hasMore;

  ContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasMore = false,
  });

  ContactsState copyWith({
    List<Contact>? contacts,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    int? total,
    bool? hasMore,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Contacts notifier
class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactsApiService _apiService;

  ContactsNotifier(this._apiService) : super(ContactsState());

  Future<void> loadContacts({
    int page = 1,
    int limit = 20,
    String? search,
    String? leadStatus,
    String? source,
    bool? hasCalls,
    bool? hasNotes,
    String? tags,
    bool append = false,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getContacts(
        page: page,
        limit: limit,
        search: search,
        leadStatus: leadStatus,
        source: source,
        hasCalls: hasCalls,
        hasNotes: hasNotes,
        tags: tags,
      );

      final newContacts = append
          ? [...state.contacts, ...response.contacts]
          : response.contacts;

      state = state.copyWith(
        contacts: newContacts,
        isLoading: false,
        currentPage: response.page,
        totalPages: response.pages,
        total: response.total,
        hasMore: response.page < response.pages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshContacts({
    String? search,
    String? leadStatus,
    String? source,
    bool? hasCalls,
    bool? hasNotes,
    String? tags,
  }) async {
    await loadContacts(
      page: 1,
      search: search,
      leadStatus: leadStatus,
      source: source,
      hasCalls: hasCalls,
      hasNotes: hasNotes,
      tags: tags,
      append: false,
    );
  }

  Future<void> loadMore({
    String? search,
    String? leadStatus,
    String? source,
    bool? hasCalls,
    bool? hasNotes,
    String? tags,
  }) async {
    if (!state.hasMore || state.isLoading) return;

    await loadContacts(
      page: state.currentPage + 1,
      search: search,
      leadStatus: leadStatus,
      source: source,
      hasCalls: hasCalls,
      hasNotes: hasNotes,
      tags: tags,
      append: true,
    );
  }

  Future<void> updateContactStatus({
    required String phoneNumber,
    required String leadStatus,
  }) async {
    // Optimistically update local contact state
    final List<Contact> updatedContacts = state.contacts.map<Contact>((contact) {
      if (contact.phoneNumber == phoneNumber) {
        return contact.copyWith(leadStatus: leadStatus);
      }
      return contact;
    }).toList();

    state = state.copyWith(contacts: updatedContacts, error: null);

    try {
      final updatedContact = await _apiService.updateContactStatus(
        phoneNumber: phoneNumber,
        leadStatus: leadStatus,
      );

      if (updatedContact != null) {
        final List<Contact> finalContacts = state.contacts.map<Contact>((c) {
          return c.phoneNumber == phoneNumber ? updatedContact : c;
        }).toList();
        state = state.copyWith(contacts: finalContacts);
      }
    } catch (_) {
      // Keep optimistic local update active; clear any transient error
      state = state.copyWith(error: null);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  final apiService = ref.watch(contactsApiServiceProvider);
  return ContactsNotifier(apiService);
});
