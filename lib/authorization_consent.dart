// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:memoauthapp/constants.dart';
import 'package:memoauthapp/main.dart';
import 'package:memoauthapp/notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'package:badges/badges.dart' as badges;

class AuthorizationConsentScreen extends StatefulWidget {
  const AuthorizationConsentScreen({super.key});

  @override
  _AuthorizationConsentScreenState createState() =>
      _AuthorizationConsentScreenState();
}

class _AuthorizationConsentScreenState extends State<AuthorizationConsentScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _pendingRequests = [];
  List<dynamic> _approvedRequests = [];
  List<dynamic> _declinedRequests = [];
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(
        const Duration(milliseconds: 5)); // Ensure dialog displays
    _showNotificationDialog('Please wait', 'Retrieving requests...');
    try {
      await fetchRequests();
    } catch (e) {
      _showErrorDialog(context, 'Error fetching requests');
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
        _approvedRequests = jsonResponse['data']
                ?.where((request) => request['status'] == 'APPROVED')
                .toList() ??
            [];
        _declinedRequests = jsonResponse['data']
                ?.where((request) => request['status'] == 'DECLINED')
                .toList() ??
            [];
      });
    } else {
      throw Exception('Failed to load requests');
    }
  }

  Future<void> _showNotificationDialog(String title, String body) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(body),
            ],
          ),
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
          throw Exception('Failed to approve request');
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to approve request');
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
          throw Exception('Failed to decline request');
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
                  onPressed: () async {
                    if (!_isLoading) {
                      _showNotificationDialog(
                          'Please wait', 'Retrieving requests...');
                      await _refreshRequests();
                    }
                  }),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                badges.Badge(
                  showBadge: _pendingRequests.isNotEmpty,
                  badgeContent: Text(
                    '${_pendingRequests.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  position: badges.BadgePosition.topEnd(top: -10, end: -12),
                  child: const Tab(
                    icon: Icon(Icons.pending_actions, color: Colors.orange),
                    text: 'Pending',
                  ),
                ),
                const Tab(
                  icon: Icon(Icons.check_circle, color: Color(0xFF117C02)),
                  text: 'Approved',
                ),
                const Tab(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  text: 'Declined',
                ),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_pendingRequests.isEmpty &&
                      _approvedRequests.isEmpty &&
                      _declinedRequests.isEmpty)
                  ? const Center(child: Text('No requests found.'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRequestList(
                            _pendingRequests, 'PENDING', Colors.orange),
                        _buildRequestList(_approvedRequests, 'APPROVED',
                            const Color(0xFF117C02)),
                        _buildRequestList(
                            _declinedRequests, 'DECLINED', Colors.red),
                      ],
                    ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF117C02),
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationScreen()));
            },
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(
      List<dynamic> requests, String status, Color statusColor) {
    if (requests.isEmpty) {
      return const Center(child: Text('No requests found.'));
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return ListTile(
            title: Text(request['title'] ?? 'No title'),
            subtitle: Text(
              status,
              style: TextStyle(color: statusColor),
            ),
            trailing: status == 'PENDING'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Color(0xFF117C02)),
                        onPressed: () {
                          _approveRequest(context, request['uid']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          _declineRequest(context, request['uid']);
                        },
                      ),
                    ],
                  )
                : null,
          );
        },
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
