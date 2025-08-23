import 'dart:async';
import 'package:flutter/material.dart'; 
import 'package:cached_network_image/cached_network_image.dart';

class NewUpdatesBanner extends StatefulWidget {
  const NewUpdatesBanner({
    super.key,
    required this.items,
    this.interval = const Duration(seconds: 3),
    this.onTap,
    this.height = 64,
  });

  /// items: each item supports keys: 'text' (String), 'image' (String, optional)
  final List<Map<String, dynamic>> items;
  final Duration interval;
  final double height;
  final void Function(int index , String text)? onTap;

  @override
  State<NewUpdatesBanner> createState() => _NewUpdatesBannerState();
}

class _NewUpdatesBannerState extends State<NewUpdatesBanner> with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    if (widget.items.isNotEmpty) {
       _timer = Timer.periodic(widget.interval, (_) {
         _index = (_index + 1) % widget.items.length;
          _pageController.animateToPage(
            _index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        });
      }
    }

    @override
    void dispose() {
      _timer?.cancel();
      _pageController.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      width: double.infinity,
      height: widget.height,
      child: PageView.builder(
        allowImplicitScrolling: true,
        controller: _pageController,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final String text = (item['text'] ?? '').toString();
          final String image = (item['image'] ?? '').toString();
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap == null ? null : () => widget.onTap!(index, text),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Larger, more prominent image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _buildImageWidget(image),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tap to explore',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildImageWidget(String image) {
    // Handle base64 data URLs
    if (image.startsWith('data:image/')) {
      try {
        final uri = Uri.parse(image);
        final data = uri.data;
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              height: 100,
              color: Colors.white.withOpacity(0.2),
              child: Icon(
                Icons.image_not_supported, 
                color: Colors.white.withOpacity(0.6), 
                size: 32
              ),
            ),
          );
        }
      } catch (e) {
        print('Error parsing base64 image: $e');
      }
    }
    
    // Handle network URLs
    if (image.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: image,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 100,
          height: 100,
          color: Colors.white.withOpacity(0.2),
          child: Icon(
            Icons.image, 
            color: Colors.white.withOpacity(0.6), 
            size: 32
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 100,
          height: 100,
          color: Colors.white.withOpacity(0.2),
          child: Icon(
            Icons.image_not_supported, 
            color: Colors.white.withOpacity(0.6), 
            size: 32
          ),
        ),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
      );
    }
    
    // Handle local assets
    return Image.asset(
      image,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 100,
        height: 100,
        color: Colors.white.withOpacity(0.2),
        child: Icon(
          Icons.image_not_supported, 
          color: Colors.white.withOpacity(0.6), 
          size: 32
        ),
      ),
    );
  }
}