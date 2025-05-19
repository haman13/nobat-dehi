import 'package:flutter/material.dart';

class CustomPageTransition extends PageRouteBuilder {
  final Widget page;
  final RouteSettings settings;
  final bool isProfile;

  CustomPageTransition({
    required this.page,
    required this.settings,
    this.isProfile = false,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (isProfile) {
      // انیمیشن برای صفحه پروفایل
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    } else {
      // انیمیشن برای سایر صفحات
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        ),
      );
    }
  }
} 