import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'config.dart';

typedef LineCallback = void Function(String line, bool isError);

class DownloadResult {
  final int exitCode;
  final List<String> lines;
  DownloadResult(this.exitCode, this.lines);
  bool get success => exitCode == 0;
}

class Downloader {
  // ── Run yt-dlp with live output streaming ─────────────────────────────────
  static Future<DownloadResult> run(
    List<String> args, {
    LineCallback? onLine,
    CancelToken? cancel,
  }) async {
    final cfg = AppConfig.instance;
    if (!cfg.ytDlpInstalled) {
      return DownloadResult(-1, ['yt-dlp not installed']);
    }

    // Filter empty args
    final cleanArgs = args.where((a) => a.trim().isNotEmpty).toList();
    AppConfig.log('RUN: ${cleanArgs.join(' ')}');

    final proc = await Process.start(cfg.ytDlpPath, cleanArgs);
    final lines = <String>[];

    // Stream stdout
    proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      lines.add(line);
      onLine?.call(line, false);
    });

    // Stream stderr
    proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.trim().isNotEmpty) {
        lines.add(line);
        onLine?.call(line, true);
      }
    });

    // Handle cancellation
    if (cancel != null) {
      cancel.onCancel = () {
        try { proc.kill(); } catch (_) {}
      };
    }

    final exitCode = await proc.exitCode;
    return DownloadResult(exitCode, lines);
  }

  // ── Get a single value (title, duration etc.) ─────────────────────────────
  static Future<String?> getValue(String url, String flag) async {
    if (!AppConfig.instance.ytDlpInstalled) return null;
    try {
      final r = await Process.run(AppConfig.instance.ytDlpPath, [flag, url]);
      final out = (r.stdout as String).trim();
      return out.isEmpty ? null : out;
    } catch (_) { return null; }
  }

  // ── Get flat playlist JSON ────────────────────────────────────────────────
  static Future<String?> getPlaylistJson(String url, List<String> extraArgs) async {
    if (!AppConfig.instance.ytDlpInstalled) return null;
    try {
      final args = ['--flat-playlist', '--dump-single-json', '--no-warnings',
        ...extraArgs, url];
      final r = await Process.run(AppConfig.instance.ytDlpPath, args);
      final out = (r.stdout as String).trim();
      return out.isEmpty ? null : out;
    } catch (_) { return null; }
  }

  // ── Get playlist URLs ─────────────────────────────────────────────────────
  static Future<List<String>> getPlaylistUrls(String url, List<String> extraArgs) async {
    final result = <String>[];
    if (!AppConfig.instance.ytDlpInstalled) return result;
    try {
      final args = ['--flat-playlist', '--get-url', '--no-warnings', ...extraArgs, url];
      final r = await Process.run(AppConfig.instance.ytDlpPath, args);
      final lines = (r.stdout as String).split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) result.add(line.trim());
      }
    } catch (_) {}
    return result;
  }

  // ── Show available formats (returns string for display) ───────────────────
  static Future<String> getFormats(String url) async {
    if (!AppConfig.instance.ytDlpInstalled) return 'yt-dlp not installed';
    try {
      final r = await Process.run(AppConfig.instance.ytDlpPath, ['-F', url]);
      return '${r.stdout}${r.stderr}'.trim();
    } catch (e) { return 'Error: $e'; }
  }

  // ── Base args shared by all downloads ────────────────────────────────────
  static List<String> baseArgs(String outputTemplate, {String? subdir}) {
    final cfg = AppConfig.instance;
    final tpl = subdir != null
        ? '${cfg.outDir}/$subdir/$outputTemplate'
        : '${cfg.outDir}/$outputTemplate';

    final args = <String>[
      '--ffmpeg-location', cfg.binDir,
      '--output', tpl,
      '--progress',
      '--no-warnings',
      '--add-metadata',
      '--retry-sleep', '3',
      '--fragment-retries', '10',
      '--retries', '10',
      '--continue',
      '--no-part',
      '--no-overwrites',
    ];

    if (cfg.speed.isNotEmpty) args.addAll(['--limit-rate', cfg.speed]);
    if (cfg.subs) args.addAll(['--write-auto-subs', '--sub-langs', 'en', '--convert-subs', 'srt']);
    if (cfg.thumb) args.add('--embed-thumbnail');

    return args;
  }

  // ── Streaming-specific extra args ─────────────────────────────────────────
  static List<String> streamArgs() => [
    '--hls-use-mpegts',
    '--extractor-retries', '5',
    '--fragment-retries', '20',
    '--retries', '15',
    '--user-agent', 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36',
  ];
}

// ── Cancellation token ────────────────────────────────────────────────────────
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void Function()? onCancel;

  void cancel() {
    _cancelled = true;
    onCancel?.call();
  }
}
