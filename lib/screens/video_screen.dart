import 'package:flutter/material.dart';
import '../services/downloader.dart';
import '../services/config.dart';
import '../widgets/download_terminal.dart';
import 'download_mixin.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> with DownloadMixin<VideoScreen> {
  @override String get downloadTitle => 'Download Video';

  final _urlCtrl = TextEditingController();
  String _quality = 'best';
  bool _fetchingTitle = false;
  String? _videoTitle;

  static const _qualities = {
    'best':   ('Best Available',    'bestvideo+bestaudio/best'),
    '4k':     ('4K / 2160p',        'bestvideo[height<=2160]+bestaudio/best[height<=2160]'),
    '1440p':  ('1440p',             'bestvideo[height<=1440]+bestaudio/best[height<=1440]'),
    '1080p':  ('1080p Full HD',     'bestvideo[height<=1080]+bestaudio/best[height<=1080]'),
    '720p':   ('720p HD',           'bestvideo[height<=720]+bestaudio/best[height<=720]'),
    '480p':   ('480p',              'bestvideo[height<=480]+bestaudio/best[height<=480]'),
    '360p':   ('360p (smallest)',   'bestvideo[height<=360]+bestaudio/best[height<=360]'),
  };

  Future<void> _fetchTitle() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _fetchingTitle = true; _videoTitle = null; });
    final title = await Downloader.getValue(url, '--get-title');
    if (mounted) setState(() { _fetchingTitle = false; _videoTitle = title; });
  }

  void _download() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste a URL first')));
      return;
    }
    final fmt = _qualities[_quality]!.$2;
    final args = [
      '-f', fmt,
      '--merge-output-format', 'mp4',
      '--remux-video', 'mp4',
      '--embed-chapters',
      '--concurrent-fragments', '4',
      ...Downloader.baseArgs('%(title)s [%(id)s].%(ext)s'),
      url,
    ];
    startDownload(args);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Video'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isDownloading || isDone
              ? buildTerminalPanel()
              : _buildForm(cs),
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Supported sites chip row
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in ['YouTube', 'TikTok', 'Instagram', 'Facebook', 'Twitter/X', 'Reddit', 'Vimeo', '1000+ more'])
              Chip(label: Text(s, style: const TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 20),

          // URL input
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: 'Video URL',
              hintText: 'https://youtube.com/watch?v=…',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: _fetchingTitle
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(icon: const Icon(Icons.info_outline_rounded), onPressed: _fetchTitle, tooltip: 'Fetch title'),
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _fetchTitle(),
          ),

          if (_videoTitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.tertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.tertiary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, color: cs.tertiary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_videoTitle!, style: const TextStyle(fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // Quality
          Text('Quality', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ..._qualities.entries.map((e) => RadioListTile<String>(
            value: e.key,
            groupValue: _quality,
            title: Text(e.value.$1),
            dense: true,
            activeColor: cs.primary,
            onChanged: (v) => setState(() => _quality = v!),
          )),

          const SizedBox(height: 24),

          // Output folder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(children: [
              Icon(Icons.folder_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(AppConfig.instance.outDir,
                style: TextStyle(fontSize: 11, color: cs.primary),
                overflow: TextOverflow.ellipsis)),
            ]),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Start Download'),
          ),
        ],
      ),
    );
  }
}
