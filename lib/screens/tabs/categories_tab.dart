import 'package:flutter/material.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
              ),
              itemCount: 6, // Example categories
              itemBuilder: (context, index) {
                final categories = [
                  {'name': 'Keyboards', 'icon': Icons.keyboard, 'color': Colors.blue},
                  {'name': 'Mouses', 'icon': Icons.mouse, 'color': Colors.green},
                  {'name': 'Accessories', 'icon': Icons.interests, 'color': Colors.orange},
                  {'name': 'Cables', 'icon': Icons.cable, 'color': Colors.red},
                  {'name': 'Headsets', 'icon': Icons.headset, 'color': Colors.purple},
                  {'name': 'Speakers', 'icon': Icons.speaker, 'color': Colors.brown},
                ];
                
                final category = categories[index];
                
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 