import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/church_finder_notifier.dart';
import '../../domain/models/church.dart';

/// Finds churches near the user. Requests location permission on first open,
/// then renders a list with distance. Tap a row → external OSM map launch.
///
/// Uses OpenStreetMap tiles (no API key). For a preview map above the list,
/// a small `flutter_map` card is rendered once a location is resolved.
class ChurchFinderScreen extends ConsumerStatefulWidget {
  const ChurchFinderScreen({super.key});

  @override
  ConsumerState<ChurchFinderScreen> createState() =>
      _ChurchFinderScreenState();
}

class _ChurchFinderScreenState extends ConsumerState<ChurchFinderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(churchFinderProvider.notifier).loadNearby();
    });
  }

  Future<void> _openInOsm(Church c) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${c.latitude}&mlon=${c.longitude}#map=17/${c.latitude}/${c.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(churchFinderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Churches nearby')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(churchFinderProvider.notifier).loadNearby(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (state.loading)
              const _LoadingBlock()
            else if (state.permissionDenied)
              _PermissionBlock(
                title: 'Location permission needed',
                body:
                    'To find churches near you, grant location access in your device settings.',
                action: 'Open settings',
                onTap: () => Geolocator.openAppSettings(),
              )
            else if (state.serviceDisabled)
              _PermissionBlock(
                title: 'Location services are off',
                body:
                    'Turn location on in your device settings so we can look nearby.',
                action: 'Open settings',
                onTap: () => Geolocator.openLocationSettings(),
              )
            else if (state.error != null)
              _ErrorBlock(
                message: state.error!,
                onRetry: () =>
                    ref.read(churchFinderProvider.notifier).loadNearby(),
              )
            else ...[
              if (state.lat != null && state.lng != null)
                _MiniMap(
                  lat: state.lat!,
                  lng: state.lng!,
                  churches: state.churches,
                ),
              const SizedBox(height: 16),
              if (state.churches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No churches within 10 km. Pull to refresh or widen your search later.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                ...state.churches.map(
                  (c) => _ChurchTile(
                    church: c,
                    onTap: () => _openInOsm(c),
                  ),
                ),
            ],
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({
    required this.lat,
    required this.lng,
    required this.churches,
  });

  final double lat;
  final double lng;
  final List<Church> churches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = LatLng(lat, lng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.elbiblio.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                for (final c in churches.take(20))
                  Marker(
                    point: LatLng(c.latitude, c.longitude),
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.church_rounded,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChurchTile extends StatelessWidget {
  const _ChurchTile({required this.church, required this.onTap});

  final Church church;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distance = church.distanceKm;
    final distanceLabel = distance == null
        ? '—'
        : distance < 1
            ? '${(distance * 1000).round()} m'
            : '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.church_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        church.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (church.address != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          church.address!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      distanceLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (church.denomination != null)
                      Text(
                        church.denomination!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PermissionBlock extends StatelessWidget {
  const _PermissionBlock({
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        children: [
          Icon(Icons.location_on_outlined,
              size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
