import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

class MvpTodayScreen extends StatelessWidget {
  const MvpTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(AppRoutes.today);
      }
    });
    return const SizedBox.shrink();
  }
}
