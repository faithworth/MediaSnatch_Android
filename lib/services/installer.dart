import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'config.dart';

typedef ProgressCallback = void Function(String message, double? progress);

class Installer {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 15),
    headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 11)'},
  ));

  // ── yt-dlp Android/ARM64 binary URLs ──────────────────────────────────────
  static const _ytDlpUrls = [
    'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux_aarch64',
    'https://github.com/yt-dlp/yt-dlp/releases/download/2025.03.27/yt-dlp_linux_aarch64',
    'https://github.com/yt-dlp/yt-dlp/releases/download/2025.01.26/yt-dlp_linux_aarch64',
  ];

  // ── FFmpeg Android static builds ──────────────────────────────────────────
  static const _ffmpegUrls = [
    'https://github.com/arthenica/ffmpeg-kit/releases/download/v6.0/ffmpeg-kit-full-6.0-android-arm64-v8a.zip',
    'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz',
  ];

  // ── Public entry: ensure both tools exist ─────────────────────────────────
  static Future<void> ensureTools(ProgressCallback onProgress) async {
    final cfg = AppConfig.instance;
    if (!cfg.ytDlpInstalled)  await installYtDlp(onProgress);
    if (!cfg.ffmpegInstalled) await installFfmpeg(onProgress);
  }

  // ── Install yt-dlp ────────────────────────────────────────────────────────
  static Future<bool> installYtDlp(ProgressCallback onProgress) async {
    final dest = AppConfig.instance.ytDlpPath;
    AppConfig.log('Installing yt-dlp');
    onProgress('Downloading yt-dlp…', 0);

    for (final url in _ytDlpUrls) {
      onProgress('Trying: ${Uri.parse(url).pathSegments.last}', null);
      try {
        await _dio.download(url, dest, onReceiveProgress: (got, total) {
          if (total > 0) onProgress('yt-dlp: ${(got * 100 / total).round()}%', got / total);
        });
        final f = File(dest);
        if (f.existsSync() && f.lengthSync() > 100000) {
          await Process.run('chmod', ['+x', dest]);
          AppConfig.log('yt-dlp OK');
          onProgress('yt-dlp installed ✓', 1.0);
          return true;
        }
      } catch (e) {
        AppConfig.log('yt-dlp download failed: $e');
      }
      try { File(dest).deleteSync(); } catch (_) {}
    }
    onProgress('yt-dlp install FAILED', null);
    AppConfig.log('yt-dlp FAILED');
    return false;
  }

  // ── Install FFmpeg ────────────────────────────────────────────────────────
  static Future<bool> installFfmpeg(ProgressCallback onProgress) async {
    final cfg     = AppConfig.instance;
    final tmpZip  = '${cfg.baseDir}/ffmpeg_tmp.zip';
    AppConfig.log('Installing FFmpeg');
    onProgress('Downloading FFmpeg (~50 MB)…', 0);

    for (final url in _ffmpegUrls) {
      onProgress('Trying: ${Uri.parse(url).pathSegments.last}', null);
      try {
        await _dio.download(url, tmpZip, onReceiveProgress: (got, total) {
          if (total > 0) onProgress('FFmpeg: ${(got * 100 / total).round()}%', got / total);
        });
        final f = File(tmpZip);
        if (!f.existsSync() || f.lengthSync() < 1000000) continue;

        onProgress('Extracting FFmpeg…', null);
        await _extractFfmpeg(tmpZip, cfg.binDir, onProgress);

        if (cfg.ffmpegInstalled) {
          await Process.run('chmod', ['+x', cfg.ffmpegPath]);
          try { await Process.run('chmod', ['+x', cfg.ffprobePath]); } catch (_) {}
          AppConfig.log('FFmpeg OK');
          onProgress('FFmpeg installed ✓', 1.0);
          try { File(tmpZip).deleteSync(); } catch (_) {}
          return true;
        }
      } catch (e) {
        AppConfig.log('FFmpeg error: $e');
      }
      try { File(tmpZip).deleteSync(); } catch (_) {}
    }
    onProgress('FFmpeg install FAILED — downloads still work but merging may fail', null);
    return false;
  }

  static Future<void> _extractFfmpeg(String zipPath, String destDir, ProgressCallback onProgress) async {
    try {
      final bytes  = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final name = file.name.split('/').last;
        if ((name == 'ffmpeg' || name == 'ffprobe' || name == 'ffplay') && file.isFile) {
          final out = File('$destDir/$name');
          out.writeAsBytesSync(file.content as List<int>);
          onProgress('Extracted $name', null);
        }
      }
    } catch (e) {
      // Try tar.xz via system tar as fallback
      try {
        final result = await Process.run('tar', ['-xf', zipPath, '-C', destDir,
          '--wildcards', '--no-anchored', 'ffmpeg', 'ffprobe']);
        AppConfig.log('tar result: ${result.exitCode} ${result.stderr}');
      } catch (e2) {
        AppConfig.log('Extraction failed: $e / $e2');
      }
    }
  }

  // ── Update yt-dlp self-update ─────────────────────────────────────────────
  static Future<String> updateYtDlp(ProgressCallback onProgress) async {
    onProgress('Running yt-dlp --update…', null);
    try {
      final r = await Process.run(AppConfig.instance.ytDlpPath, ['--update']);
      final out = '${r.stdout}${r.stderr}'.trim();
      AppConfig.log('yt-dlp update: $out');
      return out.isEmpty ? 'Done.' : out;
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ── Get yt-dlp version ────────────────────────────────────────────────────
  static Future<String?> getYtDlpVersion() async {
    if (!AppConfig.instance.ytDlpInstalled) return null;
    try {
      final r = await Process.run(AppConfig.instance.ytDlpPath, ['--version']);
      return (r.stdout as String).trim();
    } catch (_) { return null; }
  }
}
