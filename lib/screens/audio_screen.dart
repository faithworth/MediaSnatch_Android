import 'package:flutter/material.dart';
import '../services/downloader.dart';
import '../services/config.dart';
import 'download_mixin.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});
  @override State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> with DownloadMixin<AudioScreen> {
  @override String get downloadTitle => 'Download Audio';

  final _urlCtrl = TextEditingController();
  String _format = 'mp3_320';

  static const _formats = {
    'mp3_320': ('MP3 320 kbps', 'mp3',  '320K', Icons.music_note_rounded),
    'mp3_192': ('MP3 192 kbps', 'mp3',  '192K', Icons.music_note_rounded),
    'mp3_128': ('MP3 128 kbps', 'mp3',  '128K', Icons.music_note_rounded),
    'aac':     ('AAC — High quality', 'aac', '', Icons.surround_sound_rounded),
    'flac':    ('FLAC — Lossless',    'flac', '', Icons.high_quality_rounded),
    'wav':     ('WAV — Uncompressed', 'wav',  '', Icons.graphic_eq_rounded),
  };

  void _download() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste a URL first')));
      return;
    }
    final (_, ext, qual, _) = _formats[_format]!;
    final args = [
      '-x', '--audio-format', ext,
      '--embed-thumbnail',
      if (qual.isNotEmpty) ...['--audio-quality', qual],
      ...Downloader.baseArgs('%(title)s [%(id)s].%(ext)s'),
      url,
    ];
    startDownload(args);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Download Audio / MP3')),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _urlCtrl,
          decoration: const InputDecoration(
            labelText: 'Audio URL',
            hintText: 'https://youtube.com/watch?v=…',
            prefixIcon: Icon(Icons.link_rounded),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 24),
        Text('Format', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ..._formats.entries.map((e) {
          final (label, _, _, icon) = e.value;
          return RadioListTile<String>(
            value: e.key, groupValue: _format,
            title: Row(children: [Icon(icon, size: 16, color: cs.secondary), const SizedBox(width: 8), Text(label)]),
            dense: true, activeColor: cs.secondary,
            onChanged: (v) => setState(() => _format = v!),
          );
        }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF30363D))),
          child: Row(children: [
            Icon(Icons.folder_rounded, size: 14, color: cs.primary), const SizedBox(width: 8),
            Expanded(child: Text(AppConfig.instance.outDir, style: TextStyle(fontSize: 11, color: cs.primary), overflow: TextOverflow.ellipsis)),
          ]),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _download, icon: const Icon(Icons.download_rounded), label: const Text('Extract Audio')),
      ]),
    );
  }
}
