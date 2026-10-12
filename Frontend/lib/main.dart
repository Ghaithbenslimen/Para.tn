import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:project/parapharmacy_page.dart';
import 'package:project/services/cart_service.dart';
import 'package:project/welcome_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// Change to async function
Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await CartService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        fontFamily: 'Poppins',
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to HomeScreen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ParapharmacyPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 221, 245, 229),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/—Pngtree—women nature logo_7598961.png',
              height: 300,
            ),
            const SizedBox(height: 10),
            Text(
              'Para.tn',
              style: TextStyle(
                fontSize: 32,
                fontFamily: 'Poppins',
                color: Color.fromARGB(255, 5, 175, 5), // Dark pink color
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
