import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:insurex_app/services/cloudinary_service.dart';

void main() {
  test('Real Cloudinary unsigned upload test', () async {
    final service = CloudinaryService();

    // 1x1 transparent PNG bytes
    final testPngBytes = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
      0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
      120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78,
      68, 174, 66, 96, 130
    ]);

    final result = await service.uploadBytes(
      bytes: testPngBytes,
      fileName: 'verification_test_badge.png',
      folder: 'insurex/test',
      resourceType: 'image',
    );

    print('Upload result:');
    print('  secureUrl: ${result.secureUrl}');
    print('  publicId: ${result.publicId}');
    print('  resourceType: ${result.resourceType}');
    print('  bytes: ${result.bytes}');
    print('  format: ${result.format}');

    expect(result.secureUrl.isNotEmpty, true);
    expect(result.secureUrl.startsWith('https://res.cloudinary.com/d2c6a4ta'), true);
    expect(result.publicId.isNotEmpty, true);
    expect(result.resourceType, 'image');
  });
}
