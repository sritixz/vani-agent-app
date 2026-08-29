import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedContactList {
  final String id;
  final String name;
  final String description;
  final List<String> phoneNumbers;
  final DateTime createdAt;

  SavedContactList({
    required this.id,
    required this.name,
    this.description = '',
    required this.phoneNumbers,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'phoneNumbers': phoneNumbers,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedContactList.fromJson(Map<String, dynamic> json) => SavedContactList(
        id: (json['id'] ?? json['_id'] ?? json['contact_list_id'] ?? 'list_${DateTime.now().millisecondsSinceEpoch}') as String,
        name: (json['name'] ?? json['contact_list_name'] ?? 'Contact List') as String,
        description: (json['description'] as String?) ?? '',
        phoneNumbers: List<String>.from(
          (json['phoneNumbers'] ?? json['phone_numbers'] ?? json['contacts'] ?? [])
              .map((e) => e is Map ? (e['phone_number'] ?? e['phone'] ?? '').toString() : e.toString())
              .where((s) => s.toString().isNotEmpty),
        ),
        createdAt: DateTime.tryParse((json['createdAt'] ?? json['created_at'] ?? '') as String) ?? DateTime.now(),
      );
}

class SavedListsNotifier extends StateNotifier<List<SavedContactList>> {
  SavedListsNotifier()
      : super([
          SavedContactList(
            id: '6a927eec8b9ad6ec6d146325',
            name: 'August Callbacks',
            description: 'Saved contact audience from web',
            phoneNumbers: ['+917337592673', '+919920433172'],
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          SavedContactList(
            id: 'list_1',
            name: 'Q3 Real Estate High Intent Leads',
            description: 'Filtered high intent leads from CRM',
            phoneNumbers: ['+917337592673', '+919920433172'],
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          SavedContactList(
            id: 'list_2',
            name: 'Healthcare Followup List',
            description: 'Patients requiring clinic confirmation',
            phoneNumbers: ['+919876543210'],
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ]);

  void loadServerLists(List<Map<String, dynamic>> rawLists) {
    if (rawLists.isEmpty) return;
    final serverLists = rawLists.map((json) => SavedContactList.fromJson(json)).toList();
    final existingIds = serverLists.map((l) => l.id).toSet();
    final localOnly = state.where((l) => !existingIds.contains(l.id)).toList();
    state = [...serverLists, ...localOnly];
  }

  void addList({
    required String name,
    String description = '',
    required List<String> phoneNumbers,
    String? id,
  }) {
    final newList = SavedContactList(
      id: id ?? 'list_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      phoneNumbers: phoneNumbers,
      createdAt: DateTime.now(),
    );
    state = [newList, ...state.where((l) => l.id != newList.id)];
  }

  void deleteList(String id) {
    state = state.where((l) => l.id != id).toList();
  }
}

final savedListsProvider = StateNotifierProvider<SavedListsNotifier, List<SavedContactList>>((ref) {
  return SavedListsNotifier();
});
