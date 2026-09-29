import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  static const List<_FaqItem> _questions = [
    _FaqItem(
      question:
      'Otobüs sefer saatlerine nasıl ulaşabilirim?',
      answer:
      'Ana Sayfa üzerinden “Sefer Saatleri” bölümüne girerek '
          'hatlara ait hafta içi ve hafta sonu sefer saatlerini '
          'görüntüleyebilirsiniz.',
    ),
    _FaqItem(
      question:
      'Otobüs hatlarını nereden görüntüleyebilirim?',
      answer:
      'Ana Sayfa üzerindeki “Hatlar” bölümünden mevcut otobüs '
          'hatlarını görüntüleyebilir ve hat detaylarına ulaşabilirsiniz.',
    ),
    _FaqItem(
      question:
      'Bir hattı favorilerime nasıl ekleyebilirim?',
      answer:
      'Hat detay ekranının sağ üst köşesindeki kalp simgesine '
          'dokunarak hattı favorilerinize ekleyebilirsiniz. '
          'Favori hatlarınıza alt menüde bulunan “Favoriler” '
          'bölümünden hızlıca ulaşabilirsiniz.',
    ),
    _FaqItem(
      question:
      'Favorilerim uygulamayı kapattığımda silinir mi?',
      answer:
      'Hayır. Favorilerinize eklediğiniz hatlar cihazınızda '
          'saklanır ve uygulamayı yeniden açtığınızda kullanılmaya '
          'devam eder.',
    ),
    _FaqItem(
      question:
      'Hafta içi ve hafta sonu seferleri farklı mı?',
      answer:
      'Bazı hatlarda hafta içi ve hafta sonu sefer saatleri '
          'farklı olabilir. Sefer Saatleri ekranından ilgili günü '
          'seçerek güncel listeyi görüntüleyebilirsiniz.',
    ),
    _FaqItem(
      question: 'Duyurulara nereden ulaşabilirim?',
      answer:
      'Ana Sayfadaki “Duyurular” bölümünden veya Menü > Duyurular '
          'seçeneğinden Tunceli Belediyesi tarafından yayımlanan '
          'duyurulara ulaşabilirsiniz.',
    ),
    _FaqItem(
      question:
      'Ulaşım ile ilgili görüş veya önerimi nasıl iletebilirim?',
      answer:
      'Menü > İletişim ve Geri Bildirim bölümünden Tunceli '
          'Belediyesinin telefon, e-posta, adres ve diğer iletişim '
          'bilgilerine ulaşabilirsiniz.',
    ),
    _FaqItem(
      question:
      'Uygulamayı kullanmak için üyelik gerekiyor mu?',
      answer:
      'Hayır. Uygulamanın mevcut özelliklerini kullanmak için '
          'üyelik veya kullanıcı hesabı gerekmemektedir.',
    ),
  ];

  List<_FaqItem> get _filteredQuestions {
    final query = _normalize(_searchQuery.trim());

    if (query.isEmpty) {
      return _questions;
    }

    return _questions.where((item) {
      final question = _normalize(item.question);
      final answer = _normalize(item.answer);

      return question.contains(query) ||
          answer.contains(query);
    }).toList();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _filteredQuestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sık Sorulan Sorular',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior.onDrag,
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
          _FaqHero(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClear: () {
              _searchController.clear();

              setState(() {
                _searchQuery = '';
              });
            },
          ),

          const SizedBox(height: 22),

          // ==================================================
          // BAŞLIK
          // ==================================================
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merak Ettikleriniz',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sık sorulan sorular ve cevapları',
                      style: TextStyle(
                        color:
                        AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  '${questions.length} soru',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ==================================================
          // SORULAR
          // ==================================================
          if (questions.isEmpty)
            const _NoResult()
          else
            ...List.generate(
              questions.length,
                  (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                    index == questions.length - 1
                        ? 0
                        : 10,
                  ),
                  child: _FaqCard(
                    item: questions[index],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ============================================================
// HERO
// ============================================================

class _FaqHero extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _FaqHero({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

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
                          Icons.help_outline_rounded,
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
                                  .question_answer_outlined,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '8 SORU',
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
                    'Nasıl yardımcı olabiliriz?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Uygulama ve ulaşım hizmetleriyle '
                        'ilgili merak ettiklerinizi bulun.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.82,
                      ),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==========================================
                  // ARAMA
                  // ==========================================
                  TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction:
                    TextInputAction.search,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Sorularda ara...',
                      hintStyle: const TextStyle(
                        color:
                        AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: controller.text.isEmpty
                          ? null
                          : IconButton(
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors
                              .textSecondary,
                          size: 18,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                        borderSide:
                        const BorderSide(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
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
// SORU KARTI
// ============================================================

class _FaqCard extends StatelessWidget {
  final _FaqItem item;

  const _FaqCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.primary.withValues(
            alpha: 0.04,
          ),
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 3,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            63,
            0,
            17,
            17,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.question_mark_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          title: Text(
            item.question,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor:
          AppColors.textSecondary,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 3,
              ),
              child: Text(
                item.answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SONUÇ BULUNAMADI
// ============================================================

class _NoResult extends StatelessWidget {
  const _NoResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.primary,
            size: 38,
          ),

          SizedBox(height: 13),

          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Farklı bir kelimeyle tekrar aramayı deneyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODEL
// ============================================================

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}