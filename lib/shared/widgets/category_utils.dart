class CategoryUtils {
  /// Derives a category from a product title or description
  /// Uses keyword matching to determine the appropriate category
  static String deriveCategory(String titleOrCategory) {
    final value = titleOrCategory.toLowerCase();
    
    // Music category
    if (value.contains('guitar') || 
        value.contains('drum') || 
        value.contains('piano') || 
        value.contains('violin') || 
        value.contains('music') ||
        value.contains('instrument')) {
      return 'Music';
    }
    
    // Clothing category
    if (value.contains('jeans') || 
        value.contains('shorts') || 
        value.contains('shirt') || 
        value.contains('dress') || 
        value.contains('jacket') ||
        value.contains('clothing') ||
        value.contains('fashion')) {
      return 'Clothing';
    }
    
    // Sports category
    if (value.contains('skates') || 
        value.contains('karati') || 
        value.contains('soccer') || 
        value.contains('basketball') || 
        value.contains('tennis') ||
        value.contains('sports') ||
        value.contains('fitness')) {
      return 'Sports';
    }
    
    // Bags category
    if (value.contains('backpack') || 
        value.contains('suitcase') || 
        value.contains('bag') || 
        value.contains('purse') || 
        value.contains('wallet')) {
      return 'Bags';
    }
    
    // Electronics category
    if (value.contains('phone') || 
        value.contains('laptop') || 
        value.contains('computer') || 
        value.contains('tablet') || 
        value.contains('camera') ||
        value.contains('electronic')) {
      return 'Electronics';
    }
    
    // Books category
    if (value.contains('book') || 
        value.contains('novel') || 
        value.contains('magazine') || 
        value.contains('journal') || 
        value.contains('textbook')) {
      return 'Books';
    }
    
    // Home & Garden category
    if (value.contains('furniture') || 
        value.contains('decor') || 
        value.contains('garden') || 
        value.contains('kitchen') || 
        value.contains('bedroom')) {
      return 'Home & Garden';
    }
    
    // Default category
    return 'Other';
  }

  /// Gets all available categories
  static List<String> getAvailableCategories() {
    return [
      'All',
      'Music',
      'Clothing',
      'Sports',
      'Bags',
      'Electronics',
      'Books',
      'Home & Garden',
      'Other',
    ];
  }

  /// Checks if a category is valid
  static bool isValidCategory(String category) {
    return getAvailableCategories().contains(category);
  }
}
