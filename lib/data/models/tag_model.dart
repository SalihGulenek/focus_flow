import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'tag_model.g.dart';

@JsonSerializable()
class TagModel {
  @JsonKey(name: 'ID')
  final String id;
  @JsonKey(name: 'UserID')
  final String userId;
  @JsonKey(name: 'Name')
  final String name;
  @JsonKey(name: 'Color')
  final String? color;
  @JsonKey(name: 'CreatedAt')
  final DateTime createdAt;

  TagModel({required this.id, required this.userId, required this.name, this.color, required this.createdAt});

  Color get tagColor {
    if (color == null || color!.isEmpty) {
      return const Color(0xFF135BEC);
    }
    try {
      return Color(int.parse(color!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF135BEC);
    }
  }

  factory TagModel.fromJson(Map<String, dynamic> json) => _$TagModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagModelToJson(this);

  Map<String, dynamic> toDb() {
    return {'id': id, 'user_id': userId, 'name': name, 'color': color, 'created_at': createdAt.toIso8601String()};
  }

  factory TagModel.fromDb(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
