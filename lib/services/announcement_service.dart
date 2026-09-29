import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/announcement.dart';

class AnnouncementService {
  static const String _baseUrl = 'http://www.tunceli.bel.tr';

  static const String _announcementsUrl =
      'http://www.tunceli.bel.tr/duyurular';

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await http
          .get(
        Uri.parse(_announcementsUrl),
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

      if (response.statusCode != 200) {
        throw Exception(
          'Duyurular alınamadı. HTTP: ${response.statusCode}',
        );
      }

      final htmlContent = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      final document =
      html_parser.parse(htmlContent);

      final List<Announcement> announcements = [];

      final Set<String> addedUrls = {};

      //
      // TUNCELİ BELEDİYESİ DUYURU SAYFASI
      //
      // Gerçek duyurular:
      //
      // .etkinlik-box
      //      ↓
      // .col-lg-12.py-2
      //      ↓
      // .e-tarih
      // .e-content
      //
      final announcementCards =
      document.querySelectorAll(
        '.etkinlik-box > .col-lg-12.py-2',
      );

      debugPrintAnnouncements(
        'Bulunan gerçek duyuru kartı: '
            '${announcementCards.length}',
      );

      for (final card in announcementCards) {
        //
        // DUYURU İÇERİK ALANI
        //
        final content =
        card.querySelector('.e-content');

        if (content == null) {
          continue;
        }

        //
        // BAŞLIK
        //
        final titleElement =
        content.querySelector('h5');

        if (titleElement == null) {
          continue;
        }

        final title =
        _cleanText(titleElement.text);

        if (title.isEmpty) {
          continue;
        }

        //
        // URL
        //
        final linkElement =
        content.querySelector(
          'a[href]',
        );

        final href =
        linkElement?.attributes['href'];

        if (href == null ||
            href.trim().isEmpty) {
          continue;
        }

        final fullUrl =
        _makeAbsoluteUrl(href);

        //
        // Aynı duyuruyu tekrar ekleme.
        //
        if (addedUrls.contains(fullUrl)) {
          continue;
        }

        //
        // TARİH
        //
        final date =
        _extractDate(card);

        //
        // ÖZET
        //
        final summaryElement =
        content.querySelector('p');

        var summary = '';

        if (summaryElement != null) {
          summary =
              _cleanText(summaryElement.text);
        }

        //
        // Çok uzun özetleri kartta
        // göstermeye gerek yok.
        //
        if (summary.length > 220) {
          summary =
          '${summary.substring(0, 217).trim()}...';
        }

        announcements.add(
          Announcement(
            title: title,
            summary: summary,
            date: date,
            url: fullUrl,
          ),
        );

        addedUrls.add(fullUrl);
      }

      if (announcements.isEmpty) {
        throw Exception(
          'Belediye sayfasında duyuru bulunamadı.',
        );
      }

      return announcements;
    } catch (e) {
      throw Exception(
        'Duyurular yüklenemedi: $e',
      );
    }
  }

  String _extractDate(dynamic card) {
    final dateElement =
    card.querySelector('.e-tarih');

    if (dateElement == null) {
      return '';
    }

    //
    // Web sitesinde:
    //
    // <div class="e-tarih">
    //   <p>07</p>
    //   <p>EYL</p>
    //   <p>2026</p>
    // </div>
    //
    final parts =
    dateElement.querySelectorAll('p');

    if (parts.length < 3) {
      return _cleanText(
        dateElement.text,
      );
    }

    final day =
    _cleanText(parts[0].text);

    final month =
    _cleanText(parts[1].text);

    final year =
    _cleanText(parts[2].text);

    return '$day ${_monthName(month)} $year';
  }

  String _monthName(String month) {
    switch (month
        .trim()
        .toUpperCase()) {
      case 'OCA':
        return 'Ocak';

      case 'ŞUB':
        return 'Şubat';

      case 'MAR':
        return 'Mart';

      case 'NİS':
      case 'NIS':
        return 'Nisan';

      case 'MAY':
        return 'Mayıs';

      case 'HAZ':
        return 'Haziran';

      case 'TEM':
        return 'Temmuz';

      case 'AĞU':
      case 'AGU':
        return 'Ağustos';

      case 'EYL':
        return 'Eylül';

      case 'EKİ':
      case 'EKI':
        return 'Ekim';

      case 'KAS':
        return 'Kasım';

      case 'ARA':
        return 'Aralık';

      default:
        return month;
    }
  }

  String _makeAbsoluteUrl(
      String href,
      ) {
    var cleanHref =
    href.trim();

    //
    // Belediye sitesinin HTTPS
    // sertifikasında sorun olduğu için
    // kendi alan adındaki URL'leri
    // HTTP olarak kullanıyoruz.
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

  void debugPrintAnnouncements(
      String message,
      ) {
    // ignore: avoid_print
    print(
      'AnnouncementService: $message',
    );
  }
}