import 'dart:convert';
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
        id: json['id'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        phoneNumbers: List<String>.from((json['phoneNumbers'] as List? ?? [])),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class SavedListsNotifier extends StateNotifier<List<SavedContactList>> {
  SavedListsNotifier()
      : super([
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

  void addList({
    required String name,
    String description = '',
    required List<String> phoneNumbers,
  }) {
    final newList = SavedContactList(
      id: 'list_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      phoneNumbers: phoneNumbers,
      createdAt: DateTime.now(),
    );
    state = [newList, ...state];
  }

  void deleteList(String id) {
    state = state.where((l) => l.id != id).toList();
  }
}

final savedListsProvider = StateNotifierProvider<SavedListsNotifier, List<SavedContactList>>((ref) {
  return SavedListsNotifier();
});
