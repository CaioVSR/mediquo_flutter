import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mediquo_flutter/mediquo_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MediquoExampleApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } on Exception catch (error) {
    debugPrint('Firebase is not configured; push is disabled: $error');
  }
}

class MediquoExampleApp extends StatelessWidget {
  const MediquoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediQuo Flutter Example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const SessionPage(),
    );
  }
}

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final _mediquo = Mediquo();
  final _apiKeyController = TextEditingController();
  final _clientCodeController = TextEditingController();

  bool _busy = false;
  bool _authenticated = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;

  @override
  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_notificationTapSubscription?.cancel());
    _apiKeyController.dispose();
    _clientCodeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startSession() async {
    final MediquoConfiguration configuration;
    try {
      configuration = MediquoConfiguration.validated(
        apiKey: _apiKeyController.text,
        clientCode: _clientCodeController.text,
      );
    } on ArgumentError catch (error) {
      _showError(error.message.toString());
      return;
    }

    setState(() => _busy = true);
    try {
      await _mediquo.startSession(configuration);
      setState(() => _authenticated = true);
      await _setUpPushNotifications();
    } on MediquoException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openProfessionalList() async {
    try {
      await _mediquo.openProfessionalList();
    } on MediquoException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    try {
      await _mediquo.logout();
      setState(() => _authenticated = false);
    } on MediquoException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setUpPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await _mediquo.registerPushToken(MediquoPushToken.fcm(token));
      }
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((value) {
        unawaited(_mediquo.registerPushToken(MediquoPushToken.fcm(value)));
      });
      await _notificationTapSubscription?.cancel();
      _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((message) {
            unawaited(_mediquo.openFromNotification(message.data));
          });
    } on Exception catch (error) {
      debugPrint('Push notifications skipped: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediQuo Flutter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'API key'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Client code (CPF)',
              ),
            ),
            const SizedBox(height: 24),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              FilledButton(
                onPressed: _startSession,
                child: const Text('Start session'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _authenticated ? _openProfessionalList : null,
                child: const Text('Open professional list'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _authenticated ? _logout : null,
                child: const Text('Log out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
