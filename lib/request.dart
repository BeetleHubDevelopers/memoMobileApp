// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:memoauthapp/device_reg.dart';
import 'dart:convert';
import 'package:memoauthapp/main.dart'; // Make sure this import is correct // Import DeviceRegScreen

class RequestApp extends StatelessWidget {
  const RequestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Request',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RequestScreen(),
    );
  }
}

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  RequestScreenState createState() => RequestScreenState();
}

class RequestScreenState extends State<RequestScreen> {
  late Future<List<RequestModel>> requests;

  @override
  void initState() {
    super.initState();
    requests = fetchRequests();
  }

  Future<List<RequestModel>> fetchRequests() async {
    const accessToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJqd3QtYXVkaWVuY2UiLCJpc3MiOiJodHRwczovL2p3dC1wcm92aWRlci1kb21haW4vIiwidXNlclVpZCI6IjE4NjU0MGZjLTRlYzctNGRmNS05ZTUzLWI0ODVhZmUwYWFlNiIsImV4cCI6MTcxNzA2ODE3Mn0.zQHxDc-cRp3Cb0JCtgYcb_Ek2xDFj1z2FaFwsvCduxA';
    const deviceCode = '888341ed-2173-4dcb-bd00-e31bbdcdbcf8';

    final response = await http.get(
      Uri.parse(
          'https://kdsg-authenticator-43d1272b8d77.herokuapp.com/api/requests/list'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Device-ID': deviceCode,
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 300) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      List<dynamic> requestList = responseBody['data'];
      return requestList.map((json) => RequestModel.fromJson(json)).toList();
    } else {
      print("Response Code: ${response.statusCode}");
      print(response.body);
      throw Exception('Failed to load requests');
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      requests = fetchRequests();
    });
  }

  Future<void> _showOverwriteDialog(RequestModel existingRequest) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Exists'),
          content: const Text(
              'This request already exists. Do you wish to overwrite it?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                // Logic to overwrite the request
                print('Request overwritten');
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForDuplicateAndNavigate(RequestModel newRequest) async {
    List<RequestModel> existingRequests = await fetchRequests();
    for (RequestModel request in existingRequests) {
      if (request.uid == newRequest.uid) {
        await _showOverwriteDialog(request);
        return;
      }
    }
    // Navigate to the request detail screen if no duplicates found
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(uid: newRequest.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Request')),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const deviceReg()),
              );
            }),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRequests,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        child: FutureBuilder<List<RequestModel>>(
          future: requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No requests found'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final request = snapshot.data![index];
                return ListTile(
                  title: Text(request.title),
                  onTap: () => _checkForDuplicateAndNavigate(request),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class RequestModel {
  final String uid;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime lastModifiedAt;

  RequestModel({
    required this.uid,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.lastModifiedAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      uid: json['uid'],
      title: json['title'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      lastModifiedAt: DateTime.parse(json['last_modified_at']),
    );
  }
}

class RequestDetailScreen extends StatelessWidget {
  final String uid;

  const RequestDetailScreen({super.key, required this.uid});

  Future<Map<String, dynamic>> fetchRequestDetail() async {
    const accessToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJqd3QtYXVkaWVuY2UiLCJpc3MiOiJodHRwczovL2p3dC1wcm92aWRlci1kb21haW4vIiwidXNlclVpZCI6IjE4NjU0MGZjLTRlYzctNGRmNS05ZTUzLWI0ODVhZmUwYWFlNiIsImV4cCI6MTcxNzA2ODE3Mn0.zQHxDc-cRp3Cb0JCtgYcb_Ek2xDFj1z2FaFwsvCduxA';
    const deviceCode = '888341ed-2173-4dcb-bd00-e31bbdcdbcf8';

    final response = await http.get(
      Uri.parse(
          'https://kdsg-authenticator-43d1272b8d77.herokuapp.com/api/requests/find/$uid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'Device-ID': deviceCode,
      },
    );

    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load request detail');
    }
  }

  void _approveRequest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const FingerprintAuthPage(
                uid: 'uid',
              )),
    );
  }

  void _declineRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Decline'),
          content: const Text('Are you sure you want to decline this request?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request declined')),
                );
                _showResendDialog(context);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showResendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Resend Request'),
          content: const Text('Do you want to resend the declined request?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Logic to resend the request
                print('Request resent');
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchRequestDetail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
                // title: const Center(child: Text('Request Detail')),
                ),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Request Detail'),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Request Detail'),
            ),
            body: const Center(child: Text('Request not found')),
          );
        }

        final request = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title:
                Title(color: Colors.black, child: const Text('Request Detail')),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Title: ${request['title']}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        textStyle: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _approveRequest(context),
                      child: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        textStyle: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _declineRequest(context),
                      child: const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
