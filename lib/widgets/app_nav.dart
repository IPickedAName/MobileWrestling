import 'package:flutter/material.dart';

class AppNav {
  static Widget backButton(BuildContext context, {String fallbackRoute = '/home'}) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
      onPressed: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          Navigator.pushReplacementNamed(context, fallbackRoute);
        }
      },
    );
  }

  static Widget menuButton() {
    return Builder(
      builder: (context) => IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}
