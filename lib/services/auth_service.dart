import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class AuthService {
  static const _loginUrl =
      'https://a5.fhv.at/ajax/120/LoginResponsive/LoginHandler';
  static const _sessionCheckUrl = 'https://a5.fhv.at/de/noten.php';
  // domain-id 8 = FHV (from homeassistant integration reference)
  static const _domainId = '8';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late Dio _dio;
  late PersistCookieJar _cookieJar;
  final _storage = const FlutterSecureStorage();

  bool _initialized = false;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      ignoreExpires: false,
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    _dio = Dio(
      BaseOptions(
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
    _initialized = true;
  }

  Future<bool> login(
    String username,
    String password, {
    bool permanentLogin = false,
  }) async {
    await init();
    try {
      await _dio.post(
        _loginUrl,
        data: {
          'username': username,
          'password': password,
          'domain-id': _domainId,
          'permanent-login': permanentLogin ? '1' : '0',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: true,
        ),
      );

      _isLoggedIn = await checkSession();

      if (_isLoggedIn) {
        await _storage.write(key: 'username', value: username);
        await _storage.write(key: 'password', value: password);

        final cookies = await _cookieJar.loadForRequest(Uri.parse(_loginUrl));
        final session = cookies.firstOrNull;
        if (session != null) {
          await _storage.write(
            key: 'session_id',
            value: '${session.name}=${session.value}',
          );
        }
      }

      return _isLoggedIn;
    } on DioException catch (e) {
      _isLoggedIn = false;
      throw LoginException(_mapDioError(e));
    }
  }

  Future<bool> checkSession() async {
    await init();
    try {
      final response = await _dio.get(
        _sessionCheckUrl,
        options: Options(followRedirects: false, validateStatus: (_) => true),
      );
      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';
      _isLoggedIn =
          status == 200 ||
          (status == 302 && !location.toLowerCase().contains('login'));
      return _isLoggedIn;
    } catch (_) {
      _isLoggedIn = false;
      return false;
    }
  }

  Future<bool> hasCredentials() async {
    final username = await _storage.read(key: 'username');
    return username != null;
  }

  Future<bool> autoLogin() async {
    await init();
    final username = await _storage.read(key: 'username');
    final password = await _storage.read(key: 'password');
    if (username == null || password == null) return false;
    return login(username, password);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    await _cookieJar.deleteAll();
    await _storage.deleteAll();
  }

  Dio get dio => _dio;

  String _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
        'Verbindung zum Server hat zu lange gedauert.',
      DioExceptionType.connectionError =>
        'Keine Verbindung. Bitte Internetverbindung prüfen.',
      _ => 'Unbekannter Fehler: ${e.message}',
    };
  }
}

class LoginException implements Exception {
  final String message;
  LoginException(this.message);

  @override
  String toString() => message;
}
