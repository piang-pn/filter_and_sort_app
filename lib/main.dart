import 'package:flutter/material.dart';

import 'pages/search_listing.dart';

void main() {
  runApp(const MyApp());
}

/// Aplikasi tugas: fitur Search & Filter produk thrift.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Thrift — Search & Filter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F3E33)),
        useMaterial3: true,
      ),
      home: const SearchListingPage(),
    );
  }
}
