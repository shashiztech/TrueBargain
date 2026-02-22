# Firebase Remote Config — Secrets Setup Guide

## GCP Project: `truebargain-dcc83`
## Firebase Console: https://console.firebase.google.com/project/truebargain-dcc83/overview

## Setting Up API Keys as Remote Config Parameters

### Step 1: Open Firebase Remote Config Console
Navigate to: https://console.firebase.google.com/project/truebargain-dcc83/remoteconfig

### Step 2: Add the following parameters

| Parameter Key | Type | Description |
|--------------|------|-------------|
| `TB_AMAZON_API_KEY` | String | Amazon Product Advertising API key |
| `TB_AMAZON_ASSOC_TAG` | String | Amazon Associate tag |
| `TB_FLIPKART_API_KEY` | String | Flipkart Affiliate API key |
| `TB_FLIPKART_AFFIL_ID` | String | Flipkart Affiliate ID |
| `TB_WALMART_API_KEY` | String | Walmart API key |
| `TB_WALMART_AFFIL_ID` | String | Walmart Affiliate ID |
| `TB_BESTBUY_API_KEY` | String | Best Buy Products API key |
| `TB_BESTBUY_AFFIL_ID` | String | Best Buy Affiliate ID |
| `TB_TARGET_API_KEY` | String | Target API key |
| `TB_TARGET_AFFIL_ID` | String | Target Affiliate ID |
| `TB_EBAY_API_KEY` | String | eBay API key |
| `TB_MYNTRA_API_KEY` | String | Myntra API key |
| `TB_MYNTRA_AFFIL_ID` | String | Myntra Affiliate ID |
| `TB_NYKAA_API_KEY` | String | Nykaa API key |
| `TB_NYKAA_AFFIL_ID` | String | Nykaa Affiliate ID |
| `TB_MEESHO_API_KEY` | String | Meesho API key |
| `TB_CROMA_API_KEY` | String | Croma API key |
| `TB_BIGBASKET_API_KEY` | String | BigBasket API key |
| `TB_JIOMART_API_KEY` | String | JioMart API key |
| `TB_SWIGGY_API_KEY` | String | Swiggy API key |
| `TB_BLINKIT_API_KEY` | String | Blinkit API key |
| `TB_ZEPTO_API_KEY` | String | Zepto API key |
| `TB_USE_REAL_APIS` | String | `"true"` or `"false"` — toggle real API calls |
| `TB_ENABLE_AFFILIATE_LINKS` | String | `"true"` or `"false"` — enable affiliate links |

### Step 3: Publish Changes
Click "Publish changes" to make the config live.

### How It Works in the App

1. **On app startup**, `ApiKeyProvider.populate()` is called
2. It first tries **Firebase Remote Config** (fetches + activates with 1-hour cache)
3. Falls back to **Flutter Secure Storage** (device keychain/keystore)
4. Falls back to **empty defaults** (mock data mode)

### Security Architecture

```
Firebase Remote Config (GCP-managed, server-side)
       ↓ fetch on app start (1-hour cache)
Flutter Secure Storage (hardware-backed keystore)
       ↓ fallback for offline/local overrides
Empty defaults → mock data mode
```

- Remote Config values are cached locally and refreshed every hour
- API keys are never stored in source code
- SecureStorage uses Android Keystore (hardware-backed on supported devices)
- Firebase Remote Config supports conditional values per app version, platform, etc.

### Updating Secrets

1. Go to Firebase Console → Remote Config
2. Update the parameter value
3. Publish changes
4. App will pick up new values within 1 hour (or on next restart)

### For CI/CD

Use the Firebase Admin SDK or REST API to update Remote Config values:
```bash
# Export current template
firebase remoteconfig:get --project=truebargain-dcc83 -o remote_config_backup.json

# Modify and push back via REST API
curl -X PUT \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json; UTF-8" \
  -d @firebase_remote_config.json \
  "https://firebaseremoteconfig.googleapis.com/v1/projects/truebargain-dcc83/remoteConfig"
```
