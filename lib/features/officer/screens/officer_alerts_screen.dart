import 'package:flutter/material.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';
import 'officer_claim_detail_screen.dart';
import 'officer_profile_screen.dart';

class OfficerAlertsScreen extends StatefulWidget {
  const OfficerAlertsScreen({super.key});

  @override
  State<OfficerAlertsScreen> createState() => _OfficerAlertsScreenState();
}

class _OfficerAlertsScreenState extends State<OfficerAlertsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unread', 'SLA Critical', 'New Assignments'];

  late List<Map<String, dynamic>> _alerts;

  @override
  void initState() {
    super.initState();
    _alerts = [
      {
        'id': 'alt_1',
        'title': 'New Claim Assigned',
        'message': 'Claim CLM-2024-4576 (Vehicle Collision · ₹3,800) assigned to your field queue.',
        'time': '10 mins ago',
        'isRead': false,
        'claimId': 'clm_1',
        'type': 'new_claim',
        'priority': 'Critical',
      },
      {
        'id': 'alt_2',
        'title': 'SLA Breached',
        'message': 'SLA breached for CLM-2024-2109: Initial assessment report overdue by 4 hours.',
        'time': '35 mins ago',
        'isRead': false,
        'claimId': 'clm_4',
        'type': 'sla_breached',
        'priority': 'Critical',
      },
      {
        'id': 'alt_3',
        'title': 'Document Uploaded',
        'message': 'Insured Alex Johnson uploaded Police FIR Report and Dashcam footage for review.',
        'time': '1 hour ago',
        'isRead': false,
        'claimId': 'clm_1',
        'type': 'doc_upload',
        'priority': 'High',
      },
      {
        'id': 'alt_4',
        'title': 'SLA Approaching',
        'message': 'SLA approaching on CLM-2024-3901: 2 hours left before initial contact SLA expires.',
        'time': '3 hours ago',
        'isRead': true,
        'claimId': 'clm_2',
        'type': 'sla_warning',
        'priority': 'High',
      },
      {
        'id': 'alt_5',
        'title': 'Customer Requested Information',
        'message': 'Claimant Sarah Miller sent a query regarding garage deductible approval.',
        'time': '5 hours ago',
        'isRead': true,
        'claimId': 'clm_2',
        'type': 'info_request',
        'priority': 'Medium',
      },
      {
        'id': 'alt_6',
        'title': 'Claim Status Changed',
        'message': 'CLM-2024-5120 moved to Estimate Approval by supervisor Marcus Vance.',
        'time': 'Yesterday',
        'isRead': true,
        'claimId': 'clm_3',
        'type': 'status_change',
        'priority': 'Low',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _alerts;
    if (_selectedFilter == 'Unread') {
      filtered = _alerts.where((a) => a['isRead'] == false).toList();
    } else if (_selectedFilter == 'SLA Critical') {
      filtered = _alerts.where((a) => a['priority'] == 'Critical').toList();
    } else if (_selectedFilter == 'New Assignments') {
      filtered = _alerts.where((a) => a['type'] == 'new_claim').toList();
    }

    final unreadCount = _alerts.where((a) => a['isRead'] == false).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header
            _buildHeader(unreadCount),

            // Filter Chips
            _buildFilters(),

            // Alerts List
            Expanded(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.notifications_none_outlined,
                        title: 'No Alerts Found',
                        subtitle: 'You are all caught up with your field notifications.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildAlertCard(filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      color: AppColors.veniceBlue,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Alerts & Dispatch',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'CRITICAL INCIDENT & SLA MONITORING',
                style: TextStyle(
                  color: AppColors.rockBlueLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (unreadCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  for (var a in _alerts) {
                    a['isRead'] = true;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.done_all, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Mark Read ($unreadCount)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfficerProfileScreen()),
              );
            },
            child: Tooltip(
              message: 'Officer Profile',
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.rockBlueLight, width: 1.2),
                ),
                child: const Center(
                  child: Text(
                    'MV',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryBlue : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryBlue : AppColors.border,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final bool isUnread = alert['isRead'] == false;
    final String type = alert['type'] as String;
    final String priority = alert['priority'] as String;

    IconData iconData = Icons.notifications_outlined;
    Color iconColor = AppColors.primaryBlue;
    Color bgColor = AppColors.lightBlue;

    if (type == 'sla_breached' || priority == 'Critical') {
      iconData = Icons.warning_amber_rounded;
      iconColor = AppColors.error;
      bgColor = AppColors.dangerLight;
    } else if (type == 'new_claim') {
      iconData = Icons.assignment_turned_in_outlined;
      iconColor = AppColors.veniceBlue;
      bgColor = AppColors.lightBlue;
    } else if (type == 'doc_upload') {
      iconData = Icons.upload_file_outlined;
      iconColor = AppColors.veniceBlue;
      bgColor = AppColors.lightBlue;
    } else if (type == 'sla_warning') {
      iconData = Icons.alarm_outlined;
      iconColor = AppColors.warning;
      bgColor = AppColors.warningLight;
    } else if (type == 'info_request') {
      iconData = Icons.chat_bubble_outline;
      iconColor = AppColors.rockBlueDark;
      bgColor = AppColors.lightBlue;
    }

    return AppCard(
      onTap: () {
        setState(() => alert['isRead'] = true);
        final claimId = alert['claimId'] as String?;
        if (claimId != null && claimId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OfficerClaimDetailScreen(claimId: claimId),
            ),
          );
        }
      },
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Message & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert['title'] as String,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      alert['time'] as String,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert['message'] as String,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
