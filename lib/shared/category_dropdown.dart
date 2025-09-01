import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final bool isRequired;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.labelText = 'Category',
    this.isRequired = true,
  });

  // List of available categories - shared across the app
  static const List<String> availableCategories = [
    'Electronics',
    'Clothing',
    'Sports',
    'Books',
    'Home & Garden',
    'Beauty & Health',
    'Toys & Games',
    'Automotive',
    'Music',
    'Food & Beverages',
    'Jewelry',
    'Art & Crafts',
    'Tools & Hardware',
    'Pet Supplies',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.category),
      ),
      items: availableCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      } : null,
    );
  }

  // Helper method to get initial category based on product title
  static String getInitialCategory(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('guitar') || lowerTitle.contains('drum') || lowerTitle.contains('music')) {
      return 'Music';
    } else if (lowerTitle.contains('jeans') || lowerTitle.contains('shorts') || lowerTitle.contains('shirt') || lowerTitle.contains('dress')) {
      return 'Clothing';
    } else if (lowerTitle.contains('skates') || lowerTitle.contains('karati') || lowerTitle.contains('sport')) {
      return 'Sports';
    } else if (lowerTitle.contains('phone') || lowerTitle.contains('laptop') || lowerTitle.contains('computer')) {
      return 'Electronics';
    } else if (lowerTitle.contains('book') || lowerTitle.contains('novel')) {
      return 'Books';
    } else if (lowerTitle.contains('toy') || lowerTitle.contains('game')) {
      return 'Toys & Games';
    } else if (lowerTitle.contains('jewelry') || lowerTitle.contains('ring') || lowerTitle.contains('necklace')) {
      return 'Jewelry';
    } else if (lowerTitle.contains('tool') || lowerTitle.contains('hardware')) {
      return 'Tools & Hardware';
    } else if (lowerTitle.contains('pet') || lowerTitle.contains('dog') || lowerTitle.contains('cat')) {
      return 'Pet Supplies';
    } else if (lowerTitle.contains('food') || lowerTitle.contains('drink') || lowerTitle.contains('beverage')) {
      return 'Food & Beverages';
    } else if (lowerTitle.contains('beauty') || lowerTitle.contains('health') || lowerTitle.contains('cosmetic')) {
      return 'Beauty & Health';
    } else if (lowerTitle.contains('home') || lowerTitle.contains('garden') || lowerTitle.contains('furniture')) {
      return 'Home & Garden';
    } else if (lowerTitle.contains('car') || lowerTitle.contains('auto') || lowerTitle.contains('vehicle')) {
      return 'Automotive';
    } else if (lowerTitle.contains('art') || lowerTitle.contains('craft') || lowerTitle.contains('paint')) {
      return 'Art & Crafts';
    } else {
      return 'Other';
    }
  }
}
