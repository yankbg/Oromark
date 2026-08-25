// lib/data/services/cloudinary_service.dart
//
// Uploads a profile picture to Cloudinary using an unsigned upload preset.
// Deliberately does NOT use the Cloudinary API secret — that must never be
// embedded in a client app (anyone could extract it from the APK and use
// it to manage/delete the whole Cloudinary account). An unsigned upload
// preset, configured in the Cloudinary dashboard, is the safe client-side
// upload path: cloud name + preset name are not secrets.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadException implements Exception {
  final String message;
  CloudinaryUploadException(this.message);
  @override
  String toString() => message;
}

class CloudinaryService {
  /// Uploads [file] and returns its Cloudinary secure_url.
  Future<String> uploadImage(File file) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || cloudName.isEmpty || uploadPreset == null || uploadPreset.isEmpty) {
      throw CloudinaryUploadException(
        'Cloudinary is not configured — set CLOUDINARY_CLOUD_NAME and '
        'CLOUDINARY_UPLOAD_PRESET in .env',
      );
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw CloudinaryUploadException('Upload timed out — check your internet connection.'),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw CloudinaryUploadException(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null) {
      throw CloudinaryUploadException('Cloudinary response missing secure_url');
    }
    return secureUrl;
  }
}
