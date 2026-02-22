import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/favorites_provider.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<FavoritesProvider>().loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Favorites (${provider.count})'),
            actions: [
              if (provider.hasFavorites)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear All',
                  onPressed: () => _confirmClearAll(provider),
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.favorite_border,
                      title: 'No Favorites Yet',
                      subtitle:
                          'Tap the heart icon on products to add them here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.favorites.length,
                      itemBuilder: (context, index) {
                        final item = provider.favorites[index];
                        return _buildFavoriteCard(item, provider);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(FavoriteItem item, FavoritesProvider provider) {
    final priceLabel = FavoritesProvider.getPriceChangeLabel(item);
    final isPriceDrop = item.priceAtSave > item.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openProductUrl(item.productUrl),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey[200],
                  child: const Icon(Icons.shopping_bag,
                      size: 32, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.brand ?? ''} • ${item.source ?? ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (item.averageRating > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.star,
                              size: 14, color: Colors.amber[700]),
                          Text(
                            ' ${item.averageRating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    if (priceLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPriceDrop
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priceLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: isPriceDrop
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Remove button
              IconButton(
                icon:
                    const Icon(Icons.favorite, color: Color(0xFFFF6B6B)),
                onPressed: () => provider.removeFavorite(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(FavoritesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllFavorites();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
