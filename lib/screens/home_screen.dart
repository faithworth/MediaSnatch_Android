import 'package:flutter/material.dart';
import '../services/config.dart';
import '../services/installer.dart';
import '../widgets/download_terminal.dart';
import 'video_screen.dart';
import 'audio_screen.dart';
import 'other_screens.dart';   // contains all other screens

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checking = true;
  final List<TerminalLine> _setupLines = [];

  @override
  void initState() {
    super.initState();
    _runSetup();
  }

  Future<void> _runSetup() async {
    await Installer.ensureTools((msg, progress) {
      if (mounted) setState(() => _setupLines.add(TerminalLine(msg)));
    });
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final cfg = AppConfig.instance;

    if (_checking) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 32),
              _Header(),
              const SizedBox(height: 32),
              Text('Checking tools…', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Expanded(child: DownloadTerminal(lines: _setupLines, isRunning: true)),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), child: _Header())),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: _ToolStatus())),
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: _DestinationBar(cfg.outDir))),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                _MenuCard(icon: Icons.videocam_rounded,         label: 'Download Video',     sub: 'YouTube, TikTok, Instagram…',    color: cs.primary,                    onTap: () => _go(const VideoScreen())),
                _MenuCard(icon: Icons.audiotrack_rounded,       label: 'Download Audio',     sub: 'MP3, FLAC, AAC, WAV',            color: cs.secondary,                  onTap: () => _go(const AudioScreen())),
                _MenuCard(icon: Icons.queue_music_rounded,      label: 'Playlist / Channel', sub: 'Full playlists & channels',      color: const Color(0xFFD29922),        onTap: () => _go(const PlaylistScreen())),
                _MenuCard(icon: Icons.format_list_bulleted_rounded, label: 'Batch Download', sub: 'Multiple URLs at once',          color: const Color(0xFF8B5CF6),        onTap: () => _go(const BatchScreen())),
                _MenuCard(icon: Icons.content_cut_rounded,      label: 'Clip / Trim',        sub: 'Download by time range',         color: const Color(0xFFEC4899),        onTap: () => _go(const ClipScreen())),
                _MenuCard(icon: Icons.stream_rounded,           label: 'Streaming Video',    sub: 'Anime, free streaming',          color: const Color(0xFFF97316),        onTap: () => _go(const StreamScreen())),
                _MenuCard(icon: Icons.tv_rounded,               label: 'Full Series',        sub: 'All seasons S01E01 naming',      color: const Color(0xFFF97316), badge: 'NEW', onTap: () => _go(const FullSeriesScreen())),
                _MenuCard(icon: Icons.settings_rounded,         label: 'Settings',           sub: 'Output folder, speed…',         color: const Color(0xFF8B949E),        onTap: () => _go(const SettingsScreen())),
                _MenuCard(icon: Icons.build_rounded,            label: 'Tools / Update',     sub: 'yt-dlp, FFmpeg status',          color: const Color(0xFF3FB950),        onTap: () => _go(const ToolsScreen())),
                _MenuCard(icon: Icons.folder_open_rounded,      label: 'Open Downloads',     sub: cfg.outDir.split('/').last,       color: cs.primary,                    onTap: _openFolder),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }

  void _go(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _openFolder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloads folder: ${AppConfig.instance.outDir}')),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.download_rounded, color: cs.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MediaSnatch', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary)),
          Text('v4.0 · Universal Media Downloader', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
      ]),
      const SizedBox(height: 6),
      Text('YouTube · TikTok · Instagram · Facebook · Twitter/X · 1000+ sites',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
    ]);
  }
}

// ── Tool status ───────────────────────────────────────────────────────────────
class _ToolStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cfg = AppConfig.instance;
    final cs  = Theme.of(context).colorScheme;
    Widget chip(String label, bool ok) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ok ? cs.tertiary.withOpacity(0.12) : cs.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ok ? cs.tertiary.withOpacity(0.4) : cs.error.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, size: 12, color: ok ? cs.tertiary : cs.error),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: ok ? cs.tertiary : cs.error, fontWeight: FontWeight.w600)),
      ]),
    );
    return Row(children: [chip('yt-dlp', cfg.ytDlpInstalled), const SizedBox(width: 8), chip('FFmpeg', cfg.ffmpegInstalled)]);
  }
}

// ── Destination bar ───────────────────────────────────────────────────────────
class _DestinationBar extends StatelessWidget {
  final String path;
  const _DestinationBar(this.path);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF30363D))),
      child: Row(children: [
        Icon(Icons.folder_rounded, size: 14, color: cs.primary), const SizedBox(width: 8),
        Text('Saves to: ', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        Expanded(child: Text(path, style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final String? badge;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.label, required this.sub, required this.color, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
              if (badge != null) ...[const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge!, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)))],
            ]),
            const Spacer(),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
