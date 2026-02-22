import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/home_provider.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';
import '../services/affiliate_link_service.dart';

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
            title: const Text('True Bargain'),
            actions: [
              // Country selector
              TextButton.icon(
                onPressed: () => _showCountryPicker(provider),
                icon: const Icon(Icons.location_on, size: 18, color: Colors.white),
                label: Text(
                  provider.searchCountryName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              IconButton(
                icon: Icon(
                  provider.isGroupedView ? Icons.grid_view : Icons.view_list,
                ),
                onPressed: provider.toggleGroupedView,
                tooltip: provider.isGroupedView ? 'Grid view' : 'List view',
              ),
            ],
          ),
          body: Column(
            children: [
              // Location prompt
              if (provider.showLocationPrompt) _buildLocationPrompt(provider),

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
                      Text('Offline — connect to Internet to search',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),

              // AI Recommendation
              if (provider.aiRecommendationText != null &&
                  provider.hasResults)
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

              // Results or empty state
              Expanded(child: _buildResultsOrEmpty(provider)),
            ],
          ),
        );
      },
    );
  }

  // ──── Location prompt banner ────
  Widget _buildLocationPrompt(HomeProvider provider) {
    return Container(
      width: double.infinity,
      color: Colors.blue[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Set your location for local product results',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _showCountryPicker(provider),
            child: const Text('Set', style: TextStyle(fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: provider.dismissLocationPrompt,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ──── Country picker dialog ────
  void _showCountryPicker(HomeProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select your country'),
        children: HomeProvider.countries.entries.map((entry) {
          final isSelected = entry.key == provider.searchCountry;
          return SimpleDialogOption(
            onPressed: () {
              provider.setCountry(entry.key);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Text(entry.value,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    )),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ──── Search bar ────
  Widget _buildSearchBar(HomeProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products in ${provider.searchCountryName}...',
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
        onSubmitted: (_) => provider.search(),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  // ──── Filter chips ────
  Widget _buildFilterChips(HomeProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

  // ──── Results or empty state ────
  Widget _buildResultsOrEmpty(HomeProvider provider) {
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
      return _buildEmptyWithRecent(provider);
    }

    if (provider.isGroupedView) {
      return _buildGroupedView(provider);
    }

    return _buildFlatView(provider);
  }

  // ──── Empty state with recent searches ────
  Widget _buildEmptyWithRecent(HomeProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.search, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Search for Products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Compare prices across Amazon, Flipkart, eBay and more '
            'in ${provider.searchCountryName}',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (provider.recentSearches.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Recent Searches',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                TextButton(
                  onPressed: provider.clearRecentSearches,
                  child:
                      const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.recentSearches.map((q) {
                return ActionChip(
                  label: Text(q, style: const TextStyle(fontSize: 13)),
                  onPressed: () {
                    _searchController.text = q;
                    provider.setQuery(q);
                    provider.search();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ──── Grouped view ────
  Widget _buildGroupedView(HomeProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.groupedResults.length,
      itemBuilder: (context, index) {
        final group = provider.groupedResults[index];
        return _buildGroupCard(group, provider);
      },
    );
  }

  Widget _buildGroupCard(ProductGroupViewModel group, HomeProvider provider) {
    final affiliateService = context.read<AffiliateLinkService>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: group.productVariants.isNotEmpty &&
                group.productVariants.first.product.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl:
                        group.productVariants.first.product.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.shopping_bag, size: 24),
                    ),
                  ),
                ),
              )
            : null,
        title: Text(
          group.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '₹${group.minPrice.toStringAsFixed(0)} - ₹${group.maxPrice.toStringAsFixed(0)} '
          '• ${group.sources.length} sources '
          '• ${group.averageRating.toStringAsFixed(1)}★',
          style: const TextStyle(fontSize: 12),
        ),
        children: group.productVariants.map((variant) {
          final priceChange =
              provider.getPriceChangeText(variant.product);
          return ListTile(
            leading: _buildThumbnail(variant.product.imageUrl, 44),
            title: Text(variant.product.name,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${variant.price.toStringAsFixed(0)} on ${variant.source}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (priceChange != null)
                  Text(
                    priceChange,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: provider.isPriceDrop(variant.product)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () =>
                  affiliateService.openProductUrl(variant.product),
            ),
            onTap: () => affiliateService.openProductUrl(variant.product),
          );
        }).toList(),
      ),
    );
  }

  // ──── Flat grid view with thumbnails ────
  Widget _buildFlatView(HomeProvider provider) {
    final affiliateService = context.read<AffiliateLinkService>();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final product = provider.searchResults[index];
        final priceChange = provider.getPriceChangeText(product);
        final isDrop = provider.isPriceDrop(product);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => affiliateService.openProductUrl(product),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image thumbnail
                  _buildThumbnail(product.imageUrl, 80),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Source + Brand
                        Text(
                          [product.source, product.brand]
                              .where((s) => s != null)
                              .join(' • '),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),

                        // Price row
                        Row(
                          children: [
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (product.averageRating > 0) ...[
                              Icon(Icons.star,
                                  size: 14, color: Colors.amber[700]),
                              Text(
                                ' ${product.averageRating.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),

                        // Price change badge
                        if (priceChange != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDrop
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDrop
                                    ? Colors.green[300]!
                                    : Colors.red[300]!,
                              ),
                            ),
                            child: Text(
                              priceChange,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDrop
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Buy button
                  if (product.productUrl != null)
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () =>
                              affiliateService.openProductUrl(product),
                          tooltip: 'Buy',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ──── Thumbnail helper ────
  Widget _buildThumbnail(String? imageUrl, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.shopping_bag,
                      size: 24, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.shopping_bag,
                    size: 24, color: Colors.grey),
              ),
      ),
    );
  }

  // ──── Labels ────
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
