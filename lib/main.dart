import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/camera_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CameraProvider>(
          create: (context) => CameraProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (_, auth, cameraProvider) =>
              cameraProvider ?? CameraProvider(auth),
        ),
      ],
      child: const VisionTrackApp(),
    ),
  );
}

class VisionTrackApp extends StatelessWidget {
  const VisionTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionTrack',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
