import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/atari_theme.dart';
import '../../core/services/i_capture_pipeline_service.dart';

/// Freeform scribble-to-crop capture inbox view.
///
/// Users draw a loose shape over a loaded image. The pipeline crops
/// the region, extracts OCR text, and presents it for review before
/// categorizing as Note, Todo, or Health Target.
///
/// See Plans/IMPLEMENTATION.md §4.6.
class CaptureInboxView extends StatefulWidget {
  const CaptureInboxView({super.key, this.captureService});

  final ICapturePipelineService? captureService;

  @override
  State<CaptureInboxView> createState() => _CaptureInboxViewState();
}

class _CaptureInboxViewState extends State<CaptureInboxView> {
  final List<Offset> _scribblePoints = [];
  CaptureResult? _lastResult;
  bool _isProcessing = false;
  String _editedOcrText = '';
  String _selectedCategory = 'note';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CAPTURE & ORGANIZE',
              style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildCanvasArea(),
          const SizedBox(height: 16),
          _buildActionBar(),
          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            _buildOcrResultCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: AtariTheme.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Placeholder for loaded image.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined,
                      color: AtariTheme.textMuted, size: 48),
                  const SizedBox(height: 8),
                  Text('Tap to load an image',
                      style: AtariTheme.bodySmall),
                  Text('Then draw a region to capture',
                      style: AtariTheme.caption),
                ],
              ),
            ),
            // Scribble overlay.
            GestureDetector(
              onPanStart: (d) {
                setState(() => _scribblePoints.add(d.localPosition));
              },
              onPanUpdate: (d) {
                setState(() => _scribblePoints.add(d.localPosition));
              },
              onPanEnd: (_) {
                setState(() => _scribblePoints.add(Offset.zero));
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _ScribblePainter(_scribblePoints),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _processCapture,
            icon: _isProcessing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.crop, size: 18),
            label: Text(_isProcessing ? 'Processing...' : 'Capture Region'),
            style: AtariTheme.primaryButton(),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _clearCanvas,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear'),
          style: AtariTheme.outlineButton(),
        ),
      ],
    );
  }

  Widget _buildOcrResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AtariTheme.accentCardDecoration(AtariTheme.neonEmerald),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: AtariTheme.neonEmerald, size: 18),
              const SizedBox(width: 8),
              Text('Extracted Text',
                  style: AtariTheme.body.copyWith(
                      color: AtariTheme.neonEmerald, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_lastResult!.ocrConfidence > 0)
                Text('${(_lastResult!.ocrConfidence * 100).toStringAsFixed(0)}%',
                    style: AtariTheme.caption.copyWith(color: AtariTheme.neonEmerald)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _editedOcrText),
            onChanged: (v) => _editedOcrText = v,
            maxLines: 3,
            style: AtariTheme.body,
            decoration: InputDecoration(
              hintText: 'Edit extracted text...',
              hintStyle: AtariTheme.bodySmall,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AtariTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AtariTheme.borderSubtle),
              ),
              filled: true,
              fillColor: AtariTheme.surfaceHigh,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          Text('Save as:', style: AtariTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildCategoryChip('note', 'Note', Icons.note_outlined),
              _buildCategoryChip('todo', 'Todo', Icons.check_box_outlined),
              _buildCategoryChip('health', 'Health Target', Icons.favorite_outline),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveItem,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save & Organize'),
              style: AtariTheme.primaryButton(color: AtariTheme.neonEmerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, IconData icon) {
    final selected = _selectedCategory == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? Colors.white : AtariTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCategory = value),
      selectedColor: AtariTheme.cyberViolet,
      backgroundColor: AtariTheme.surfaceHigh,
      labelStyle: TextStyle(
          color: selected ? Colors.white : AtariTheme.textSecondary,
          fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
          color: selected ? AtariTheme.cyberViolet : AtariTheme.borderSubtle),
    );
  }

  void _clearCanvas() {
    setState(() {
      _scribblePoints.clear();
      _lastResult = null;
    });
  }

  Future<void> _processCapture() async {
    if (widget.captureService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture pipeline not connected')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final result = await widget.captureService!.capture(
        scribblePoints: _scribblePoints
            .where((p) => p != Offset.zero)
            .map((p) => {'dx': p.dx, 'dy': p.dy})
            .toList(),
        sourceImagePath: '', // would be set by image picker
        origin: 'screenshot',
      );
      setState(() {
        _lastResult = result;
        _editedOcrText = result.ocrText;
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _saveItem() {
    // In production, this would save to GoalContextRetriever.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved as $_selectedCategory'),
        backgroundColor: AtariTheme.neonEmerald,
      ),
    );
    _clearCanvas();
  }
}

class _ScribblePainter extends CustomPainter {
  _ScribblePainter(this.points);
  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtariTheme.cyberViolet.withValues(alpha: 0.7)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScribblePainter old) => true;
}
