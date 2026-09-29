import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../models/announcement.dart';

class AnnouncementDetailPage extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailPage({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailPage> createState() =>
      _AnnouncementDetailPageState();
}

class _AnnouncementDetailPageState
    extends State<AnnouncementDetailPage> {
  bool _isLoading = true;

  String? _errorMessage;

  String _content = '';

  final List<_AnnouncementAttachment> _attachments = [];

  static const String _baseUrl =
      'http://www.tunceli.bel.tr';

  @override
  void initState() {
    super.initState();

    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _content = '';
      _attachments.clear();
    });

    try {
      debugPrint(
        'Duyuru detay URL: ${widget.announcement.url}',
      );

      final response = await http
          .get(
        Uri.parse(widget.announcement.url),
        headers: {
          'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) TunceliUlasim/1.0',
          'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      )
          .timeout(
        const Duration(seconds: 15),
      );

      debugPrint(
        'Duyuru HTTP durum: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}',
        );
      }

      final htmlContent = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      final document =
      html_parser.parse(htmlContent);

      //
      // GERÇEK DUYURU METNİ
      //
      // Belediye sitesinde duyuru içeriği:
      //
      // .haber-detay-box
      //      └── .detay
      //
      final detailElement =
      document.querySelector(
        '.haber-detay-box .detay',
      );

      var content = '';

      if (detailElement != null) {
        content = _cleanText(
          detailElement.text,
        );
      }

      //
      // EK DOSYALARI BUL
      //
      // Bazı duyurularda .detay boş.
      // İçerik PDF veya görsel olarak eklenmiş.
      //
      final detailBox =
      document.querySelector(
        '.haber-detay-box',
      );

      if (detailBox != null) {
        final links =
        detailBox.querySelectorAll(
          'a[href]',
        );

        for (final link in links) {
          final href =
          link.attributes['href'];

          if (href == null ||
              href.trim().isEmpty) {
            continue;
          }

          final lowerHref =
          href.toLowerCase();

          //
          // Yalnızca gerçek dosyaları al.
          //
          if (!_isAttachment(
            lowerHref,
          )) {
            continue;
          }

          final fullUrl =
          _makeAbsoluteUrl(href);

          //
          // Aynı dosyayı iki kez ekleme.
          //
          if (_attachments.any(
                (item) =>
            item.url == fullUrl,
          )) {
            continue;
          }

          _attachments.add(
            _AnnouncementAttachment(
              url: fullUrl,
              name: _getFileName(
                href,
              ),
              type: _getAttachmentType(
                lowerHref,
              ),
            ),
          );
        }
      }

      debugPrint(
        'Duyuru metni: ${content.length} karakter',
      );

      debugPrint(
        'Duyuru ek dosya: ${_attachments.length}',
      );

      if (!mounted) return;

      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Duyuru detay hatası: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage =
        'Duyuru detayı şu anda alınamıyor.';
      });
    }
  }

  bool _isAttachment(
      String href,
      ) {
    return href.endsWith('.pdf') ||
        href.endsWith('.jpg') ||
        href.endsWith('.jpeg') ||
        href.endsWith('.png') ||
        href.endsWith('.webp') ||
        href.endsWith('.doc') ||
        href.endsWith('.docx') ||
        href.endsWith('.xls') ||
        href.endsWith('.xlsx');
  }

  String _getAttachmentType(
      String href,
      ) {
    if (href.endsWith('.pdf')) {
      return 'PDF';
    }

    if (href.endsWith('.jpg') ||
        href.endsWith('.jpeg') ||
        href.endsWith('.png') ||
        href.endsWith('.webp')) {
      return 'Görsel';
    }

    if (href.endsWith('.doc') ||
        href.endsWith('.docx')) {
      return 'Word';
    }

    if (href.endsWith('.xls') ||
        href.endsWith('.xlsx')) {
      return 'Excel';
    }

    return 'Dosya';
  }

  String _getFileName(
      String url,
      ) {
    try {
      final uri = Uri.parse(url);

      if (uri.pathSegments.isNotEmpty) {
        final fileName =
            uri.pathSegments.last;

        if (fileName.isNotEmpty) {
          return Uri.decodeComponent(
            fileName,
          );
        }
      }
    } catch (_) {
      // ignore
    }

    return 'Ek Dosya';
  }

  String _makeAbsoluteUrl(
      String href,
      ) {
    var cleanHref =
    href.trim();

    //
    // Belediye HTTPS sertifikasında
    // problem olduğu için HTTP kullanıyoruz.
    //
    cleanHref =
        cleanHref.replaceFirst(
          'https://www.tunceli.bel.tr',
          'http://www.tunceli.bel.tr',
        );

    cleanHref =
        cleanHref.replaceFirst(
          'https://tunceli.bel.tr',
          'http://www.tunceli.bel.tr',
        );

    if (cleanHref.startsWith(
      'http://',
    )) {
      return cleanHref;
    }

    if (cleanHref.startsWith('/')) {
      return '$_baseUrl$cleanHref';
    }

    return '$_baseUrl/$cleanHref';
  }

  String _cleanText(
      String text,
      ) {
    return text
        .replaceAll(
      '\u00A0',
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  Future<void> _openAttachment(
      _AnnouncementAttachment attachment,
      ) async {
    try {
      final uri =
      Uri.parse(attachment.url);

      final opened =
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception(
          'Dosya açılamadı.',
        );
      }
    } catch (e) {
      debugPrint(
        'Ek dosya açma hatası: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Dosya açılamadı.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Duyuru Detayı',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDetail,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(20),
        children: [
          //
          // ÜST İKON
          //
          Container(
            width: double.infinity,
            height: 54,
            alignment:
            Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color:
              AppColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          //
          // BAŞLIK
          //
          Text(
            widget.announcement.title,
            style: const TextStyle(
              fontSize: 21,
              height: 1.35,
              fontWeight:
              FontWeight.w800,
              color:
              AppColors.textPrimary,
            ),
          ),

          //
          // TARİH
          //
          if (widget
              .announcement
              .date
              .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 14,
                  color: AppColors
                      .textSecondary,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  widget
                      .announcement
                      .date,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: AppColors
                        .textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 20,
          ),

          const Divider(
            color:
            AppColors.divider,
          ),

          const SizedBox(
            height: 20,
          ),

          //
          // DUYURU METNİ
          //
          if (_content.isNotEmpty) ...[
            SelectableText(
              _content,
              style:
              const TextStyle(
                fontSize: 15,
                height: 1.65,
                color: AppColors
                    .textPrimary,
              ),
            ),

            const SizedBox(
              height: 24,
            ),
          ],

          //
          // EK DOSYALAR
          //
          if (_attachments
              .isNotEmpty) ...[
            const Text(
              'Ek Dosyalar',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w700,
                color: AppColors
                    .textPrimary,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            ..._attachments.map(
                  (attachment) =>
                  _buildAttachmentCard(
                    attachment,
                  ),
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          //
          // METİN DE YOK DOSYA DA YOK
          //
          if (_content.isEmpty &&
              _attachments.isEmpty)
            Container(
              padding:
              const EdgeInsets.all(
                18,
              ),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius
                    .circular(
                  14,
                ),
                border: Border.all(
                  color: AppColors
                      .divider,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Icon(
                    Icons
                        .info_outline_rounded,
                    color: AppColors
                        .textSecondary,
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      'Bu duyuru için metin veya ek dosya bulunamadı.',
                      style:
                      TextStyle(
                        height: 1.5,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 24,
          ),

          //
          // KAYNAK
          //
          Container(
            padding:
            const EdgeInsets.all(
              14,
            ),
            decoration:
            BoxDecoration(
              color: AppColors.primary
                  .withValues(
                alpha: 0.06,
              ),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons
                      .verified_outlined,
                  color:
                  AppColors.primary,
                  size: 20,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'Kaynak: Tunceli Belediyesi',
                    style:
                    TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight
                          .w600,
                      color:
                      AppColors
                          .primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(
      _AnnouncementAttachment attachment,
      ) {
    IconData icon;

    switch (attachment.type) {
      case 'PDF':
        icon =
            Icons.picture_as_pdf_rounded;
        break;

      case 'Görsel':
        icon =
            Icons.image_outlined;
        break;

      case 'Word':
        icon =
            Icons.description_outlined;
        break;

      case 'Excel':
        icon =
            Icons.table_chart_outlined;
        break;

      default:
        icon =
            Icons.attach_file_rounded;
    }

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          onTap: () =>
              _openAttachment(
                attachment,
              ),
          child: Container(
            padding:
            const EdgeInsets.all(
              14,
            ),
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color:
                AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                  BoxDecoration(
                    color: AppColors
                        .primary
                        .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors
                        .primary,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        attachment
                            .type,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight
                              .w700,
                          color:
                          AppColors
                              .primary,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        attachment
                            .name,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          color: AppColors
                              .textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                const Icon(
                  Icons
                      .open_in_new_rounded,
                  size: 19,
                  color: AppColors
                      .textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            const Icon(
              Icons
                  .cloud_off_rounded,
              size: 60,
              color: AppColors
                  .textSecondary,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Duyuru detayı yüklenemedi',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w700,
                color: AppColors
                    .textPrimary,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _errorMessage ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: AppColors
                    .textSecondary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            FilledButton.icon(
              onPressed:
              _loadDetail,
              icon: const Icon(
                Icons
                    .refresh_rounded,
              ),
              label: const Text(
                'Tekrar Dene',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementAttachment {
  final String url;
  final String name;
  final String type;

  const _AnnouncementAttachment({
    required this.url,
    required this.name,
    required this.type,
  });
}