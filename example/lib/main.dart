import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phantom_flutter/phantom_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PhantomOverlay(
      child: MaterialApp(
        title: 'Phantom Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _seedSampleData();
  }

  void _seedSampleData() {
    Phantom.registerConfig('API Base URL', key: 'api_base_url', defaultValue: 'https://jsonplaceholder.typicode.com');
    Phantom.registerConfig('Enable Cache', key: 'enable_cache', defaultValue: 'true', type: PhantomConfigType.toggle, group: 'Performance');
    Phantom.registerConfig('Log Level', key: 'log_level', defaultValue: 'info', type: PhantomConfigType.picker, options: ['debug', 'info', 'warning', 'error'], group: 'General');
    Phantom.registerConfig('Timeout (seconds)', key: 'timeout', defaultValue: '30', group: 'Performance');

    Phantom.registerLocalization(key: 'welcome', english: 'Welcome', spanish: 'Bienvenido', group: 'Home');
    Phantom.registerLocalization(key: 'login', english: 'Log In', spanish: 'Iniciar Sesión', group: 'Auth');
    Phantom.registerLocalization(key: 'logout', english: 'Log Out', spanish: 'Cerrar Sesión', group: 'Auth');
    Phantom.registerLocalization(key: 'settings', english: 'Settings', spanish: 'Configuración', group: 'General');
    Phantom.registerLocalization(key: 'profile', english: 'Profile', spanish: 'Perfil', group: 'General');

    Phantom.log(PhantomLogLevel.info, 'App started', tag: 'Lifecycle');
    Phantom.log(PhantomLogLevel.info, 'User session initialized', tag: 'Auth');

    Phantom.completeRequest(
      method: 'GET',
      url: 'https://api.example.com/v1/users',
      statusCode: 200,
      responseHeaders: 'Content-Type: application/json',
      responseBody: '{"users": [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]}',
      durationMs: 245,
    );

    Phantom.completeRequest(
      method: 'POST',
      url: 'https://api.example.com/v1/auth/login',
      requestHeaders: 'Content-Type: application/json',
      requestBody: '{"email": "john@example.com", "password": "***"}',
      statusCode: 200,
      responseBody: '{"token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.abc123"}',
      durationMs: 380,
    );

    Phantom.completeRequest(
      method: 'GET',
      url: 'https://api.example.com/v1/orders/999',
      statusCode: 404,
      responseBody: '{"error": "Order not found"}',
      durationMs: 95,
    );

    Phantom.log(PhantomLogLevel.error, 'Order 999 not found', tag: 'Network');
    Phantom.log(PhantomLogLevel.warning, 'Cache expired, refreshing...', tag: 'Cache');
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    Phantom.log(PhantomLogLevel.info, 'Fetching posts...', tag: 'Network');

    const urlStr = 'https://jsonplaceholder.typicode.com/posts';
    Phantom.logRequest(method: 'GET', url: urlStr);

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(urlStr));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final statusCode = response.statusCode;
      final headers = <String>[];
      response.headers.forEach((name, values) {
        headers.add('$name: ${values.join(', ')}');
      });

      Phantom.logResponse(
        url: urlStr,
        statusCode: statusCode,
        headers: headers.join('\n'),
        body: body,
      );

      client.close();

      if (statusCode == 200) {
        setState(() => _posts = jsonDecode(body) as List);
        Phantom.log(PhantomLogLevel.info, 'Loaded ${_posts.length} posts', tag: 'Network');
      }
    } catch (e) {
      Phantom.log(PhantomLogLevel.error, 'Fetch failed: $e', tag: 'Network');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Phantom Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.deepPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap the floating purple button to open Phantom',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No posts yet'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchPosts,
                              child: const Text('Fetch Posts'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (_, i) {
                          final post = _posts[i] as Map<String, dynamic>;
                          return ListTile(
                            title: Text(
                              post['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              post['body'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
