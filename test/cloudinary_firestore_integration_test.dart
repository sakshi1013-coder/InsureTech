import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:insurex_app/services/cloudinary_service.dart';
import 'package:insurex_app/services/firestore_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/core/constants/app_constants.dart';

void main() {
  test('Cloudinary upload and Firestore metadata persistence test', () async {
    final cloudinary = CloudinaryService();
    final firestore = FirestoreService();

    // 1. Upload to Cloudinary
    final testBytes = Uint8List.fromList([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
      0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68, 65, 84,
      120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78,
      68, 174, 66, 96, 130
    ]);

    final uploadRes = await cloudinary.uploadBytes(
      bytes: testBytes,
      fileName: 'claim_police_report.png',
      folder: 'insurex/documents',
      resourceType: 'image',
    );

    expect(uploadRes.secureUrl.startsWith('https://res.cloudinary.com/d2c6a4ta'), true);
    expect(uploadRes.publicId.isNotEmpty, true);

    // 2. Persist metadata into Firestore
    final docId = await firestore.addDocument(DocumentModel(
      id: '',
      claimId: 'clm_test_123',
      customerId: 'usr_customer_demo',
      documentType: 'Police Report',
      fileName: uploadRes.fileName,
      fileUrl: uploadRes.secureUrl,
      cloudinaryPublicId: uploadRes.publicId,
      resourceType: uploadRes.resourceType,
      fileSize: cloudinary.formatBytes(uploadRes.bytes),
      verificationStatus: AppConstants.docPending,
      uploadedAt: DateTime.now(),
    ));

    expect(docId.isNotEmpty, true);

    // 3. Persist evidence into Firestore
    final evId = await firestore.addEvidence(EvidenceModel(
      id: '',
      claimId: 'clm_test_123',
      customerId: 'usr_customer_demo',
      type: 'image',
      fileName: uploadRes.fileName,
      fileUrl: uploadRes.secureUrl,
      cloudinaryPublicId: uploadRes.publicId,
      resourceType: uploadRes.resourceType,
      description: 'Accident scene evidence',
      uploadedAt: DateTime.now(),
    ));

    expect(evId.isNotEmpty, true);
  });
}
