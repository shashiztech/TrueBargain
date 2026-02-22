import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Data
import 'data/product_database.dart';

// Models
import 'models/models.dart';

// Services
import 'services/services.dart';

// Providers
import 'providers/providers.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/compare_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';
import 'pages/product_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with GCP project truebargain-dcc83
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize core singletons
  final database = ProductDatabase();
  final connectivityService = ConnectivityService();
  final cacheService = CacheService();
  final configurationService = ConfigurationService();
  final apiKeyProvider = ApiKeyProvider();
  final httpClient = http.Client();

  // Populate API config from Firebase Remote Config → SecureStorage → defaults
  final apiConfig = await apiKeyProvider.populate(ApiConfiguration());

  // Initialize services
  final productDataService = ProductDataService(database);
  final favoritesService = FavoritesService(database);
  final productComparisonService = ProductComparisonService();
  final realEcommerceService =
      RealEcommerceService(httpClient, apiConfig, connectivityService);
  final ecommerceSearchService = EcommerceSearchService(
      httpClient, productDataService, realEcommerceService, apiConfig);

  // RapidAPI service — real e-commerce product search
  final rapidApiService =
      RapidApiService(httpClient, apiConfig, connectivityService);
  ecommerceSearchService.setRapidApiService(rapidApiService);

  final productGroupingService = ProductGroupingService();
  final analyticsService = AnalyticsService(database);
  final aiRecommendationService =
      AIRecommendationService(ecommerceSearchService, analyticsService);
  final enhancedComparisonService =
      EnhancedComparisonService(aiRecommendationService, configurationService);
  final priceHistoryService = PriceHistoryService(database);
  final productAlertService = ProductAlertService(database);

  // Affiliate link service — appends associate IDs to product URLs
  final affiliateLinkService = AffiliateLinkService(apiConfig);

  runApp(
    MultiProvider(
      providers: [
        // Singleton services
        Provider<ProductDatabase>.value(value: database),
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<CacheService>.value(value: cacheService),
        Provider<ConfigurationService>.value(value: configurationService),
        Provider<ApiKeyProvider>.value(value: apiKeyProvider),
        Provider<ApiConfiguration>.value(value: apiConfig),

        // Scoped services
        Provider<ProductDataService>.value(value: productDataService),
        Provider<FavoritesService>.value(value: favoritesService),
        Provider<ProductComparisonService>.value(
            value: productComparisonService),
        Provider<RealEcommerceService>.value(value: realEcommerceService),
        Provider<RapidApiService>.value(value: rapidApiService),
        Provider<EcommerceSearchService>.value(value: ecommerceSearchService),
        Provider<ProductGroupingService>.value(value: productGroupingService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<AIRecommendationService>.value(
            value: aiRecommendationService),
        Provider<EnhancedComparisonService>.value(
            value: enhancedComparisonService),
        Provider<PriceHistoryService>.value(value: priceHistoryService),
        Provider<ProductAlertService>.value(value: productAlertService),
        Provider<AffiliateLinkService>.value(value: affiliateLinkService),

        // Firebase Analytics
        Provider<FirebaseAnalytics>.value(
            value: FirebaseAnalytics.instance),

        // State providers (ChangeNotifier)
        ChangeNotifierProvider(
          create: (_) => HomeProvider(
            searchService: ecommerceSearchService,
            groupingService: productGroupingService,
            aiRecommendation: aiRecommendationService,
            cacheService: cacheService,
            analyticsService: analyticsService,
            connectivityService: connectivityService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CompareProvider(
            searchService: ecommerceSearchService,
            aiRecommendation: aiRecommendationService,
            comparisonService: productComparisonService,
            groupingService: productGroupingService,
            enhancedComparison: enhancedComparisonService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(
            favoritesService: favoritesService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            configService: configurationService,
            apiKeyProvider: apiKeyProvider,
          ),
        ),
      ],
      child: const TrueBargainApp(),
    ),
  );
}

class TrueBargainApp extends StatelessWidget {
  const TrueBargainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'True Bargain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppShell(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/product-detail':
            final product = settings.arguments as Product;
            return MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: product),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const AppShell(),
            );
        }
      },
    );
  }
}

/// Bottom navigation shell
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    ComparePage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
