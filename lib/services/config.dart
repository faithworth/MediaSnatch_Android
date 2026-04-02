import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance!;

  late SharedPreferences _prefs;

  // ── Paths ──────────────────────────────────────────────────────────────────
  late String baseDir;    // <app support>/MediaSnatch
  late String binDir;     // <app support>/MediaSnatch/bin
  late String _outDir;    // /storage/emulated/0/Download/MediaSnatch
  late String logFile;    // <app support>/MediaSnatch/mediasnatch.log

  String get outDir       => _outDir;
  String get ytDlpPath    => '$binDir/yt-dlp';
  String get ffmpegPath   => '$binDir/ffmpeg';
  String get ffprobePath  => '$binDir/ffprobe';

  // ── Settings ───────────────────────────────────────────────────────────────
  bool   get subs      => _prefs.getBool('subs')    ?? false;
  bool   get thumb     => _prefs.getBool('thumb')   ?? false;
  String get speed     => _prefs.getString('speed') ?? '';
  bool   get setupDone => _prefs.getBool('setupDone') ?? false;

  set subs(bool v)     => _prefs.setBool('subs', v);
  set thumb(bool v)    => _prefs.setBool('thumb', v);
  set speed(String v)  => _prefs.setString('speed', v);
  set setupDone(bool v)=> _prefs.setBool('setupDone', v);

  set outDir(String v) {
    _outDir = v;
    _prefs.setString('outDir', v);
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    final cfg = AppConfig();
    cfg._prefs = await SharedPreferences.getInstance();

    final appDir = await getApplicationSupportDirectory();
    cfg.baseDir  = '${appDir.path}/MediaSnatch';
    cfg.binDir   = '${cfg.baseDir}/bin';
    cfg.logFile  = '${cfg.baseDir}/mediasnatch.log';

    // Default output: Android Downloads folder
    const defaultOut = '/storage/emulated/0/Download/MediaSnatch';
    cfg._outDir = cfg._prefs.getString('outDir') ?? defaultOut;

    // Ensure dirs exist
    await Directory(cfg.baseDir).create(recursive: true);
    await Directory(cfg.binDir).create(recursive: true);
    try { await Directory(cfg._outDir).create(recursive: true); } catch (_) {}

    _instance = cfg;
  }

  // ── Logging ────────────────────────────────────────────────────────────────
  static void log(String msg) {
    try {
      final now = DateTime.now();
      final ts  = '${now.hour.toString().padLeft(2,'0')}:'
                  '${now.minute.toString().padLeft(2,'0')}:'
                  '${now.second.toString().padLeft(2,'0')}';
      File(instance.logFile).writeAsStringSync('$ts  $msg\n', mode: FileMode.append);
    } catch (_) {}
  }

  // ── Status helpers ─────────────────────────────────────────────────────────
  bool get ytDlpInstalled  => File(ytDlpPath).existsSync();
  bool get ffmpegInstalled => File(ffmpegPath).existsSync();
}
