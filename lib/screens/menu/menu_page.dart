import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../about/about_page.dart';
import '../announcements/announcements_page.dart';
import '../contact/contact_page.dart';
import '../faq/faq_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Menü',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          30,
        ),
        children: [
          // ==================================================
          // ÜST HERO
          // ==================================================
          const _MenuHero(),

          const SizedBox(height: 22),

          // ==================================================
          // BAŞLIK
          // ==================================================
          const Text(
            'Uygulama',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Bilgi ve destek hizmetlerine ulaşın',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // DUYURULAR
          // ==================================================
          _MenuItem(
            icon: Icons.campaign_outlined,
            title: 'Duyurular',
            subtitle: 'Belediyenin güncel duyuruları',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AnnouncementsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ==================================================
          // İLETİŞİM
          // ==================================================
          _MenuItem(
            icon: Icons.forum_outlined,
            title: 'İletişim ve Geri Bildirim',
            subtitle:
            'Bize ulaşın ve görüşlerinizi iletin',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ==================================================
          // SSS
          // ==================================================
          _MenuItem(
            icon: Icons.help_outline_rounded,
            title: 'Sık Sorulan Sorular',
            subtitle:
            'Sıkça sorulan sorular ve cevapları',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FaqPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // ==================================================
          // HAKKIMIZDA
          // ==================================================
          _MenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Hakkımızda',
            subtitle: 'Tunceli Belediyesi Ulaşım',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // ==================================================
          // ALT BİLGİ
          // ==================================================
          const _Footer(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _MenuHero extends StatelessWidget {
  const _MenuHero();

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
            // Dekoratif daire - sağ üst
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

            // Dekoratif daire - sağ alt
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
                      // Logo alanı
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
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),

                      const Spacer(),

                      // Belediye etiketi
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
                              'TUNCELİ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight:
                                FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Tunceli Ulaşım',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Ulaşım bilgileri, belediye duyuruları '
                        've destek hizmetleri tek yerde.',
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
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),

                        SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            'Tunceli Belediyesi ulaşım '
                                'hizmetlerine hızlıca erişin.',
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
// MENÜ KARTI
// ============================================================

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
              // Sol ikon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              // Metin
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                        AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Sağ ok
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.07,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ALT BİLGİ
// ============================================================

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.07,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: AppColors.primary,
            size: 25,
          ),
        ),

        const SizedBox(height: 11),

        const Text(
          'TUNCELİ ULAŞIM',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Tunceli Belediyesi',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.divider,
            ),
          ),
          child: const Text(
            'Sürüm 1.0.0',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}