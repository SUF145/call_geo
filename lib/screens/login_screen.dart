import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/supabase_service.dart';
import '../theme/space_theme.dart';
import '../widgets/space_background.dart';
import '../widgets/cosmic_button.dart';
import '../widgets/cosmic_text_field.dart';
import '../widgets/cosmic_card.dart';
import 'admin_signup_screen.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = await SupabaseService().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (user != null && mounted) {
        // Debug information
        debugPrint('User logged in: ${user.email}');
        debugPrint('User role: ${user.role}');
        debugPrint('Is admin: ${user.isAdmin}');

        // Navigate to the appropriate screen based on user role
        if (user.isAdmin) {
          debugPrint('Navigating to AdminHomeScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => AdminHomeScreen(admin: user)),
          );
        } else {
          debugPrint('Navigating to HomeScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App logo/title
                    Column(
                      children: [
                        Text(
                          "CallGeo",
                          style: SpaceTheme.textTheme.displayLarge?.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: SpaceTheme.starlightSilver,
                            shadows: [
                              BoxShadow(
                                color: SpaceTheme.pulsarBlue.withOpacity(0.7),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "TRACKER",
                          style: SpaceTheme.orbitronStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: SpaceTheme.nebulaPink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Login form card
                    CosmicCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mission Control Access',
                            style: SpaceTheme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Email field
                          CosmicTextField(
                            label: 'Email',
                            hint: 'Enter your email address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Password field
                          CosmicTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: SpaceTheme.starlightSilver,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Login button
                          CosmicButton(
                            text: 'Launch Mission',
                            icon: Icons.rocket_launch,
                            color: SpaceTheme.cosmicPurple,
                            onPressed: _isLoading ? () {} : _signIn,
                            isGlowing: !_isLoading,
                            height: 56,
                          ),
                          if (_isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Center(
                                child: SpinKitRing(
                                  color: SpaceTheme.pulsarBlue,
                                  size: 30,
                                  lineWidth: 3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                
                    // Admin account creation section
                    FutureBuilder<bool>(
                      future: SupabaseService().adminExists(),
                      builder: (context, snapshot) {
                        // Show loading indicator while checking admin status
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SpaceTheme.pulsarBlue,
                              ),
                            ),
                          );
                        }

                        // Handle error case
                        if (snapshot.hasError) {
                          debugPrint('Error checking admin exists: ${snapshot.error}');
                          return CosmicCard(
                            glowColor: SpaceTheme.marsRed,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Connection Error',
                                  style: SpaceTheme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Unable to verify admin status.',
                                  style: SpaceTheme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                CosmicButton(
                                  text: 'Retry',
                                  icon: Icons.refresh,
                                  color: SpaceTheme.marsRed,
                                  onPressed: () => setState(() {}),
                                  width: 120,
                                ),
                              ],
                            ),
                          );
                        }

                        // Get admin exists status, default to false if null
                        final adminExists = snapshot.data ?? false;
                        debugPrint('Admin exists check result: $adminExists');

                        if (adminExists) {
                          // If admin exists, just show a message about contacting admin
                          return CosmicCard(
                            isGlowing: false,
                            padding: const EdgeInsets.all(16),
                            backgroundColor: SpaceTheme.deepSpaceNavy.withOpacity(0.5),
                            child: Text(
                              'Contact your mission commander for access credentials.',
                              textAlign: TextAlign.center,
                              style: SpaceTheme.textTheme.bodyMedium?.copyWith(
                                color: SpaceTheme.starlightSilver.withOpacity(0.7),
                              ),
                            ),
                          );
                        }

                        // No admin exists, show option to create one
                        return CosmicCard(
                          glowColor: SpaceTheme.saturnGold,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'No Mission Commander Detected',
                                style: SpaceTheme.textTheme.titleLarge?.copyWith(
                                  color: SpaceTheme.saturnGold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              CosmicButton(
                                text: 'Establish Command Center',
                                icon: Icons.admin_panel_settings,
                                color: SpaceTheme.saturnGold,
                                onPressed: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const AdminSignupScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
