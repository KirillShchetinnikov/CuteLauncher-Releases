import 'package:flauncher/widgets/action_notice.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/now_playing_service.dart';
import '../providers/settings_service.dart';

class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({super.key});
  @override Widget build(BuildContext context) {
    final service = context.watch<NowPlayingService?>();
    if (service == null || !context.watch<SettingsService>().showNowPlaying) return const SizedBox.shrink();
    if (!service.initialized && !service.failed) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final media = service.media;
    if (media == null && service.allowed && !service.failed) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.nowPlaying, style: Theme.of(context).textTheme.titleMedium),
          if (media != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(width: 64, height: 64, child: media.artwork == null
                ? const Icon(Icons.music_note, size: 40)
                : Image.memory(media.artwork!, cacheWidth: 128, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.music_note, size: 40))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(media.title.isEmpty ? media.packageName : media.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (media.artist.isNotEmpty) Text(media.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
              ])),
            ]),
            Wrap(spacing: 8, children: [
              if (media.canPause) TextButton.icon(onPressed: service.busy ? null : () => service.control('pause'),
                icon: const Icon(Icons.pause), label: Text(l.mediaPause)),
              if (media.canPlay) TextButton.icon(onPressed: service.busy ? null : () => service.control('play'),
                icon: const Icon(Icons.play_arrow), label: Text(l.mediaPlay)),
              if (media.canNext) TextButton.icon(onPressed: service.busy ? null : () => service.control('next'),
                icon: const Icon(Icons.skip_next), label: Text(l.mediaNext)),
            ]),
          ] else if (!service.allowed && !service.failed) ...[
            Text(l.nowPlayingAccessHint),
            TextButton(onPressed: () async {
              if (!await service.requestPermission() && context.mounted) {
                showActionNotice(context, l.nowPlayingAccessHint);
              }
            }, child: Text(l.notificationAccess)),
          ],
          if (service.failed) Text(l.mediaControlError),
        ],
      ))));
  }
}
