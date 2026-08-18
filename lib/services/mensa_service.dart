import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qnox_pdf_text/qnox_pdf_text.dart';

import '../models/mensa_menu.dart';

class MensaService {
  static const _baseUrl =
      'https://laendlegastronomie.at/menue.html?file=files/Laendlegastronomie/Menuekarten/KW';
  static const _urlSuffix = '_FHMensa.pdf';
  static const _cacheFileName = 'mensa_cache.json';

  static const _days = [
    'MONTAG',
    'DIENSTAG',
    'MITTWOCH',
    'DONNERSTAG',
    'FREITAG',
  ];
  static const _dayLabels = {
    'MONTAG': 'Montag',
    'DIENSTAG': 'Dienstag',
    'MITTWOCH': 'Mittwoch',
    'DONNERSTAG': 'Donnerstag',
    'FREITAG': 'Freitag',
  };

  static final _allergenCode = RegExp(r'^[ABCDEFGHLMNOPR]{1,10}$');
  static final _pricingMarker = RegExp(r'EUR\s*\d');
  static final _dateRangePattern = RegExp(
    r'\d{1,2}\.\s*[A-Za-zÄÖÜäöü]+\s*\d{4}\s*[–-]\s*\d{1,2}\.\s*[A-Za-zÄÖÜäöü]+\s*\d{4}',
  );

  static final MensaService _instance = MensaService._internal();
  factory MensaService() => _instance;
  MensaService._internal();

  final _qnox = QnoxPdfText();

  static int isoWeekNumber(DateTime date) {
    final d = DateTime.utc(date.year, date.month, date.day);
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final ordinalDay =
        thursday.difference(DateTime.utc(thursday.year, 1, 1)).inDays + 1;
    return ((ordinalDay - 1) ~/ 7) + 1;
  }

  static String urlForWeek(int week) => '$_baseUrl$week$_urlSuffix';

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<Map<String, dynamic>> _readCacheMap() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return {};
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeCacheMap(Map<String, dynamic> map) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  Future<MensaWeekMenu?> loadCached(int week) async {
    final map = await _readCacheMap();
    final entry = map['$week'];
    if (entry == null) return null;
    try {
      return MensaWeekMenu.fromJson(entry as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(MensaWeekMenu menu) async {
    final map = await _readCacheMap();
    map['${menu.week}'] = menu.toJson();
    await _writeCacheMap(map);
  }

  Future<MensaWeekMenu> fetchWeek({int weekOffset = 0}) async {
    final target = DateTime.now().add(Duration(days: 7 * weekOffset));
    final week = isoWeekNumber(target);
    final url = urlForWeek(week);

    final String rawText;
    try {
      rawText = await _qnox.extractPageTextFromUrl(url, 0);
    } catch (e) {
      throw Exception(
        'Menüplan für KW$week konnte nicht geladen werden. '
        'Möglicherweise ist für diese Woche noch kein Plan veröffentlicht.',
      );
    }

    final menu = _parse(week: week, rawText: rawText);
    await _saveCache(menu);
    return menu;
  }

  Future<MensaDayMenu?> loadCachedToday() async {
    if (DateTime.now().weekday > 5) return null;
    final cached = await loadCached(isoWeekNumber(DateTime.now()));
    return cached == null ? null : _today(cached);
  }

  Future<MensaDayMenu?> fetchToday() async {
    if (DateTime.now().weekday > 5) return null;
    return _today(await fetchWeek());
  }

  MensaDayMenu? _today(MensaWeekMenu menu) {
    final label = _dayLabels.values.elementAt(DateTime.now().weekday - 1);
    final day = menu.days.firstWhere(
      (d) => d.day == label,
      orElse: () => MensaDayMenu(day: label, items: const []),
    );
    return day.items.isEmpty ? null : day;
  }

  @visibleForTesting
  MensaWeekMenu parseRawText({required int week, required String rawText}) =>
      _parse(week: week, rawText: rawText);

  MensaWeekMenu _parse({required int week, required String rawText}) {
    final firstHeader = rawText.indexOf('MENÜPLAN');
    var section = firstHeader >= 0 ? rawText.substring(firstHeader) : rawText;
    final secondHeader = section.indexOf('MENÜPLAN', 1);
    if (secondHeader > 0) section = section.substring(0, secondHeader);

    final dateRangeLabel = _dateRangePattern.firstMatch(section)?.group(0);

    final lines = section
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final itemsByDay = {for (final d in _days) d: <MensaMenuItem>[]};
    String? currentDay;
    MensaMenuItem? pending;
    final descBuffer = StringBuffer();

    void flushPending() {
      if (pending == null) return;
      var desc = descBuffer.toString().trim().replaceFirst(
        RegExp(r'^ALLERGENE?N?S?\s+', caseSensitive: false),
        '',
      );
      final allergens = <String>[];
      final words = desc.split(RegExp(r'\s+'));
      final lastWord = words.isEmpty ? '' : words.last.toUpperCase();
      final isAllergenCode =
          lastWord != 'ALLERGENE' &&
          lastWord != 'ALLERGENS' &&
          _allergenCode.hasMatch(lastWord);
      if (isAllergenCode) {
        allergens.addAll(words.last.split(''));
        desc = words.sublist(0, words.length - 1).join(' ');
      }
      itemsByDay[currentDay]!.add(
        MensaMenuItem(
          category: pending!.category,
          title: pending!.title,
          description: desc,
          allergens: allergens,
        ),
      );
      pending = null;
      descBuffer.clear();
    }

    for (var line in lines) {
      if (_pricingMarker.hasMatch(line)) break;

      final dayMatch = _days.firstWhere(
        (d) => line.startsWith(d),
        orElse: () => '',
      );
      if (dayMatch.isNotEmpty) {
        flushPending();
        currentDay = dayMatch;
        line = line.substring(dayMatch.length).trim();
        if (line.isEmpty) continue;
      }

      if (currentDay == null) continue;

      final titleMatch = RegExp(
        r'^(MENÜ\s*[12]|VEGAN)\b\.?\s*(.*)$',
      ).firstMatch(line);
      if (titleMatch != null) {
        flushPending();
        final rawCategory = titleMatch
            .group(1)!
            .replaceAll(RegExp(r'\s+'), ' ');
        final category = rawCategory == 'VEGAN'
            ? 'Vegan'
            : 'Menü ${rawCategory.substring(rawCategory.length - 1)}';
        var title = titleMatch.group(2)!.trim();
        title = title.replaceFirst(
          RegExp(r'\s*ALLERGENE?N?S?$', caseSensitive: false),
          '',
        );
        pending = MensaMenuItem(
          category: category,
          title: title,
          description: '',
          allergens: const [],
        );
        continue;
      }

      if (pending != null) {
        if (descBuffer.isNotEmpty) descBuffer.write(' ');
        descBuffer.write(line);
      }
    }
    flushPending();

    final days = _days
        .map((d) => MensaDayMenu(day: _dayLabels[d]!, items: itemsByDay[d]!))
        .toList();

    return MensaWeekMenu(
      week: week,
      dateRangeLabel: dateRangeLabel,
      days: days,
      rawText: rawText,
      fetchedAt: DateTime.now(),
    );
  }
}
