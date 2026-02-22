# TrueBargain — Technical Implementation Reference

> **Last updated:** Iteration 11 (full rewrite — reflects all implemented code)
>
> This document is the single source of truth for developers. It covers every implemented file, class, interface, method, DI registration, database schema, platform configuration, and build setting currently in the codebase.



Section	Content
1 — Overview	App purpose, core principles, target platforms
2 — Tech Stack	All 10 NuGet packages with versions and purpose
3 — Project Structure	Full annotated directory tree
4 — Storage Strategy	5-layer storage map (SQLite / JSON cache / JSON config / SecureStorage / env vars)
5 — Database Schema	All 5 SQLite tables with every column, type, and constraint
6 — DI Registration	Every Singleton / Scoped / Transient registration with interface→implementation mapping
7 — Models	All 6 model files, every class, enum, and key property
8 — Services	All 21 services — constructor deps, DI scope, every public method with return type
9 — ViewModels	All 9 ViewModels — constructor deps, commands, collections, computed properties
10 — Pages	All 6 pages — ViewModel resolution chains and fallback logic
11 — Converters	All 9 converters with input/output/use
12 — Platform Config	Android, iOS, macOS, Windows permissions and manifest entries
13 — Build Config	Trimming, AOT, platform release settings, LinkerConfig.xml preservation rules
14 — API Keys	All 22 TB_* keys with ApiConfiguration property mapping + runtime usage examples
15 — Markets	10 Indian + 5 global platforms, mock catalog description
16 — Call Graphs	DI registration tree, search call chain, price alert check chain
17 — Production Readiness	Status table for 24 areas (PRODUCTION / COMPLETE / PENDING / STUB)
18 — Deployment	Step-by-step for Android/iOS/Windows/macOS + pre-publish checklist
19 — Known Issues	9 actionable cleanup items with file references

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack & Dependencies](#2-technology-stack--dependencies)
3. [Project Structure](#3-project-structure)
4. [Storage & Security Strategy](#4-storage--security-strategy)
5. [Database Schema](#5-database-schema)
6. [Dependency Injection Registration](#6-dependency-injection-registration)
7. [Models Reference](#7-models-reference)
8. [Services Reference](#8-services-reference)
9. [ViewModels Reference](#9-viewmodels-reference)
10. [Pages & Views Reference](#10-pages--views-reference)
11. [Converters Reference](#11-converters-reference)
12. [Platform Configuration](#12-platform-configuration)
13. [Build & Release Configuration](#13-build--release-configuration)
14. [API Key Management](#14-api-key-management)
15. [Supported Markets & Platforms](#15-supported-markets--platforms)
16. [Dependency & Call Graphs](#16-dependency--call-graphs)
17. [Production Readiness Status](#17-production-readiness-status)
18. [Deployment Guide](#18-deployment-guide)
19. [Known Issues & Cleanup Candidates](#19-known-issues--cleanup-candidates)

---

## 1. Project Overview

**TrueBargain** is a cross-platform .NET MAUI price-comparison app. Users search for a product and the app aggregates results from multiple e-commerce platforms, groups variants by model, and presents the best deal with AI-assisted verdicts.

**Core Principles:**
- No external/cloud database — all data is stored 100% on-device
- Works offline with cached results; guards all network calls
- Supports Indian and global e-commerce platforms
- Production-ready security: API keys in device SecureStorage, never in source

**Target Platforms:** Android 5.0+ · iOS 15+ · macOS Catalyst 15+ · Windows 10 (1809+)

---

## 2. Technology Stack & Dependencies

### Runtime Framework
| Item | Value |
|------|-------|
| SDK | .NET 9.0 MAUI |
| UI Framework | Microsoft.Maui.Controls (MauiVersion) |
| MVVM Pattern | Manual (BaseViewModel + INotifyPropertyChanged) |
| DI Container | Microsoft.Extensions.DependencyInjection (built into MAUI) |

### NuGet Packages
| Package | Version | Purpose |
|---------|---------|---------|
| `Microsoft.Maui.Controls` | `$(MauiVersion)` | Core MAUI UI and navigation |
| `Microsoft.Maui.Essentials` | `9.0.111` | Device APIs: Connectivity, Geolocation, SecureStorage, FileSystem, Browser |
| `Microsoft.Extensions.Http` | `9.0.8` | IHttpClientFactory for pooled HTTP connections |
| `Microsoft.Extensions.Logging.Abstractions` | `9.0.8` | ILogger<T> interface |
| `Microsoft.Extensions.Logging.Debug` | `9.0.8` | Debug-window log sink |
| `sqlite-net-pcl` | `1.9.172` | Async SQLite ORM (attribute-driven) |
| `SQLitePCLRaw.bundle_green` | `2.1.10` | Native SQLite bindings for all 4 platforms |
| `CommunityToolkit.Mvvm` | `8.3.2` | Source generator helpers (optional use) |
| `HtmlAgilityPack` | `1.12.1` | HTML DOM parsing for WebScrapingService |
| `System.Text.Json` | `9.0.0` | JSON serialization for cache and config files |

---

## 3. Project Structure

```
TrueBargain/
├── MauiProgram.cs                   — App bootstrap & DI container
├── App.xaml / App.xaml.cs           — Application lifecycle, global exception handlers
├── AppShell.xaml / AppShell.xaml.cs — Shell navigation root
├── Constants.cs                     — DatabasePath constant
│
├── Models/
│   ├── Product.cs                   — SQLite Product entity
│   ├── ProductComparison.cs         — Comparison result + SearchFilter DTO
│   ├── SearchModels.cs              — SearchRequest, SearchResult, enums
│   ├── ConfigurationModels.cs       — Config, website, alert, country, user prefs models
│   ├── EnhancedModels.cs            — Extended domain: tiers, grouping, locations, variants
│   └── AdvancedModels.cs            — SQLite-mapped entities + ApiConfiguration
│
├── Data/
│   └── ProductDatabase.cs           — SQLite async wrapper — 5 tables, thread-safe init
│
├── Services/
│   ├── ApiKeyProvider.cs            — Resolves API keys from SecureStorage / env vars
│   ├── ConfigurationService.cs      — User prefs & e-commerce config (JSON persistence)
│   ├── ConnectivityService.cs       — MAUI Connectivity wrapper (online/offline)
│   ├── CacheService.cs              — File-system JSON search cache (SHA-256 keyed)
│   ├── ProductDataService.cs        — CRUD abstraction over ProductDatabase
│   ├── FavoritesService.cs          — Favorites CRUD backed by SQLite Favorites table
│   ├── ProductComparisonService.cs  — In-memory comparison scoring
│   ├── ComparisonService.cs         — Comparison lists, AI verdict, sharing
│   ├── EcommerceSearchService.cs    — Multi-platform search orchestration
│   ├── RealEcommerceService.cs      — Per-platform search (real API + mock fallback)
│   ├── WebScrapingService.cs        — HTML scraping via HtmlAgilityPack
│   ├── PublicSearchService.cs       — Public search engine aggregation
│   ├── EnhancedComparisonService.cs — AI-assisted verdict + scoring
│   ├── ProductGroupingService.cs    — Groups product variants by model/brand/category
│   ├── AIRecommendationService.cs   — NLP parsing, recommendations, behavioral learning
│   ├── LocalizationService.cs       — Region detection, currency conversion, localized search
│   ├── LocationService.cs           — MAUI Geolocation + reverse geocoding
│   ├── LocalStoreService.cs         — Nearby store inventory search
│   ├── PriceAlertService.cs         — Simple in-memory price alert management
│   ├── PremiumAlertService.cs       — Multi-source premium alerts + IPremiumNotificationService
│   └── AdvancedServices.cs          — PriceHistoryService, ProductAlertService, AnalyticsService
│
├── ViewModels/
│   ├── BaseViewModel.cs             — INotifyPropertyChanged base
│   ├── HomeViewModel.cs             — Basic local-DB search
│   ├── EnhancedHomeViewModel.cs     — Full multi-source search with grouping & caching
│   ├── SuperEnhancedHomeViewModel.cs — NLP search + analytics + personalization
│   ├── CompareViewModel.cs          — Simple comparison list
│   ├── EnhancedCompareViewModel.cs  — AI-assisted comparison with best-choice ribbon
│   ├── FavoritesViewModel.cs        — Favorites list with price-drop badges
│   ├── SettingsViewModel.cs         — Settings MVVM abstraction
│   └── ProductDetailViewModel.cs    — Product detail: AI summary, price history, alerts
│
├── Converters/
│   ├── UIConverters.cs              — 7 IValueConverter implementations
│   ├── NotNullConverter.cs          — Returns true when value is non-null
│   └── NotNullToBoolConverter.cs    — Obsolete wrapper → delegates to NotNullConverter
│
├── HomePage.xaml / .cs
├── ComparePage.xaml / .cs
├── FavoritesPage.xaml / .cs
├── SettingsPage.xaml / .cs
├── ProductDetailPage.xaml / .cs
├── MainPage.xaml / .cs              — Legacy counter demo page
│
├── Platforms/
│   ├── Android/AndroidManifest.xml
│   ├── iOS/Info.plist
│   ├── MacCatalyst/Info.plist + Entitlements.plist
│   └── Windows/Package.appxmanifest
│
├── LinkerConfig.xml                 — IL Linker preservation rules
├── TrueBargain.csproj
└── TrueBargain.sln
```

---

## 4. Storage & Security Strategy

TrueBargain uses **no external or cloud database**. All persistence is device-native.

| Layer | Mechanism | Location | Contents |
|-------|-----------|----------|----------|
| Structured data | SQLite (`sqlite-net-pcl`) | `AppDataDirectory/products.db3` | Products, Favorites, PriceHistory, ProductAlerts, SearchAnalytics |
| Search cache | JSON files | `CacheDirectory/search_cache/` | Serialized `List<Product>`, named by SHA-256 hash |
| User config & prefs | JSON files | `AppDataDirectory/` | EcommerceConfiguration, UserPreferences |
| API keys & secrets | MAUI `SecureStorage` | Platform hardware keystore | API keys, affiliate IDs — hardware-backed on Android/iOS |
| Fallback key source | Environment variables | Process environment | `TB_*` named variables for CI/server provisioning |

---

## 5. Database Schema

**File:** `Data/ProductDatabase.cs`
**Connection type:** `SQLiteAsyncConnection`
**Thread safety:** `SemaphoreSlim` guard on first-run `CreateTableAsync` calls

### Tables

#### Products `[Table("Products")]` — `Models/Product.cs`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PrimaryKey, AutoIncrement |
| Name | string | MaxLength(250), NotNull |
| Type | string | MaxLength(100) |
| SKU | string | MaxLength(100) |
| Price | decimal | |
| NumberOfRatings | int | |
| AverageRating | double | |
| Source | string | MaxLength(100) |
| Description | string | MaxLength(1000) |
| ImageUrl | string | MaxLength(500) |
| Brand | string | MaxLength(100) |
| Category | string | MaxLength(100) |
| DateAdded | DateTime | |
| IsFavorite | bool | |
| ProductUrl | string | MaxLength(500) |
| ComparisonScore | double | `[Ignore]` — transient, computed at runtime |

> **Note:** `[Unique]` was intentionally removed from `SKU` to prevent duplicate-key errors when mock data generators produce the same SKU from different platform sources.

#### Favorites `[Table("Favorites")]` — `Models/AdvancedModels.cs:FavoriteItem`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PrimaryKey, AutoIncrement |
| ProductIdentifier | string | MaxLength(400) — `"{Name}\|{Source}"` |
| ProductName | string | MaxLength(250) |
| Brand | string | MaxLength(100) |
| Category | string | MaxLength(100) |
| Source | string | MaxLength(100) |
| Price | decimal | Current price at query time |
| PriceAtSave | decimal | Price when user saved — used for price-drop badges |
| AverageRating | double | |
| NumberOfRatings | int | |
| ProductUrl | string | MaxLength(500) |
| ImageUrl | string | MaxLength(500) |
| Description | string | MaxLength(1000) |
| SavedAt | DateTime | |

**Static helper:** `FavoriteItem.BuildIdentifier(name, source)` → `"{name}|{source}"` (deduplication key)

#### PriceHistory `[Table("PriceHistory")]` — `Models/AdvancedModels.cs:PriceHistoryEntry`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PrimaryKey, AutoIncrement |
| ProductIdentifier | string | MaxLength(400) |
| ProductName | string | MaxLength(250) |
| Price | decimal | |
| Currency | string | MaxLength(10) |
| Source | string | MaxLength(100) |
| RecordedAt | DateTime | |

**Retention:** Auto-purged after 90 days (`PurgePriceHistoryOlderThanAsync`)

#### ProductAlerts `[Table("ProductAlerts")]` — `Models/AdvancedModels.cs:ProductAlertEntry`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PrimaryKey, AutoIncrement |
| ProductIdentifier | string | MaxLength(400) |
| ProductName | string | MaxLength(250) |
| Category | string | MaxLength(100) |
| TargetPrice | decimal | |
| LastKnownPrice | decimal | |
| IsActive | bool | |
| IsCategory | bool | Category-wide alert flag |
| CreatedAt | DateTime | |
| LastCheckedAt | DateTime? | |
| LastNotifiedAt | DateTime? | |

#### SearchAnalytics `[Table("SearchAnalytics")]` — `Models/AdvancedModels.cs:SearchAnalyticsEntry`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PrimaryKey, AutoIncrement |
| Query | string | MaxLength(500) |
| ResultCount | int | |
| ResponseMs | double | |
| Region | string | MaxLength(100) |
| SortOrder | string | MaxLength(50) |
| SearchedAt | DateTime | |

**Retention:** Auto-purged after 30 days (`PurgeOldAnalyticsAsync` — called probabilistically on insert)

---

## 6. Dependency Injection Registration

All registrations are in `MauiProgram.CreateMauiApp()`.

### Singleton (one instance per app lifetime)
| Interface | Implementation | Notes |
|-----------|----------------|-------|
| — | `ProductDatabase` | SQLite connection; path from `Constants.DatabasePath` |
| `IConnectivityService` | `ConnectivityService` | MAUI Connectivity wrapper; subscribes to connectivity events |
| `ICacheService` | `CacheService` | File-system JSON search cache |
| `IConfigurationService` | `ConfigurationService` | User prefs + e-commerce config (JSON files) |
| `IApiKeyProvider` | `ApiKeyProvider` | SecureStorage / env-var key resolution |
| — | `ApiConfiguration` | Populated by `ApiKeyProvider.Populate()` at startup |

### Scoped (new instance per DI scope)
| Interface | Implementation |
|-----------|----------------|
| `IProductDataService` | `ProductDataService` |
| `IFavoritesService` | `FavoritesService` |
| `IProductComparisonService` | `ProductComparisonService` |
| `IRealEcommerceService` | `RealEcommerceService` |
| `IEcommerceSearchService` | `EcommerceSearchService` |
| `IWebScrapingService` | `WebScrapingService` |
| `IPublicSearchService` | `PublicSearchService` |
| `IEnhancedComparisonService` | `EnhancedComparisonService` |
| `IProductGroupingService` | `ProductGroupingService` |
| `ILocalizationService` | `LocalizationService` |
| `ILocalStoreService` | `LocalStoreService` |
| `ILocationService` | `LocationService` |
| `INotificationService` | `NotificationService` (stub — platform TODO) |
| `IPremiumAlertService` | `PremiumAlertService` |
| `IPriceHistoryService` | `PriceHistoryService` |
| `IProductAlertService` | `ProductAlertService` |
| `IAnalyticsService` | `AnalyticsService` |
| `IAIRecommendationService` | `AIRecommendationService` |
| — | `SettingsViewModel` |
| — | `FavoritesViewModel` |
| — | `EnhancedHomeViewModel` |
| — | `EnhancedCompareViewModel` |
| — | `ProductDetailViewModel` |
| — | `SuperEnhancedHomeViewModel` |

### Transient (new instance every time)
| Type | Notes |
|------|-------|
| `HttpClient` | Bridge from `IHttpClientFactory.CreateClient("TrueBargain")` — ensures connection pooling |
| `HomePage` | Page |
| `ComparePage` | Page |
| `SettingsPage` | Page |
| `ProductDetailPage` | Page |
| `FavoritesPage` | Page |

---

## 7. Models Reference

### `Models/Product.cs`
**Namespace:** `TrueBargain.Models`
**SQLite table:** `Products`

Core entity representing a product from any e-commerce source. `ComparisonScore` is a transient `[Ignore]` property computed at runtime during sorting/comparison.

---

### `Models/ProductComparison.cs`
**Classes:**
- **`ProductComparison`** — Result of a comparison operation: `List<Product> Products`, `Product? BestMatch`, `string ComparisonCriteria`, `DateTime ComparisonDate`
- **`SearchFilter`** — Filter DTO: Name, Type, Brand, Category, MinPrice, MaxPrice, MinRating, MaxRating, Source

---

### `Models/SearchModels.cs`
**Enums:**
- **`SearchSortOrder`** — `Relevance | PriceLowToHigh | PriceHighToLow | RatingHighToLow | MostReviews | Newest`
- **`EcommerceSource`** — `All | Amazon | Flipkart | Walmart | BestBuy | Target | Local`

**Classes:**
- **`SearchRequest`** — Query + filters: Query, SortOrder, Source, MinPrice, MaxPrice, MinRating, Category, Brand, `MaxResults` (default 50)
- **`SearchResult`** — Output: `List<Product> Products`, TotalCount, Query, SearchDuration, `Dictionary<EcommerceSource,int> SourceCounts`

---

### `Models/ConfigurationModels.cs`
| Class | Purpose |
|-------|---------|
| `EcommerceConfiguration` | Country, Currency, website list, feature toggles (scraping, local stores, public APIs) |
| `EcommerceWebsite` | Name, BaseUrl, SearchUrlPattern, IsEnabled, ScrapingConfiguration |
| `ScrapingConfiguration` | CSS selectors for all product fields, request headers, delay, JavaScript flag |
| `WebsiteType` (enum) | `GeneralEcommerce \| ElectronicsSpecialist \| GroceryDelivery \| LocalRetail \| PriceComparison \| Marketplace` |
| `CountrySettings` | CountryCode, CountryName, Currency, CurrencySymbol, TimeZone, TaxRate |
| `UserPreferences` | UserId, location (PostalCode/City/Coordinates), CountrySettings, PreferredCategories, PreferredBrands, MaxBudget (default ₹50,000), IsPremiumUser |
| `PriceAlert` (legacy) | In-memory alert model used by `PriceAlertService` and `PremiumAlertService` |
| `ComparisonVerdict` | WinnerProduct, WinnerReason, BestPrice, BestRating, ProsAndCons, OverallRecommendation, ConfidenceScore |

---

### `Models/EnhancedModels.cs`
| Class / Enum | Purpose |
|-------------|---------|
| `UserTier` (enum) | `Free \| Premium \| Enterprise` |
| `SearchEngineType` (enum) | `Google \| Bing \| DuckDuckGo \| PriceComparison \| Direct` |
| `ComparisonCriteria` (enum) | `BestValue \| LowestPrice \| HighestRating \| MostReviews \| BestFeatures \| BrandReputation` |
| `AlertType` (enum) | `PriceAlert \| StockAlert \| AIComparison` |
| `ProductGroupingType` (enum) | `ExactMatch \| ModelMatch \| CategoryMatch \| BrandMatch` |
| `UserProfile` | Full user profile with Tier, location, currency/language preferences, location tracking consent |
| `CountryInfo` | Code, Name, Currency, Flag, Languages, PopularEcommerceSites |
| `LocationInfo` | Country, Region, City, PostalCode, Lat/Lng, IsAutoDetected |
| `LocalizedSearchRequest` | Extends `SearchRequest` with Country, Region, Currency, Language, IncludeLocalStores, UsePublicEndpoints, UserTier |
| `EnhancedProductComparison` | Products list with BestOverall/BestPrice/BestRating/BestValue, AIVerdict, IsAIGenerated |
| `ProductGroupViewModel` | Display model mapping a product group to UI: GroupName, Brand, ModelName, ProductVariants, price range, sources, ratings |
| `ProductVariant` | Individual variant within a group: Product, Source, Price, IsInStock, StoreRating, PriceChangeIndicator |
| `GroupedSearchResult` | Top-level grouped search output: SearchQuery, ProductGroups, SourceCounts, BrandCounts, CategoryCounts |

---

### `Models/AdvancedModels.cs`
| Class | Type | Purpose |
|-------|------|---------|
| `ApiConfiguration` | Config (DI Singleton) | API keys + affiliate IDs for 14 platforms, UseRealApis flag, MaxRetryAttempts, RetryDelayMilliseconds |
| `FavoriteItem` | SQLite `[Table("Favorites")]` | Persistent favorite with price snapshot |
| `PriceHistoryEntry` | SQLite `[Table("PriceHistory")]` | One price observation per product per timestamp |
| `ProductAlertEntry` | SQLite `[Table("ProductAlerts")]` | DB-backed price-drop alert |
| `SearchAnalyticsEntry` | SQLite `[Table("SearchAnalytics")]` | Persisted search telemetry |
| `PriceHistory` | In-memory (legacy) | Used by legacy `PriceHistoryService.GetPriceHistoryAsync(int)` |
| `ProductAlert` | In-memory (legacy) | Used by legacy `ProductAlertService` before DB migration |
| `SearchAnalytics` | In-memory (legacy) | Used by legacy `AnalyticsService.RecordSearchAsync` |

---

## 8. Services Reference

### `ApiKeyProvider` (`IApiKeyProvider`)
**DI Scope:** Singleton
**Purpose:** Populates `ApiConfiguration` from SecureStorage → Environment variables → defaults
**Method:** `Populate(ApiConfiguration config) → ApiConfiguration`
**Key naming convention:** `TB_{PLATFORM}_{TYPE}` (e.g., `TB_AMAZON_API_KEY`, `TB_FLIPKART_AFFIL_ID`)

See [Section 14](#14-api-key-management) for the full key list.

---

### `ConfigurationService` (`IConfigurationService`)
**DI Scope:** Singleton
**Persistence:** JSON files in `FileSystem.AppDataDirectory`
**Methods:**

| Method | Returns |
|--------|---------|
| `GetConfigurationAsync(string countryCode)` | `Task<EcommerceConfiguration>` |
| `GetSupportedCountriesAsync()` | `Task<List<CountrySettings>>` |
| `GetUserPreferencesAsync()` | `Task<UserPreferences>` |
| `SaveUserPreferencesAsync(UserPreferences)` | `Task` |
| `GetWebsitesForCountryAsync(string)` | `Task<List<EcommerceWebsite>>` |
| `UpdateWebsiteConfigurationAsync(string, List<EcommerceWebsite>)` | `Task` |

**Default country:** India (`IN`). Default websites seeded: Amazon India, Flipkart, Myntra, BigBasket, Swiggy, Blinkit.

---

### `ConnectivityService` (`IConnectivityService`)
**DI Scope:** Singleton
**Constructor:** `ILogger<ConnectivityService>`
**Properties:** `bool IsConnected`, `bool IsOnWifi`
**Events:** `EventHandler<bool> ConnectivityChanged`
**Notes:** Wraps `Connectivity.Current`; subscribes to system connectivity change events; safe fallback on desktop (always connected).

---

### `CacheService` (`ICacheService`)
**DI Scope:** Singleton
**Constructor:** `ILogger<CacheService>`
**Cache directory:** `FileSystem.CacheDirectory/search_cache/`
**Key algorithm:** SHA-256 of `query+region+sortOrder` → 24-char hex string

| Method | Returns |
|--------|---------|
| `GetCachedSearchAsync(key, maxAge)` | `Task<List<Product>?>` — null if missing or expired |
| `SetCachedSearchAsync(key, products)` | `Task` |
| `PurgeExpiredCacheAsync(maxAge)` | `Task` |
| `ClearAllCacheAsync()` | `Task` |
| `BuildCacheKey(query, region, sortOrder)` | `string` |

---

### `ProductDataService` (`IProductDataService`)
**DI Scope:** Scoped
**Constructor:** `ProductDatabase`, `ILogger<ProductDataService>`

| Method | Returns |
|--------|---------|
| `GetAllProductsAsync()` | `Task<List<Product>>` |
| `GetProductByIdAsync(int id)` | `Task<Product?>` |
| `SearchProductsAsync(SearchFilter)` | `Task<List<Product>>` |
| `SaveProductAsync(Product)` | `Task<int>` |
| `DeleteProductAsync(Product)` | `Task<int>` |
| `GetFavoriteProductsAsync()` | `Task<List<Product>>` (projects FavoriteItem → Product for legacy callers) |

---

### `FavoritesService` (`IFavoritesService`)
**DI Scope:** Scoped
**Constructor:** `ProductDatabase`, `ILogger<FavoritesService>`

| Method | Returns |
|--------|---------|
| `GetFavoritesAsync()` | `Task<List<FavoriteItem>>` |
| `IsFavoriteAsync(productName, source)` | `Task<bool>` |
| `AddFavoriteAsync(Product)` | `Task<FavoriteItem?>` — snapshots price at save time |
| `RemoveFavoriteAsync(productName, source)` | `Task<bool>` |
| `ToggleFavoriteAsync(Product)` | `Task<bool>` — adds if missing, removes if present |
| `GetFavoriteCountAsync()` | `Task<int>` |

---

### `ProductComparisonService` (`IProductComparisonService`)
**DI Scope:** Scoped
**Constructor:** (none)
**Comparison criteria logic:**
- `BestPrice` → lowest Price
- `HighestRating` → highest AverageRating
- `MostReviews` → highest NumberOfRatings
- `BestValue` → `(AverageRating × NumberOfRatings) / Price`

| Method | Returns |
|--------|---------|
| `CompareProductsAsync(products, criteria)` | `Task<ProductComparison>` |
| `FindBestMatchAsync(products, criteria)` | `Task<Product?>` |
| `SearchProductsAsync(SearchFilter)` | `Task<List<Product>>` |

---

### `EcommerceSearchService` (`IEcommerceSearchService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`, `IProductDataService`, `IRealEcommerceService`, `ApiConfiguration`
**Primary method:** `SearchAllPlatformsAsync(SearchRequest) → Task<SearchResult>`
Routes to per-platform search methods in parallel based on `SearchRequest.Source`.

**Per-platform methods:** `SearchAmazonAsync`, `SearchFlipkartAsync`, `SearchWalmartAsync`, `SearchBestBuyAsync`, `SearchTargetAsync`, `SearchLocalAsync`

**Mock data:** Generates realistic products (Samsung, Apple, Sony variants) with per-platform price multipliers and SKU suffixes. Includes INR-priced Indian market products.

---

### `RealEcommerceService` (`IRealEcommerceService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`, `ApiConfiguration`, `IConnectivityService`, `ILogger<RealEcommerceService>`

**Resilience:** All search methods go through `ExecuteWithRetryAsync`:
- Checks `IConnectivityService.IsConnected` → returns empty list immediately if offline
- Exponential backoff: `delay × 2^attempt` (delay from `ApiConfiguration.RetryDelayMilliseconds`)
- Respects `CancellationToken` throughout

**Global platform methods:**

| Method | Platform |
|--------|----------|
| `SearchAmazonProductsAsync` | Amazon (US/Global) |
| `SearchBestBuyProductsAsync` | Best Buy |
| `SearchWalmartProductsAsync` | Walmart |
| `SearchEbayProductsAsync` | eBay |

**Indian market methods:**

| Method | Platform |
|--------|----------|
| `SearchFlipkartProductsAsync` | Flipkart |
| `SearchMyntraProductsAsync` | Myntra (fashion/lifestyle) |
| `SearchNykaaProductsAsync` | Nykaa (beauty/wellness) |
| `SearchMeeshoProductsAsync` | Meesho (social commerce) |
| `SearchCromaProductsAsync` | Croma (electronics) |
| `SearchBlinkitProductsAsync` | Blinkit (quick commerce) |
| `SearchSwiggyProductsAsync` | Swiggy Instamart (grocery) |

**Affiliate URL building:** `GetProductLinkAsync(Product) → Task<string>` — appends affiliate tags for Amazon, Flipkart, Myntra, Nykaa, Walmart, BestBuy, Target when `ApiConfiguration.EnableAffiliateLinks = true`.

**Indian platform detection:** `IsIndianPlatform(source)` checks source name against Indian platform list.

---

### `WebScrapingService` (`IWebScrapingService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`, `IConfigurationService`, `IConnectivityService`, `ILogger<WebScrapingService>`
**Library:** HtmlAgilityPack for HTML DOM parsing

| Method | Returns |
|--------|---------|
| `ScrapeWebsiteAsync(website, query, maxResults)` | `Task<List<Product>>` |
| `ScrapeMultipleWebsitesAsync(websites, query)` | `Task<List<Product>>` |
| `GetProductDetailsAsync(website, productUrl)` | `Task<Product?>` |

**Notes:**
- Offline guard via `IConnectivityService.IsConnected`
- User-Agent spoofing; respects `ScrapingConfiguration.DelayBetweenRequests`
- Uses `TryAddWithoutValidation` for headers to prevent duplicate-header exceptions

---

### `PublicSearchService` (`IPublicSearchService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`
**Primary method:** `SearchWithPublicEnginesAsync(query, country) → Task<List<Product>>`
Parallel aggregation across `SearchGoogleShoppingAsync`, `SearchBingShoppingAsync`, `ScrapePriceComparisonSitesAsync`; deduplicates results.

---

### `EnhancedComparisonService` (`IEnhancedComparisonService`)
**DI Scope:** Scoped
**Constructor:** `IAIRecommendationService`, `IConfigurationService`

| Method | Returns |
|--------|---------|
| `GenerateComparisonVerdictAsync(products, query)` | `Task<ComparisonVerdict>` |
| `GetBestDealsAsync(products, criteria)` | `Task<List<Product>>` |
| `CompareProductsDetailedAsync(products)` | `Task<ProductComparisonResult>` |
| `GetComparisonCriteriaAsync()` | `Task<List<string>>` |

Generates structured pros/cons, confidence scores, and integrates AI recommendation text.

---

### `ProductGroupingService` (`IProductGroupingService`)
**DI Scope:** Scoped
**Constructor:** (none)

**Grouping strategies (in priority order):** ExactMatch → ModelMatch → CategoryMatch → BrandMatch

| Method | Returns |
|--------|---------|
| `GroupProductsAsync(products, query, settings)` | `Task<GroupedSearchResult>` |
| `GroupProductsByModelAsync(products)` | `Task<List<ProductGroupViewModel>>` |
| `GroupProductsByCategoryAsync(products)` | `Task<List<ProductGroupViewModel>>` |
| `GroupProductsByBrandAsync(products)` | `Task<List<ProductGroupViewModel>>` |
| `NormalizeProductName(name, brand)` | `string` |
| `ExtractModelName(name, brand)` | `string` |
| `CalculateProductSimilarity(p1, p2)` | `double` (0.0–1.0) |

Uses brand variation dictionaries (Samsung/Galaxy, Apple/iPhone, etc.) for fuzzy matching.

---

### `AIRecommendationService` (`IAIRecommendationService`)
**DI Scope:** Scoped
**Constructor:** `IEcommerceSearchService`, `IAnalyticsService`

| Method | Returns |
|--------|---------|
| `ParseNaturalLanguageQueryAsync(query)` | `Task<SearchRequest>` — extracts product name, sort, source, price range, category, brand |
| `GetPersonalizedRecommendationsAsync(userProfile)` | `Task<List<Product>>` |
| `GetSimilarProductsAsync(product)` | `Task<List<Product>>` |
| `GenerateProductSummaryAsync(product)` | `Task<string>` |
| `LearnFromUserBehaviorAsync(UserInteraction)` | `Task` |
| `GetRecommendationAsync(query, products)` | `Task<string>` |

**`UserInteraction`** inner class: SearchQuery, ProductId, `ActionType` (view/favorite/compare/purchase), ViewDuration

---

### `LocalizationService` (`ILocalizationService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`, `IPublicSearchService`

| Method | Returns |
|--------|---------|
| `DetectUserLocationAsync()` | `Task<UserProfile>` |
| `GetSupportedCountriesAsync()` | `Task<List<string>>` |
| `SearchLocalizedAsync(LocalizedSearchRequest)` | `Task<List<Product>>` |
| `GetLocalEcommerceSourcesAsync(country)` | `Task<Dictionary<string,string>>` |
| `ConvertCurrencyAsync(amount, from, to)` | `Task<decimal>` |

Supports: US, IN, UK, CA, AU, DE, JP + more.

---

### `LocationService` (`ILocationService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`

| Method | Returns |
|--------|---------|
| `GetCurrentLocationAsync()` | `Task<LocationInfo>` |
| `RequestLocationPermissionAsync()` | `Task<bool>` |
| `GetLocationByPostalCodeAsync(code, country)` | `Task<LocationInfo>` |
| `GetAvailableCountriesAsync()` | `Task<List<CountryInfo>>` |
| `GetCountryInfoAsync(countryCode)` | `Task<CountryInfo>` |
| `SetupUserLocationAsync(profile, useCurrentLocation)` | `Task<UserProfile>` |
| `IsLocationServicesEnabledAsync()` | `Task<bool>` |

Built-in country database: US, IN, UK, CA, AU, DE, FR, JP, BR + more with popular e-commerce sites per country.

---

### `LocalStoreService` (`ILocalStoreService`)
**DI Scope:** Scoped
**Constructor:** `HttpClient`

| Method | Returns |
|--------|---------|
| `FindNearbyStoresAsync(lat, lng, radiusKm)` | `Task<List<LocalStore>>` |
| `SearchStoresByProductAsync(query, lat, lng)` | `Task<List<LocalStore>>` |
| `SearchLocalStoreInventoryAsync(storeId, query)` | `Task<List<Product>>` |
| `CheckProductAvailabilityAsync(storeId, name)` | `Task<bool>` |
| `GetStoresByRegionAsync(city, country)` | `Task<List<LocalStore>>` |

Uses Haversine formula for distance calculations.

---

### `ComparisonService` (`IComparisonService`)
**DI Scope:** Scoped
**Constructor:** `IProductDataService`, `IAIRecommendationService`

| Method | Returns |
|--------|---------|
| `CreateComparisonListAsync(userId, name)` | `Task<ComparisonList>` |
| `AddProductToComparisonAsync(listId, product)` | `Task<ComparisonList>` |
| `RemoveProductFromComparisonAsync(listId, productId)` | `Task<ComparisonList>` |
| `GetUserComparisonListsAsync(userId)` | `Task<List<ComparisonList>>` |
| `GenerateAIComparisonAsync(list)` | `Task<EnhancedProductComparison>` |
| `GetComparisonSuggestionsAsync(query)` | `Task<List<AIComparisonSuggestion>>` |
| `ShareComparisonAsync(listId)` | `Task<bool>` |
| `GetSharedComparisonAsync(shareId)` | `Task<ComparisonList>` |

---

### `PriceAlertService` (`IPriceAlertService`)
**DI Scope:** Scoped
**Constructor:** `IEcommerceSearchService`
**Storage:** In-memory (legacy — for `PremiumAlertService` tier-gated alerts)

| Method | Returns |
|--------|---------|
| `CreatePriceAlertAsync(userId, query, targetPrice)` | `Task<PriceAlert>` |
| `GetUserPriceAlertsAsync(userId)` | `Task<List<PriceAlert>>` |
| `UpdatePriceAlertAsync(alertId, newTargetPrice)` | `Task<bool>` |
| `DeletePriceAlertAsync(alertId)` | `Task<bool>` |
| `CheckPriceAlertsAsync()` | `Task<List<PriceAlert>>` |
| `CreateAIComparisonAlertAsync(userId, query)` | `Task<AIComparisonSuggestion>` |
| `SendPriceAlertNotificationAsync(alert, newPrice)` | `Task<bool>` |

---

### `PremiumAlertService` (`IPremiumAlertService`) — `Services/PremiumAlertService.cs`
**DI Scope:** Scoped
**Constructor:** `IEcommerceSearchService`, `IPublicSearchService`, `IWebScrapingService`, `IPremiumNotificationService`, `IConfigurationService`
**Storage:** In-memory `List<PriceAlert>` (upgrade path: wire to `ProductDatabase` alerts table)

**Tier limits:** Free → 0 alerts, Premium → 15, Enterprise → 100

| Method | Returns |
|--------|---------|
| `GetUserAlertsAsync(userId)` | `Task<List<PriceAlert>>` |
| `CreatePriceAlertAsync(alert)` | `Task<int>` |
| `UpdateAlertAsync(alert)` | `Task<bool>` |
| `DeleteAlertAsync(alertId)` | `Task<bool>` |
| `CheckAllAlertsAsync()` | `Task` — searches all active alerts, dispatches notifications |
| `CanCreateAlert(UserTier)` | `Task<bool>` |
| `GetMaxAlertsForTier(UserTier)` | `Task<int>` |
| `CreateCategoryAlertAsync(userId, category, maxPrice)` | `Task<bool>` |
| `GetNewProductsInCategoryAsync(category, since)` | `Task<List<Product>>` |

**Related interfaces in same file:**
- `IPremiumNotificationService` — `SendPriceDropNotificationAsync`, `SendCategoryAlertAsync`, `RegisterForPushNotificationsAsync`
- `PremiumNotificationService` — concrete implementation of `IPremiumNotificationService` (stub, logs to Debug)
- `UserTier` enum — `Free | Premium | Enterprise`

---

### `AdvancedServices.cs` — Three services in one file

#### `PriceHistoryService` (`IPriceHistoryService`)
**DI Scope:** Scoped
**Constructor:** `ProductDatabase`
**Persistence:** SQLite `PriceHistory` table

| Method | Returns |
|--------|---------|
| `GetPriceHistoryAsync(int productId)` | `Task<List<PriceHistory>>` (legacy) |
| `GetPriceHistoryByIdentifierAsync(identifier)` | `Task<List<PriceHistoryEntry>>` |
| `RecordPriceAsync(identifier, name, price, source)` | `Task` — writes entry, auto-purges >90 days |
| `GetLowestPriceAsync(identifier, period)` | `Task<decimal>` |
| `HasPriceDroppedAsync(identifier, threshold)` | `Task<bool>` |

#### `ProductAlertService` (`IProductAlertService`)
**DI Scope:** Scoped
**Constructor:** `ProductDatabase`
**Persistence:** SQLite `ProductAlerts` table

| Method | Returns |
|--------|---------|
| `GetActiveAlertsAsync()` | `Task<List<ProductAlertEntry>>` |
| `GetAllAlertsAsync()` | `Task<List<ProductAlertEntry>>` |
| `CreateAlertAsync(ProductAlertEntry)` | `Task<int>` |
| `DeleteAlertAsync(int alertId)` | `Task` |
| `CheckAndSendAlertsAsync(searchService, notificationService)` | `Task<int>` — checks all active alerts against live prices, sends notifications for hits |

#### `AnalyticsService` (`IAnalyticsService`)
**DI Scope:** Scoped
**Constructor:** `ProductDatabase`
**Persistence:** SQLite `SearchAnalytics` table

| Method | Returns |
|--------|---------|
| `RecordSearchAsync(SearchAnalytics)` | `Task` (legacy) |
| `RecordSearchEntryAsync(query, resultCount, responseMs, region)` | `Task` — writes `SearchAnalyticsEntry`, probabilistic 30-day purge |
| `GetPopularSearchesAsync(count)` | `Task<List<string>>` |
| `GetSourceUsageStatsAsync()` | `Task<Dictionary<EcommerceSource,int>>` |
| `GetAverageResponseTimeAsync()` | `Task<TimeSpan>` |

#### `INotificationService` / `NotificationService` (also in AdvancedServices.cs)
**DI Scope:** Scoped
Stub implementation — platform-specific push notification TODOs (FCM for Android, APNs for iOS, WNS for Windows).

| Method | Status |
|--------|--------|
| `SendNotificationAsync(title, body)` | TODO — hook to FCM/APNs/WNS |
| `SendPriceDropNotificationAsync(productName, currentPrice, targetPrice)` | TODO |

---

## 9. ViewModels Reference

### `BaseViewModel`
Implements `INotifyPropertyChanged`. Provides `OnPropertyChanged()` and `SetProperty<T>()` helpers for all derived ViewModels.

---

### `HomeViewModel`
**DI Scope:** Not registered (instantiated directly by `HomePage` fallback)
**Constructor:** `IProductDataService`, `IProductComparisonService`
**Collections:** `Products`, `RecentSearches`
**Commands:** `SearchCommand`, `LoadSampleDataCommand`
**Use:** Basic local-DB search fallback when enhanced services unavailable.

---

### `EnhancedHomeViewModel`
**DI Scope:** Scoped
**Constructor:** `IEcommerceSearchService`, `IWebScrapingService`, `IPublicSearchService`, `IConfigurationService`, `ILocationService`, `IPremiumAlertService`, `IEnhancedComparisonService`, `IAIRecommendationService`, `IProductGroupingService`, `ILogger<EnhancedHomeViewModel>?`
**Implements:** `IDisposable`

**Observable Collections:** `GroupedSearchResults`, `SearchResults`, `AvailableCountries`, `SortOptions`, `SourceOptions`, `GroupingOptions`

**Commands:**

| Command | Action |
|---------|--------|
| `SearchCommand` | Triggers multi-platform search with debounce (500ms) |
| `CancelSearchCommand` | Cancels in-flight search via CancellationTokenSource |
| `ToggleSearchModeCommand` | Switches between standard and natural language mode |
| `ToggleResultsViewCommand` | Toggles grouped/flat results view |
| `RefreshGroupingCommand` | Re-groups existing results with new grouping setting |
| `UseCurrentLocationCommand` | Detects and sets device location |
| `SetManualLocationCommand` | Sets location by postal code |
| `SkipLocationSetupCommand` | Dismisses location prompt |
| `ChangeLocationCommand` | Opens location change UI |
| `ClearFiltersCommand` | Resets all sort/filter selections |

**Caching:** `ConcurrentDictionary` cache with 5-minute TTL keyed by query+source+sort.
**Concurrency:** `SemaphoreSlim` prevents overlapping searches.

---

### `SuperEnhancedHomeViewModel`
**DI Scope:** Scoped
**Constructor:** `IEcommerceSearchService`, `IProductDataService`, `IAIRecommendationService`, `IAnalyticsService`
**Key features:** Natural language query parsing via AI, personalized recommendations, recent/popular searches, analytics recording
**Commands:** `SearchCommand`, `ClearFiltersCommand`, `AddToFavoritesCommand`, `ViewProductDetailsCommand`, `ToggleSearchModeCommand`

---

### `CompareViewModel`
**DI Scope:** Not registered (instantiated by ComparePage fallback)
**Constructor:** `IProductDataService`, `IProductComparisonService`
**Commands:** `CompareCommand`, `AddProductCommand`, `RemoveProductCommand`, `ClearComparisonCommand`, `LoadAvailableProductsCommand`

---

### `FavoritesViewModel`
**DI Scope:** Scoped
**Constructor:** `IFavoritesService`, `ILogger<FavoritesViewModel>`
**Collection:** `ObservableCollection<FavoriteItem> Favorites`
**Computed properties:** `HasFavorites`, `IsEmpty`
**Commands:** `LoadFavoritesCommand`, `RemoveFavoriteCommand`, `NavigateToProductCommand`, `ClearAllFavoritesCommand`
**Static helper:** `GetPriceChangeLabel(FavoriteItem)` returns "Price dropped X% since saved!" or "Price up X% since saved"
**Navigation:** Opens product URLs via `Browser.Default.OpenAsync`

---

### `SettingsViewModel`
**DI Scope:** Scoped
**Constructor:** `IConfigurationService`, `ILocationService`
**Collections:** `Countries`, `Websites`
**Feature toggles:** `EnableWebScraping`, `EnablePublicAPIs`, `EnableLocalStores`, `EnablePriceAlerts`
**Computed:** `PremiumStatusText`, `AlertsInfoText`, `ShowUpgradeButton`, `AppVersion`
**Commands:** `RefreshCommand`, `SaveCommand`, `AddWebsiteCommand`, `DetectLocationCommand`, `ResetDefaultsCommand`, `UpgradeCommand`

---

### `ProductDetailViewModel`
**DI Scope:** Scoped
**Constructor:** `Product product`, `IAIRecommendationService`, `IPriceHistoryService`, `IProductAlertService`, `IProductDataService`
**Collections:** `ObservableCollection<PriceHistory> PriceHistory`, `ObservableCollection<Product> SimilarProducts`
**Key properties:** `AIProductSummary`, `IsLoadingSummary`, `TargetPrice` (for alert creation)
**Commands:** `ToggleFavoriteCommand`, `AddToCompareCommand`, `SetPriceAlertCommand`
**Alert creation:** Uses `ProductAlertEntry` (SQLite-backed) via `IProductAlertService.CreateAlertAsync`

---

### `EnhancedCompareViewModel`
**DI Scope:** Scoped
**Constructor:** `IEcommerceSearchService`, `IAIRecommendationService`, `IProductComparisonService`, `IProductGroupingService?`, `IConfigurationService?`

**Best product properties:** `BestOverall`, `BestPrice`, `BestRating`, `BestValue`, `BestChoice` (user preference + AI)
**Commands:**

| Command | Action |
|---------|--------|
| `SearchAndAddCommand` | Searches, groups by model, auto-populates comparison list |
| `RemoveProductCommand` | Removes item from comparison |
| `ClearAllCommand` | Clears comparison list |
| `GenerateComparisonCommand` | Generates multi-metric comparison + AI verdict |
| `ExportReportCommand` | Exports comparison report |
| `ShareResultsCommand` | Shares results |
| `OpenBuyLinkCommand` | Opens product URL via Browser (affiliate-decorated if enabled) |

**AI Best Choice logic:** Combines user preferences (brand, category, budget from `IConfigurationService`) with value heuristics and AI verdict text.

---

## 10. Pages & Views Reference

### `HomePage.xaml.cs`
**BindingContext resolution chain:**
1. Resolve all 11 services from DI
2. `EnhancedHomeViewModel` (if all services available) ← primary
3. `HomeViewModel` (basic services only) ← fallback
4. `SimpleHomeViewModel` (no services) ← last resort

---

### `ComparePage.xaml.cs`
**Constructor injects:** `IEcommerceSearchService`, `IAIRecommendationService`, `IProductComparisonService`, `IProductGroupingService`, `IConfigurationService`
**BindingContext:** `EnhancedCompareViewModel` → `SimpleCompareViewModel` fallback

---

### `FavoritesPage.xaml.cs`
Minimal implementation. Sets `Title = "Favorites"`. ViewModel binding to be wired in XAML.

---

### `SettingsPage.xaml.cs`
**Constructor injects:** `IConfigurationService`, `ILocationService` (direct DI injection into page)
**BindingContext:** `SettingsViewModel(configService, locationService)`

---

### `ProductDetailPage.xaml.cs`
**Constructor:** `Product product` (passed directly)
Resolves `IAIRecommendationService`, `IPriceHistoryService`, `IProductAlertService`, `IProductDataService` from DI.
**BindingContext:** `ProductDetailViewModel` → `SimpleProductDetailViewModel` fallback

---

### `MainPage.xaml.cs`
Legacy counter demo page. `OnCounterClicked` increments counter and announces via `SemanticScreenReader`. Not part of the main app navigation.

---

## 11. Converters Reference

All converters are in namespace `TrueBargain.Converters` and implement `IValueConverter`.

| Converter | Input | Output | Use |
|-----------|-------|--------|-----|
| `InvertedBoolConverter` | `bool` | `bool` (negated) | Show/hide inverse visibility |
| `StringToBoolConverter` | `string` | `bool` (true if non-empty) | Button enable state |
| `IntToBoolConverter` | `int` | `bool` (true if > 0) | Button enable from count |
| `CountToBoolConverter` | `int` | `bool` (true if > 0) | List visibility |
| `CountToInverseBoolConverter` | `int` | `bool` (true if == 0) | Empty-state visibility |
| `FavoriteTextConverter` | `bool` | `"♥"` or `"♡"` | Heart icon toggle |
| `FavoriteColorConverter` | `bool` | `#FF6B6B` (red) or `#CCCCCC` | Heart color toggle |
| `NotNullConverter` | `object?` | `bool` | Visibility when non-null |
| `NotNullToBoolConverter` | `object?` | `bool` | **`[Obsolete]`** — delegates to `NotNullConverter` |

---

## 12. Platform Configuration

### Android — `Platforms/Android/AndroidManifest.xml`
| Permission | Purpose |
|-----------|---------|
| `INTERNET` | All network calls |
| `ACCESS_NETWORK_STATE` | Connectivity checks |
| `ACCESS_COARSE_LOCATION` | Approximate location (store search) |
| `ACCESS_FINE_LOCATION` | Precise GPS location |
| `READ_EXTERNAL_STORAGE` (maxSdkVersion=28) | Legacy file access (Android ≤ 9) |
| `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=28) | Legacy file access (Android ≤ 9) |

**App attributes:** `android:usesCleartextTraffic="false"` (HTTPS enforced), `android:allowBackup="false"` (prevents cloud backup of sensitive data)

---

### iOS — `Platforms/iOS/Info.plist`
| Key | Purpose |
|-----|---------|
| `NSLocationWhenInUseUsageDescription` | Location prompt text shown to user |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Background location prompt |
| `NSAppTransportSecurity → NSAllowsArbitraryLoads = false` | Enforces HTTPS |

---

### macOS Catalyst — `Platforms/MacCatalyst/`
**Info.plist additions:**
- `NSLocationUsageDescription` — location prompt
- `ITSAppUsesNonExemptEncryption = false` — App Store export compliance
- `LSApplicationCategoryType = public.app-category.shopping`
- `NSAppTransportSecurity → NSAllowsArbitraryLoads = false`

**Entitlements.plist additions:**
- `com.apple.security.personal-information.location` — location access
- `keychain-access-groups` with `$(AppIdentifierPrefix)com.companyname.truebargain` — SecureStorage support

---

### Windows — `Platforms/Windows/Package.appxmanifest`
| Capability | Purpose |
|-----------|---------|
| `internetClient` | Outbound internet access |
| `location` (uap capability) | Location services |

---

## 13. Build & Release Configuration

### Target Frameworks
| Platform | Framework |
|----------|-----------|
| Android | `net9.0-android` |
| iOS | `net9.0-ios` |
| macOS | `net9.0-maccatalyst` |
| Windows | `net9.0-windows10.0.19041.0` |

### Release Build Settings
| Setting | Value | Notes |
|---------|-------|-------|
| `PublishTrimmed` | `true` | IL Linker removes unused code in Release |
| `TrimMode` | `link` | Aggressive trimming |
| `SuppressTrimAnalysisWarnings` | `true` | Suppresses noisy warnings |
| `RunAOTCompilation` | `true` (Release only) | Faster app startup on device |

### Platform-Specific Release Settings
| Platform | Key Settings |
|----------|-------------|
| Android | `AndroidPackageFormat=aab` (App Bundle), keystore signing (commented — fill in before publish) |
| iOS | `CodesignKey=iPhone Distribution`, `ArchiveOnBuild=true`, `RuntimeIdentifier=ios-arm64` |
| Windows | `WindowsPackageType=None` (unpackaged MSIX), `SelfContained=true`, `RuntimeIdentifier=win10-x64` |

### Linker Preservation (`LinkerConfig.xml`)
| Assembly | What's preserved |
|---|---|
| `TrueBargain` (all namespaces) | Entire app |
| `Microsoft.Maui.Controls` | ContentPage, Shell, Application, CollectionView, ListView, DataTrigger |
| `SQLite-net` | All types (ORM reflection) |
| `SQLitePCLRaw.core` | All (native binding) |
| `System.Text.Json` | All types |
| `System.Security.Cryptography.Algorithms` + `.Primitives` | All (SHA-256 for cache keys) |
| `HtmlAgilityPack` | All types |
| `CommunityToolkit.Mvvm` | All |

---

## 14. API Key Management

`ApiKeyProvider.Populate()` resolves each key in priority order:
**1. MAUI SecureStorage** (device hardware keystore) → **2. Environment variable** → **3. Default in `ApiConfiguration`**

### Global Platform Keys
| SecureStorage / Env Key | `ApiConfiguration` Property |
|------------------------|------------------------------|
| `TB_AMAZON_API_KEY` | `AmazonApiKey` |
| `TB_AMAZON_ASSOC_TAG` | `AmazonAssociateTag` |
| `TB_WALMART_API_KEY` | `WalmartApiKey` |
| `TB_WALMART_AFFIL_ID` | `WalmartAffiliateId` |
| `TB_BESTBUY_API_KEY` | `BestBuyApiKey` |
| `TB_BESTBUY_AFFIL_ID` | `BestBuyAffiliateId` |
| `TB_TARGET_API_KEY` | `TargetApiKey` |
| `TB_TARGET_AFFIL_ID` | `TargetAffiliateId` |
| `TB_EBAY_API_KEY` | `EbayApiKey` |

### Indian Market Keys
| SecureStorage / Env Key | `ApiConfiguration` Property |
|------------------------|------------------------------|
| `TB_FLIPKART_API_KEY` | `FlipkartApiKey` |
| `TB_FLIPKART_AFFIL_ID` | `FlipkartAffiliateId` |
| `TB_MYNTRA_API_KEY` | `MyntraApiKey` |
| `TB_MYNTRA_AFFIL_ID` | `MyntraAffiliateId` |
| `TB_NYKAA_API_KEY` | `NykaaApiKey` |
| `TB_NYKAA_AFFIL_ID` | `NykaaAffiliateId` |
| `TB_MEESHO_API_KEY` | `MeeshoApiKey` |
| `TB_CROMA_API_KEY` | `CromaApiKey` |
| `TB_BIGBASKET_API_KEY` | `BigBasketApiKey` |
| `TB_JIOMART_API_KEY` | `JioMartApiKey` |
| `TB_SWIGGY_API_KEY` | `SwiggyApiKey` |
| `TB_BLINKIT_API_KEY` | `BlinkitApiKey` |
| `TB_ZEPTO_API_KEY` | `ZeptoApiKey` |

### Setting Keys at Runtime
```csharp
// Via MAUI SecureStorage (in-app settings screen — recommended for production)
await SecureStorage.Default.SetAsync("TB_AMAZON_API_KEY", "your_key_here");

// Via environment variable (CI/CD, server provisioning)
// Set TB_AMAZON_API_KEY=your_key in the build/deployment environment
```

---

## 15. Supported Markets & Platforms

### Indian Market (Primary)
| Platform | Category | Search Method |
|----------|----------|---------------|
| Flipkart | General e-commerce | `SearchFlipkartProductsAsync` |
| Myntra | Fashion / Lifestyle | `SearchMyntraProductsAsync` |
| Nykaa | Beauty / Wellness | `SearchNykaaProductsAsync` |
| Meesho | Social Commerce | `SearchMeeshoProductsAsync` |
| Croma | Electronics | `SearchCromaProductsAsync` |
| Blinkit | Quick Commerce (10-min) | `SearchBlinkitProductsAsync` |
| Swiggy Instamart | Grocery | `SearchSwiggyProductsAsync` |
| BigBasket | Grocery | API key configured |
| JioMart | Grocery / General | API key configured |
| Zepto | Quick Commerce | API key configured |

### Global Market
| Platform | Country | Search Method |
|----------|---------|---------------|
| Amazon | US / Global | `SearchAmazonProductsAsync` |
| Walmart | US | `SearchWalmartProductsAsync` |
| Best Buy | US | `SearchBestBuyProductsAsync` |
| eBay | Global | `SearchEbayProductsAsync` |
| Target | US | Via `EcommerceSearchService` |

### Mock INR Product Catalog
When `ApiConfiguration.UseRealApis = false`, Indian platform searches return realistic mock data including:
- Grocery items (Blinkit, Swiggy, BigBasket) with per-kg/per-unit INR pricing
- Fashion products (Myntra, Meesho) with INR pricing
- Electronics (Croma, Flipkart) with INR pricing
- Beauty/wellness (Nykaa) with INR pricing
- Smartphones, laptops, TVs with realistic INR MSRP ranges

---

## 16. Dependency & Call Graphs

### Service Registration Graph
```
MauiProgram.CreateMauiApp()
  ├── Singleton
  │   ├── ProductDatabase(Constants.DatabasePath)
  │   ├── ConnectivityService(ILogger)
  │   ├── CacheService(ILogger)
  │   ├── ConfigurationService()
  │   └── ApiConfiguration ← ApiKeyProvider.Populate()
  │
  ├── Scoped
  │   ├── ProductDataService(ProductDatabase, ILogger)
  │   ├── FavoritesService(ProductDatabase, ILogger)
  │   ├── ProductComparisonService()
  │   ├── RealEcommerceService(HttpClient, ApiConfig, IConnectivity, ILogger)
  │   ├── EcommerceSearchService(HttpClient, IProductData, IRealEcommerce, ApiConfig)
  │   ├── WebScrapingService(HttpClient, IConfig, IConnectivity, ILogger)
  │   ├── PublicSearchService(HttpClient)
  │   ├── EnhancedComparisonService(IAIRecommendation, IConfig)
  │   ├── ProductGroupingService()
  │   ├── LocalizationService(HttpClient, IPublicSearch)
  │   ├── LocationService(HttpClient)
  │   ├── LocalStoreService(HttpClient)
  │   ├── PriceAlertService(IEcommerceSearch)
  │   ├── PremiumAlertService(IEcommerceSearch, IPublicSearch, IWebScraping, IPremiumNotification, IConfig)
  │   ├── PriceHistoryService(ProductDatabase)     ← SQLite-backed
  │   ├── ProductAlertService(ProductDatabase)     ← SQLite-backed
  │   ├── AnalyticsService(ProductDatabase)        ← SQLite-backed
  │   ├── NotificationService()                    ← stub
  │   ├── AIRecommendationService(IEcommerceSearch, IAnalytics)
  │   └── ViewModels...
  │
  └── Transient
      ├── HttpClient ← IHttpClientFactory.CreateClient("TrueBargain")
      └── Pages (HomePage, ComparePage, SettingsPage, ProductDetailPage, FavoritesPage)
```

### Key Search Call Chain
```
User types query
  → EnhancedHomeViewModel.SearchCommand (debounced 500ms)
  → (check ConcurrentDictionary cache, TTL 5 min)
  → EcommerceSearchService.SearchAllPlatformsAsync(SearchRequest)
      ├─ RealEcommerceService.Search{Platform}Async (per source, parallel)
      │     └─ ExecuteWithRetryAsync → IConnectivityService.IsConnected guard
      │                              → exponential backoff (RetryDelay × 2^attempt)
      ├─ WebScrapingService.ScrapeMultipleWebsitesAsync (if enabled)
      └─ PublicSearchService.SearchWithPublicEnginesAsync (if enabled)
  → ProductGroupingService.GroupProductsAsync(results, query, settings)
  → AIRecommendationService.GetRecommendationAsync(query, products)
  → AnalyticsService.RecordSearchEntryAsync(query, count, ms, region)  ← SQLite
  → EnhancedHomeViewModel.GroupedSearchResults  (ObservableCollection → UI)
```

### Price Alert Check Chain
```
ProductAlertService.CheckAndSendAlertsAsync(searchService, notificationService)
  → ProductDatabase.GetActiveAlertsAsync()         ← SQLite read
  → foreach alert:
      → SearchRequest { Query=alert.ProductName, MaxResults=5 }
      → searchService.SearchAllPlatformsAsync(request)
      → results.Products.Min(p => p.Price) == lowestPrice
      → if lowestPrice <= alert.TargetPrice:
          → notificationService.SendNotificationAsync(...)  ← platform TODO
          → alert.LastNotifiedAt = DateTime.UtcNow
          → ProductDatabase.SaveAlertAsync(alert)           ← SQLite write
```

---

## 17. Production Readiness Status

| Area | Status | Notes |
|------|--------|-------|
| Device Storage | PRODUCTION | SQLite + SecureStorage + FileSystem — no cloud DB needed |
| Offline Guard | PRODUCTION | ConnectivityService checks before every network call |
| Search Cache | PRODUCTION | SHA-256 keyed file cache, configurable TTL, auto-purge |
| Favorites | PRODUCTION | Full SQLite CRUD with price-snapshot for drop detection |
| Price History | PRODUCTION | SQLite, 90-day retention, per-product identifier |
| Price Alerts | PRODUCTION | SQLite-backed CRUD + alert check + notification dispatch |
| Analytics | PRODUCTION | SQLite, 30-day retention, popular search query aggregation |
| HTTP Resilience | PRODUCTION | Exponential backoff, CancellationToken, offline guard |
| Secure Key Mgmt | PRODUCTION | SecureStorage hardware-backed + env var fallback |
| Admin Panel | PRODUCTION | Settings page has API key entry UI with Save/Load/Clear |
| DI Registration | COMPLETE | All services + all ViewModels registered |
| Structured Logging | PRODUCTION | ILogger<T> throughout; Debug sink in dev; configurable in prod |
| Indian Market | COMPLETE | 10 platforms (Flipkart, Myntra, Nykaa, Meesho, Croma, Blinkit, Swiggy, BigBasket, JioMart, Zepto) |
| Global Market | COMPLETE | Amazon, Walmart, BestBuy, eBay, Target |
| Affiliate Links | COMPLETE | Amazon, Flipkart, Myntra, Nykaa, Walmart, BestBuy, Target |
| NLP Search | COMPLETE | AI natural language query → SearchRequest conversion |
| Product Grouping | COMPLETE | 4-strategy grouping with similarity scoring |
| AI Comparison | COMPLETE | Verdict + pros/cons + confidence score |
| Trimmer Config | PRODUCTION | LinkerConfig.xml preserves all critical namespaces |
| AOT Compilation | PRODUCTION | Enabled for Release builds on all platforms |
| Android Manifest | PRODUCTION | All required permissions declared, cleartext disabled |
| iOS Plist | PRODUCTION | Location descriptions, ATS enforced |
| Windows Manifest | PRODUCTION | internetClient + location capabilities declared |
| macOS Entitlements | PRODUCTION | Location + keychain-access-groups for SecureStorage |
| Real API Integration | FRAMEWORK READY | RealEcommerceService has API stubs — implement PA-API 5.0 etc. |
| Push Notifications | STUB | Platform-specific TODOs in NotificationService (FCM/APNs/WNS) |
| Unit Tests | PENDING | No test project yet; priority targets: ProductGroupingService, EcommerceSearchService |

### Production Deployment Checklist

Before deploying to production:

- [ ] **Obtain API Keys**: Register for affiliate programs (Amazon PA-API, Flipkart Affiliate, etc.)
- [ ] **Implement Real API Calls**: Complete the `Search{Platform}RealAsync` methods in `RealEcommerceService`
- [ ] **Configure Keys**: Use Settings → API Key Management to save keys to SecureStorage, OR set environment variables
- [ ] **Enable Real APIs**: Toggle `UseRealApis = true` in Settings or via `TB_USE_REAL_APIS` env var
- [ ] **Update App Identifier**: Change `com.companyname.truebargain` to your real bundle ID
- [ ] **Configure Android Signing**: Uncomment and fill in keystore settings in `.csproj`
- [ ] **Configure iOS Provisioning**: Set up certificates in Apple Developer Portal
- [ ] **Enable Production Logging**: Wire Application Insights / Sentry / Firebase Crashlytics
- [ ] **Implement Push Notifications**: Complete FCM (Android), APNs (iOS), WNS (Windows) in NotificationService

---

## 18. Deployment Guide

### Android
1. Generate keystore: `keytool -genkey -v -keystore truebargain.keystore -alias truebargain -keyalg RSA -keysize 2048 -validity 10000`
2. Uncomment signing config in `TrueBargain.csproj` and set `AndroidSigningKeyStore`, `AndroidSigningKeyAlias`
3. Set `AndroidSigningKeyPass` and `AndroidSigningStorePass` as **environment variables** (never in .csproj)
4. Build: `dotnet publish -f net9.0-android -c Release`
5. Output: `.aab` bundle → upload to Google Play Console

### iOS
1. Create App ID + Distribution Certificate + Provisioning Profile in Apple Developer portal
2. Set `ApplicationId = com.yourcompany.truebargain` in .csproj
3. Build on macOS: `dotnet publish -f net9.0-ios -c Release`
4. Archive → upload via Transporter

### Windows
1. Build: `dotnet publish -f net9.0-windows10.0.19041.0 -c Release`
2. Output: self-contained `.exe` + assets in publish folder
3. Optionally package as MSIX (set `WindowsPackageType=MSIX`) for Microsoft Store submission

### macOS Catalyst
1. Set entitlements App Identifier Prefix: replace `$(AppIdentifierPrefix)` in `Entitlements.plist` with your Team ID prefix
2. Build: `dotnet publish -f net9.0-maccatalyst -c Release`
3. Submit via Transporter

### Pre-publish Checklist
- [ ] Update `ApplicationId` from `com.companyname.truebargain` to your real bundle ID
- [ ] Update Windows `Package.appxmanifest` Identity Publisher
- [ ] Update macOS Entitlements `keychain-access-groups` with real App Identifier Prefix
- [ ] Set `UseRealApis = true` in `ApiConfiguration` and provision all API keys in SecureStorage
- [ ] Enable `EnableAffiliateLinks = true` and set affiliate IDs for revenue
- [ ] Replace Debug logging with production provider (Application Insights / Sentry / Firebase Crashlytics)
- [ ] Wire platform push notifications in `NotificationService` (FCM / APNs / WNS)

---

## 19. Known Issues & Cleanup Candidates

| Item | File | Action |
|------|------|--------|
| `NotNullToBoolConverter` marked `[Obsolete]` | `Converters/NotNullToBoolConverter.cs` | Remove after verifying no XAML references |
| `PremiumAlertService` uses in-memory `List<PriceAlert>` | `Services/PremiumAlertService.cs` | Migrate to `ProductAlertEntry` SQLite table |
| `FavoritesPage` has no ViewModel binding | `FavoritesPage.xaml` | Wire `FavoritesViewModel` in XAML `BindingContext` |
| `MainPage` is a legacy counter demo | `MainPage.xaml` | Remove from AppShell routes if not in use |
| Navigation uses `Shell.Current` magic strings | Multiple ViewModels | Introduce `INavigationService` abstraction |
| Unit tests missing | (no test project) | Add xUnit project; prioritize `ProductGroupingService.CalculateProductSimilarity` and `EcommerceSearchService` filter/sort logic |
| `NotificationService` push implementation | `Services/AdvancedServices.cs` | Implement FCM (Android), APNs (iOS), WNS (Windows) |
| Real API implementations are stubs | `Services/RealEcommerceService.cs` | Implement actual PA-API 5.0, Flipkart Affiliate API, etc. |

---

## 20. Production API Integration Guide

### Amazon Product Advertising API 5.0

1. **Register**: https://affiliate-program.amazon.in/ (India) or https://affiliate-program.amazon.com/ (US)
2. **Get Credentials**: Access Key, Secret Key, Associate Tag
3. **Save to SecureStorage**: Use Settings → API Key Management
4. **Implementation Location**: `RealEcommerceService.SearchAmazonRealAsync()`

```csharp
// Example PA-API 5.0 SearchItems request structure:
// POST https://webservices.amazon.in/paapi5/searchitems
// Headers: x-amz-access-key, x-amz-secret-key, x-amz-signature
// Body: { "Keywords": query, "PartnerTag": associateTag, "Resources": [...] }
```

### Flipkart Affiliate API

1. **Register**: https://affiliate.flipkart.com/
2. **Get Credentials**: Affiliate ID, Token
3. **Implementation Location**: `RealEcommerceService.SearchFlipkartRealAsync()`

```csharp
// Example Flipkart Affiliate API request:
// GET https://affiliate-api.flipkart.net/affiliate/1.0/search.json?query={query}&resultCount={maxResults}
// Header: Fk-Affiliate-Id: {affiliateId}
// Header: Fk-Affiliate-Token: {token}
```

### Best Buy Products API

1. **Register**: https://developer.bestbuy.com/
2. **Get API Key**: Free tier available
3. **Implementation Location**: `RealEcommerceService.SearchBestBuyRealAsync()`

```csharp
// Example Best Buy API request:
// GET https://api.bestbuy.com/v1/products((search={query}))?apiKey={key}&format=json
```

---

*Document updated to reflect production readiness improvements including API Key Management UI and real API integration framework.*
