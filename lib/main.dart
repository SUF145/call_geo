import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'services/supabase_service.dart';
import 'services/call_recording_service.dart';
import 'services/geo_tracking_service.dart';
import 'services/notification_service.dart';
import 'services/firebase_messaging_service_new.dart';
import 'models/user_model.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_user_location_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize services
  final callRecordingService = CallRecordingService();
  await callRecordingService.initialize();

  // Initialize Firebase Messaging Service
  final firebaseMessagingService = FirebaseMessagingService();
  await firebaseMessagingService.initialize();

  // Initialize geo tracking service with background capability
  final geoTrackingService = GeoTrackingService();
  await geoTrackingService.initialize();

  // Initialize Google Maps
  if (defaultTargetPlatform == TargetPlatform.android) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Global navigator key to access navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Set up method channel to handle navigation from native code
    const MethodChannel channel = MethodChannel('com.example.call_geo/main');
    channel.setMethodCallHandler(_handleMethodCall);

    // Set up Firebase Messaging handlers
    _setupFirebaseMessaging();
  }

  // Set up Firebase Messaging handlers
  void _setupFirebaseMessaging() {
    // Handle notification when app is opened from a terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
            'App opened from terminated state with message: ${message.data}');
        _handleNotificationData(message.data);
      }
    });

    // Handle notification when app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          'App opened from background state with message: ${message.data}');
      _handleNotificationData(message.data);
    });

    // Handle notification when app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'Received message while app was in foreground: ${message.data}');
      // No need to navigate here as the notification will be shown by the system
    });
  }

  // Handle notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    final bool isAdminNotification =
        data['is_admin_notification']?.toString() == 'true';
    final String? userId = data['user_id'];

    debugPrint('Handling notification data: $data');
    debugPrint('Is admin notification: $isAdminNotification');
    debugPrint('User ID: $userId');

    if (isAdminNotification && userId != null) {
      // Navigate to the user location screen
      _navigateToUserLocation(userId);
    }
  }

  // Handle method calls from native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'navigateToUserLocation':
        final String userId = call.arguments as String;
        // Navigate to the user location screen
        _navigateToUserLocation(userId);
        return true;
      default:
        return null;
    }
  }

  // Navigate to user location screen
  void _navigateToUserLocation(String userId) async {
    // Get the current context from the navigator key
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Check if the current user is an admin
      final currentUser = await SupabaseService().getCurrentUser();
      if (currentUser != null &&
          currentUser.isAdmin &&
          navigatorKey.currentContext != null) {
        // Navigate to the user location screen
        Navigator.of(navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (context) => AdminUserLocationScreen(userId: userId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call & Geo',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await SupabaseService().getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser != null) {
      // Debug information
      debugPrint('Current user: ${_currentUser!.email}');
      debugPrint('User role: ${_currentUser!.role}');
      debugPrint('Is admin: ${_currentUser!.isAdmin}');

      // Navigate based on user role
      if (_currentUser!.isAdmin) {
        debugPrint('Navigating to AdminHomeScreen');
        return AdminHomeScreen(admin: _currentUser!);
      } else {
        debugPrint('Navigating to HomeScreen');
        return const HomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}
