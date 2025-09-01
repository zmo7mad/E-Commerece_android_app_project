import 'package:flutter/material.dart';
import 'package:e_commerece/shared/widgets/product_image.dart';
import 'dart:async'; // Added for Timer

// Added for indicators placement 
enum IndicatorsPlacement {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class MultiImageViewer extends StatefulWidget {
  final List<String> images;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showIndicators;
  final IndicatorsPlacement indicatorsPlacement;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const MultiImageViewer({
    super.key,
    required this.images,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showIndicators = true,
    this.indicatorsPlacement = IndicatorsPlacement.bottom,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  @override
  State<MultiImageViewer> createState() => _MultiImageViewerState();
}

class _MultiImageViewerState extends State<MultiImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    if (widget.autoPlay && widget.images.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (mounted && widget.images.length > 1) {
        final nextIndex = (_currentIndex + 1) % widget.images.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildPlaceholder();
    }

    if (widget.images.length == 1) {
      return _buildSingleImage();
    }

    return _buildMultiImage();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: widget.borderRadius,
      ),
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSingleImage() {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: ProductImage(
        image: widget.images.first,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      ),
    );
  }

  Widget _buildMultiImage() {
    return Stack(
      children: [
        // PageView for images
        ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return ProductImage(
                image: widget.images[index],
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
              );
            },
          ),
        ),
        
        // Navigation arrows
        if (widget.images.length > 1) ...[
          // Previous button
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final previousIndex = (_currentIndex - 1 + widget.images.length) % widget.images.length;
                  _pageController.animateToPage(
                    previousIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          
          // Next button
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final nextIndex = (_currentIndex + 1) % widget.images.length;
                  _pageController.animateToPage(
                    nextIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
        
                 // Image counter
         if (widget.images.length > 1)
           Positioned(
             bottom: 8,
             left: 8,
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.7),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 '${_currentIndex + 1}/${widget.images.length}',
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 12,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
           ),
        
        // Page indicators
        if (widget.showIndicators && widget.images.length > 1)
          _buildIndicators(),
      ],
    );
  }

  Widget _buildIndicators() {
    final indicators = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.images.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );

    switch (widget.indicatorsPlacement) {
      case IndicatorsPlacement.top:
        return Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: indicators,
        );
      case IndicatorsPlacement.bottom:
        return Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: indicators,
        );
      case IndicatorsPlacement.left:
        return Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        );
      case IndicatorsPlacement.right:
        return Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        );
      case IndicatorsPlacement.topLeft:
        return Positioned(
          top: 8,
          left: 8,
          child: indicators,
        );
      case IndicatorsPlacement.topRight:
        return Positioned(
          top: 8,
          right: 8,
          child: indicators,
        );
      case IndicatorsPlacement.bottomLeft:
        return Positioned(
          bottom: 8,
          left: 8,
          child: indicators,
        );
      case IndicatorsPlacement.bottomRight:
        return Positioned(
          bottom: 8,
          right: 8,
          child: indicators,
        );
    }
  }
}
