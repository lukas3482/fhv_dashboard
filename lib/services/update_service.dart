import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String tag;
  final String version;
  final String htmlUrl;

  const UpdateInfo({
    required this.tag,
    required this.version,
    required this.htmlUrl,
  });
}

class UpdateService {
  static const _repo = 'lukas3482/fhv_dashboard';
  static const _latestReleaseUrl =
      'https://api.github.com/repos/$_repo/releases/latest';
  static const _lastNotifiedBuildKey = 'update_last_notified_build';

  static final _tagBuildPattern = RegExp(r'\+(\d+)$');

  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final _dio = Dio();

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentBuild = int.parse(
        (await PackageInfo.fromPlatform()).buildNumber,
      );

      final response = await _dio.get<Map<String, dynamic>>(_latestReleaseUrl);
      final data = response.data;
      if (data == null) return null;

      final tag = data['tag_name'] as String?;
      final htmlUrl = data['html_url'] as String?;
      if (tag == null || htmlUrl == null) return null;

      final remoteBuild = int.tryParse(
        _tagBuildPattern.firstMatch(tag)?.group(1) ?? '',
      );
      if (remoteBuild == null || remoteBuild <= currentBuild) return null;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt(_lastNotifiedBuildKey) == remoteBuild) return null;

      return UpdateInfo(
        tag: tag,
        version: tag.replaceFirst(RegExp(r'^v'), ''),
        htmlUrl: htmlUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> markNotified(UpdateInfo info) async {
    final build = int.tryParse(
      _tagBuildPattern.firstMatch(info.tag)?.group(1) ?? '',
    );
    if (build == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastNotifiedBuildKey, build);
  }
}
