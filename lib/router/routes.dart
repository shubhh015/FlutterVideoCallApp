// 🐦 Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_video_call_app/screens/call_participants_list.dart';
import 'package:flutter_video_call_app/screens/call_screen.dart';
import 'package:flutter_video_call_app/screens/call_stats_screen.dart';
import 'package:flutter_video_call_app/screens/home_screen.dart';
import 'package:flutter_video_call_app/screens/lobby_screen.dart';
// 📦 Package imports:
import 'package:go_router/go_router.dart';
import 'package:stream_video/src/models/user_info.dart' as User;
import 'package:stream_video_flutter/stream_video_flutter.dart';

// 🌎 Project imports:

import '../screens/login_screen.dart';

part 'routes.g.dart';

@immutable
@TypedGoRoute<HomeRoute>(path: '/', name: 'home')
class HomeRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomeScreen();
  }
}

@immutable
@TypedGoRoute<LoginRoute>(path: '/login', name: 'login')
class LoginRoute extends GoRouteData {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

@immutable
@TypedGoRoute<LobbyRoute>(path: '/lobby', name: 'lobby')
class LobbyRoute extends GoRouteData {
  const LobbyRoute({required this.$extra, required this.user});

  final Call $extra;
  final User.UserInfo user;
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return LobbyScreen(
      call: $extra,
      onJoinCallPressed: (connectOptions) {
        // Navigate to the call screen.
        CallRoute(
          $extra: (
            call: $extra,
            connectOptions: connectOptions,
          ),
          user: user,
        ).replace(context);
      },
    );
  }
}

@immutable
@TypedGoRoute<CallRoute>(path: '/call', name: 'call')
class CallRoute extends GoRouteData {
  const CallRoute({required this.$extra, required this.user});

  final ({
    Call call,
    CallConnectOptions? connectOptions,
  }) $extra;
  final User.UserInfo user;
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CallScreen(
      call: $extra.call,
      user: user,
      connectOptions: $extra.connectOptions,
    );
  }
}

@immutable
@TypedGoRoute<CallParticipantsRoute>(
    path: '/call/participants', name: 'participants')
class CallParticipantsRoute extends GoRouteData {
  const CallParticipantsRoute({required this.$extra});

  final Call $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CallParticipantsList(
      call: $extra,
    );
  }
}

@immutable
@TypedGoRoute<CallStatsRoute>(path: '/call/stats', name: 'stats')
class CallStatsRoute extends GoRouteData {
  const CallStatsRoute({required this.$extra});

  final Call $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CallStatsScreen(
      call: $extra,
    );
  }
}
