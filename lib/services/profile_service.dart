import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ProfileService {
  final ApiClient _client = ApiClient.instance;

  Future<AppUser> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
    });
    final response = await _client.postForm('/auth/me/avatar', formData);
    return AppUser.fromJson(unwrapUser(response.data as Map<String, dynamic>));
  }
}
