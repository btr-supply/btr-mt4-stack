//+------------------------------------------------------------------+
//|                                                       BTRIds.mqh |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property strict

#include "BTRHashMap.mqh"

//+------------------------------------------------------------------+
//| BTR Currency Constants (uint32)                                 |
//+------------------------------------------------------------------+
#define BTR_CURRENCY_ARS    1      // Argentine Peso
#define BTR_CURRENCY_AUD    11     // Australian Dollar
#define BTR_CURRENCY_BRL    21     // Brazilian Real
#define BTR_CURRENCY_GBP    31     // British Pound Sterling
#define BTR_CURRENCY_CAD    41     // Canadian Dollar
#define BTR_CURRENCY_CLP    51     // Chilean Peso
#define BTR_CURRENCY_CNY    61     // Chinese Renminbi
#define BTR_CURRENCY_COP    71     // Colombian Peso
#define BTR_CURRENCY_CZK    81     // Czech Koruna
#define BTR_CURRENCY_DKK    91     // Danish Krone
#define BTR_CURRENCY_EGP    101    // Egyptian Pound
#define BTR_CURRENCY_EUR    111    // Euro
#define BTR_CURRENCY_HKD    121    // Hong Kong Dollar
#define BTR_CURRENCY_HUF    131    // Hungarian Forint
#define BTR_CURRENCY_INR    141    // Indian Rupee
#define BTR_CURRENCY_IDR    151    // Indonesian Rupiah
#define BTR_CURRENCY_ILS    161    // Israeli New Shekel
#define BTR_CURRENCY_JPY    171    // Japanese Yen
#define BTR_CURRENCY_KZT    181    // Kazakhstani Tenge
#define BTR_CURRENCY_KWD    191    // Kuwaiti Dinar
#define BTR_CURRENCY_MYR    201    // Malaysian Ringgit
#define BTR_CURRENCY_MXN    211    // Mexican Peso
#define BTR_CURRENCY_MAD    221    // Moroccan Dirham
#define BTR_CURRENCY_TWD    231    // New Taiwan Dollar
#define BTR_CURRENCY_NZD    241    // New Zealand Dollar
#define BTR_CURRENCY_NGN    251    // Nigerian Naira
#define BTR_CURRENCY_NOK    261    // Norwegian Krone
#define BTR_CURRENCY_PKR    271    // Pakistani Rupee
#define BTR_CURRENCY_PEN    281    // Peruvian Sol
#define BTR_CURRENCY_PHP    291    // Philippine Peso
#define BTR_CURRENCY_PLN    301    // Polish Złoty
#define BTR_CURRENCY_QAR    311    // Qatari Riyal
#define BTR_CURRENCY_RON    321    // Romanian Leu
#define BTR_CURRENCY_RUB    331    // Russian Ruble
#define BTR_CURRENCY_SAR    341    // Saudi Riyal
#define BTR_CURRENCY_RSD    351    // Serbian Dinar
#define BTR_CURRENCY_SGD    361    // Singapore Dollar
#define BTR_CURRENCY_ZAR    371    // South African Rand
#define BTR_CURRENCY_KRW    381    // South Korean Won
#define BTR_CURRENCY_LKR    391    // Sri Lankan Rupee
#define BTR_CURRENCY_SEK    401    // Swedish Krona
#define BTR_CURRENCY_CHF    411    // Swiss Franc
#define BTR_CURRENCY_THB    421    // Thai Baht
#define BTR_CURRENCY_TRY    431    // Turkish Lira
#define BTR_CURRENCY_AED    441    // UAE Dirham
#define BTR_CURRENCY_UAH    451    // Ukrainian Hryvnia
#define BTR_CURRENCY_USD    461    // US Dollar
#define BTR_CURRENCY_VND    471    // Vietnamese Dong

//+------------------------------------------------------------------+
//| BTR Instrument Types (uint8)                                    |
//+------------------------------------------------------------------+
#define BTR_INST_SPOT             0x0    // Direct asset trading
#define BTR_INST_FUTURE           0x1    // Standardized futures contract
#define BTR_INST_FORWARD          0x2    // Custom forward contract
#define BTR_INST_SWAP             0x3    // Interest rate or currency swap
#define BTR_INST_PERPETUAL        0x4    // Crypto perpetual futures
#define BTR_INST_CFD              0x5    // Contract for difference
#define BTR_INST_CALL_OPTION      0x6    // Call option contract
#define BTR_INST_PUT_OPTION       0x7    // Put option contract
#define BTR_INST_DIGITAL_OPTION   0x8    // Binary/digital option
#define BTR_INST_BARRIER_OPTION   0x9    // Barrier option contract
#define BTR_INST_WARRANT          0xA    // Warrant contract
#define BTR_INST_PREDICTION       0xB    // Contract based on predicted outcomes
#define BTR_INST_STRUCTURED       0xC    // Financial instruments with multiple components
#define BTR_INST_RESERVED_D       0xD    // Reserved for future use
#define BTR_INST_RESERVED_E       0xE    // Reserved for future use
#define BTR_INST_RESERVED_F       0xF    // Reserved for future use

//+------------------------------------------------------------------+
//| BTR Asset Classes (uint8)                                       |
//+------------------------------------------------------------------+
#define BTR_ASSET_EQUITIES        0x0    // AAPL, MSFT, GOOGL
#define BTR_ASSET_CORP_BONDS      0x1    // Corporate debt securities
#define BTR_ASSET_SOVEREIGN_DEBT  0x2    // Government bonds, treasuries
#define BTR_ASSET_FOREX           0x3    // EUR, USD, JPY, GBP
#define BTR_ASSET_COMMODITIES     0x4    // WTI, Brent, Gold, Silver
#define BTR_ASSET_PRECIOUS_METALS 0x5    // Gold, Silver, Platinum
#define BTR_ASSET_REAL_ESTATE     0x6    // REITs, property indices
#define BTR_ASSET_CRYPTO          0x7    // BTC, ETH, USDC, SOL
#define BTR_ASSET_PRIVATE_MARKETS 0x8    // Investments in private companies
#define BTR_ASSET_COLLECTIBLES    0x9    // Art, antiques, rare items
#define BTR_ASSET_INFRASTRUCTURE  0xA    // Investments in physical assets
#define BTR_ASSET_INDICES         0xB    // Market indices and related products
#define BTR_ASSET_STRUCTURED      0xC    // Financial instruments with multiple components
#define BTR_ASSET_CASH_EQUIV      0xD    // Cash and cash-like instruments
#define BTR_ASSET_LOANS           0xE    // Debt instruments and receivables
#define BTR_ASSET_RESERVED        0xF    // Reserved for future use

//+------------------------------------------------------------------+
//| Currency Lookup Functions                                       |
//+------------------------------------------------------------------+

// Get BTR currency ID from ISO code
uint GetBTRCurrencyFromISO(string iso_code)
{
   if(iso_code == "ARS") return BTR_CURRENCY_ARS;
   if(iso_code == "AUD") return BTR_CURRENCY_AUD;
   if(iso_code == "BRL") return BTR_CURRENCY_BRL;
   if(iso_code == "GBP") return BTR_CURRENCY_GBP;
   if(iso_code == "CAD") return BTR_CURRENCY_CAD;
   if(iso_code == "CLP") return BTR_CURRENCY_CLP;
   if(iso_code == "CNY") return BTR_CURRENCY_CNY;
   if(iso_code == "COP") return BTR_CURRENCY_COP;
   if(iso_code == "CZK") return BTR_CURRENCY_CZK;
   if(iso_code == "DKK") return BTR_CURRENCY_DKK;
   if(iso_code == "EGP") return BTR_CURRENCY_EGP;
   if(iso_code == "EUR") return BTR_CURRENCY_EUR;
   if(iso_code == "HKD") return BTR_CURRENCY_HKD;
   if(iso_code == "HUF") return BTR_CURRENCY_HUF;
   if(iso_code == "INR") return BTR_CURRENCY_INR;
   if(iso_code == "IDR") return BTR_CURRENCY_IDR;
   if(iso_code == "ILS") return BTR_CURRENCY_ILS;
   if(iso_code == "JPY") return BTR_CURRENCY_JPY;
   if(iso_code == "KZT") return BTR_CURRENCY_KZT;
   if(iso_code == "KWD") return BTR_CURRENCY_KWD;
   if(iso_code == "MYR") return BTR_CURRENCY_MYR;
   if(iso_code == "MXN") return BTR_CURRENCY_MXN;
   if(iso_code == "MAD") return BTR_CURRENCY_MAD;
   if(iso_code == "TWD") return BTR_CURRENCY_TWD;
   if(iso_code == "NZD") return BTR_CURRENCY_NZD;
   if(iso_code == "NGN") return BTR_CURRENCY_NGN;
   if(iso_code == "NOK") return BTR_CURRENCY_NOK;
   if(iso_code == "PKR") return BTR_CURRENCY_PKR;
   if(iso_code == "PEN") return BTR_CURRENCY_PEN;
   if(iso_code == "PHP") return BTR_CURRENCY_PHP;
   if(iso_code == "PLN") return BTR_CURRENCY_PLN;
   if(iso_code == "QAR") return BTR_CURRENCY_QAR;
   if(iso_code == "RON") return BTR_CURRENCY_RON;
   if(iso_code == "RUB") return BTR_CURRENCY_RUB;
   if(iso_code == "SAR") return BTR_CURRENCY_SAR;
   if(iso_code == "RSD") return BTR_CURRENCY_RSD;
   if(iso_code == "SGD") return BTR_CURRENCY_SGD;
   if(iso_code == "ZAR") return BTR_CURRENCY_ZAR;
   if(iso_code == "KRW") return BTR_CURRENCY_KRW;
   if(iso_code == "LKR") return BTR_CURRENCY_LKR;
   if(iso_code == "SEK") return BTR_CURRENCY_SEK;
   if(iso_code == "CHF") return BTR_CURRENCY_CHF;
   if(iso_code == "THB") return BTR_CURRENCY_THB;
   if(iso_code == "TRY") return BTR_CURRENCY_TRY;
   if(iso_code == "AED") return BTR_CURRENCY_AED;
   if(iso_code == "UAH") return BTR_CURRENCY_UAH;
   if(iso_code == "USD") return BTR_CURRENCY_USD;
   if(iso_code == "VND") return BTR_CURRENCY_VND;
   
   return 0; // Unknown currency
}

// Get ISO code from BTR currency ID
string GetISOFromBTRCurrency(uint btr_id)
{
   switch(btr_id)
   {
      case BTR_CURRENCY_ARS: return "ARS";
      case BTR_CURRENCY_AUD: return "AUD";
      case BTR_CURRENCY_BRL: return "BRL";
      case BTR_CURRENCY_GBP: return "GBP";
      case BTR_CURRENCY_CAD: return "CAD";
      case BTR_CURRENCY_CLP: return "CLP";
      case BTR_CURRENCY_CNY: return "CNY";
      case BTR_CURRENCY_COP: return "COP";
      case BTR_CURRENCY_CZK: return "CZK";
      case BTR_CURRENCY_DKK: return "DKK";
      case BTR_CURRENCY_EGP: return "EGP";
      case BTR_CURRENCY_EUR: return "EUR";
      case BTR_CURRENCY_HKD: return "HKD";
      case BTR_CURRENCY_HUF: return "HUF";
      case BTR_CURRENCY_INR: return "INR";
      case BTR_CURRENCY_IDR: return "IDR";
      case BTR_CURRENCY_ILS: return "ILS";
      case BTR_CURRENCY_JPY: return "JPY";
      case BTR_CURRENCY_KZT: return "KZT";
      case BTR_CURRENCY_KWD: return "KWD";
      case BTR_CURRENCY_MYR: return "MYR";
      case BTR_CURRENCY_MXN: return "MXN";
      case BTR_CURRENCY_MAD: return "MAD";
      case BTR_CURRENCY_TWD: return "TWD";
      case BTR_CURRENCY_NZD: return "NZD";
      case BTR_CURRENCY_NGN: return "NGN";
      case BTR_CURRENCY_NOK: return "NOK";
      case BTR_CURRENCY_PKR: return "PKR";
      case BTR_CURRENCY_PEN: return "PEN";
      case BTR_CURRENCY_PHP: return "PHP";
      case BTR_CURRENCY_PLN: return "PLN";
      case BTR_CURRENCY_QAR: return "QAR";
      case BTR_CURRENCY_RON: return "RON";
      case BTR_CURRENCY_RUB: return "RUB";
      case BTR_CURRENCY_SAR: return "SAR";
      case BTR_CURRENCY_RSD: return "RSD";
      case BTR_CURRENCY_SGD: return "SGD";
      case BTR_CURRENCY_ZAR: return "ZAR";
      case BTR_CURRENCY_KRW: return "KRW";
      case BTR_CURRENCY_LKR: return "LKR";
      case BTR_CURRENCY_SEK: return "SEK";
      case BTR_CURRENCY_CHF: return "CHF";
      case BTR_CURRENCY_THB: return "THB";
      case BTR_CURRENCY_TRY: return "TRY";
      case BTR_CURRENCY_AED: return "AED";
      case BTR_CURRENCY_UAH: return "UAH";
      case BTR_CURRENCY_USD: return "USD";
      case BTR_CURRENCY_VND: return "VND";
      default: return "";
   }
}

//+------------------------------------------------------------------+
//| Symbol Cleanup Functions                                        |
//+------------------------------------------------------------------+

// Symbol cleanup cache using hash map
Hash* g_symbolCache = NULL;

// Initialize symbol cache
void InitializeSymbolCache()
{
   if(g_symbolCache == NULL)
      g_symbolCache = new Hash(53, true); // Start with moderate size, auto-adopt values
}

// Get cleaned symbol from cache or clean and cache it
string GetCleanedSymbol(string symbol)
{
   // Initialize cache if needed
   if(g_symbolCache == NULL)
      InitializeSymbolCache();
   
   // Check cache first
   HashString* cached = g_symbolCache.hGet(symbol);
   if(cached != NULL)
      return cached.getVal();
   
   // Clean symbol and add to cache
   string cleaned;
   CleanupSymbol(symbol, cleaned);
   
   // Store in cache
   g_symbolCache.hPutString(symbol, cleaned);
   
   return cleaned;
}

// Optimized symbol cleanup function
void CleanupSymbol(string symbol, string &target)
{
   target = symbol;
   
   // Remove common separators
   StringReplace(target, ".", "");
   StringReplace(target, "_", "");
   StringReplace(target, "/", "");
   
   // Convert to uppercase early
   StringToUpper(target);
   
   int len = StringLen(target);
   if(len < 3) return; // Invalid symbol
   
   // CRITICAL: Check if this looks like a 6-char forex pair before cleanup
   bool isCandidateForexPair = false;
   if(len == 6)
   {
      string base = StringSubstr(target, 0, 3);
      string quote = StringSubstr(target, 3, 3);
      if(IsValidCurrency(base) && IsValidCurrency(quote))
      {
         isCandidateForexPair = true;
         // For valid forex pairs, skip all cleanup and return as-is
         return;
      }
   }
   
   // Only apply cleanup to non-standard symbols
   // Remove single character suffixes (-m, -c, -z, -b, -r, -d, -i)
   string lastChar = StringSubstr(target, len-1, 1);
   if(lastChar == "M" || lastChar == "C" || lastChar == "Z" || 
      lastChar == "B" || lastChar == "R" || lastChar == "D" || lastChar == "I")
   {
      target = StringSubstr(target, 0, len-1);
      len = StringLen(target);
   }
   
   // Remove multi-character suffixes
   if(len > 4)
   {
      string suffix4 = StringSubstr(target, len-4, 4);
      if(suffix4 == "CASH" || suffix4 == "SPOT")
      {
         target = StringSubstr(target, 0, len-4);
         len = StringLen(target);
      }
      else if(len > 5)
      {
         string suffix5 = StringSubstr(target, len-5, 5);
         if(suffix5 == "MICRO")
         {
            target = StringSubstr(target, 0, len-5);
            len = StringLen(target);
         }
      }
   }
   
   // Remove "ZERO" suffix
   if(len > 4)
   {
      string suffix4 = StringSubstr(target, len-4, 4);
      if(suffix4 == "ZERO")
      {
         target = StringSubstr(target, 0, len-4);
         len = StringLen(target);
      }
   }
   
   // Remove "ECN" suffix
   if(len > 3)
   {
      string suffix3 = StringSubstr(target, len-3, 3);
      if(suffix3 == "ECN")
      {
         target = StringSubstr(target, 0, len-3);
         len = StringLen(target);
      }
   }
   
   // Apply aliases
   target = Unalias(target);
}

// Handle common symbol aliases
string Unalias(string symbol)
{
   // Gold/Silver aliases
   if(symbol == "GOLD" || symbol == "XAU") return "XAUUSD";
   if(symbol == "SILVER" || symbol == "XAG") return "XAGUSD";
   
   // Oil aliases
   if(symbol == "OIL" || symbol == "CRUDE") return "WTIUSD";
   if(symbol == "BRENT") return "BRENTUSD";
   
   // Crypto aliases
   if(symbol == "BTC") return "BTCUSD";
   if(symbol == "ETH") return "ETHUSD";
   
   // Ensure forex pairs have 6 characters
   if(StringLen(symbol) == 6)
   {
      // Check if it's a valid forex pair format
      string base = StringSubstr(symbol, 0, 3);
      string quote = StringSubstr(symbol, 3, 3);
      
      // Common currency validation
      if(IsValidCurrency(base) && IsValidCurrency(quote))
         return symbol;
   }
   
   return symbol;
}

// Basic currency validation
bool IsValidCurrency(string currency)
{
   // Check against BTR currency system
   return GetBTRCurrencyFromISO(currency) > 0;
}

// Get symbol cache size
int GetSymbolCacheSize()
{
   if(g_symbolCache == NULL)
      return 0;
   return g_symbolCache.getCount();
}

// Cleanup symbol cache (call on deinit)
void CleanupSymbolCache()
{
   if(g_symbolCache != NULL)
   {
      delete g_symbolCache;
      g_symbolCache = NULL;
   }
}

//+------------------------------------------------------------------+
//| Symbol Parsing Functions                                        |
//+------------------------------------------------------------------+

// Parse MQL4 forex symbol to BTR currency pair (with symbol cleanup)
void ParseForexSymbol(string symbol, uint &base_currency, uint &quote_currency)
{
   // Clean symbol first
   string cleaned = GetCleanedSymbol(symbol);
   
   if(StringLen(cleaned) < 6)
   {
      base_currency = 0;
      quote_currency = 0;
      return;
   }
   
   string base = StringSubstr(cleaned, 0, 3);
   string quote = StringSubstr(cleaned, 3, 3);
   
   base_currency = GetBTRCurrencyFromISO(base);
   quote_currency = GetBTRCurrencyFromISO(quote);
}

// Generate MITCH ticker ID for forex pair (proper specification format)
ulong GetMitchTickerID(string symbol)
{
   uint base_currency, quote_currency;
   ParseForexSymbol(symbol, base_currency, quote_currency);
   
   if(base_currency == 0 || quote_currency == 0)
   {
      // Fallback to hash-based ID for unknown currencies
      ulong hash = 0;
      string cleaned = GetCleanedSymbol(symbol);
      for(int i = 0; i < StringLen(cleaned); i++)
      {
         hash = hash * 31 + StringGetCharacter(cleaned, i);
      }
      return (((ulong)BTR_INST_SPOT << 60) | 
              ((ulong)BTR_ASSET_FOREX << 56) | 
              (hash & 0xFFFFFFFFFFFFFF));
   }
   
   // MITCH Format: [4-bit inst type][20-bit base asset][20-bit quote asset][20-bit sub-type]
   // Per specification: Base and Quote assets are the currency IDs directly
   // EUR = 111 = 0x6F, USD = 461 = 0x1CD
   
   ulong base_asset = base_currency & 0xFFFFF;   // 20-bit base asset (currency ID)
   ulong quote_asset = quote_currency & 0xFFFFF; // 20-bit quote asset (currency ID)
   ulong sub_type = 0; // For spot forex, sub-type is 0
   
   return (((ulong)BTR_INST_SPOT << 60) |     // 4-bit instrument type
           (base_asset << 40) |                // 20-bit base asset
           (quote_asset << 20) |               // 20-bit quote asset
           sub_type);                          // 20-bit sub-type
}

// Legacy function for backward compatibility
ulong GenerateBTRForexTickerID(string symbol)
{
   return GetMitchTickerID(symbol);
}

//+------------------------------------------------------------------+
//| MITCH Ticker ID Analysis Functions                              |
//+------------------------------------------------------------------+

// Extract components from MITCH ticker ID
uchar GetMitchInstrumentType(ulong ticker_id)
{
   return (uchar)((ticker_id >> 60) & 0xF);
}

ulong GetMitchBaseAsset(ulong ticker_id)
{
   return (ticker_id >> 40) & 0xFFFFF; // 20 bits
}

ulong GetMitchQuoteAsset(ulong ticker_id)
{
   return (ticker_id >> 20) & 0xFFFFF; // 20 bits
}

ulong GetMitchSubType(ulong ticker_id)
{
   return ticker_id & 0xFFFFF; // 20 bits
}

// Extract currency IDs from asset fields  
uint GetCurrencyFromMitchAsset(ulong asset)
{
   return (uint)(asset & 0xFFFFF); // Full 20-bit asset is now the currency ID
}

uchar GetAssetClassFromMitchAsset(ulong asset)
{
   return BTR_ASSET_FOREX; // All assets in our system are forex (0x3)
}

// Analyze MITCH ticker ID
string AnalyzeMitchTickerID(ulong ticker_id)
{
   uchar inst_type = GetMitchInstrumentType(ticker_id);
   ulong base_asset = GetMitchBaseAsset(ticker_id);
   ulong quote_asset = GetMitchQuoteAsset(ticker_id);
   ulong sub_type = GetMitchSubType(ticker_id);
   
   uint base_currency = GetCurrencyFromMitchAsset(base_asset);
   uint quote_currency = GetCurrencyFromMitchAsset(quote_asset);
   
   string base_iso = GetISOFromBTRCurrency(base_currency);
   string quote_iso = GetISOFromBTRCurrency(quote_currency);
   
   return StringFormat("MITCH ID: 0x%016llX | Type: 0x%X | %s/%s | Base: %s(%d) | Quote: %s(%d) | Sub: 0x%05X",
                       ticker_id, inst_type, base_iso, quote_iso, 
                       base_iso, base_currency, quote_iso, quote_currency, sub_type);
}

// Analyze symbol cleanup (for debugging)
string AnalyzeSymbolCleanup(string original_symbol)
{
   string cleaned = GetCleanedSymbol(original_symbol);
   ulong ticker_id = GetMitchTickerID(cleaned);
   
   return StringFormat("%s -> %s | %s", original_symbol, cleaned, AnalyzeMitchTickerID(ticker_id));
}

// Legacy functions for backward compatibility
uchar GetInstrumentType(ulong ticker_id)
{
   return GetMitchInstrumentType(ticker_id);
}

uchar GetAssetClass(ulong ticker_id)
{
   return BTR_ASSET_FOREX;
}

uint GetBaseCurrency(ulong ticker_id)
{
   return GetCurrencyFromMitchAsset(GetMitchBaseAsset(ticker_id));
}

uint GetQuoteCurrency(ulong ticker_id)
{
   return GetCurrencyFromMitchAsset(GetMitchQuoteAsset(ticker_id));
} 