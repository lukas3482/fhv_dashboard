import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';

import '../models/profile_info.dart';
import 'auth_service.dart';

class ProfileService {
  static const _profileUrl = 'https://a5.fhv.at/de/profile.php';
  static const _cacheFileName = 'profile_cache.json';

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<ProfileInfo?> loadCached() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return ProfileInfo.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final file = await _cacheFile;
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> _saveCache(ProfileInfo profile) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  Future<ProfileInfo> fetchProfile() async {
    final response = await AuthService().authenticatedGet(_profileUrl);

    if (response.statusCode != 200) {
      throw Exception(
        'Profilseite konnte nicht geladen werden (${response.statusCode})',
      );
    }

    final profile = _parseHtml(response.data.toString());
    await _saveCache(profile);
    return profile;
  }

  ProfileInfo _parseHtml(String html) {
    final document = html_parser.parse(html);
    final personSection = document.getElementById('profile-responsive-page');

    final name = (personSection?.querySelector('.panel-heading h2')?.text ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final details = <String, String>{};
    for (final row
        in personSection?.querySelectorAll('table.table-hover tbody tr') ??
            const <dom.Element>[]) {
      final cells = row.querySelectorAll('td');
      final label = row.querySelector('strong')?.text.trim();
      if (label == null || cells.length < 2) continue;
      details[label] = cells[1].text.trim();
    }

    return ProfileInfo(
      name: name,
      affiliation: details['Zugehörigkeit'] ?? '',
      matriculationNumber: details['Matrikelnummer'] ?? '',
      personKey: details['Personenkennzeichen'] ?? '',
      contacts: _parseContacts(document),
    );
  }

  List<ProfileContact> _parseContacts(dom.Document document) {
    final contacts = <ProfileContact>[];

    for (final section in document.querySelectorAll('section')) {
      final heading = section.querySelector('.panel-heading h2')?.text.trim();
      if (heading != 'Kontaktdaten') continue;

      for (final tile in section.querySelectorAll('.tile-edit')) {
        final value = tile
            .querySelector('.tile-edit__description p')
            ?.text
            .trim();
        if (value == null || value.isEmpty) continue;

        final iconClasses =
            tile.querySelector('.tile-edit__icon i')?.classes ?? {};
        final label =
            (tile.querySelector('.tile-edit__description strong span')?.text ??
                    '')
                .trim();

        contacts.add(
          ProfileContact(
            type: iconClasses.contains('fa-phone') ? 'phone' : 'email',
            label: label,
            value: value,
            isPrimary:
                tile.querySelector('.tile-edit__description .fa-star') != null,
          ),
        );
      }
    }

    return contacts;
  }
}
