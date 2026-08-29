import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DraggableCatButton extends StatefulWidget {
  final VoidCallback onTap;

  const DraggableCatButton({super.key, required this.onTap});

  @override
  State<DraggableCatButton> createState() => _DraggableCatButtonState();
}

class _DraggableCatButtonState extends State<DraggableCatButton> {
  Offset _position = const Offset(-1, -1);
  bool _isDragging = false;
  bool _isLeft = false;

  final double _catSize = 100.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position.dx == -1) {
      // Initialize at bottom right (where the FAB was)
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - _catSize - 24, size.height - 220);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final size = MediaQuery.of(context).size;
    
    // Determine which half of the screen the center of the cat is on
    final catCenterX = _position.dx + (_catSize / 2);
    final isLeftHalf = catCenterX < size.width / 2;
    
    // Clamp Y to prevent dragging completely off screen
    final clampedY = _position.dy.clamp(
      MediaQuery.of(context).padding.top + 16.0, 
      size.height - _catSize - 100.0, // Leave room for navbar
    );

    setState(() {
      _isDragging = false;
      _isLeft = isLeftHalf;
      _position = Offset(
        isLeftHalf ? 16.0 : size.width - _catSize - 16.0,
        clampedY,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTap: widget.onTap,
        // Using MouseRegion so Web users know it's interactive
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Transform.scale(
            // Mirror reflection: negative scaleX flips the image horizontally
            scaleX: _isLeft ? -1 : 1, 
            child: SizedBox(
              width: _catSize,
              height: _catSize,
              child: Lottie.asset(
                'assets/lotties/cat.json',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
