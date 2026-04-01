import 'package:flutter/material.dart';

/// Global key so auth/session code can redirect without a [BuildContext].
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
