import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/providers/stock_provider.dart';
import 'package:e_commerece/shared/firebase.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StockManagementScreen extends ConsumerStatefulWidget {
  const StockManagementScreen({super.key});

  @override
  ConsumerState<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends ConsumerState<StockManagementScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await fetchProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });

      // Initialize stock provider with current stock data
      final stockData = <String, int>{};
      for (final product in products) {
        final stockQuantity = product['stockQuantity'] != null
            ? int.tryParse(product['stockQuantity'].toString()) ?? 0
            : 0;
        stockData[product['id']?.toString() ?? ''] = stockQuantity;
      }
      ref.read(stockNotifierProvider.notifier).initializeStock(stockData);
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStock(String productId, int newStock) async {
    try {
      ref.read(stockNotifierProvider.notifier).updateStock(productId, newStock);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
          color: Color.fromARGB(255, 41, 52, 117),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Stock Management',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 41, 52, 117),
        ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
            color: Color.fromARGB(255, 41, 52, 117),
            ),
            onPressed: _loadProducts,
          ),
         
          
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final productId = product['id']?.toString() ?? '';
                        final currentStock = ref.watch(productStockProvider(productId));
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: _ProductImage(
                                      image: product['image']?.toString() ?? '',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['title']?.toString() ?? 'No Title',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${product['price']?.toString() ?? '0'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            currentStock > 0 ? Icons.check_circle : Icons.cancel,
                                            color: currentStock > 0 ? Colors.green : Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            currentStock > 0 ? 'In Stock' : 'Out of Stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: currentStock > 0 ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Stock Input
                                Column(
                                  children: [
                                    const Text(
                                      'Stock',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: currentStock.toString(),
                                        ),
                                        onSubmitted: (value) {
                                          final newStock = int.tryParse(value) ?? 0;
                                          if (newStock >= 0) {
                                            _updateStock(productId, newStock);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.image});

  final String image;

  bool get _isNetwork => image.startsWith('http://') || image.startsWith('https://');
  bool get _isDataUrl => image.startsWith('data:image/');

  @override
  Widget build(BuildContext context) {
    if (_isDataUrl) {
      try {
        final uri = Uri.parse(image);
        final data = uri.data;
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(),
            fit: BoxFit.cover,
          );
        }
      } catch (_) {}
      return Image.asset(
        'assets/products/backpack.png',
        fit: BoxFit.cover,
      );
    }
    
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[100],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[100],
          child: Icon(
            Icons.image_not_supported,
            size: 24,
            color: Colors.grey[400],
          ),
        ),
      );
    }
    
    return Image.asset(
      image,
      fit: BoxFit.cover,
    );
  }
}
