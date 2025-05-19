import 'package:flutter/material.dart';

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final RouteSettings settings;
  final bool isSlide;

  CustomPageRoute({
    required this.page,
    required this.settings,
    this.isSlide = true,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (isSlide) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    } else {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    }
  }
} 