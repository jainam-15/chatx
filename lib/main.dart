import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/config/firebase_options.dart';
import 'core/utils/logger.dart';
import 'services/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Logger.info('main', 'Initializing Firebase platforms...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    Logger.info('main', 'Firebase successfully initialized');
  } catch (e, stack) {
    Logger.error(
      'main',
      'Initialization failed',
      e,
      stack,
    );
  }

  runApp(
    const ProviderScope(
      child: ChatXApp(),
    ),
  );
}
