// 🎯 Dart imports:
import 'dart:async';

// 🐦 Flutter imports:
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_call_app/core/repos/app_preferences.dart';
import 'package:flutter_video_call_app/router/routes.dart';
import 'package:flutter_video_call_app/theme/app_palette.dart';
import 'package:flutter_video_call_app/widgets/environment_switcher.dart';
import 'package:flutter_video_call_app/widgets/stream_button.dart';
// 🌎 Project imports:

// 📦 Package imports:
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'package:stream_video_flutter/stream_video_flutter_background.dart';

import '../app/user_auth_controller.dart';
import '../di/injector.dart';
import '../utils/consts.dart';
import '../utils/loading_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _streamVideo = locator.get<StreamVideo>();
  late final _appPreferences = locator.get<AppPreferences>();
  late final _userAuthController = locator.get<UserAuthController>();
  late final _callIdController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance
      .reference()
      .child('users'); // Firebase users reference

  var _users = [];
  Call? _call;

  @override
  void initState() {
    StreamBackgroundService.init(
      StreamVideo.instance,
      onButtonClick: (call, type, serviceType) async {
        switch (serviceType) {
          case ServiceType.call:
            call.end();
          case ServiceType.screenSharing:
            StreamVideoFlutterBackground.stopService(ServiceType.screenSharing);
            call.setScreenShareEnabled(enabled: false);
        }
      },
    );
    super.initState();
    _fetchUsers();
    //print("values $_users");
  }

  Future<void> _fetchUsers() async {
    try {
      _usersRef.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;

        List<UserInfo> users = [];
        if (data != null) {
          var entries = (data as Map<dynamic, dynamic>)
              .values; // Cast as Map and get values
          for (var obj in entries) {
            // Now obj is each value in the Map
            UserInfo user = UserInfo(
              image: obj['image'],
              role: obj['role'],
              name: obj['name'],
              id: obj['id'],
            );
            users.add(user);
          }
        }
        setState(() {
          _users = users;
        });
      });
    } catch (error) {
      print('Error fetching users: $error');
    }
  }

  Future<void> _getOrCreateCall(UserInfo user,
      {required List<String> memberIds}) async {
    var callId = _callIdController.text;
    if (callId.isEmpty) callId = generateAlphanumericString(12);

    unawaited(showLoadingIndicator(context));
    _call = _streamVideo.makeCall(callType: kCallType, id: callId);

    bool isRinging = memberIds.isNotEmpty;

    try {
      await _call!.getOrCreate(
        memberIds: memberIds,
        ringing: isRinging,
      );
    } catch (e, stk) {
      debugPrint('Error joining or creating call: $e');
      debugPrint(stk.toString());
    }

    if (mounted) {
      hideLoadingIndicator(context);

      if (isRinging) {
        CallRoute($extra: (
          call: _call!,
          connectOptions: null,
        ), user: user)
            .push(context);
      } else {
        LobbyRoute($extra: _call!, user: user).push(context);
      }
    }
  }

  Future<void> _startDirectCall(UserInfo user) async {
    // Start a direct call with the selected user
    // Implement your logic to start a call here
    print('Starting direct call with ${user?.name}');
    _getOrCreateCall(memberIds: [user.id], user);
  }

  @override
  void dispose() {
    _callIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _userAuthController.currentUser;
    assert(currentUser != null, 'User must be logged in to access home screen');

    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final name = currentUser!.name;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: StreamUserAvatar(user: currentUser),
        ),
        titleSpacing: 4,
        centerTitle: false,
        title: Text(
          name,
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: EnvironmentBanner(
                    currentEnvironment: _appPreferences.environment),
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                // ignore: avoid_print
                onPressed: () => _userAuthController.logout,
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          print("userfirsy $user");
          return ListTile(
            title: Text(user?.name ?? ""),
            onTap: () =>
                _startDirectCall(user), // Start call when user is tapped
          );
        },
      ),
    );
  }
}

class _JoinForm extends StatelessWidget {
  const _JoinForm({
    required this.callIdController,
    required this.onJoinPressed,
  });

  final TextEditingController callIdController;
  final VoidCallback onJoinPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Flexible(
              child: TextField(
                controller: callIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColorPalette.secondaryText,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(36)),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(36)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                  hintText: 'Enter call id',
                  // suffix button to generate a random call id
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // generate a 10 character nanoId for call id
                      final callId = generateAlphanumericString(10);
                      callIdController.value = TextEditingValue(
                        text: callId,
                        selection: TextSelection.collapsed(
                          offset: callId.length,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ValueListenableBuilder(
              valueListenable: callIdController,
              builder: (context, value, __) {
                final hasText = value.text.isNotEmpty;
                return StreamButton.active(
                    label: 'Join call',
                    icon: const Icon(Icons.login, color: Colors.white),
                    onPressed: hasText ? onJoinPressed : () {});
              },
            ),
          ],
        ),
      ],
    );
  }
}
