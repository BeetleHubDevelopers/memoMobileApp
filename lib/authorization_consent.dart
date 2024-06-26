// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:memoauthapp/constants.dart';
import 'package:memoauthapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';

class AuthorizationConsentScreen extends StatefulWidget {
  const AuthorizationConsentScreen({super.key});

  @override
  _AuthorizationConsentScreenState createState() =>
      _AuthorizationConsentScreenState();
}

class _AuthorizationConsentScreenState
    extends State<AuthorizationConsentScreen> {
  List<dynamic> _pendingRequests = [];
  List<dynamic> _completedRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

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

  Future<void> fetchRequests() async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString(sharedPrefKeyAccessToken) ?? '';
    var deviceCode = prefs.getString(sharedPrefKeyDeviceCode) ?? '';

    if (accessToken.isEmpty || deviceCode.isEmpty) {
      throw Exception('Missing access token or device code');
    }

    var url = Uri.parse(
        '$apiBaseUrl/profile/authorization-consents/list?device_code=$deviceCode');
    var response = await httpClient.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == 404) {
      _showErrorDialog(context, 'Page not found');
      return;
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      var jsonResponse = json.decode(response.body);
      setState(() {
        _pendingRequests = jsonResponse['data']
                ?.where((request) => request['status'] == 'PENDING')
                .toList() ??
            [];
        _completedRequests = jsonResponse['data']
                ?.where((request) => request['status'] != 'PENDING')
                .toList() ??
            [];
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

  Future<void> _approveRequest(BuildContext context, String uid) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FingerprintAuthPage(uid: uid),
      ),
    );

    if (result == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString(sharedPrefKeyAccessToken) ?? '';
        var deviceCode = prefs.getString(sharedPrefKeyDeviceCode) ?? '';

        if (accessToken.isEmpty || deviceCode.isEmpty) {
          throw Exception('Missing access token or device code');
        }

        var url =
            Uri.parse('$apiBaseUrl/profile/authorization-consents/complete');
        var response = await httpClient.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: jsonEncode(
              {'uid': uid, 'action': 'APPROVED', 'device_code': deviceCode}),
        );

        if (response.statusCode == 404) {
          _showErrorDialog(
              context, 'Request not found. Please try again later.');
        } else if (response.statusCode == 400) {
          _showErrorDialog(context, 'Request has been approved already.');
        } else if (response.statusCode >= 200 && response.statusCode <= 300) {
          _showSuccessfulDialog(context, 'Request has been approved!');
          setState(() {
            fetchRequests();
          });
        } else {
          throw Exception(
              'Failed to approve request: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to approve request: $e');
      } finally {}
    }
  }

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
      try {
        final prefs = await SharedPreferences.getInstance();
        var accessToken = prefs.getString(sharedPrefKeyAccessToken) ?? '';
        var deviceCode = prefs.getString(sharedPrefKeyDeviceCode) ?? '';

        if (accessToken.isEmpty || deviceCode.isEmpty) {
          throw Exception('Missing access token or device code');
        }

        var url =
            Uri.parse('$apiBaseUrl/profile/authorization-consents/complete');
        var response = await httpClient.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: jsonEncode(
              {'uid': uid, 'action': 'DECLINED', 'device_code': deviceCode}),
        );

        if (response.statusCode == 404) {
          _showErrorDialog(
              context, 'Request not found. Please try again later.');
        } else if (response.statusCode == 400) {
          _showErrorDialog(context, 'Request has been declined already.');
        } else if (response.statusCode >= 200 && response.statusCode <= 300) {
          _showSuccessfulDialog(context, 'Request has been declined!');
          setState(() {
            fetchRequests();
          });
        } else {
          throw Exception(
              'Failed to decline request: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to decline request: $e');
      } finally {}
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const LoginScreenPage()));
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
            leading: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
              ),
              onPressed: _isLoading ? null : () => _logout(context),
            ),
            title: const Center(
              child: Text(
                'Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _refreshRequests,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_pendingRequests.isEmpty && _completedRequests.isEmpty)
                  ? const Center(child: Text('No requests found.'))
                  : RefreshIndicator(
                      onRefresh: _refreshRequests,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_pendingRequests.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Pending Requests',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _pendingRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _pendingRequests[index];
                                  return ListTile(
                                    title: Text(request['title'] ?? 'No title'),
                                    subtitle: const Text(
                                      'PENDING',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(
                                              Icons.check_circle_rounded),
                                          onPressed: () {
                                            _approveRequest(
                                                context, request['uid']);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: () {
                                            _declineRequest(
                                                context, request['uid']);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (_completedRequests.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Completed Requests',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _completedRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _completedRequests[index];
                                  final status =
                                      request['status'] ?? 'No status';
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
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
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
