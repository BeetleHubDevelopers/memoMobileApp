// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:local_auth/local_auth.dart';

class RequestApp extends StatefulWidget {
  const RequestApp({super.key});

  @override
  _RequestAppState createState() => _RequestAppState();
}

class _RequestAppState extends State<RequestApp> {
  List<dynamic>? _requests;
  bool _isLoading = false;

  Future<void> _refreshRequests() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await fetchRequests();
    } catch (e) {
      _showErrorDialog(context, 'Error fetching requests: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// fetches all the requests
  Future<void> fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access_token') ?? '';
    var deviceCode = prefs.getString('device_code') ?? '';

    if (accessToken.isEmpty || deviceCode.isEmpty) {
      throw Exception('Missing access token or device code');
    }

    var url = Uri.parse(
        'https://kdsg-authenticator-43d1272b8d77.herokuapp.com/api/requests/list');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Device-ID': deviceCode,
      },
    );

    if (response.statusCode == 404) {
      _showErrorDialog(context, 'Page not found');
      return;
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      var jsonResponse = json.decode(response.body);
      setState(() {
        _requests = jsonResponse['data'] ?? [];
      });
    } else {
      throw Exception(
          'Failed to load requests: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _showSuccessfulDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
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

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
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

// handles the approve request
  Future<void> _approveRequest(BuildContext context, String uid) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FingerprintAuthPage(uid: uid),
      ),
    );

    if (result == true) {
      var client = http.Client();
      try {
        final prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access_token') ?? '';
        var deviceCode = prefs.getString('device_code') ?? '';

        if (accessToken.isEmpty || deviceCode.isEmpty) {
          throw Exception('Missing access token or device code');
        }

        var url = Uri.parse(
            'https://kdsg-authenticator-43d1272b8d77.herokuapp.com/api/requests/complete/$uid');
        var response = await client.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Device-ID': deviceCode,
          },
          body: jsonEncode({
            'action': 'APPROVED',
          }),
        );

        if (response.statusCode == 404) {
          _showErrorDialog(
              context, 'Request not found. Please try again later.');
        } else if (response.statusCode == 400) {
          _showErrorDialog(context, 'Request has been approved already.');
        } else if (response.statusCode >= 200 && response.statusCode <= 300) {
          _showSuccessfulDialog(context, 'Request has been approved!');
          setState(() {
            _isLoading = true;
          });
          await _refreshRequests();
          setState(() {
            _isLoading = false;
          });
        } else {
          throw Exception(
              'Failed to approve request: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to approve request: $e');
      } finally {
        client.close();
      }
    } else {
      // Handle the case where the user cancels the authentication or declines the request
    }
  }
// 
  Future<void> _declineRequest(BuildContext context, String uid) async {
    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Request'),
          content: const Text('Are you sure you want to decline this request?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    if (shouldDecline == true) {
      var client = http.Client();
      try {
        final prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString('access_token') ?? '';
        var deviceCode = prefs.getString('device_code') ?? '';

        if (accessToken.isEmpty || deviceCode.isEmpty) {
          throw Exception('Missing access token or device code');
        }

        var url = Uri.parse(
            'https://kdsg-authenticator-43d1272b8d77.herokuapp.blackcom/api/requests/complete/$uid');
        var response = await client.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'Device-ID': deviceCode,
          },
          body: jsonEncode({
            'action': 'DECLINED',
          }),
        );

        if (response.statusCode == 404) {
          _showErrorDialog(
              context, 'Request not found. Please try again later.');
        } else if (response.statusCode == 400) {
          _showErrorDialog(context, 'Request has been declined already.');
        } else if (response.statusCode >= 200 && response.statusCode <= 300) {
          _showSuccessfulDialog(context, 'Request has been declined!');
          setState(() {
            _isLoading = true;
          });
          await _refreshRequests();
          setState(() {
            _isLoading = false;
          });
        } else {
          throw Exception(
              'Failed to decline request: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to decline request: $e');
      } finally {
        client.close();
      }
    } else {
      // Handle the case where the user cancels the decline request
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) {
          return false;
        }
        return true;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Request'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _refreshRequests,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _requests == null
                  ? const Center(child: Text('No requests found.'))
                  : RefreshIndicator(
                      onRefresh: _refreshRequests,
                      child: ListView.builder(
                        itemCount: _requests!.length,
                        itemBuilder: (context, index) {
                          final request = _requests![index];
                          final status = request['status'] ?? 'No status';
                          Color statusColor;

                          if (status == 'APPROVED') {
                            statusColor = Colors.green;
                          } else if (status == 'DECLINED') {
                            statusColor = Colors.red;
                          } else {
                            statusColor = Colors.orange;
                          }

                          return ListTile(
                            title: Text(request['title'] ?? 'No title'),
                            subtitle: Text(
                              status,
                              style: TextStyle(color: statusColor),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (status == 'PENDING')
                                  IconButton(
                                    icon:
                                        const Icon(Icons.check_circle_rounded),
                                    onPressed: () {
                                      _approveRequest(context, request['uid']);
                                    },
                                  ),
                                if (status == 'PENDING')
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      _declineRequest(context, request['uid']);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

class FingerprintAuthPage extends StatefulWidget {
  final String uid;
  const FingerprintAuthPage({super.key, required this.uid});

  @override
  _FingerprintAuthPageState createState() => _FingerprintAuthPageState();
}

class _FingerprintAuthPageState extends State<FingerprintAuthPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String _message = "Please authenticate";
  String _localizedReason = 'Scan your biometric to authenticate';
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });
    try {
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

      if (availableBiometrics.contains(BiometricType.face)) {
        _localizedReason = 'Scan your faceID to authenticate';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        _localizedReason = 'Scan your fingerprint to authenticate';
      }

      bool authenticated = await auth.authenticate(
        localizedReason: _localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _message = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticate'),
      ),
      body: Center(
        child: _isAuthenticating
            ? const CircularProgressIndicator()
            : Text(_message),
      ),
    );
  }
}

void main() => runApp(const RequestApp());
