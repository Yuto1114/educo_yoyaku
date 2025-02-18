import 'package:educo_yoyaku/auth_service.dart';
import 'package:educo_yoyaku/widgets/navibar.dart';
import 'package:educo_yoyaku/screens/login_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

final authService = AuthService();
final router = GoRouter(
  redirect: (BuildContext context, GoRouterState state) async {
    bool isLoggedIn = await authService.isLoggedIn();
    final isGoingToSignIn = state.uri.toString() == '/login';

    if (!isLoggedIn && !isGoingToSignIn) {
      return '/login';
    } else if (isLoggedIn && state.uri.toString() == '/login') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Navibar(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
  ],
);
