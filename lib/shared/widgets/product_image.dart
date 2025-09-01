import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImage extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholderAsset;
  final String? errorAsset;

  const ProductImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderAsset = 'assets/products/backpack.png',
    this.errorAsset = 'assets/products/backpack.png',
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (image.startsWith('data:image/')) {
      // Handle base64 images
      imageWidget = _buildBase64Image();
    } else if (image.startsWith('http://') || image.startsWith('https://')) {
      // Handle network images
      imageWidget = _buildNetworkImage();
    } else {
      // Handle asset images
      imageWidget = _buildAssetImage();
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildBase64Image() {
    try {
      final uri = Uri.parse(image);
      final data = uri.data;
      if (data != null) {
        return Image.memory(
          data.contentAsBytes(),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }
    } catch (e) {
      print('Error parsing base64 image: $e');
    }
    return _buildErrorWidget();
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: image,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholderWidget(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  Widget _buildAssetImage() {
    return Image.asset(
      image,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
    );
  }

  Widget _buildPlaceholderWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
}
