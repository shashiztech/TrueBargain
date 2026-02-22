import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_detail_provider.dart';
import '../models/models.dart';
import '../services/services.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = ProductDetailProvider(
          product: product,
          aiRecommendation: ctx.read<AIRecommendationService>(),
          priceHistory: ctx.read<PriceHistoryService>(),
          alertService: ctx.read<ProductAlertService>(),
          favoritesService: ctx.read<FavoritesService>(),
        );
        provider.loadDetails();
        return provider;
      },
      child: _ProductDetailView(product: product),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  final Product product;

  const _ProductDetailView({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductDetailProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  provider.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      provider.isFavorite ? const Color(0xFFFF6B6B) : null,
                ),
                onPressed: provider.toggleFavorite,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag,
                        size: 64, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // Name + Price
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (product.averageRating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star,
                                size: 18, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              '${product.averageRating.toStringAsFixed(1)} '
                              '(${product.numberOfRatings})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Source + Brand
                Wrap(
                  spacing: 8,
                  children: [
                    if (product.source != null)
                      Chip(
                          label: Text(product.source!),
                          visualDensity: VisualDensity.compact),
                    if (product.brand != null)
                      Chip(
                          label: Text(product.brand!),
                          visualDensity: VisualDensity.compact),
                    if (product.category != null)
                      Chip(
                          label: Text(product.category!),
                          visualDensity: VisualDensity.compact),
                  ],
                ),
                const SizedBox(height: 16),

                // AI Summary
                _buildSection(
                  context,
                  'AI Summary',
                  Icons.auto_awesome,
                  child: provider.isLoadingSummary
                      ? const Center(child: CircularProgressIndicator())
                      : Text(provider.aiSummary ?? 'Loading...'),
                ),
                const SizedBox(height: 16),

                // Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  _buildSection(
                    context,
                    'Description',
                    Icons.description,
                    child: Text(product.description!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Price Alert
                _buildSection(
                  context,
                  'Set Price Alert',
                  Icons.notifications,
                  child: _buildPriceAlertForm(context, provider),
                ),
                const SizedBox(height: 16),

                // Price History
                _buildSection(
                  context,
                  'Price History',
                  Icons.timeline,
                  child: provider.priceHistoryEntries.isEmpty
                      ? const Text('No price history available yet')
                      : Column(
                          children: provider.priceHistoryEntries
                              .take(10)
                              .map((entry) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                        '₹${entry.price.toStringAsFixed(0)}'),
                                    subtitle: Text(entry.source ?? ''),
                                    trailing: Text(
                                      _formatDate(entry.recordedAt),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),

                // Similar Products
                if (provider.similarProducts.isNotEmpty) ...[
                  _buildSection(
                    context,
                    'Similar Products',
                    Icons.grid_view,
                    child: Column(
                      children: provider.similarProducts.map((p) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle:
                              Text('₹${p.price.toStringAsFixed(0)} • ${p.source ?? ""}'),
                          trailing: Text(
                              '${p.averageRating.toStringAsFixed(1)}★'),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailPage(product: p),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon, {
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAlertForm(
      BuildContext context, ProductDetailProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Target price (₹)',
              prefixText: '₹ ',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final price = double.tryParse(v);
              if (price != null) provider.setTargetPrice(price);
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () async {
            await provider.setPriceAlert();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Price alert set!')),
              );
            }
          },
          icon: const Icon(Icons.add_alert, size: 18),
          label: const Text('Set'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
