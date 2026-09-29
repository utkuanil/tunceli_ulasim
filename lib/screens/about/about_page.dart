import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Hakkımızda',
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
        children: const [
          // ==================================================
          // HERO
          // ==================================================
          _AboutHero(),

          SizedBox(height: 22),

          // ==================================================
          // BAŞLIK
          // ==================================================
          Text(
            'Uygulama Hakkında',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          SizedBox(height: 3),

          Text(
            'Tunceli şehir içi ulaşım bilgileri tek uygulamada',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),

          SizedBox(height: 12),

          // ==================================================
          // UYGULAMA
          // ==================================================
          _InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Tunceli Ulaşım',
            text:
            'Tunceli Ulaşım, şehir içi toplu taşıma '
                'hizmetlerine daha kolay ve hızlı erişim '
                'sağlamak amacıyla hazırlanmıştır.',
          ),

          SizedBox(height: 10),

          // ==================================================
          // HATLAR VE SEFERLER
          // ==================================================
          _InfoCard(
            icon: Icons.directions_bus_outlined,
            title: 'Hatlar ve Seferler',
            text:
            'Otobüs hatlarını, kalkış noktalarını ve '
                'hafta içi ile hafta sonu sefer saatlerini '
                'uygulama üzerinden görüntüleyebilirsiniz.',
          ),

          SizedBox(height: 10),

          // ==================================================
          // DURAKLAR
          // ==================================================
          _InfoCard(
            icon: Icons.location_on_outlined,
            title: 'Durak Haritası',
            text:
            'Belediyeden alınan 55 durak konumunu harita '
                'üzerinde görüntüleyebilir ve seçtiğiniz durağa '
                'yol tarifi alabilirsiniz.',
          ),

          SizedBox(height: 10),

          // ==================================================
          // FAVORİLER
          // ==================================================
          _InfoCard(
            icon: Icons.favorite_border_rounded,
            title: 'Favoriler',
            text:
            'Sık kullandığınız otobüs hatlarını '
                'favorilerinize ekleyerek daha hızlı '
                'erişebilirsiniz.',
          ),

          SizedBox(height: 10),

          // ==================================================
          // DUYURULAR
          // ==================================================
          _InfoCard(
            icon: Icons.campaign_outlined,
            title: 'Belediye Duyuruları',
            text:
            'Tunceli Belediyesi tarafından yayımlanan '
                'güncel duyuruları uygulama üzerinden takip '
                'edebilirsiniz.',
          ),

          SizedBox(height: 26),

          // ==================================================
          // ALT BİLGİ
          // ==================================================
          _VersionCard(),

          SizedBox(height: 18),

          Center(
            child: Text(
              '© 2026 Tunceli Belediyesi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _AboutHero extends StatelessWidget {
  const _AboutHero();

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
                          Icons.directions_bus_rounded,
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

                  const SizedBox(height: 17),

                  const Text(
                    'Tunceli Ulaşım',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Tunceli Belediyesi',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Şehir içi ulaşım bilgilerine kolay, '
                        'hızlı ve tek noktadan erişim.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.88,
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
                          Icons.phone_android_rounded,
                          color: Colors.white,
                          size: 16,
                        ),

                        SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            'Hatlar, seferler, duraklar ve '
                                'belediye duyuruları cebinizde.',
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
// BİLGİ KARTI
// ============================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
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
            child: Icon(
              icon,
              size: 21,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  text,
                  style: const TextStyle(
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

// ============================================================
// SÜRÜM
// ============================================================

class _VersionCard extends StatelessWidget {
  const _VersionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 19,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Uygulama Sürümü',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Text(
            '1.0.0',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}