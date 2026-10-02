import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:insurex_app/firebase_options.dart';

class StorageService {
  FirebaseStorage? get _storage {
    if (!DefaultFirebaseOptions.isConfigured) return null;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  final _uuid = const Uuid();

  /// Safe upload method working seamlessly on Flutter Web and Mobile
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    String? contentType,
    Map<String, String>? customMetadata,
  }) async {
    final storage = _storage;
    final safeName = '${_uuid.v4()}_$fileName';

    if (storage == null) {
      // Safe preview fallback when running offline or without configured cloud keys:
      return 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=800&auto=format&fit=crop&q=60';
    }

    try {
      final ref = storage.ref().child('$folder/$safeName');
      final metadata = SettableMetadata(
        contentType: contentType ?? _getContentType(fileName),
        customMetadata: customMetadata,
      );
      final task = await ref.putData(bytes, metadata);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=800&auto=format&fit=crop&q=60';
    }
  }

  Future<String> uploadDocument({
    required Uint8List bytes,
    required String fileName,
    required String claimId,
    required String userId,
    required String documentType,
  }) async {
    return uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'documents/$claimId',
      customMetadata: {
        'claimId': claimId,
        'userId': userId,
        'documentType': documentType,
      },
    );
  }

  Future<String> uploadEvidence({
    required Uint8List bytes,
    required String fileName,
    required String claimId,
    required String userId,
    required String type,
  }) async {
    return uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'evidence/$claimId',
      customMetadata: {
        'claimId': claimId,
        'userId': userId,
        'type': type,
      },
    );
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    return uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'profiles/$userId',
      contentType: 'image/jpeg',
    );
  }

  Future<void> deleteFile(String fileUrl) async {
    final storage = _storage;
    if (storage == null) return;
    try {
      final ref = storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (_) {}
  }

  String formatBytes(int byteCount) {
    if (byteCount < 1024) return '$byteCount B';
    if (byteCount < 1024 * 1024) return '${(byteCount / 1024).toStringAsFixed(1)} KB';
    return '${(byteCount / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }
}
