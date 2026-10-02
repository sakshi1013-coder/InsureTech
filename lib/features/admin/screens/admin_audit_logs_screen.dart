import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:insurex_app/core/theme/app_colors.dart';
import 'package:insurex_app/core/theme/app_text_styles.dart';
import 'package:insurex_app/services/firebase_service.dart';
import 'package:insurex_app/models/claim_model.dart';
import 'package:insurex_app/widgets/common/app_widgets.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: InsureXAppBar(
        title: 'Audit Logs',
        subtitle: 'Complete system activity trail',
      ),
      body: StreamBuilder<List<AuditLogModel>>(
        stream: fs.getAuditLogs(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final logs = snap.data ?? [];
          if (logs.isEmpty) {
            return const EmptyState(icon: Icons.history_outlined, title: 'No Logs', subtitle: 'No audit activity recorded yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _logCard(logs[i]),
          );
        },
      ),
    );
  }

  Widget _logCard(AuditLogModel log) {
    final config = _getConfig(log.action);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.description, style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(log.userName, style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight, fontSize: 10)),
                    Text(' • ${log.role.toUpperCase()}', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    const Spacer(),
                    Text(DateFormat('MMM dd, HH:mm').format(log.timestamp), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                  ],
                ),
                if (log.claimId != null)
                  Text('Claim: ${log.claimId}', style: AppTextStyles.monospace.copyWith(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getConfig(String action) {
    switch (action) {
      case 'claim_submitted': return {'icon': Icons.assignment_outlined, 'color': AppColors.primary};
      case 'officer_assigned': return {'icon': Icons.person_outlined, 'color': AppColors.info};
      case 'document_verified': return {'icon': Icons.verified_outlined, 'color': AppColors.success};
      case 'document_rejected': return {'icon': Icons.cancel_outlined, 'color': AppColors.danger};
      case 'claim_approved': return {'icon': Icons.check_circle_outlined, 'color': AppColors.success};
      case 'claim_rejected': return {'icon': Icons.close_outlined, 'color': AppColors.danger};
      case 'status_updated': return {'icon': Icons.update_outlined, 'color': AppColors.warning};
      default: return {'icon': Icons.history_outlined, 'color': AppColors.textMuted};
    }
  }
}
