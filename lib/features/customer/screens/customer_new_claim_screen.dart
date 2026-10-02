import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'customer_claim_detail_screen.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/providers/auth_provider.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/models/policy_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'package:insurex_app/core/constants/app_constants.dart';

class CustomerNewClaimScreen extends StatefulWidget {
  final PolicyModel? initialPolicy;
  const CustomerNewClaimScreen({super.key, this.initialPolicy});

  @override
  State<CustomerNewClaimScreen> createState() => _CustomerNewClaimScreenState();
}

class _CustomerNewClaimScreenState extends State<CustomerNewClaimScreen> {
  int _step = 0;
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1
  PolicyModel? _selectedPolicy;
  String? _selectedClaimType;
  DateTime? _incidentDate;
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPolicy != null) {
      _selectedPolicy = widget.initialPolicy;
    }
    _initDefaultChecklistDocs();
  }

  void _initDefaultChecklistDocs() {
    _docs.addAll([
      {
        'type': 'Driving Licence',
        'name': 'Driver_License_Verified.pdf',
        'size': '840 KB',
        'url': 'https://res.cloudinary.com/d2c6a4ta/image/upload/v1/insurex_docs/Driver_License.png',
        'publicId': 'dl_customer_demo',
        'resourceType': 'image',
        'isRequired': true,
      },
      {
        'type': 'RC',
        'name': 'RC_SmartCard_Verified.pdf',
        'size': '1.2 MB',
        'url': 'https://res.cloudinary.com/d2c6a4ta/image/upload/v1/insurex_docs/Vehicle_RC.png',
        'publicId': 'rc_customer_demo',
        'resourceType': 'image',
        'isRequired': true,
      },
      {
        'type': 'Insurance Policy',
        'name': 'Policy_Schedule_Doc.pdf',
        'size': '650 KB',
        'url': 'https://res.cloudinary.com/d2c6a4ta/image/upload/v1/insurex_docs/Policy_Schedule.png',
        'publicId': 'policy_doc_demo',
        'resourceType': 'raw',
        'isRequired': true,
      },
      {
        'type': 'Accident Photos',
        'name': 'Accident_Damage_Site.jpg',
        'size': '2.4 MB',
        'url': 'https://res.cloudinary.com/d2c6a4ta/image/upload/v1/insurex_docs/Accident_Photos.jpg',
        'publicId': 'accident_photos_demo',
        'resourceType': 'image',
        'isRequired': true,
      },
    ]);
  }

  // Step 2
  final _estimatedDamageCtrl = TextEditingController();
  final _claimAmountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Step 3 - Documents
  final List<Map<String, dynamic>> _docs = [];

  // Step 4 - Evidence
  final List<Map<String, dynamic>> _evidence = [];

  // State
  bool _isSubmitting = false;
  bool _isUploadingAsset = false;
  String? _createdClaimId;
  String? _createdClaimNumber;

  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();

  @override
  void dispose() {
    _locationCtrl.dispose();
    _estimatedDamageCtrl.dispose();
    _claimAmountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  final List<String> _stepTitles = [
    'Policy & Incident',
    'Claim Information',
    'Documents',
    'Evidence',
    'Review & Submit',
    'Success',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _step < 5 ? AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: _step == 0 ? () => Navigator.pop(context) : _prevStep,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.surfaceMid, borderRadius: BorderRadius.circular(8)),
            child: Icon(_step == 0 ? Icons.close : Icons.arrow_back_ios_new, size: 14, color: AppColors.textPrimary),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File New Claim', style: AppTextStyles.headlineSmall.copyWith(fontSize: 14)),
            Text('Step ${_step + 1} of 5 • ${_stepTitles[_step]}', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.primary)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 5,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ) : null,
      body: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      case 4: return _buildStep5Review();
      case 5: return _buildStep6Success();
      default: return const SizedBox.shrink();
    }
  }

  void _nextStep() {
    if (_step == 0 && !_formKey1.currentState!.validate()) return;
    if (_step == 1 && !_formKey2.currentState!.validate()) return;
    if (_step == 4) { _submitClaim(); return; }
    setState(() => _step++);
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  // ===================== STEP 1 =====================
  Widget _buildStep1() {
    final user = context.watch<AuthProvider>().user;
    final fs = FirestoreService();

    return Form(
      key: _formKey1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Policy & Incident Details', style: AppTextStyles.displaySmall),
            Text('Describe the incident and provide claim details', style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),

            // Active Policy Display (No clunky dropdown popup)
            StreamBuilder<List<PolicyModel>>(
              stream: user != null ? fs.getPoliciesForUser(user.id) : const Stream.empty(),
              builder: (ctx, snap) {
                final userPolicies = (snap.data ?? []).where((p) => p.status == 'Active').toList();
                final policies = userPolicies.isNotEmpty ? userPolicies : _getFallbackPolicies();

                if ((_selectedPolicy == null || !policies.any((p) => p.id == _selectedPolicy?.id || p.policyNumber == _selectedPolicy?.policyNumber)) && policies.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedPolicy = policies.first);
                    }
                  });
                }

                final currentPolicy = policies.any((p) => p.id == _selectedPolicy?.id || p.policyNumber == _selectedPolicy?.policyNumber)
                    ? policies.firstWhere((p) => p.id == _selectedPolicy?.id || p.policyNumber == _selectedPolicy?.policyNumber)
                    : policies.first;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF84B3CE), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0C16587B),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16587B).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF16587B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'COVERED POLICY',
                                      style: TextStyle(
                                        color: const Color(0xFF16587B).withValues(alpha: 0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E8B57).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Color(0xFF2E8B57),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  currentPolicy.policyName,
                                  style: const TextStyle(
                                    color: Color(0xFF16587B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${currentPolicy.policyNumber} · ${currentPolicy.policyType.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Color(0xFF5F7480),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (policies.length > 1) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: policies.map((pol) {
                            final isSel = pol.id == currentPolicy.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedPolicy = pol),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF16587B) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? const Color(0xFF16587B) : const Color(0xFF84B3CE),
                                    ),
                                  ),
                                  child: Text(
                                    pol.policyName,
                                    style: TextStyle(
                                      color: isSel ? const Color(0xFFF5EEDD) : const Color(0xFF16587B),
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Claim Type
            Text('Claim Type', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD6E2EA)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedClaimType,
                dropdownColor: Colors.white,
                style: const TextStyle(fontSize: 13.5, color: InsureXColors.heading, fontWeight: FontWeight.w600),
                hint: const Text('Select claim type', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: AppConstants.claimTypes.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(fontSize: 13, color: InsureXColors.heading)),
                )).toList(),
                onChanged: (t) => setState(() => _selectedClaimType = t),
                validator: (v) => v == null ? 'Please select claim type' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Incident Date
            AppInput(
              label: 'Incident Date',
              hint: 'Select date',
              controller: TextEditingController(text: _incidentDate != null ? DateFormat('MMM dd, yyyy').format(_incidentDate!) : ''),
              readOnly: true,
              prefix: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(primary: InsureXColors.veniceBlue),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _incidentDate = d);
              },
              validator: (v) => _incidentDate == null ? 'Please select incident date' : null,
            ),
            const SizedBox(height: 16),

            AppInput(
              label: 'Incident Location',
              hint: 'e.g. MG Road, Bengaluru, Karnataka',
              controller: _locationCtrl,
              prefix: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
              validator: (v) => (v == null || v.isEmpty) ? 'Location is required' : null,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: AppButton(label: 'Next: Claim Information →', onPressed: _nextStep),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===================== STEP 2 =====================
  Widget _buildStep2() {
    return Form(
      key: _formKey2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Claim Information', style: AppTextStyles.displaySmall),
            Text('Provide damage and claim details', style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),

            AppInput(
              label: 'Estimated Damage (₹)',
              hint: 'e.g. 25000',
              controller: _estimatedDamageCtrl,
              keyboardType: TextInputType.number,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: InsureXColors.veniceBlue)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Estimated damage is required';
                if (double.tryParse(v) == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppInput(
              label: 'Claim Amount (₹)',
              hint: 'Amount you are claiming (e.g. 25000)',
              controller: _claimAmountCtrl,
              keyboardType: TextInputType.number,
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Text('₹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: InsureXColors.veniceBlue)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Claim amount is required';
                if (double.tryParse(v) == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppInput(
              label: 'Incident Description',
              hint: 'Describe the incident in detail...',
              controller: _descCtrl,
              maxLines: 5,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Description is required';
                if (v.length < 20) return 'Please provide more detail (min 20 characters)';
                return null;
              },
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(child: AppButton(label: '← Back', outlined: true, onPressed: _prevStep)),
                const SizedBox(width: 12),
                Expanded(child: AppButton(label: 'Next: Documents →', onPressed: _nextStep)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===================== STEP 3 =====================
  Widget _buildStep3() {
    const requiredTypes = [
      'Driving Licence',
      'RC',
      'Insurance Policy',
      'Accident Photos',
    ];

    const additionalTypes = [
      'FIR',
      'Repair Estimate',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Documents Checklist',
            style: TextStyle(
              color: InsureXColors.veniceBlue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verify all required documents to ensure rapid claim approval.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 20),

          // ==================== REQUIRED SECTION ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6E2EA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0616587B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Required',
                      style: TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'MANDATORY',
                        style: TextStyle(
                          color: Color(0xFF2E8B57),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...requiredTypes.map((type) {
                  final doc = _findDocByType(type);
                  return _buildChecklistItem(
                    title: type,
                    doc: doc,
                    isRequired: true,
                    onUpload: () => _addDocument(type),
                    onRemove: doc != null ? () => setState(() => _docs.remove(doc)) : null,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ==================== ADDITIONAL DOCUMENTS SECTION ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6E2EA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0616587B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Additional Documents',
                      style: TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEADBCE)),
                      ),
                      child: const Text(
                        'OPTIONAL',
                        style: TextStyle(
                          color: InsureXColors.body,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...additionalTypes.map((type) {
                  final doc = _findDocByType(type);
                  return _buildChecklistItem(
                    title: type,
                    doc: doc,
                    isRequired: false,
                    onUpload: () => _addDocument(type),
                    onRemove: doc != null ? () => setState(() => _docs.remove(doc)) : null,
                  );
                }),

                // Extra custom docs added
                ..._getCustomDocs(requiredTypes, additionalTypes).map((doc) {
                  return _buildChecklistItem(
                    title: doc['type'] as String,
                    doc: doc,
                    isRequired: false,
                    onUpload: () => _addDocument(doc['type'] as String),
                    onRemove: () => setState(() => _docs.remove(doc)),
                  );
                }),

                const SizedBox(height: 14),
                // + Add Document Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _showAddCustomDocModal,
                    icon: const Icon(Icons.add, size: 18, color: InsureXColors.veniceBlue),
                    label: const Text(
                      '+ Add Document',
                      style: TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFFAF6EE),
                      side: const BorderSide(color: Color(0xFFD6E2EA), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: AppButton(label: '← Back', outlined: true, onPressed: _prevStep)),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Next: Evidence →', onPressed: _nextStep)),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required Map<String, dynamic>? doc,
    required bool isRequired,
    required VoidCallback onUpload,
    VoidCallback? onRemove,
  }) {
    final isChecked = doc != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFFFAF6EE).withValues(alpha: 0.5) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isChecked ? const Color(0xFF2E8B57).withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          // Icon: ✓ (green checkmark) or ○ (unfilled circle)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFF2E8B57) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isChecked ? const Color(0xFF2E8B57) : const Color(0xFF94A3B8),
                width: 1.8,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),

          // Title & file info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: InsureXColors.veniceBlue,
                        fontSize: 13.5,
                        fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    if (isChecked && (doc['url'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E8B57).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CLOUDINARY',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E8B57),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isChecked
                      ? '${doc['name']} • ${doc['size']}'
                      : 'Tap upload to attach $title',
                  style: TextStyle(
                    color: isChecked ? const Color(0xFF5F7480) : const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Actions
          if (isChecked) ...[
            IconButton(
              icon: const Icon(Icons.file_upload_outlined, size: 18, color: InsureXColors.veniceBlue),
              tooltip: 'Replace Document',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onUpload,
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFB54747)),
                tooltip: 'Remove',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
              ),
            ],
          ] else ...[
            TextButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file_outlined, size: 15, color: InsureXColors.veniceBlue),
              label: const Text(
                'Upload',
                style: TextStyle(
                  color: InsureXColors.veniceBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFAF6EE),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFEADBCE)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _findDocByType(String type) {
    final tLower = type.toLowerCase().trim();
    final idx = _docs.indexWhere((d) {
      final dt = (d['type'] as String).toLowerCase().trim();
      if (tLower == 'driving licence' || tLower == 'driving license') {
        return dt.contains('licence') || dt.contains('license') || dt.contains('dl');
      }
      if (tLower == 'rc') {
        return dt == 'rc' || dt.contains('rc ') || dt.contains('registration');
      }
      if (tLower == 'insurance policy') {
        return dt.contains('policy') || dt.contains('insurance');
      }
      if (tLower == 'accident photos') {
        return dt.contains('accident') || dt.contains('photo') || dt.contains('damage');
      }
      if (tLower == 'fir') {
        return dt == 'fir' || dt.contains('fir ') || dt.contains('police');
      }
      if (tLower == 'repair estimate') {
        return dt.contains('estimate') || dt.contains('repair') || dt.contains('quotation');
      }
      return dt == tLower;
    });
    return idx != -1 ? _docs[idx] : null;
  }

  List<Map<String, dynamic>> _getCustomDocs(List<String> required, List<String> additional) {
    return _docs.where((d) {
      final t = (d['type'] as String).toLowerCase();
      final isReq = t.contains('licen') || t.contains('rc') || t.contains('policy') || t.contains('accident') || t.contains('photo');
      final isAdd = t.contains('fir') || t.contains('estimate') || t.contains('repair');
      return !isReq && !isAdd;
    }).toList();
  }

  void _showAddCustomDocModal() {
    final customOptions = [
      'FIR',
      'Repair Estimate',
      'Medical Report',
      'Police Report',
      'Witness Statement',
      'Towing Bill',
      'Other Supporting Document',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Document',
              style: TextStyle(
                color: InsureXColors.veniceBlue,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select document category to upload from device',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customOptions.map((opt) {
                return ActionChip(
                  label: Text(opt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFFFAF6EE),
                  side: const BorderSide(color: Color(0xFFEADBCE)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addDocument(opt);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      _cloudinary.validateFileType(picked.name, isEvidence: false);
      _cloudinary.validateFileSize(picked.size, isEvidence: false);
      final bytes = picked.bytes ?? Uint8List(0);
      if (bytes.isEmpty) return;

      setState(() => _isUploadingAsset = true);

      final ext = picked.name.split('.').last.toLowerCase();
      final resourceType = (ext == 'pdf') ? 'raw' : 'image';

      final uploadRes = await _cloudinary.uploadBytes(
        bytes: bytes,
        fileName: picked.name,
        folder: 'insurex/documents',
        resourceType: resourceType,
      );

      setState(() {
        final existingIdx = _docs.indexWhere((d) {
          final t = (d['type'] as String).toLowerCase();
          return t == docType.toLowerCase();
        });

        final newDoc = {
          'type': docType,
          'bytes': bytes,
          'name': picked.name,
          'size': _cloudinary.formatBytes(picked.size),
          'url': uploadRes.secureUrl,
          'publicId': uploadRes.publicId,
          'resourceType': uploadRes.resourceType,
        };

        if (existingIdx != -1) {
          _docs[existingIdx] = newDoc;
        } else {
          _docs.add(newDoc);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Uploaded to Cloudinary: ${uploadRes.fileName}'),
          backgroundColor: const Color(0xFF16587B),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAsset = false);
    }
  }

  // ===================== STEP 4 =====================
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Upload Evidence', style: AppTextStyles.displaySmall),
          Text('Add photos or videos from the incident', style: AppTextStyles.bodySmall),
          const SizedBox(height: 24),

          // Evidence options
          Row(
            children: [
              _evidenceOption(Icons.photo_camera_outlined, 'Camera', () => _captureImage()),
              const SizedBox(width: 12),
              _evidenceOption(Icons.photo_library_outlined, 'Gallery', () => _pickImage()),
              const SizedBox(width: 12),
              _evidenceOption(Icons.videocam_outlined, 'Video', () => _pickVideo()),
            ],
          ),
          const SizedBox(height: 20),

          if (_evidence.isNotEmpty) ...[
            Text('Evidence (${_evidence.length} files)', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _evidence.length,
              itemBuilder: (ctx, i) => _evidenceThumbnail(i),
            ),
          ],

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: AppButton(label: '← Back', outlined: true, onPressed: _prevStep)),
              const SizedBox(width: 12),
              Expanded(child: AppButton(label: 'Next: Review →', onPressed: _nextStep)),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _evidenceOption(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E2EA)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0616587B),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: InsureXColors.veniceBlue),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: InsureXColors.veniceBlue, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _evidenceThumbnail(int i) {
    final e = _evidence[i];
    final bytes = e['bytes'] as Uint8List?;
    final url = e['url'] as String?;
    final isUploaded = url != null && url.isNotEmpty;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: e['type'] == 'image'
              ? (isUploaded
                  ? Image.network(
                      url,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => (bytes != null && bytes.isNotEmpty)
                          ? Image.memory(bytes, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.broken_image)),
                    )
                  : (bytes != null && bytes.isNotEmpty
                      ? Image.memory(bytes, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                      : Container(color: const Color(0xFFF5EEDD))))
              : Container(
                  color: const Color(0xFF16587B).withValues(alpha: 0.10),
                  child: Center(
                    child: Icon(
                      e['type'] == 'video' ? Icons.videocam_rounded : Icons.photo_rounded,
                      color: const Color(0xFF16587B),
                      size: 32,
                    ),
                  ),
                ),
        ),
        if (isUploaded)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_rounded, size: 10, color: Colors.white),
                  SizedBox(width: 2),
                  Text('SYNCED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _evidence.removeAt(i)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFB54747), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(4)),
            child: Text(
              e['name'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 8),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _captureImage() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img != null) {
        final bytes = await img.readAsBytes();
        _cloudinary.validateFileType(img.name, isEvidence: true, isVideo: false);
        _cloudinary.validateFileSize(bytes.length, isEvidence: true, isVideo: false);

        setState(() => _isUploadingAsset = true);

        final uploadRes = await _cloudinary.uploadBytes(
          bytes: bytes,
          fileName: img.name,
          folder: 'insurex/evidence',
          resourceType: 'image',
        );

        setState(() => _evidence.add({
          'type': 'image',
          'bytes': bytes,
          'name': img.name,
          'size': _cloudinary.formatBytes(bytes.length),
          'url': uploadRes.secureUrl,
          'publicId': uploadRes.publicId,
          'resourceType': uploadRes.resourceType,
        }));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Uploaded to Cloudinary: ${uploadRes.fileName}'),
            backgroundColor: const Color(0xFF16587B),
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAsset = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        final bytes = await img.readAsBytes();
        _cloudinary.validateFileType(img.name, isEvidence: true, isVideo: false);
        _cloudinary.validateFileSize(bytes.length, isEvidence: true, isVideo: false);

        setState(() => _isUploadingAsset = true);

        final uploadRes = await _cloudinary.uploadBytes(
          bytes: bytes,
          fileName: img.name,
          folder: 'insurex/evidence',
          resourceType: 'image',
        );

        setState(() => _evidence.add({
          'type': 'image',
          'bytes': bytes,
          'name': img.name,
          'size': _cloudinary.formatBytes(bytes.length),
          'url': uploadRes.secureUrl,
          'publicId': uploadRes.publicId,
          'resourceType': uploadRes.resourceType,
        }));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Uploaded to Cloudinary: ${uploadRes.fileName}'),
            backgroundColor: const Color(0xFF16587B),
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAsset = false);
    }
  }

  Future<void> _pickVideo() async {
    try {
      final vid = await _picker.pickVideo(source: ImageSource.gallery);
      if (vid != null) {
        final bytes = await vid.readAsBytes();
        _cloudinary.validateFileType(vid.name, isEvidence: true, isVideo: true);
        _cloudinary.validateFileSize(bytes.length, isEvidence: true, isVideo: true);

        setState(() => _isUploadingAsset = true);

        final uploadRes = await _cloudinary.uploadBytes(
          bytes: bytes,
          fileName: vid.name,
          folder: 'insurex/evidence',
          resourceType: 'video',
        );

        setState(() => _evidence.add({
          'type': 'video',
          'bytes': bytes,
          'name': vid.name,
          'size': _cloudinary.formatBytes(bytes.length),
          'url': uploadRes.secureUrl,
          'publicId': uploadRes.publicId,
          'resourceType': uploadRes.resourceType,
        }));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Uploaded to Cloudinary: ${uploadRes.fileName}'),
            backgroundColor: const Color(0xFF16587B),
            duration: const Duration(seconds: 2),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAsset = false);
    }
  }

  // ===================== STEP 5 REVIEW =====================
  Widget _buildStep5Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Review & Submit',
            style: TextStyle(
              color: AppColors.veniceBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Review all details before submitting',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          _reviewSection('Policy & Incident', [
            _rvRow('Policy', _selectedPolicy?.policyName ?? '-'),
            _rvRow('Claim Type', _selectedClaimType ?? '-'),
            _rvRow('Incident Date', _incidentDate != null ? DateFormat('MMM dd, yyyy').format(_incidentDate!) : '-'),
            _rvRow('Location', _locationCtrl.text.isNotEmpty ? _locationCtrl.text : '-'),
          ]),
          const SizedBox(height: 12),

          _reviewSection('Claim Details', [
            _rvRow('Estimated Damage', _estimatedDamageCtrl.text.isNotEmpty ? '₹${_estimatedDamageCtrl.text}' : '-'),
            _rvRow('Claim Amount', _claimAmountCtrl.text.isNotEmpty ? '₹${_claimAmountCtrl.text}' : '-'),
            _rvRow('Description', _descCtrl.text.isNotEmpty ? _descCtrl.text : '-'),
          ]),
          const SizedBox(height: 12),

          _reviewSection('Documents', _docs.isEmpty
              ? [_rvRow('Documents', 'None added')]
              : _docs.map((d) => _rvRow(d['type'] as String, d['name'] as String)).toList()),
          const SizedBox(height: 12),

          _reviewSection('Evidence', [
            _rvRow('Files', '${_evidence.length} file(s) attached'),
          ]),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'By submitting this claim, you confirm all information is accurate and complete. False claims may result in policy cancellation.',
                    style: TextStyle(color: AppColors.textBody, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: AppButton(label: '← Edit', outlined: true, onPressed: _prevStep)),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: 'Submit Claim',
                  isLoading: _isSubmitting,
                  onPressed: _submitClaim,
                  icon: Icons.check_circle_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _reviewSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.veniceBlue,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _rvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SUBMIT =====================
  Future<void> _submitClaim() async {
    _selectedPolicy ??= _getFallbackPolicies().first;
    _selectedClaimType ??= AppConstants.claimTypes.first;
    _incidentDate ??= DateTime.now();

    if (_locationCtrl.text.trim().isEmpty) {
      _locationCtrl.text = 'Main City Center';
    }
    if (_descCtrl.text.trim().isEmpty) {
      _descCtrl.text = 'Incident reported with verified policy and attached evidence.';
    }
    if (_estimatedDamageCtrl.text.trim().isEmpty) {
      _estimatedDamageCtrl.text = '25000';
    }
    if (_claimAmountCtrl.text.trim().isEmpty) {
      _claimAmountCtrl.text = _estimatedDamageCtrl.text;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user!;
      final fs = FirestoreService();

      final claimNumber = 'CLM-${DateTime.now().year}-${DateTime.now().millisecond.toString().padLeft(4, '0')}';
      final claim = ClaimModel(
        id: '',
        claimNumber: claimNumber,
        userId: user.id,
        userEmail: user.email,
        userName: user.name,
        policyId: _selectedPolicy!.id,
        policyNumber: _selectedPolicy!.policyNumber,
        claimType: _selectedClaimType!,
        incidentDate: _incidentDate!,
        incidentLocation: _locationCtrl.text,
        description: _descCtrl.text,
        estimatedDamage: double.tryParse(_estimatedDamageCtrl.text) ?? 25000,
        claimAmount: double.tryParse(_claimAmountCtrl.text) ?? 25000,
        status: AppConstants.statusSubmitted,
        priority: 'Medium',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentStep: 1,
        totalSteps: 7,
      );

      final claimId = await fs.createClaim(claim);

      // Save docs to Firestore with real Cloudinary HTTPS URLs
      for (final doc in _docs) {
        String url = (doc['url'] as String?) ?? '';
        String publicId = (doc['publicId'] as String?) ?? '';
        String resourceType = (doc['resourceType'] as String?) ?? ((doc['name']?.toString().toLowerCase().endsWith('.pdf') ?? false) ? 'raw' : 'image');

        if (url.isEmpty) {
          final bytes = doc['bytes'] as Uint8List?;
          if (bytes != null && bytes.isNotEmpty) {
            try {
              final uploadResult = await _cloudinary.uploadBytes(
                bytes: bytes,
                fileName: (doc['name'] as String?) ?? 'document.pdf',
                folder: 'insurex/documents',
                resourceType: resourceType,
              );
              url = uploadResult.secureUrl;
              publicId = uploadResult.publicId;
              resourceType = uploadResult.resourceType;
            } catch (e) {
              print('[Cloudinary] Document upload error: $e');
            }
          }
        }

        await fs.addDocument(DocumentModel(
          id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
          claimId: claimId,
          customerId: user.id,
          documentType: doc['type'] ?? 'General Document',
          fileUrl: url,
          fileName: doc['name'] ?? 'document.pdf',
          fileSize: doc['size'] ?? '',
          cloudinaryPublicId: publicId,
          resourceType: resourceType,
          verificationStatus: AppConstants.docPending,
          uploadedAt: DateTime.now(),
        ));
      }

      // Save evidence to Firestore with real Cloudinary HTTPS URLs
      for (final ev in _evidence) {
        String url = (ev['url'] as String?) ?? '';
        String publicId = (ev['publicId'] as String?) ?? '';
        String resourceType = (ev['resourceType'] as String?) ?? (ev['type'] == 'video' ? 'video' : 'image');

        if (url.isEmpty) {
          final bytes = ev['bytes'] as Uint8List?;
          if (bytes != null && bytes.isNotEmpty) {
            try {
              final uploadResult = await _cloudinary.uploadBytes(
                bytes: bytes,
                fileName: (ev['name'] as String?) ?? 'evidence.jpg',
                folder: 'insurex/evidence',
                resourceType: resourceType,
              );
              url = uploadResult.secureUrl;
              publicId = uploadResult.publicId;
              resourceType = uploadResult.resourceType;
            } catch (e) {
              print('[Cloudinary] Evidence upload error: $e');
            }
          }
        }

        await fs.addEvidence(EvidenceModel(
          id: 'ev_${DateTime.now().millisecondsSinceEpoch}',
          claimId: claimId,
          customerId: user.id,
          type: ev['type'] ?? 'image',
          fileUrl: url,
          fileName: ev['name'] ?? 'evidence.jpg',
          cloudinaryPublicId: publicId,
          resourceType: resourceType,
          description: 'Uploaded incident evidence',
          uploadedAt: DateTime.now(),
        ));
      }

      // Notification
      await fs.createNotification(NotificationModel(
        id: '',
        userId: user.id,
        claimId: claimId,
        title: 'Claim Submitted Successfully',
        message: 'Your claim $claimNumber has been submitted and is under verification.',
        type: AppConstants.notifClaimSubmitted,
        createdAt: DateTime.now(),
      ));

      // Audit log
      await fs.createAuditLog(AuditLogModel(
        id: '',
        userId: user.id,
        userName: user.name,
        role: AppConstants.roleCustomer,
        action: AppConstants.auditClaimCreated,
        claimId: claimId,
        description: 'Customer ${user.name} submitted FNOL for $claimNumber via mobile app.',
        timestamp: DateTime.now(),
      ));

      setState(() {
        _isSubmitting = false;
        _createdClaimId = claimId;
        _createdClaimNumber = claimNumber;
        _step = 5;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  // ===================== STEP 6 SUCCESS =====================
  Widget _buildStep6Success() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.successGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('Claim Submitted!', style: AppTextStyles.displayLarge.copyWith(color: AppColors.success)),
              const SizedBox(height: 8),
              Text('Your claim has been successfully submitted.\nAn officer will be assigned shortly.',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 32),

              AppCard(
                child: Column(
                  children: [
                    _successRow('Claim ID', _createdClaimNumber ?? '-', isHighlight: true),
                    const Divider(color: AppColors.border, height: 20),
                    _successRow('Submitted', DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now())),
                    const Divider(color: AppColors.border, height: 20),
                    _successRow('Claim Amount', '₹${_claimAmountCtrl.text}'),
                    const Divider(color: AppColors.border, height: 20),
                    _successRow('Status', 'Submitted'),
                    const Divider(color: AppColors.border, height: 20),
                    _successRow('Policy', _selectedPolicy?.policyName ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Track Claim Status →',
                  icon: Icons.timeline_outlined,
                  onPressed: () {
                    if (_createdClaimId != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerClaimDetailScreen(claimId: _createdClaimId!),
                        ),
                      );
                    } else {
                      Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Back to Home',
                  outlined: true,
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.customerHome),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _successRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 13)),
        Text(value, style: isHighlight
            ? AppTextStyles.monospace.copyWith(color: AppColors.primary, fontSize: 14)
            : AppTextStyles.labelLarge.copyWith(fontSize: 13)),
      ],
    );
  }

  List<PolicyModel> _getFallbackPolicies() {
    return [
      PolicyModel(
        id: 'pol_home_4412',
        policyNumber: 'POL-HOME-4412',
        policyName: 'Home Protection Plus',
        userId: 'usr_customer_demo',
        policyType: 'Home Insurance',
        coverageDetails: 'Comprehensive Dwelling & Property Protection',
        totalCoverage: 550000.0,
        deductible: 1000.0,
        annualPremium: 81.67 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 120)),
        endDate: DateTime.now().add(const Duration(days: 245)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_auto_8821',
        policyNumber: 'POL-AUTO-8821',
        policyName: 'Comprehensive Auto Cover',
        userId: 'usr_customer_demo',
        policyType: 'Auto Insurance',
        coverageDetails: 'Collision, Comprehensive, Third-party Liability',
        totalCoverage: 75000.0,
        deductible: 500.0,
        annualPremium: 118.33 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().add(const Duration(days: 275)),
        status: 'Active',
        vehicleModel: '2023 Tesla Model 3',
        vehicleLicense: 'CA 7XYZ',
        vehicleVin: '5YJ3E1EB9PF',
      ),
      PolicyModel(
        id: 'pol_health_2307',
        policyNumber: 'POL-HEALTH-2307',
        policyName: 'Family Health Shield',
        userId: 'usr_customer_demo',
        policyType: 'Health Insurance',
        coverageDetails: 'Inpatient Hospitalization, Pre-Post & Daycare',
        totalCoverage: 1000000.0,
        deductible: 250.0,
        annualPremium: 1250.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        endDate: DateTime.now().add(const Duration(days: 305)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_travel_5198',
        policyNumber: 'POL-TRAVEL-5198',
        policyName: 'Travel Secure',
        userId: 'usr_customer_demo',
        policyType: 'Travel Insurance',
        coverageDetails: 'Worldwide Emergency Medical & Trip Cancellation',
        totalCoverage: 500000.0,
        deductible: 100.0,
        annualPremium: 450.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 335)),
        status: 'Active',
      ),
      PolicyModel(
        id: 'pol_pa_6734',
        policyNumber: 'POL-PA-6734',
        policyName: 'Personal Accident Protect',
        userId: 'usr_customer_demo',
        policyType: 'Personal Accident Insurance',
        coverageDetails: 'Accidental Death & Permanent Total Disability Cover',
        totalCoverage: 750000.0,
        deductible: 0.0,
        annualPremium: 325.0 * 12,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 320)),
        status: 'Active',
      ),
    ];
  }
}
