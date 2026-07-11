import 'package:json_annotation/json_annotation.dart';

part 'conversation_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ConversationModel {
  final String id;
  final String? title;
  final List<MessageModel>? messages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationModel({
    required this.id,
    this.title,
    this.messages,
    this.createdAt,
    this.updatedAt,
  });

  ConversationModel copyWith({
    String? id,
    String? title,
    List<MessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.metadata,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RunAgentRequest {
  final String? conversationId;
  final String message;
  final Map<String, dynamic>? context;

  RunAgentRequest({
    this.conversationId,
    required this.message,
    this.context,
  });

  Map<String, dynamic> toJson() => _$RunAgentRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RunAgentResponse {
  final String conversationId;
  final MessageModel message;
  final Map<String, dynamic>? metadata;

  RunAgentResponse({
    required this.conversationId,
    required this.message,
    this.metadata,
  });

  factory RunAgentResponse.fromJson(Map<String, dynamic> json) =>
      _$RunAgentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RunAgentResponseToJson(this);
}
