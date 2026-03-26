// lib/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Call AppConfig.load() once in main() before runApp
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // ─── Backend ───────────────────────────────────────────────────────────────
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  // ─── Google Maps ───────────────────────────────────────────────────────────
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // ─── App info ──────────────────────────────────────────────────────────────
  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'Fluense';

  static String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'development';

  static bool get isProduction => appEnv == 'production';

  // ─── Derived API endpoints ─────────────────────────────────────────────────
  static String get loginEndpoint      => '$baseUrl/auth/login';
  static String get meEndpoint         => '$baseUrl/auth/me';
  static String get attendanceEndpoint => '$baseUrl/attendance';
  static String get visitsEndpoint     => '$baseUrl/visits';
  static String get clientsEndpoint    => '$baseUrl/clients';
  static String get goalsEndpoint      => '$baseUrl/goals';
  static String get usersEndpoint      => '$baseUrl/users';

  // ─── Static data ───────────────────────────────────────────────────────────
  static const List<String> products = [
    'Cirilla',
    'Fertigrace',
    'Grecia Z',
    'Flured XT',
    'Creantia Plus',
    'Reller',
    'Hemfer',
    'Zincovit',
    'Neurobion',
    'Shelcal',
  ];
}
