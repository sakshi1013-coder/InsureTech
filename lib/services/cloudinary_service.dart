import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/app_constants.dart';

/// Result object returned by Cloudinary direct unsigned upload.
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String fileName;
  final int bytes;
  final String? format;

  CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.fileName,
    required this.bytes,
    this.format,
  });

  Map<String, dynamic> toMap() {
    return {
      'secureUrl': secureUrl,
      'publicId': publicId,
      'resourceType': resourceType,
      'fileName': fileName,
      'bytes': bytes,
      'format': format,
    };
  }
}

/// Cloudinary Direct Client-Side Service
/// Uses unsigned upload preset directly from Flutter.
/// Never exposes or uses Cloudinary API secret.
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  /// Cloudinary cloud name: d2c6a4ta
  String _cloudName = AppConstants.cloudinaryCloudName;

  /// Configurable unsigned upload preset
  String _uploadPreset = AppConstants.cloudinaryUploadPreset;

  final ImagePicker _picker = ImagePicker();

  String get cloudName => _cloudName;
  String get uploadPreset => _uploadPreset;

  /// Allows dynamically configuring the cloud name or preset if needed
  void configure({String? cloudName, String? uploadPreset}) {
    if (cloudName != null && cloudName.trim().isNotEmpty) {
      _cloudName = cloudName.trim();
    }
    if (uploadPreset != null && uploadPreset.trim().isNotEmpty) {
      _uploadPreset = uploadPreset.trim();
      AppConstants.cloudinaryUploadPreset = _uploadPreset;
    }
  }

  // Allowed extensions
  static const Set<String> allowedDocExtensions = {'pdf', 'jpg', 'jpeg', 'png'};
  static const Set<String> allowedEvidenceExtensions = {'jpg', 'jpeg', 'png', 'mp4'};

  // Size limits
  static const int maxDocSizeBytes = AppConstants.maxDocSizeMB * 1024 * 1024;
  static const int maxImageSizeBytes = AppConstants.maxImageSizeMB * 1024 * 1024;
  static const int maxVideoSizeBytes = AppConstants.maxVideoSizeMB * 1024 * 1024;

  /// Validate file type based on extension
  void validateFileType(String fileName, {required bool isEvidence, bool isVideo = false}) {
    final ext = fileName.split('.').last.toLowerCase();
    if (isEvidence) {
      if (isVideo) {
        if (ext != 'mp4') {
          throw Exception('Invalid video format ($ext). Allowed format: MP4.');
        }
      } else {
        if (!allowedEvidenceExtensions.contains(ext)) {
          throw Exception('Invalid evidence format ($ext). Allowed: JPG, JPEG, PNG, MP4.');
        }
      }
    } else {
      if (!allowedDocExtensions.contains(ext)) {
        throw Exception('Invalid document format ($ext). Allowed: PDF, JPG, JPEG, PNG.');
      }
    }
  }

  /// Validate file size in bytes
  void validateFileSize(int sizeInBytes, {required bool isEvidence, bool isVideo = false}) {
    if (isVideo) {
      if (sizeInBytes > maxVideoSizeBytes) {
        throw Exception('Video exceeds maximum size limit of ${AppConstants.maxVideoSizeMB}MB.');
      }
    } else if (isEvidence) {
      if (sizeInBytes > maxImageSizeBytes) {
        throw Exception('Evidence image exceeds maximum size limit of ${AppConstants.maxImageSizeMB}MB.');
      }
    } else {
      if (sizeInBytes > maxDocSizeBytes) {
        throw Exception('Document exceeds maximum size limit of ${AppConstants.maxDocSizeMB}MB.');
      }
    }
  }

  /// Core Direct Unsigned Upload to Cloudinary
  Future<CloudinaryUploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String? resourceType, // 'image', 'video', 'raw', or 'auto'
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Cannot upload empty file.');
    }

    final ext = fileName.split('.').last.toLowerCase();
    final effectiveResourceType = resourceType ?? (ext == 'mp4' ? 'video' : (ext == 'pdf' ? 'raw' : 'image'));

    print('[Cloudinary] File selected: $fileName');
    print('[Cloudinary] File size: ${bytes.length} bytes');
    print('[Cloudinary] Upload started');
    print('[Cloudinary] Cloud name: $_cloudName');
    print('[Cloudinary] Upload preset: $_uploadPreset');
    print('[Cloudinary] Uploading...');

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$effectiveResourceType/upload');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['api_key'] = AppConstants.cloudinaryApiKey
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      if (folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final responseBody = await streamedResponse.stream.bytesToString();

      print('[Cloudinary] Response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final secureUrl = data['secure_url']?.toString() ?? '';
        final publicId = data['public_id']?.toString() ?? '';
        final resType = data['resource_type']?.toString() ?? effectiveResourceType;

        print('[Cloudinary] secure_url: $secureUrl');
        print('[Cloudinary] public_id: $publicId');
        print('[Cloudinary] resource_type: $resType');

        return CloudinaryUploadResult(
          secureUrl: secureUrl,
          publicId: publicId,
          resourceType: resType,
          fileName: fileName,
          bytes: (data['bytes'] is num) ? (data['bytes'] as num).toInt() : bytes.length,
          format: data['format']?.toString() ?? ext,
        );
      } else {
        print('[Cloudinary] COMPLETE ERROR RESPONSE: $responseBody');
        throw Exception('Cloudinary upload failed (${streamedResponse.statusCode}): $responseBody');
      }
    } catch (e) {
      print('[Cloudinary] Upload exception: $e');
      rethrow;
    }
  }

  /// Direct unsigned upload helper alias
  Future<CloudinaryUploadResult> uploadFileDirectUnsigned({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String? resourceType,
  }) =>
      uploadBytes(
        bytes: bytes,
        fileName: fileName,
        folder: folder,
        resourceType: resourceType,
      );

  /// Pick and upload image
  Future<CloudinaryUploadResult?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    String folder = 'claims/evidence',
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    validateFileType(file.name, isEvidence: true, isVideo: false);
    validateFileSize(bytes.length, isEvidence: true, isVideo: false);

    return uploadBytes(
      bytes: bytes,
      fileName: file.name,
      folder: folder,
      resourceType: 'image',
    );
  }

  /// Pick and upload video
  Future<CloudinaryUploadResult?> pickAndUploadVideo({
    ImageSource source = ImageSource.gallery,
    String folder = 'claims/evidence',
  }) async {
    final XFile? file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 3),
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    validateFileType(file.name, isEvidence: true, isVideo: true);
    validateFileSize(bytes.length, isEvidence: true, isVideo: true);

    return uploadBytes(
      bytes: bytes,
      fileName: file.name,
      folder: folder,
      resourceType: 'video',
    );
  }

  /// Pick and upload document (PDF, PNG, JPG)
  Future<CloudinaryUploadResult?> pickAndUploadDocument({
    String folder = 'claims/documents',
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    validateFileType(picked.name, isEvidence: false);
    validateFileSize(bytes.length, isEvidence: false);

    final ext = picked.name.split('.').last.toLowerCase();
    final resourceType = (ext == 'pdf') ? 'raw' : 'image';

    return uploadBytes(
      bytes: bytes,
      fileName: picked.name,
      folder: folder,
      resourceType: resourceType,
    );
  }

  /// Format byte counts nicely
  String formatBytes(int byteCount) {
    if (byteCount < 1024) return '$byteCount B';
    if (byteCount < 1024 * 1024) return '${(byteCount / 1024).toStringAsFixed(1)} KB';
    return '${(byteCount / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
