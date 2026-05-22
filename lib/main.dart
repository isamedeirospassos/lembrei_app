import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'services/device_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente do .env
  await dotenv.load(fileName: ".env");

  // Inicializa o Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 🔐 Login anônimo automático (se ainda não tiver usuário)
  await _garantirLogin();

  // Inicializa timezone e notificações
  tz_data.initializeTimeZones();
  await NotificationService().inicializar();

  final deviceId = await DeviceService.getDeviceId();
  print('✅ Device ID do app: $deviceId');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// Faz login anônimo automaticamente se ainda não estiver logado.
/// Cada dispositivo vira um "usuário fantasma" no Supabase.
Future<void> _garantirLogin() async {
  final supabase = Supabase.instance.client;

  if (supabase.auth.currentUser != null) {
    print('✅ Usuário já logado: ${supabase.auth.currentUser!.id}');
    return;
  }

  try {
    final response = await supabase.auth.signInAnonymously();
    print('✅ Login anônimo realizado: ${response.user?.id}');
  } catch (e) {
    print('❌ Erro no login anônimo: $e');
    print('⚠️ Verifique se "Anonymous Sign-ins" está habilitado no Supabase');
  }
}

// Atalho pra usar o Supabase em qualquer tela do app
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Lembrei',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      home: const HomePage(),
    );
  }
}