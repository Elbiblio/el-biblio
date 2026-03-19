import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../today/presentation/helpers/share_helper.dart' as share_helper;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _androidPackageName = 'com.elbiblio.app';
  static const String? _iosAppId = null;
  static const String? _donateUrl = null;

  Future<PackageInfo> _loadPackageInfo() => PackageInfo.fromPlatform();

  Future<void> _openStore(BuildContext context) async {
    await share_helper.openStoreReview(context);
  }

  Future<void> _openDonate(BuildContext context) async {
    const rawUrl = _donateUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donate link not configured yet.')),
      );
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid donate link.')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open donate link.')),
      );
    }
  }

  Future<void> _openStoreListingFallback(BuildContext context) async {
    Uri? uri;

    if (Platform.isAndroid) {
      uri = Uri.parse('https://play.google.com/store/apps/details?id=$_androidPackageName');
    } else if (Platform.isIOS) {
      const appId = _iosAppId;
      if (appId != null && appId.trim().isNotEmpty) {
        uri = Uri.parse('https://apps.apple.com/app/id$appId');
      }
    }

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store link not available for this platform.')),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open store listing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.palette.border),
            ),
            child: FutureBuilder<PackageInfo>(
              future: _loadPackageInfo(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final versionLabel = info == null
                    ? '—'
                    : '${info.version} (${info.buildNumber})';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EL BIBLIO',
                      style: theme.textTheme.sectionHeader.copyWith(
                        color: tokens.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version $versionLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A personal spiritual operating system built for daily rhythm and clarity.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.palette.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_rate_rounded),
                  title: const Text('Rate the app'),
                  subtitle: const Text('Help others discover El Biblio'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await _openStore(context);
                  },
                ),
                Divider(height: 1, color: tokens.palette.border),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism_rounded),
                  title: const Text('Donate'),
                  subtitle: const Text('Support development and ongoing improvements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await _openDonate(context);
                  },
                ),
                Divider(height: 1, color: tokens.palette.border),
                ListTile(
                  leading: const Icon(Icons.storefront_rounded),
                  title: const Text('Open store listing'),
                  subtitle: const Text('If rating doesn\'t open on your device'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await _openStoreListingFallback(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
