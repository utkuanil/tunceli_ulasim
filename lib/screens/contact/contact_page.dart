import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const String _phone = '04282121327';
  static const String _phoneDisplay =
      '0 (428) 212 13 27';

  static const String _fax =
      '0 (428) 212 10 17';

  static const String _email =
      'info@tunceli.bel.tr';

  static const String _address =
      'Moğultay Mahallesi Cami Sokak No: 3 Merkez/Tunceli';

  // =========================================================
  // TELEFON
  // =========================================================

  Future<void> _call(
      BuildContext context,
      ) async {
    final uri = Uri(
      scheme: 'tel',
      path: _phone,
    );

    if (!await launchUrl(uri)) {
      if (!context.mounted) return;

      _showError(
        context,
        'Telefon uygulaması açılamadı.',
      );
    }
  }

  // =========================================================
  // E-POSTA
  // =========================================================

  Future<void> _sendEmail(
      BuildContext context,
      ) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
    );

    if (!await launchUrl(uri)) {
      if (!context.mounted) return;

      _showError(
        context,
        'E-posta uygulaması açılamadı.',
      );
    }
  }

  // =========================================================
  // HARİTA
  // =========================================================

  Future<void> _openMap(
      BuildContext context,
      ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
          '${Uri.encodeComponent(_address)}',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!context.mounted) return;

      _showError(
        context,
        'Harita açılamadı.',
      );
    }
  }

  // =========================================================
  // WEB SİTESİ
  // =========================================================

  Future<void> _openWebsite(
      BuildContext context,
      ) async {
    final uri = Uri.parse(
      'http://www.tunceli.bel.tr',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!context.mounted) return;

      _showError(
        context,
        'Web sitesi açılamadı.',
      );
    }
  }

  // =========================================================
  // HATA
  // =========================================================

  void _showError(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'İletişim ve Geri Bildirim',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          30,
        ),
        children: [
          // ==================================================
          // HERO
          // ==================================================
          const _ContactHero(),

          const SizedBox(height: 22),

          // ==================================================
          // İLETİŞİM BAŞLIĞI
          // ==================================================
          const Text(
            'İletişim Bilgileri',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Belediyeye ulaşabileceğiniz iletişim kanalları',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // TELEFON
          // ==================================================
          _ContactCard(
            icon: Icons.phone_outlined,
            title: 'Telefon',
            value: _phoneDisplay,
            actionIcon: Icons.call_rounded,
            actionText: 'Ara',
            onTap: () => _call(context),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // E-POSTA
          // ==================================================
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'E-posta',
            value: _email,
            actionIcon: Icons.send_outlined,
            actionText: 'Gönder',
            onTap: () => _sendEmail(context),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // ADRES
          // ==================================================
          _ContactCard(
            icon: Icons.location_on_outlined,
            title: 'Adres',
            value: _address,
            actionIcon: Icons.map_outlined,
            actionText: 'Harita',
            onTap: () => _openMap(context),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // FAKS
          // ==================================================
          const _ContactCard(
            icon: Icons.print_outlined,
            title: 'Faks',
            value: _fax,
          ),

          const SizedBox(height: 10),

          // ==================================================
          // WEB
          // ==================================================
          _ContactCard(
            icon: Icons.language_rounded,
            title: 'Web Sitesi',
            value: 'www.tunceli.bel.tr',
            actionIcon: Icons.open_in_new_rounded,
            actionText: 'Aç',
            onTap: () => _openWebsite(context),
          ),

          const SizedBox(height: 26),

          // ==================================================
          // GERİ BİLDİRİM
          // ==================================================
          const Text(
            'Geri Bildirim',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Görüş ve önerilerinizi bizimle paylaşın',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 12),

          const _FeedbackCard(),
        ],
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _ContactHero extends StatelessWidget {
  const _ContactHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: 0.16,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -52,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.055,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 55,
              bottom: -80,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(19),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius:
                          BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .account_balance_outlined,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'BELEDİYE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  const Text(
                    'Bize Ulaşın',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Tunceli Belediyesi iletişim '
                        'kanallarına hızlıca ulaşabilirsiniz.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.82,
                      ),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: Colors.white,
                          size: 16,
                        ),

                        SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            'İletişim kartlarına dokunarak '
                                'ilgili işlemi başlatabilirsiniz.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// İLETİŞİM KARTI
// ============================================================

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  final IconData? actionIcon;
  final String? actionText;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    this.actionIcon,
    this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              // SOL İKON
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // BİLGİ
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                        AppColors.textSecondary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // AKSİYON
              if (onTap != null) ...[
                const SizedBox(width: 8),

                Container(
                  constraints: const BoxConstraints(
                    minWidth: 45,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.07,
                    ),
                    borderRadius:
                    BorderRadius.circular(11),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        actionIcon ??
                            Icons
                                .chevron_right_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),

                      if (actionText != null) ...[
                        const SizedBox(height: 2),

                        Text(
                          actionText!,
                          style: const TextStyle(
                            color:
                            AppColors.primary,
                            fontSize: 7.5,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GERİ BİLDİRİM KARTI
// ============================================================

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.feedback_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Görüşleriniz bizim için değerli',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Ulaşım hizmetleriyle ilgili görüş, '
                      'öneri ve bildirimlerinizi yukarıdaki '
                      'iletişim kanalları üzerinden '
                      'belediyeye iletebilirsiniz.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.5,
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