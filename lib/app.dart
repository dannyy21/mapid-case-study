import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/map/map_screen.dart';

class MapidApp extends StatelessWidget {
  const MapidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAPID Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MapScreen(),
    );
  }
}
