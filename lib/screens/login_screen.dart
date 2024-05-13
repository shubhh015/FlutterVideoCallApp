// 🎯 Dart imports:
import 'dart:async';
import 'dart:math' as math;

// 🐦 Flutter imports:
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 📦 Package imports:
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_video_call_app/app/user_auth_controller.dart';
import 'package:flutter_video_call_app/theme/app_palette.dart';
import 'package:flutter_video_call_app/widgets/stream_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

// 🌎 Project imports:
import '../core/repos/app_preferences.dart';
import '../core/repos/token_service.dart';
import '../di/injector.dart';
import '../utils/assets.dart';
import '../utils/loading_dialog.dart';
import '../widgets/environment_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _appPreferences = locator<AppPreferences>();
  final _emailController = TextEditingController();

  Future<void> _loginWithGoogle() async {
    final googleService = locator<GoogleSignIn>();

    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return debugPrint('Google login cancelled');

    final userInfo = UserInfo(
      role: 'admin',
      id: googleUser.id,
      name: googleUser.displayName ?? '',
      image: googleUser.photoUrl,
    );
    debugPrint('user is empty');
    return _login(User(info: userInfo), _appPreferences.environment);
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text;
    if (email.isEmpty) return debugPrint('Email is empty');

    final userInfo = UserInfo(
      role: 'admin',
      id: email.replaceAll('@', '_').replaceAll('.', '_'),
      name: email,
    );

    return _login(User(info: userInfo), _appPreferences.environment);
  }

  Future<void> _loginAsGuest() async {
    final userId = randomId(size: 6);
    final userInfo = UserInfo(
      role: 'admin',
      id: userId,
      name: userId,
      image:
          'https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg',
    );

    return _login(User(info: userInfo, type: UserType.guest),
        _appPreferences.environment);
  }

  Future<void> _login(User user, Environment environment) async {
    if (mounted) unawaited(showLoadingIndicator(context));

    // Register StreamVideo client with the user.
    final authController = locator.get<UserAuthController>();
    final credentials = await authController.login(user, environment);
    if (credentials != null) {
      final databaseReference = FirebaseDatabase.instance.reference();
      await databaseReference
          .child('users')
          .child(credentials.userInfo.id)
          .set({
        'id': credentials.userInfo.id,
        'role': credentials.userInfo.role,
        'name': credentials.userInfo.name,
        'image': credentials.userInfo.image,
      });
    }
    if (mounted) hideLoadingIndicator(context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColorPalette.backgroundColor,
        actions: [
          EnvironmentSwitcher(
            currentEnvironment: _appPreferences.environment,
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 36),
                Text('Soulmegle', style: theme.textTheme.headlineMedium),
                Text(
                  '[Video Calling]',
                  style: theme.textTheme.headlineMedium?.apply(
                    color: AppColorPalette.appGreen,
                  ),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _emailController,
                    style:
                        theme.textTheme.bodyMedium?.apply(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Enter Email',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamButton.active(
                    label: 'Sign up with email',
                    icon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                    ),
                    onPressed: _loginWithEmail,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR'),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GoogleLoginButton(
                    onPressed: _loginWithGoogle,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamButton.tertiary(
                    onPressed: _loginAsGuest,
                    label: 'Join As Guest',
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

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({
    super.key,
    required this.onPressed,
    this.label = 'Login with Google',
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Google SignIn plugin is only supported on Web, Android and iOS.
    final isGoogleSignInSupported =
        defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android ||
            kIsWeb;

    final currentPlatform = Theme.of(context).platform.name;

    if (!isGoogleSignInSupported) {
      return Text('Google SignIn is not supported on $currentPlatform.');
    }

    return StreamButton.primary(
      onPressed: onPressed,
      label: 'Continue with Google',
      icon: SvgPicture.asset(
        googleLogoAsset,
        width: 24,
        semanticsLabel: 'Google Logo',
      ),
    );
  }
}

// This alphabet uses `A-Za-z0-9_-` symbols. The genetic algorithm helped
// optimize the gzip compression for this alphabet.
const _alphabet =
    'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';

/// Generates a random String id
/// Adopted from: https://github.com/ai/nanoid/blob/main/non-secure/index.js
String randomId({int size = 21}) {
  var id = '';
  for (var i = 0; i < size; i++) {
    id += _alphabet[(math.Random().nextDouble() * 64).floor() | 0];
  }
  return id;
}
