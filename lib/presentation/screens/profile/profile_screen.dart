import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/dummy_data/salama_data.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/brand_header.dart';
import '../scan/scan_qr_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = SalamaData.worker;
    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: BrandHeader(trailing: ConnectionPill()),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              AppDimensions.spaceMD,
              AppDimensions.screenPadding,
              AppDimensions.spaceXXL,
            ),
            children: [
              Text('My Profile',
                  style: AppTextStyles.h1.copyWith(fontSize: 19)),
              Text('Manage your account and preferences',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppDimensions.spaceMD),
              _ProfileCard(
                name: w.name,
                role: w.role,
                facility: '${w.facility}, ${w.county}',
                phone: w.phone,
                workerId: w.workerId,
                onQr: () => showScanQrSheet(context),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              Text('Activity summary', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              const _ActivityCard(),
              const SizedBox(height: AppDimensions.spaceMD),
              Text('Account & settings', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              const _SettingsGroup(items: [
                _SettingItem(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.primary,
                  title: 'Personal information',
                  subtitle: 'View and update your details',
                ),
                _SettingItem(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.info,
                  title: 'Security',
                  subtitle: 'Change password and manage PIN',
                ),
                _SettingItem(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.primary,
                  title: 'Language',
                  subtitle: 'English (US)',
                  trailingText: 'English',
                ),
                _SettingItem(
                  icon: Icons.notifications_none_rounded,
                  iconColor: AppColors.accentPurple,
                  title: 'Notifications',
                  subtitle: 'Manage alerts and reminders',
                ),
                _SettingItem(
                  icon: Icons.cloud_sync_outlined,
                  iconColor: AppColors.warningMid,
                  title: 'Sync settings',
                  subtitle: 'Data sync over Wi-Fi or mobile data',
                ),
                _SettingItem(
                  icon: Icons.smartphone_rounded,
                  iconColor: AppColors.primary,
                  title: 'App settings',
                  subtitle: 'Offline mode, data usage and more',
                  isLast: true,
                ),
              ]),
              const SizedBox(height: AppDimensions.spaceMD),
              Text('Support & resources', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              const _SettingsGroup(items: [
                _SettingItem(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.primary,
                  title: 'Help center',
                  subtitle: 'FAQs and user guides',
                ),
                _SettingItem(
                  icon: Icons.headset_mic_outlined,
                  iconColor: AppColors.info,
                  title: 'Contact support',
                  subtitle: 'Get help from the Salama Health team',
                ),
                _SettingItem(
                  icon: Icons.menu_book_outlined,
                  iconColor: AppColors.warningMid,
                  title: 'Training materials',
                  subtitle: 'View guides and training resources',
                ),
                _SettingItem(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.accentPurple,
                  title: 'About Salama Health',
                  subtitle: 'App version 1.0.0',
                  isLast: true,
                ),
              ]),
              const SizedBox(height: AppDimensions.spaceMD),
              const _LogoutButton(),
              const SizedBox(height: AppDimensions.spaceSM),
              Row(
                children: [
                  Text('Last synced: Today, 6:30 AM',
                      style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Synced',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Profile card ─────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String facility;
  final String phone;
  final String workerId;
  final VoidCallback onQr;

  const _ProfileCard({
    required this.name,
    required this.role,
    required this.facility,
    required this.phone,
    required this.workerId,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.cardPaddingSm),
      color: AppColors.primarySurface.withValues(alpha: 0.5),
      borderColor: AppColors.primary.withValues(alpha: 0.16),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.cardBackground, width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 26),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderMedium, width: 1),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          size: 9, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.h2),
                    Text(role, style: AppTextStyles.captionMuted),
                  ],
                ),
              ),
              const StatusPill(
                label: 'Active',
                icon: Icons.verified_outlined,
                color: AppColors.success,
                background: AppColors.successLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
              height: 1,
              thickness: 1,
              color: AppColors.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconLine(
                        icon: Icons.location_on_outlined, text: facility),
                    const SizedBox(height: 5),
                    _IconLine(icon: Icons.phone_outlined, text: phone),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Worker ID',
                      style: AppTextStyles.captionMuted.copyWith(fontSize: 10)),
                  Text(workerId,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: onQr,
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text('My QR Code',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.textTertiary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              style: AppTextStyles.captionMuted,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ── Activity card ────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  static const _stats = [
    (Icons.groups_outlined, AppColors.primary, '128', 'Children\nvisited',
        '↑ 18'),
    (Icons.vaccines_outlined, AppColors.info, '96', 'Doses\nadministered',
        '↑ 12'),
    (Icons.event_available_outlined, AppColors.warningMid, '85%',
        'Visits\ncompleted', '↑ 8pp'),
    (Icons.schedule_rounded, AppColors.accentPurple, '63', 'Hours in\nfield',
        'week'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: List.generate(_stats.length, (i) {
          final s = _stats[i];
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: i < _stats.length - 1
                    ? const Border(
                        right: BorderSide(
                            color: AppColors.borderLight, width: 1))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: s.$2.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Icon(s.$1, size: 13, color: s.$2),
                  ),
                  const SizedBox(height: 5),
                  Text(s.$3,
                      style: AppTextStyles.statNumberSmall
                          .copyWith(fontSize: 16)),
                  const SizedBox(height: 1),
                  Text(s.$4,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionMuted.copyWith(
                        fontSize: 9,
                        height: 1.25,
                      )),
                  const SizedBox(height: 2),
                  Text(s.$5,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Settings group ───────────────────────────────────────────────────────
class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: items),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailingText;
  final bool isLast;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                    color: AppColors.borderLight, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPaddingSm, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4),
                Text(subtitle, style: AppTextStyles.captionMuted),
              ],
            ),
          ),
          if (trailingText != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: AppColors.borderMedium, width: 1),
              ),
              child: Row(
                children: [
                  Text(trailingText!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      )),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 13, color: AppColors.textSecondary),
                ],
              ),
            )
          else
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

// ── Logout ───────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, size: 15, color: AppColors.error),
          const SizedBox(width: 7),
          Text('Log out',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}
