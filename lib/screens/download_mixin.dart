import 'dart:io';
import 'package:flutter/material.dart';
import '../services/downloader.dart';
import '../services/config.dart';
import '../widgets/download_terminal.dart';

/// Mixin that provides standard download flow for all download screens.
mixin DownloadMixin<T extends StatefulWidget> on State<T> {
  List<TerminalLine> termLines = [];
  bool    isDownloading = false;
  bool    isDone        = false;
  int     exitCode      = -1;
  double? progress;
  CancelToken? _cancelToken;

  String get downloadTitle;

  Future<void> startDownload(List<String> args) async {
    if (isDownloading) return;
    setState(() {
      isDownloading = true;
      isDone        = false;
      exitCode      = -1;
      progress      = null;
      termLines     = [];
    });

    _cancelToken = CancelToken();
    final result = await Downloader.run(
      args,
      cancel: _cancelToken,
      onLine: (line, isErr) {
        if (!mounted) return;
        final p = parseProgress(line);
        setState(() {
          termLines = [...termLines, parseYtDlpLine(line, isErr)];
          if (p != null) progress = p;
        });
      },
    );

    if (!mounted) return;
    setState(() {
      isDownloading = false;
      isDone        = true;
      exitCode      = result.exitCode;
      if (result.success) progress = 1.0;
      termLines = [...termLines, result.success
          ? TerminalLine.ok('DOWNLOAD COMPLETE!')
          : TerminalLine.warn('Done with warnings — check output above.')];
    });
    AppConfig.log('Download finished: exit=$exitCode');
  }

  void cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      isDownloading = false;
      termLines = [...termLines, TerminalLine.warn('Cancelled by user.')];
    });
  }

  void openOutputFolder() {
    final dir = AppConfig.instance.outDir;
    // Android intent to open file manager at folder
    try {
      Process.run('am', ['start', '-a', 'android.intent.action.VIEW',
        '-t', 'resource/folder', '-d', 'file://$dir']);
    } catch (_) {}
  }

  Widget buildTerminalPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DownloadTerminal(
            lines: termLines,
            isRunning: isDownloading,
            progress: progress,
            onCancel: isDownloading ? cancelDownload : null,
          ),
        ),
        if (isDone) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Open Folder'),
                onPressed: openOutputFolder,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Download Again'),
                onPressed: () => setState(() {
                  isDone    = false;
                  termLines = [];
                  progress  = null;
                }),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}
