// ════════════════════════════════════════════════════════════════════════════════
//  PLAYLIST SCREEN  —  maps MenuPlaylist.Show()
// ════════════════════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/downloader.dart';
import '../services/config.dart';
import '../services/installer.dart';
import '../widgets/download_terminal.dart';
import 'download_mixin.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});
  @override State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> with DownloadMixin<PlaylistScreen> {
  @override String get downloadTitle => 'Playlist / Channel';
  final _urlCtrl   = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  String _type = 'video_best';

  void _download() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste a URL first'))); return; }
    final cfg = AppConfig.instance;
    final tpl = '${cfg.outDir}/%(playlist_title)s/%(playlist_index)s - %(title)s [%(id)s].%(ext)s';
    final base = ['--ffmpeg-location', cfg.binDir, '--output', tpl, '--progress', '--no-warnings',
      '--add-metadata', '--retry-sleep', '3', '--fragment-retries', '10', '--retries', '10',
      '--continue', '--no-part', '--no-overwrites', '--concurrent-fragments', '4',
      if (_startCtrl.text.trim().isNotEmpty) ...['--playlist-start', _startCtrl.text.trim()],
      if (_endCtrl.text.trim().isNotEmpty)   ...['--playlist-end',   _endCtrl.text.trim()],
    ];
    final fmt = switch(_type) {
      'video_best' => ['-f','bestvideo+bestaudio/best','--merge-output-format','mp4','--embed-chapters'],
      'video_1080' => ['-f','bestvideo[height<=1080]+bestaudio/best[height<=1080]','--merge-output-format','mp4'],
      'audio_mp3'  => ['-x','--audio-format','mp3','--audio-quality','320K','--embed-thumbnail'],
      _            => ['-f','bestvideo+bestaudio/best','--merge-output-format','mp4'],
    };
    startDownload([...fmt, ...base, url]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist / Channel')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: isDownloading || isDone ? buildTerminalPanel() : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Playlist / Channel URL', prefixIcon: Icon(Icons.link_rounded)), keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _startCtrl, decoration: const InputDecoration(labelText: 'Start item #', hintText: '(optional)'), keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _endCtrl, decoration: const InputDecoration(labelText: 'End item #', hintText: '(optional)'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          Text('Type', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final e in {'video_best': 'Video — Best quality', 'video_1080': 'Video — 1080p max', 'audio_mp3': 'Audio — MP3 320kbps'}.entries)
            RadioListTile<String>(value: e.key, groupValue: _type, title: Text(e.value), dense: true, activeColor: cs.primary, onChanged: (v) => setState(() => _type = v!)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _download, icon: const Icon(Icons.download_rounded), label: const Text('Download Playlist')),
        ])))),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  BATCH SCREEN  —  maps MenuBatch.Show()
// ════════════════════════════════════════════════════════════════════════════════
class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});
  @override State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> with DownloadMixin<BatchScreen> {
  @override String get downloadTitle => 'Batch Download';
  final _urlsCtrl = TextEditingController();
  String _mode = 'video';

  void _download() {
    final raw = _urlsCtrl.text.trim();
    if (raw.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter at least one URL'))); return; }
    final urls = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final fmt = _mode == 'video'
        ? ['-f', 'bestvideo+bestaudio/best', '--merge-output-format', 'mp4']
        : ['-x', '--audio-format', 'mp3', '--audio-quality', '320K', '--embed-thumbnail'];
    final args = [...fmt, ...Downloader.baseArgs('%(title)s [%(id)s].%(ext)s'), ...urls];
    startDownload(args);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Download')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: isDownloading || isDone ? buildTerminalPanel() : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('One URL per line', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Expanded(child: TextField(controller: _urlsCtrl, maxLines: null, expands: true,
            decoration: const InputDecoration(hintText: 'https://youtube.com/…\nhttps://tiktok.com/…\nhttps://instagram.com/…', alignLabelWithHint: true),
            keyboardType: TextInputType.multiline)),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.videocam_rounded)),
              ButtonSegment(value: 'audio', label: Text('Audio MP3'), icon: Icon(Icons.audiotrack_rounded))],
            selected: {_mode}, onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _download, icon: const Icon(Icons.download_rounded), label: const Text('Start Batch Download')),
        ]))),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  CLIP SCREEN  —  maps MenuClip.Show()
// ════════════════════════════════════════════════════════════════════════════════
class ClipScreen extends StatefulWidget {
  const ClipScreen({super.key});
  @override State<ClipScreen> createState() => _ClipScreenState();
}

class _ClipScreenState extends State<ClipScreen> with DownloadMixin<ClipScreen> {
  @override String get downloadTitle => 'Clip / Trim';
  final _urlCtrl   = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();
  String _format = 'video';

  void _download() {
    final url   = _urlCtrl.text.trim();
    final start = _startCtrl.text.trim();
    final end   = _endCtrl.text.trim();
    if (url.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste a URL first'))); return; }
    final range = [if (start.isNotEmpty || end.isNotEmpty) '--download-sections',
      if (start.isNotEmpty || end.isNotEmpty) '*${start.isNotEmpty ? start : '0'}:${end.isNotEmpty ? end : 'inf'}'];
    final fmt = _format == 'video'
        ? ['-f', 'bestvideo+bestaudio/best', '--merge-output-format', 'mp4']
        : ['-x', '--audio-format', 'mp3', '--audio-quality', '320K'];
    final args = [...fmt, ...range, '--force-keyframes-at-cuts',
      ...Downloader.baseArgs('%(title)s [%(id)s] clip.%(ext)s'), url];
    startDownload(args);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Clip / Trim Video')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: isDownloading || isDone ? buildTerminalPanel() : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Video URL', prefixIcon: Icon(Icons.link_rounded)), keyboardType: TextInputType.url),
          const SizedBox(height: 16),
          Text('Time Range  (leave blank to download full video)', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _startCtrl, decoration: const InputDecoration(labelText: 'Start time', hintText: '00:01:30'), keyboardType: TextInputType.text)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _endCtrl, decoration: const InputDecoration(labelText: 'End time', hintText: '00:02:45'), keyboardType: TextInputType.text)),
          ]),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'video', label: Text('Video'), icon: Icon(Icons.videocam_rounded)),
              ButtonSegment(value: 'audio', label: Text('Audio'), icon: Icon(Icons.audiotrack_rounded))],
            selected: {_format}, onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _download, icon: const Icon(Icons.content_cut_rounded), label: const Text('Clip & Download')),
        ])))),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  STREAM SCREEN  —  maps MenuStream.Show()
// ════════════════════════════════════════════════════════════════════════════════
class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});
  @override State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> with DownloadMixin<StreamScreen> {
  @override String get downloadTitle => 'Streaming Video';
  final _urlCtrl = TextEditingController();
  String _quality = 'best';

  void _download() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste a URL first'))); return; }
    final fmt = switch(_quality) {
      '1080p' => 'bestvideo[height<=1080]+bestaudio/best[height<=1080]',
      '720p'  => 'bestvideo[height<=720]+bestaudio/best[height<=720]',
      '480p'  => 'bestvideo[height<=480]+bestaudio/best[height<=480]',
      _       => 'bestvideo+bestaudio/best',
    };
    final args = ['-f', fmt, '--merge-output-format', 'mp4',
      ...Downloader.streamArgs(), ...Downloader.baseArgs('%(title)s [%(id)s].%(ext)s'), url];
    startDownload(args);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Streaming Video')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: isDownloading || isDone ? buildTerminalPanel() : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF97316).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFF97316).withOpacity(0.3))),
            child: const Row(children: [Icon(Icons.info_outline_rounded, color: Color(0xFFF97316), size: 16), SizedBox(width: 8), Expanded(child: Text('Works with AniWatch, HiAnime, Gogoanime, Tubi, Pluto TV, m3u8 streams', style: TextStyle(fontSize: 12)))])),
          const SizedBox(height: 16),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Stream URL or Episode URL', prefixIcon: Icon(Icons.link_rounded)), keyboardType: TextInputType.url),
          const SizedBox(height: 20),
          Text('Quality', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final e in {'best': 'Best available', '1080p': '1080p', '720p': '720p', '480p': '480p'}.entries)
            RadioListTile<String>(value: e.key, groupValue: _quality, title: Text(e.value), dense: true, activeColor: cs.primary, onChanged: (v) => setState(() => _quality = v!)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _download, icon: const Icon(Icons.stream_rounded), label: const Text('Download Stream')),
        ])))),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  FULL SERIES SCREEN  —  maps MenuFullSeries.Show()
// ════════════════════════════════════════════════════════════════════════════════
class FullSeriesScreen extends StatefulWidget {
  const FullSeriesScreen({super.key});
  @override State<FullSeriesScreen> createState() => _FullSeriesScreenState();
}

class _FullSeriesScreenState extends State<FullSeriesScreen> with DownloadMixin<FullSeriesScreen> {
  @override String get downloadTitle => 'Full Series';
  final _urlCtrl      = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _seasonCtrl   = TextEditingController();
  String _format = 'best';
  String _audioLang = 'any';

  void _download() {
    final url  = _urlCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (url.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL and Show Name are required')));
      return;
    }
    final cfg  = AppConfig.instance;
    final season = _seasonCtrl.text.trim().isNotEmpty ? _seasonCtrl.text.trim().padLeft(2, '0') : null;
    final tpl  = '${cfg.outDir}/$name/${season != null ? 'Season $season' : '%(season_number|1)s'}/%(title)s.%(ext)s';
    final fmt  = switch(_format) {
      '1080p' => ['-f','bestvideo[height<=1080]+bestaudio/best[height<=1080]','--merge-output-format','mp4'],
      '720p'  => ['-f','bestvideo[height<=720]+bestaudio/best[height<=720]','--merge-output-format','mp4'],
      'audio' => ['-x','--audio-format','mp3','--audio-quality','320K'],
      _       => ['-f','bestvideo+bestaudio/best','--merge-output-format','mp4'],
    };
    final langArgs = _audioLang != 'any' ? ['--audio-multistreams', '--audio-language', _audioLang] : <String>[];
    final args = [...fmt, ...langArgs,
      '--ffmpeg-location', cfg.binDir, '--output', tpl, '--progress', '--no-warnings',
      '--add-metadata', '--retry-sleep', '3', '--fragment-retries', '10', '--retries', '10',
      '--continue', '--no-part', '--no-overwrites', ...Downloader.streamArgs(), url];
    startDownload(args);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Download Full Series')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: isDownloading || isDone ? buildTerminalPanel() : SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Show / Series URL', prefixIcon: Icon(Icons.link_rounded)), keyboardType: TextInputType.url),
          const SizedBox(height: 12),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Show Name (used for folder)', hintText: 'e.g. Attack on Titan', prefixIcon: Icon(Icons.tv_rounded))),
          const SizedBox(height: 12),
          TextField(controller: _seasonCtrl, decoration: const InputDecoration(labelText: 'Force season number (optional)', hintText: 'e.g. 1', prefixIcon: Icon(Icons.calendar_today_rounded)), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          Text('Format', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final e in {'best': 'Best quality', '1080p': '1080p', '720p': '720p', 'audio': 'Audio only'}.entries)
            RadioListTile<String>(value: e.key, groupValue: _format, title: Text(e.value), dense: true, activeColor: cs.primary, onChanged: (v) => setState(() => _format = v!)),
          const SizedBox(height: 12),
          Text('Audio language preference', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final e in {'any': 'Any (default)', 'ja': 'Japanese (original)', 'en': 'English dub', 'pt': 'Portuguese', 'es': 'Spanish'}.entries)
            RadioListTile<String>(value: e.key, groupValue: _audioLang, title: Text(e.value), dense: true, activeColor: cs.primary, onChanged: (v) => setState(() => _audioLang = v!)),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: _download, icon: const Icon(Icons.tv_rounded), label: const Text('Download Full Series')),
        ])))),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  SETTINGS SCREEN  —  maps MenuSettings + MenuAdvanced
// ════════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _outDirCtrl  = TextEditingController();
  final _speedCtrl   = TextEditingController();
  late  AppConfig    cfg;

  @override
  void initState() {
    super.initState();
    cfg = AppConfig.instance;
    _outDirCtrl.text = cfg.outDir;
    _speedCtrl.text  = cfg.speed;
  }

  void _save() {
    cfg.outDir = _outDirCtrl.text.trim().isNotEmpty ? _outDirCtrl.text.trim() : cfg.outDir;
    cfg.speed  = _speedCtrl.text.trim();
    try { Directory(cfg.outDir).createSync(recursive: true); } catch (_) {}
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved ✓')));
  }

  void _reset() {
    cfg.outDir = '/storage/emulated/0/Download/MediaSnatch';
    _outDirCtrl.text = cfg.outDir;
    cfg.speed = '';
    _speedCtrl.text = '';
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset to defaults')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Output folder
        _SectionHeader('Download Location'),
        TextField(controller: _outDirCtrl, decoration: const InputDecoration(labelText: 'Output folder', prefixIcon: Icon(Icons.folder_rounded))),
        const SizedBox(height: 8),
        Text('Tip: Use /storage/emulated/0/Download/MediaSnatch for the Downloads folder', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),

        // Advanced toggles
        _SectionHeader('Advanced'),
        SwitchListTile(value: cfg.subs, title: const Text('Auto-download subtitles'), subtitle: const Text('Downloads .srt for each video'), activeColor: cs.primary,
          onChanged: (v) { cfg.subs = v; setState(() {}); }),
        SwitchListTile(value: cfg.thumb, title: const Text('Embed thumbnail'), subtitle: const Text('Embed cover art in file'), activeColor: cs.primary,
          onChanged: (v) { cfg.thumb = v; setState(() {}); }),
        const SizedBox(height: 16),
        TextField(controller: _speedCtrl, decoration: const InputDecoration(labelText: 'Speed limit', hintText: 'e.g. 2M, 500K  (blank = unlimited)', prefixIcon: Icon(Icons.speed_rounded))),
        const SizedBox(height: 24),

        // Buttons
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _reset, child: const Text('Reset Defaults'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save Settings'))),
        ]),
        const SizedBox(height: 24),

        // Log viewer
        _SectionHeader('Log'),
        OutlinedButton.icon(
          icon: const Icon(Icons.article_outlined),
          label: const Text('View Log'),
          onPressed: () => showDialog(context: context, builder: (_) => _LogDialog()),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Clear Log'),
          style: OutlinedButton.styleFrom(foregroundColor: cs.error),
          onPressed: () {
            try { File(cfg.logFile).deleteSync(); } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log cleared')));
          },
        ),
      ])),
    );
  }
}

class _LogDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cfg = AppConfig.instance;
    String log = '';
    try { log = File(cfg.logFile).readAsStringSync(); } catch (_) { log = '(no log yet)'; }
    return AlertDialog(
      title: const Text('Log'),
      content: SizedBox(width: double.maxFinite, height: 400,
        child: SingleChildScrollView(child: Text(log, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
//  TOOLS SCREEN  —  maps MenuTools.Show()
// ════════════════════════════════════════════════════════════════════════════════
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});
  @override State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String? _ytDlpVersion;
  bool    _loading = false;
  final List<TerminalLine> _logLines = [];

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await Installer.getYtDlpVersion();
    if (mounted) setState(() => _ytDlpVersion = v);
  }

  Future<void> _installYtDlp() async {
    setState(() { _loading = true; _logLines.clear(); });
    await Installer.installYtDlp((msg, _) {
      if (mounted) setState(() => _logLines.add(TerminalLine(msg)));
    });
    await _loadVersion();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _installFfmpeg() async {
    setState(() { _loading = true; _logLines.clear(); });
    await Installer.installFfmpeg((msg, _) {
      if (mounted) setState(() => _logLines.add(TerminalLine(msg)));
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateYtDlp() async {
    setState(() { _loading = true; _logLines.clear(); });
    final out = await Installer.updateYtDlp((msg, _) {
      if (mounted) setState(() => _logLines.add(TerminalLine(msg)));
    });
    await _loadVersion();
    if (mounted) setState(() { _loading = false; _logLines.add(TerminalLine(out)); });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = AppConfig.instance;
    final cs  = Theme.of(context).colorScheme;

    Widget statusRow(String name, bool ok, String? version) => ListTile(
      leading: Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: ok ? cs.tertiary : cs.error),
      title: Text(name),
      subtitle: Text(ok ? (version != null ? 'v$version' : 'Installed') : 'NOT INSTALLED', style: TextStyle(color: ok ? cs.tertiary : cs.error)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Tools / Update')),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(child: Column(children: [
            statusRow('yt-dlp',  cfg.ytDlpInstalled,  _ytDlpVersion),
            const Divider(height: 1),
            statusRow('FFmpeg',  cfg.ffmpegInstalled, null),
            const Divider(height: 1),
            statusRow('FFprobe', File(cfg.ffprobePath).existsSync(), null),
          ])),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton.icon(onPressed: _loading ? null : _installYtDlp, icon: const Icon(Icons.download_rounded), label: const Text('Install yt-dlp')),
            ElevatedButton.icon(onPressed: _loading ? null : _installFfmpeg, icon: const Icon(Icons.download_rounded), label: const Text('Install FFmpeg')),
            OutlinedButton.icon(onPressed: _loading ? null : _updateYtDlp, icon: const Icon(Icons.update_rounded), label: const Text('Update yt-dlp')),
          ]),
          const SizedBox(height: 16),
          if (_loading || _logLines.isNotEmpty)
            Expanded(child: DownloadTerminal(lines: _logLines, isRunning: _loading)),
        ]))),
    );
  }
}
