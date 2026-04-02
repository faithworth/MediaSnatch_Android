import 'package:flutter/material.dart';

class DownloadTerminal extends StatefulWidget {
  final List<TerminalLine> lines;
  final bool isRunning;
  final VoidCallback? onCancel;
  final double? progress; // 0.0–1.0 or null

  const DownloadTerminal({
    super.key,
    required this.lines,
    this.isRunning = false,
    this.onCancel,
    this.progress,
  });

  @override
  State<DownloadTerminal> createState() => _DownloadTerminalState();
}

class _DownloadTerminalState extends State<DownloadTerminal> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(DownloadTerminal old) {
    super.didUpdateWidget(old);
    if (widget.lines.length != old.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar
        if (widget.progress != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: cs.surfaceVariant,
                  color: cs.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((widget.progress ?? 0) * 100).round()}%',
                  style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else if (widget.isRunning)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(
              backgroundColor: cs.surfaceVariant,
              color: cs.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

        // Terminal box
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            padding: const EdgeInsets.all(12),
            child: widget.lines.isEmpty
                ? Center(child: Text('Waiting…', style: TextStyle(color: cs.onSurfaceVariant, fontFamily: 'monospace')))
                : ListView.builder(
                    controller: _scroll,
                    itemCount: widget.lines.length,
                    itemBuilder: (_, i) {
                      final l = widget.lines[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          l.text,
                          style: TextStyle(
                            color: l.color,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Cancel button
        if (widget.isRunning && widget.onCancel != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Cancel Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.error,
                side: BorderSide(color: cs.error),
              ),
            ),
          ),
      ],
    );
  }
}

class TerminalLine {
  final String text;
  final Color color;
  TerminalLine(this.text, {this.color = const Color(0xFF8B949E)});

  factory TerminalLine.ok(String t)    => TerminalLine('✓ $t', color: const Color(0xFF3FB950));
  factory TerminalLine.err(String t)   => TerminalLine('✗ $t', color: const Color(0xFFF85149));
  factory TerminalLine.warn(String t)  => TerminalLine('⚠ $t', color: const Color(0xFFD29922));
  factory TerminalLine.info(String t)  => TerminalLine('» $t', color: const Color(0xFF58A6FF));
  factory TerminalLine.plain(String t) => TerminalLine(t);
  factory TerminalLine.progress(String t) => TerminalLine(t, color: const Color(0xFF00BCD4));
}

// ── Parse yt-dlp output lines into coloured terminal lines ───────────────────
TerminalLine parseYtDlpLine(String line, bool isError) {
  final t = line.trim();
  if (isError) {
    if (t.startsWith('ERROR:')) return TerminalLine.err(t);
    return TerminalLine(t, color: const Color(0xFF484F58));
  }
  if (t.startsWith('[download]')) return TerminalLine.progress(t);
  if (t.startsWith('ERROR:'))     return TerminalLine.err(t);
  if (t.startsWith('WARNING:'))   return TerminalLine.warn(t);
  if (t.startsWith('[info]'))     return TerminalLine.info(t);
  return TerminalLine.plain(t);
}

// ── Parse download % from yt-dlp progress line ───────────────────────────────
double? parseProgress(String line) {
  final match = RegExp(r'\[download\]\s+([\d.]+)%').firstMatch(line);
  if (match == null) return null;
  return double.tryParse(match.group(1)!) != null
      ? double.parse(match.group(1)!) / 100.0
      : null;
}
