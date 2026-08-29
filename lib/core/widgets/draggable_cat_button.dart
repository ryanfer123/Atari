import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DraggableCatButton extends StatefulWidget {
  final VoidCallback onTap;
  final double bottomInset;
  final double sideInset;
  final double catWidth;
  final double catHeight;

  const DraggableCatButton({
    super.key, 
    required this.onTap,
    this.bottomInset = 60.0, // Touches the navbar exactly
    this.sideInset = 5.0, // Exact bounds, moved inwards
    this.catWidth = 70.0, // Tighter core body width for circle
    this.catHeight = 70.0, // Tighter core body height for circle
  });

  @override
  State<DraggableCatButton> createState() => _DraggableCatButtonState();
}

class _DraggableCatButtonState extends State<DraggableCatButton> {
  Offset _position = const Offset(-1, -1);
  bool _isDragging = false;
  bool _isLeft = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Safe defaults if constraints are unbound (e.g. not in a Stack)
        final maxWidth = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final maxHeight = constraints.hasBoundedHeight ? constraints.maxHeight : MediaQuery.of(context).size.height;
        
        // Initialize position on first build
        if (_position.dx == -1) {
          _position = Offset(
            maxWidth - widget.catWidth - widget.sideInset, 
            maxHeight - widget.catHeight - widget.bottomInset, // Exact bottom position
          );
        } else if (!_isDragging) {
          // On screen resize or layout change, ensure it stays clamped
          final catCenterX = _position.dx + (widget.catWidth / 2);
          final isLeftHalf = catCenterX < maxWidth / 2;
          
          final clampedY = _position.dy.clamp(
            -15.0, // Allow bleeding off the top edge by 15px
            maxHeight - widget.catHeight - widget.bottomInset,
          );
          
          _position = Offset(
            isLeftHalf ? widget.sideInset : maxWidth - widget.catWidth - widget.sideInset,
            clampedY,
          );
        }

        return SizedBox(
          width: maxWidth,
          height: maxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
            AnimatedPositioned(
              duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: _position.dx,
              top: _position.dy,
              width: widget.catWidth,
              height: widget.catHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Visual Cat (Ignores touches, scales freely)
                  IgnorePointer(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          // The cat drawing is physically offset in the 280x280 Lottie canvas.
                          // It is located at exactly X=130, Y=145 (almost dead center).
                          // Target center is X=35, Y=35 in the 70x70 circle hit box.
                          left: _isLeft ? -95 : -115,
                          top: -110,
                          child: Transform(
                            alignment: Alignment.center,
                            // Only handle horizontal mirroring
                            transform: Matrix4.identity()..scale(_isLeft ? -1.0 : 1.0, 1.0, 1.0),
                            child: Lottie.asset(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'assets/lotties/cat1o.json'
                                  : 'assets/lotties/cat1b.json',
                              width: 280,
                              height: 280,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 2. Gesture Detector over the core body only!
                  Positioned.fill(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _isDragging = true;
                            _position += details.delta;
                          });
                        },
                        onPanEnd: (details) {
                          // Determine which half of the screen the center of the cat is on
                          final catCenterX = _position.dx + (widget.catWidth / 2);
                          final isLeftHalf = catCenterX < maxWidth / 2;
                          
                          // Clamp Y to prevent dragging completely off screen
                          final clampedY = _position.dy.clamp(
                            -15.0, // Allow bleeding off the top edge by 15px
                            maxHeight - widget.catHeight - widget.bottomInset,
                          );

                          setState(() {
                            _isDragging = false;
                            _isLeft = isLeftHalf;
                            _position = Offset(
                              isLeftHalf ? widget.sideInset : maxWidth - widget.catWidth - widget.sideInset,
                              clampedY,
                            );
                          });
                        },
                        onTap: widget.onTap,
                        child: Container(
                          // Invisible hit circle over the cat's belly
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      },
    );
  }
}
