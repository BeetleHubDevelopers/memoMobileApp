//ignore_for_file: use_build_context_synchronously, unused_element, avoid_print, unused_local_variable, dead_code

import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:memoauthapp/constants.dart';
import 'package:memoauthapp/device_registration.dart';
import 'package:memoauthapp/authorization_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    'resource://drawable/ic_launcher', // Your app icon here
    [
      NotificationChannel(
        channelKey: 'kdsg_channel',
        channelName: 'Kdsg notifications',
        channelDescription: 'Kdsg notifications',
        defaultColor: const Color(0xFA4D50DD),
        ledColor: Colors.white,
      )
    ],
  );

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

//for the splashscreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

//initializes the splash screen before the login page
class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(sharedPrefKeyAccessToken);
    if (mounted) {
      bool isAuthorized = false;
      if (token != null) {
        print("Token is not null. Validating...");
        try {
          var response = await httpClient.get(
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
          // print(e);
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

  //the first screen you see (splash screen) before the login screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/KDSG.jpeg',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "KDSG Authenticator",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(6.0),
            child: Text(
              '© 2024 KDSG. All rights reserved.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(6.0),
            child: Text(
              'Powered by turtletech.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
            ),
          )
        ],
      ),
    );
  }
}

class LoginScreenPage extends StatefulWidget {
  const LoginScreenPage({super.key});

  @override
  State<LoginScreenPage> createState() => _LoginScreenPageState();
}

//declaration of variables for the email and password
class _LoginScreenPageState extends State<LoginScreenPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> login() async {
    final String username = _textController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showWarningDialog(context, 'Email and Password cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    //this handles the request from the login endpoint
    try {
      var response = await httpClient.post(
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

          _showSuccessfulDialog(context, 'Login Successful!').then((_) {
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
          _showErrorDialog(
              context, 'Login failed. Please check your credentials.');
        }
      } else {
        _showErrorDialog(context, 'Login failed. Please try again later.');
      }
    } catch (e) {
      _showErrorDialog(context, 'An error occurred. Please try again later.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //displays whatever errors encountered
  Future<void> _showErrorDialog(BuildContext context, String message) {
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWarningDialog(BuildContext context, String message) {
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccessfulDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF117C02),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  //login page for the app
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Image.asset(
                    'assets/KDSG.jpeg',
                    height: 100,
                    width: 100,
                  ),
                ),
                const SizedBox(
                  height: 5.0,
                ),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 35.0),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF117C02)),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    suffixIcon: Icon(Icons.person_rounded),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF117C02), width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  keyboardType: TextInputType.text,
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
