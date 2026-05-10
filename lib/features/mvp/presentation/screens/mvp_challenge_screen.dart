import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

class MvpChallengeScreen extends StatelessWidget {
  const MvpChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(AppRoutes.commit);
      }
    });
    return const SizedBox.shrink();
  }
}
