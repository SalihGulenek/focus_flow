// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagModel _$TagModelFromJson(Map<String, dynamic> json) => TagModel(
  id: json['ID'] as String,
  userId: json['UserID'] as String,
  name: json['Name'] as String,
  color: json['Color'] as String?,
  createdAt: DateTime.parse(json['CreatedAt'] as String),
);

Map<String, dynamic> _$TagModelToJson(TagModel instance) => <String, dynamic>{
  'ID': instance.id,
  'UserID': instance.userId,
  'Name': instance.name,
  'Color': instance.color,
  'CreatedAt': instance.createdAt.toIso8601String(),
};
