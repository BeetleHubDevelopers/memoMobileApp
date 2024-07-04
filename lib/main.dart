// ignore_for_file: use_build_context_synchronously, unused_element, avoid_print, unused_local_variable

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memoauthapp/constants.dart';
import 'package:memoauthapp/device_registration.dart';
import 'package:memoauthapp/authorization_consent.dart';
import 'package:memoauthapp/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService.initialize();
  // Disable hardware keyboard
  // SystemChannels.keyEvent.setMessageHandler((_) async {
  //   return null;
  // });

  runApp(const LoginScreen());
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(sharedPrefKeyAccessToken);
    if (mounted) {
      bool isAuthorized = false;
      if (token != null) {
        print("Token is not null. Validating...");
        try {
          var response = await http.get(
            Uri.parse('$apiBaseUrl/auth/check-auth'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
          );

          if (response.statusCode >= 200 && response.statusCode <= 300) {
            isAuthorized = true;
          } else {
            print("Status Code: ${response.statusCode}");
          }
        } catch (e) {
          print("An error occurred!");
          print(e);
        }
      }

      if (isAuthorized) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const AuthorizationConsentScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreenPage()),
        );
      }
    }
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
              image: AssetImage('assets/KDSG.jpeg'),
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

class LoginScreenPage extends StatefulWidget {
  const LoginScreenPage({super.key});

  @override
  State<LoginScreenPage> createState() => _LoginScreenPageState();
}

class _LoginScreenPageState extends State<LoginScreenPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> login() async {
    final String username = _emailController.text;
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showWarningDialog('Email and Password cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['data'] != null &&
            responseBody['data']['access_token'] != null) {
          String accessToken = responseBody['data']['access_token'] as String;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(sharedPrefKeyAccessToken, accessToken);

          var deviceCode = prefs.getString(sharedPrefKeyDeviceCode);

          _showSuccessfulDialog('Login Successful!').then((_) {
            if (mounted) {
              if (deviceCode != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AuthorizationConsentScreen()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DeviceRegistrationScreen()),
                );
              }
            }
          });
        } else {
          _showErrorDialog('Login failed. Please check your credentials.');
        }
      } else {
        _showErrorDialog('Login failed. Please try again later.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again later. Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
              ),
              SizedBox(
                width: 8,
              ),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWarningDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orangeAccent,
              ),
              SizedBox(
                width: 8,
              ),
              Text('Warning'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccessfulDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
              ),
              SizedBox(
                width: 8,
              ),
              Text('Success'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Image.asset(
                    'assets/KDSG.jpeg',
                    height: 150,
                    width: 150,
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32.0),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF117C02)),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    suffixIcon: Icon(Icons.email_rounded),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF117C02), width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF117C02)),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF117C02), width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                ),
                const SizedBox(height: 32.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.maxFinite,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF117C02),
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            textStyle: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
