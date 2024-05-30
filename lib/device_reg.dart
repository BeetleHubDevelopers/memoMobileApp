// ignore_for_file: camel_case_types, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:memoauthapp/main.dart';
import 'package:memoauthapp/request.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class deviceReg extends StatefulWidget {
  const deviceReg({super.key});

  @override
  State<deviceReg> createState() => _deviceRegState();
}

class _deviceRegState extends State<deviceReg> {
  final TextEditingController _deviceNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerDevice() async {
    if (_deviceNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a valid device name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final deviceUid = prefs.getString('device_uid') ?? const Uuid().v4();
    final accessToken = prefs.getString('access_token') ?? "";

    try {
      final checkResponse = await http.get(
        Uri.parse(
            'https://kdsg-authenticator-43d1272b8d77.herokuapp.com/api/devices/check?device_code=$deviceUid'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (checkResponse.statusCode == 200) {
        final responseData = jsonDecode(checkResponse.body);
        if (responseData['registered'] == true) {
          _showErrorDialog('Device is already registered');
          return;
        }
      }

      final registerResponse = await http.post(
        Uri.parse(
            'https://kdsg-authenticator-43d1272b8d77.herokuapp.com/api/devices/link'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({
          'device_code': deviceUid,
          'device_name': _deviceNameController.text,
        }),
      );

      if (registerResponse.statusCode >= 200 &&
          registerResponse.statusCode <= 300) {
        prefs.setString('device_uid', deviceUid);
        _showSuccessfulDialog('Device registered successfully!').then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RequestApp()),
          );
        });
      } else {
        print(
            'Failed to register device. Status code: ${registerResponse.statusCode}');
        print('Response body: ${registerResponse.body}');
        throw Exception(
            'Failed to register device. Status code: ${registerResponse.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to register device: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
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
          title: const Text('Success'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreenPage()),
            );
          },
        ),
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
                    'assets/kdsglogo.png',
                    height: 150,
                    width: 150,
                  ),
                ),
                const Text(
                  'Register Device',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32.0),
                TextField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Device name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.maxFinite,
                        child: ElevatedButton(
                          onPressed: _registerDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                            textStyle: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text(
                            'Register',
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
