import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerece/models/product.dart';
import 'package:e_commerece/shared/category_dropdown.dart';
import 'package:e_commerece/shared/image_utils.dart';
import 'package:e_commerece/providers/deletion_provider.dart';
import 'dart:io';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _stockController = TextEditingController();
  
  List<File> _newImageFiles = [];
  bool _isLoading = false;
  bool _keepExistingImages = true;
  String? _selectedCategory;
  static const int maxImages = 3;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _titleController.text = widget.product.title;
    _priceController.text = widget.product.price.toString();
    _descriptionController.text = widget.product.description ?? '';
    _sellerNameController.text = widget.product.sellerName ?? '';
    _stockController.text = widget.product.stockQuantity.toString();
    
    // Initialize category - try to get from product data or derive from title
    _selectedCategory = _getInitialCategory();
  }

  String _getInitialCategory() {
    // Use the shared category dropdown helper method
    return CategoryDropdown.getInitialCategory(widget.product.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sellerNameController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_newImageFiles.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $maxImages images allowed')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _newImageFiles.add(File(image.path));
        _keepExistingImages = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
      if (_newImageFiles.isEmpty) {
        _keepExistingImages = true;
      }
    });
  }

  void _clearImages() {
    setState(() {
      _newImageFiles.clear();
      _keepExistingImages = true;
    });
  }

  void _deleteExistingImage(int index) {
    ref.read(deletionProvider.notifier).markImageAsDeleted(widget.product.id, index);
  }

  void _restoreDeletedImage(int index) {
    ref.read(deletionProvider.notifier).restoreDeletedImage(widget.product.id, index);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? mainImageUrl = widget.product.image;
      List<String>? additionalImages = widget.product.images;
      
      // Process new images if selected
      if (_newImageFiles.isNotEmpty && !_keepExistingImages) {
        List<String> processedImages = [];
        
        // Convert all new images to base64
        for (File imageFile in _newImageFiles) {
          final base64Image = await ImageUtils.convertImageToBase64(imageFile);
          if (base64Image != null) {
            processedImages.add(base64Image);
          }
        }
        
        if (processedImages.isNotEmpty) {
          mainImageUrl = processedImages.first; // First image becomes main image
          additionalImages = processedImages.skip(1).toList(); // Rest become additional images
        }
      } else if (_keepExistingImages) {
        // Handle deletion of existing images using the deletion provider
        final deletionNotifier = ref.read(deletionProvider.notifier);
        final deletedIndices = deletionNotifier.getDeletedImageIndices(widget.product.id);
        
        final allImages = widget.product.allImages;
        List<String> remainingImages = [];
        
        for (int i = 0; i < allImages.length; i++) {
          if (!deletedIndices.contains(i.toString())) {
            remainingImages.add(allImages[i]);
          }
        }
        
        if (remainingImages.isNotEmpty) {
          mainImageUrl = remainingImages.first;
          additionalImages = remainingImages.skip(1).toList();
        } else {
          // If all images are deleted, keep the original main image
          mainImageUrl = widget.product.image;
          additionalImages = null; // Clear additional images
        }
      }

      // Update product in Firestore
      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.product.id)
          .update({
        'title': _titleController.text.trim(),
        'price': int.parse(_priceController.text.trim()),
        'description': _descriptionController.text.trim(),
        'sellerName': _sellerNameController.text.trim(),
        'stockQuantity': int.parse(_stockController.text.trim()),
        'category': _selectedCategory,
        'image': mainImageUrl,
        'images': additionalImages,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear deletion state for this product after successful save
      ref.read(deletionProvider.notifier).clearProductDeletions(widget.product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the deletion provider to rebuild when deletion state changes
    final deletionState = ref.watch(deletionProvider);
    final deletedIndices = deletionState[widget.product.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
          color: Color.fromARGB(255, 255, 255, 255),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title:  Text('Edit Product',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        ),
        backgroundColor:  Color.fromARGB(255, 76, 94, 168),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              _buildImageSection(deletedIndices),
              const SizedBox(height: 24),
              
              // Product Information Form
              _buildProductForm(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(List<String> deletedIndices) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product Images',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_newImageFiles.length}/$maxImages',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Current Images Display
            if (_keepExistingImages || _newImageFiles.isEmpty)
              _buildCurrentImagesDisplay(deletedIndices),
            
            // Deleted Images Display (if any)
            if (deletedIndices.isNotEmpty && _keepExistingImages)
              _buildDeletedImagesDisplay(deletedIndices),
            
            // New Images Display
            if (_newImageFiles.isNotEmpty && !_keepExistingImages)
              _buildNewImagesDisplay(),
            
            const SizedBox(height: 12),
            
            // Image Options
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Add Images'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 78, 93, 178),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_newImageFiles.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _keepExistingImages = !_keepExistingImages;
                        });
                      },
                      icon: Icon(_keepExistingImages ? Icons.image : Icons.undo),
                      label: Text(_keepExistingImages ? 'Keep Current' : 'Use New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _keepExistingImages 
                            ? Colors.green 
                            : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      // Handle base64 images
      try {
        final uri = Uri.parse(imageUrl);
        final data = uri.data;
        if (data != null) {
          return Image.memory(
            data.contentAsBytes(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.image_not_supported,
                  size: 50,
                  color: Colors.grey,
                ),
              );
            },
          );
        }
      } catch (e) {
        print('Error parsing base64 image: $e');
      }
      // Fallback to placeholder
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      );
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }

  Widget _buildProductForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a product title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Price Field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                final price = int.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Stock Quantity Field
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter stock quantity';
                }
                final stock = int.tryParse(value.trim());
                if (stock == null || stock < 0) {
                  return 'Please enter a valid stock quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            CategoryDropdown(
              selectedCategory: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.trim().length > 500) {
                  return 'Description must be less than 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Seller Name Field
            TextFormField(
              controller: _sellerNameController,
              decoration: const InputDecoration(
                labelText: 'Seller Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value != null && value.trim().length > 100) {
                  return 'Seller name must be less than 100 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentImagesDisplay(List<String> deletedIndices) {
    final allImages = widget.product.allImages;
    final remainingImages = <String>[];
    
    // Filter out deleted images
    for (int i = 0; i < allImages.length; i++) {
      if (!deletedIndices.contains(i.toString())) {
        remainingImages.add(allImages[i]);
      }
    }
    
    if (remainingImages.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'All images deleted',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (remainingImages.length == 1) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(remainingImages.first),
        ),
      );
    }

    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: remainingImages.length,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: index < remainingImages.length - 1 ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  _buildImageWidget(remainingImages[index]),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}/${remainingImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Delete button for existing images
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        // Find the original index of this image
                        int originalIndex = 0;
                        for (int i = 0; i < allImages.length; i++) {
                          if (allImages[i] == remainingImages[index] && 
                              !deletedIndices.contains(i.toString())) {
                            originalIndex = i;
                            break;
                          }
                        }
                        _deleteExistingImage(originalIndex);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeletedImagesDisplay(List<String> deletedIndices) {
    final allImages = widget.product.allImages;
    final deletedImages = <String>[];
    
    // Get deleted images
    for (int i = 0; i < allImages.length; i++) {
      if (deletedIndices.contains(i.toString())) {
        deletedImages.add(allImages[i]);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Deleted Images (${deletedImages.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: deletedImages.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: index < deletedImages.length - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      _buildImageWidget(deletedImages[index]),
                      // Semi-transparent overlay to show deleted state
                      Container(
                        color: Colors.red.withOpacity(0.3),
                      ),
                      // Restore button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            // Find the original index of this image
                            int originalIndex = 0;
                            for (int i = 0; i < allImages.length; i++) {
                              if (allImages[i] == deletedImages[index] && 
                                  deletedIndices.contains(i.toString())) {
                                originalIndex = i;
                                break;
                              }
                            }
                            _restoreDeletedImage(originalIndex);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restore,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewImagesDisplay() {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _newImageFiles.length,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: index < _newImageFiles.length - 1 ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Image.file(
                    _newImageFiles[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}/${_newImageFiles.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
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
 
