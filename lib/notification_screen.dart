// ignore_for_file: use_build_context_synchronously, unused_local_variable, prefer_final_fields, avoid_print

import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'authorization_consent.dart';
import 'constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeNotifications();
    _refreshNotifications();
  }

  void _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  void _initializeNotifications() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (receivedNotification) async {
        if (mounted) {
          setState(() {
            _notifications.add(
                receivedNotification.body ?? 'You have a new notification');
          });
          await _showNotificationDialog(
            receivedNotification.title ?? 'Notification',
            receivedNotification.body ?? 'You have a new notification',
          );
        }
      },
    );
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await fetchNotifications();
    } catch (e) {
      if (mounted) {
        await _showErrorDialog(context, 'Error fetching notifications');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString(sharedPrefKeyAccessToken) ?? '';

    if (accessToken.isEmpty) {
      throw Exception('Missing access token');
    }

    var url = Uri.parse('$apiBaseUrl/notifications/list');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
    );

    if (response.statusCode == 404) {
      await _showErrorDialog(context, 'Page not found');
      return;
    } else if (response.statusCode >= 200 && response.statusCode < 300) {
      var jsonResponse = json.decode(response.body);
      // Handle the response as per your requirement
      await _showSuccessfulDialog(
          context, 'Notifications retrieved successfully!');
    } else {
      throw Exception(
          'Failed to load notifications'); //: ${response.statusCode} ${response.body}
    }
  }

  Future<void> _showNotificationDialog(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
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

  Future<void> _showSuccessfulDialog(
      BuildContext context, String message) async {
    await showDialog<void>(
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

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    await showDialog<void>(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
            child: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        )),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AuthorizationConsentScreen(),
              ),
            );
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              if (!_isLoading) {
                _refreshNotifications();
              }
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications found.'))
              : RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_notifications[index]),
                      );
                    },
                  ),
                ),
    );
  }
}
