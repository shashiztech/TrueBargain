import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('TrueBargain'),
            actions: [
              IconButton(
                icon: Icon(
                  provider.isNlpMode ? Icons.auto_awesome : Icons.search,
                ),
                tooltip: provider.isNlpMode
                    ? 'Natural Language Mode'
                    : 'Standard Mode',
                onPressed: provider.toggleNlpMode,
              ),
              IconButton(
                icon: Icon(
                  provider.isGroupedView
                      ? Icons.view_list
                      : Icons.grid_view,
                ),
                onPressed: provider.toggleGroupedView,
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              _buildSearchBar(provider),

              // Filter chips
              _buildFilterChips(provider),

              // Connectivity warning
              if (!provider.isConnected)
                Container(
                  width: double.infinity,
                  color: Colors.orange[100],
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Offline — showing cached results',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),

              // AI Recommendation
              if (provider.aiRecommendationText != null)
                Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.aiRecommendationText!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Results
              Expanded(child: _buildResults(provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: provider.isNlpMode
              ? 'Try: "best Samsung phone under ₹30000"'
              : 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearResults();
                  },
                ),
              IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.setQuery(_searchController.text);
                        provider.search();
                        FocusScope.of(context).unfocus();
                      },
              ),
            ],
          ),
        ),
        onChanged: (value) {
          provider.setQuery(value);
          if (value.length >= 3) {
            provider.searchDebounced();
          }
        },
        onSubmitted: (_) {
          provider.search();
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildFilterChips(HomeProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Sort
          DropdownButton<SearchSortOrder>(
            value: provider.sortOrder,
            underline: const SizedBox(),
            isDense: true,
            items: SearchSortOrder.values.map((order) {
              return DropdownMenuItem(
                value: order,
                child: Text(_sortOrderLabel(order),
                    style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) provider.setSortOrder(v);
            },
          ),
          const SizedBox(width: 8),

          // Source filter
          DropdownButton<EcommerceSource>(
            value: provider.sourceFilter,
            underline: const SizedBox(),
            isDense: true,
            items: [
              EcommerceSource.all,
              EcommerceSource.amazon,
              EcommerceSource.flipkart,
              EcommerceSource.walmart,
              EcommerceSource.bestBuy,
              EcommerceSource.myntra,
              EcommerceSource.croma,
            ].map((source) {
              return DropdownMenuItem(
                value: source,
                child: Text(_sourceLabel(source),
                    style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) provider.setSourceFilter(v);
            },
          ),
          const SizedBox(width: 8),

          if (provider.sortOrder != SearchSortOrder.relevance ||
              provider.sourceFilter != EcommerceSource.all)
            TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(HomeProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: provider.errorMessage,
        action: ElevatedButton(
          onPressed: provider.search,
          child: const Text('Retry'),
        ),
      );
    }

    if (!provider.hasResults) {
      return const EmptyStateWidget(
        icon: Icons.search,
        title: 'Search for Products',
        subtitle:
            'Compare prices across Amazon, Flipkart, Walmart and more',
      );
    }

    if (provider.isGroupedView && provider.groupedResults.isNotEmpty) {
      return _buildGroupedView(provider);
    }

    return _buildFlatView(provider);
  }

  Widget _buildGroupedView(HomeProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.groupedResults.length,
      itemBuilder: (context, index) {
        final group = provider.groupedResults[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(ProductGroupViewModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          group.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '₹${group.minPrice.toStringAsFixed(0)} - ₹${group.maxPrice.toStringAsFixed(0)} '
          '• ${group.sources.length} sources '
          '• ${group.averageRating.toStringAsFixed(1)}★',
          style: const TextStyle(fontSize: 12),
        ),
        children: group.productVariants.map((variant) {
          return ProductListTile(
            product: variant.product,
            subtitle:
                '₹${variant.price.toStringAsFixed(0)} on ${variant.source}',
            onTap: () => _navigateToDetail(variant.product),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlatView(HomeProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final product = provider.searchResults[index];
        return ProductCard(
          product: product,
          onTap: () => _navigateToDetail(product),
        );
      },
    );
  }

  void _navigateToDetail(Product product) {
    Navigator.pushNamed(context, '/product-detail', arguments: product);
  }

  String _sortOrderLabel(SearchSortOrder order) {
    switch (order) {
      case SearchSortOrder.relevance:
        return 'Relevance';
      case SearchSortOrder.priceLowToHigh:
        return 'Price ↑';
      case SearchSortOrder.priceHighToLow:
        return 'Price ↓';
      case SearchSortOrder.ratingHighToLow:
        return 'Rating ↓';
      case SearchSortOrder.mostReviews:
        return 'Reviews';
      case SearchSortOrder.newest:
        return 'Newest';
    }
  }

  String _sourceLabel(EcommerceSource source) {
    switch (source) {
      case EcommerceSource.all:
        return 'All Sources';
      case EcommerceSource.amazon:
        return 'Amazon';
      case EcommerceSource.flipkart:
        return 'Flipkart';
      case EcommerceSource.walmart:
        return 'Walmart';
      case EcommerceSource.bestBuy:
        return 'Best Buy';
      case EcommerceSource.myntra:
        return 'Myntra';
      case EcommerceSource.croma:
        return 'Croma';
      default:
        return source.name;
    }
  }
}
