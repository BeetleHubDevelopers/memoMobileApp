import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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
    // Check if the device name is empty or contains only spaces
    if (_deviceNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a valid device name');
      return; // Exit the function without registering the device
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final deviceUid = prefs.getString('device_uid') ?? const Uuid().v4();
    final accessToken = prefs.getString('access_token') ?? "";

    try {
      final response = await http.post(
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

      if (response.statusCode >= 200 && response.statusCode <= 300) {
        prefs.setString('device_uid', deviceUid);
        _showSuccesfulDialog('Device registered successfully');
      } else {
        // Log status code and response body for debugging
        print('Failed to register device. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to register device. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to register device: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //displays whatever errors encountered
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

  //displays whatever errors encountered
  void _showSuccesfulDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Successful'),
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
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                  keyboardType: TextInputType.emailAddress,
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
