// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['ID'] as String,
  email: json['Email'] as String,
  fullName: json['FullName'] as String?,
  avatarUrl: json['AvatarURL'] as String?,
  timezone: json['Timezone'] as String,
  createdAt: DateTime.parse(json['CreatedAt'] as String),
  updatedAt: DateTime.parse(json['UpdatedAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'ID': instance.id,
  'Email': instance.email,
  'FullName': instance.fullName,
  'AvatarURL': instance.avatarUrl,
  'Timezone': instance.timezone,
  'CreatedAt': instance.createdAt.toIso8601String(),
  'UpdatedAt': instance.updatedAt.toIso8601String(),
};
