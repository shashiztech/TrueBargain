import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/compare_provider.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompareProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Compare'),
            actions: [
              if (provider.hasProducts)
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: provider.clearAll,
                  tooltip: 'Clear All',
                ),
            ],
          ),
          body: Column(
            children: [
              // Search to add products
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products to compare...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      onPressed: provider.isLoading
                          ? null
                          : () {
                              provider.searchAndAdd(_searchController.text);
                              FocusScope.of(context).unfocus();
                            },
                    ),
                  ),
                  onSubmitted: (value) => provider.searchAndAdd(value),
                ),
              ),

              // Products list
              if (provider.hasProducts) ...[
                // Compare button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isComparing
                          ? null
                          : provider.generateComparison,
                      icon: provider.isComparing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.compare_arrows),
                      label: Text(
                        provider.isComparing
                            ? 'Comparing...'
                            : 'Compare ${provider.products.length} Products',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Verdict card
                if (provider.verdict != null) _buildVerdictCard(provider),

                // Product list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final product = provider.products[index];
                      return _buildComparisonItem(product, provider);
                    },
                  ),
                ),
              ] else
                const Expanded(
                  child: EmptyStateWidget(
                    icon: Icons.compare_arrows,
                    title: 'Compare Products',
                    subtitle:
                        'Search and add products to compare side-by-side',
                  ),
                ),

              // Error
              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerdictCard(CompareProvider provider) {
    final verdict = provider.verdict!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.green[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'AI Verdict',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(verdict.confidenceScore * 100).toStringAsFixed(0)}% confidence',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(verdict.overallRecommendation),
          const SizedBox(height: 8),
          if (verdict.bestPrice != null)
            _buildWinnerRow(
                '💰 Best Price', verdict.bestPrice!.name,
                '₹${verdict.bestPrice!.price.toStringAsFixed(0)}'),
          if (verdict.bestRating != null)
            _buildWinnerRow(
                '⭐ Best Rated', verdict.bestRating!.name,
                '${verdict.bestRating!.averageRating.toStringAsFixed(1)}★'),
          if (verdict.winnerProduct != null)
            _buildWinnerRow(
                '🏆 Overall Winner', verdict.winnerProduct!.name,
                verdict.winnerReason),
        ],
      ),
    );
  }

  Widget _buildWinnerRow(String label, String name, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          Text(detail,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(Product product, CompareProvider provider) {
    final isBest = provider.bestChoice?.name == product.name &&
        provider.bestChoice?.source == product.source;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isBest ? Colors.green[50] : null,
      child: ListTile(
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                color: Colors.grey[200],
                child: const Icon(Icons.shopping_bag),
              ),
            ),
            if (isBest)
              const Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.star, size: 18, color: Colors.green),
              ),
          ],
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '₹${product.price.toStringAsFixed(0)} • ${product.source ?? ""} '
          '• ${product.averageRating.toStringAsFixed(1)}★',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => provider.removeProduct(product),
        ),
      ),
    );
  }
}
