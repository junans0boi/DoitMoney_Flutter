// lib/core/navigation/navigation_service.dart
import 'package:flutter/widgets.dart';

/// 전역 NavigatorKey
/// MaterialApp.router 사용 시 navigatorKey: navigationService.navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
