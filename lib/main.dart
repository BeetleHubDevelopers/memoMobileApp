import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MemoAuthApp());
}

class MemoAuthApp extends StatelessWidget {
  const MemoAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FingerprintAuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('assets/kdsglogo.png'),
              width: 150,
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              "KDSG Authenticator",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class FingerprintAuthPage extends StatefulWidget {
  const FingerprintAuthPage({super.key});

  @override
  FingerprintAuthPageState createState() => FingerprintAuthPageState();
}

class FingerprintAuthPageState extends State<FingerprintAuthPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String _message = "Please authenticate";
  String _localizedReason = 'Scan your biometric to authenticate';

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      // Check if biometrics are available and any biometric method is enrolled
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isBiometricSupported = await auth.isDeviceSupported();
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      if (!canCheckBiometrics ||
          !isBiometricSupported ||
          availableBiometrics.isEmpty) {
        setState(() {
          _message = "Biometric authentication is not available";
        });
        return;
      }

      // Set localized reason based on available biometrics
      if (availableBiometrics.contains(BiometricType.face)) {
        _localizedReason = 'Scan your faceID to authenticate';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        _localizedReason = 'Scan your fingerprint to authenticate';
      }

      authenticated = await auth.authenticate(
        localizedReason: _localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );
      setState(() {
        _message = authenticated
            ? "Authentication successful"
            : "Authentication failed";
      });
    } catch (e) {
      setState(() {
        _message = "Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blue[900]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text("Authenticate"),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
