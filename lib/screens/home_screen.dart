import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/space_theme.dart';
import '../widgets/space_background.dart';
import '../widgets/cosmic_button.dart';
import '../widgets/cosmic_card.dart';
import 'login_screen.dart';
import 'user_location_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await SupabaseService().signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mission Control',
          style: SpaceTheme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SpaceBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Welcome, Explorer',
                  style: SpaceTheme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                CosmicCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 60,
                        color: SpaceTheme.nebulaPink,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Location Tracking',
                        style: SpaceTheme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitor your cosmic coordinates in real-time',
                        textAlign: TextAlign.center,
                        style: SpaceTheme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      CosmicButton(
                        text: 'Launch Tracker',
                        icon: Icons.rocket_launch,
                        color: SpaceTheme.pulsarBlue,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const UserLocationScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
