import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MemoAuthApp(),
    ));

class MemoAuthApp extends StatefulWidget {
  const MemoAuthApp({super.key});

  @override
  State<MemoAuthApp> createState() => _MemoAuthAppState();
}

class _MemoAuthAppState extends State<MemoAuthApp> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0x00ffffff),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Center(
                child: Text(
                  "Memo Workflow App",
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                  margin: const EdgeInsets.symmetric(vertical: 50.0),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        "",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 15.0),
                        width: 150.0,
                        child: const Text(
                          "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 15.0),
                        width: double.infinity,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                            ),
                            onPressed: () {},
                            child: const Text(
                              "Authenticate",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )),
                      )
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
