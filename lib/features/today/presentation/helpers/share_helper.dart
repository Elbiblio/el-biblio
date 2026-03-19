import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';

import '../widgets/store_fallback_dialog.dart';

const _shareText =
    'Check out Elbiblio - a personal spiritual operating system to help you '
    'grow in virtue and faith!\n\nDownload it and start your journey today.';

const _shareSubject = 'Elbiblio - Grow in your spiritual journey';

/// Shares the app via the native contact-sync invite flow (authenticated
/// users) or falls back to the platform share sheet for guests.
Future<void> shareWithContacts(
  BuildContext context, {
  required bool isAuthenticated,
  required bool isGuest,
}) async {
  Navigator.of(context).pop();

  if (!isAuthenticated || isGuest) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Create a full account to sync contacts. Sharing app link instead.'),
        ),
      );
    }

    await Share.share(_shareText, subject: _shareSubject);
    return;
  }

  if (context.mounted) {
    context.push('/invite');
  }
}

/// Shares a plain-text app link via the platform share sheet.
Future<void> shareAppUrl(BuildContext context) async {
  try {
    await Share.share(_shareText, subject: _shareSubject);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share app')),
      );
    }
  }

  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}

/// Opens the appropriate app-store review page for the current platform,
/// falling back to elbiblio.com if the store cannot be launched.
Future<void> openStoreReview(BuildContext context) async {
  final theme = Theme.of(context);
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  final appId = packageInfo.packageName;
  const fallbackUrl = 'https://elbiblio.com';

  Uri storeUrl;
  String platform = 'website';

  try {
    if (theme.platform == TargetPlatform.iOS) {
      storeUrl =
          Uri.parse('https://apps.apple.com/app/id123456789?action=write-review');
      platform = 'App Store';
    } else if (theme.platform == TargetPlatform.android) {
      storeUrl =
          Uri.parse('https://play.google.com/store/apps/details?id=$appId');
      platform = 'Google Play Store';
    } else {
      storeUrl = Uri.parse(fallbackUrl);
      platform = 'website';
    }

    if (await canLaunchUrl(storeUrl)) {
      await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        StoreFallbackDialog.show(context, url: fallbackUrl, platform: platform);
      }
    }
  } catch (e) {
    if (context.mounted) {
      StoreFallbackDialog.show(context, url: fallbackUrl, platform: platform);
    }
  }

  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }
}
