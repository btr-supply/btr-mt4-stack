//+------------------------------------------------------------------+
//|                                                       BTRIds.mqh |
//|                 Copyright BTR Supply (Refactored)                |
//|                         https://btr.supply                       |
//+------------------------------------------------------------------+
#property strict

#include "BTRHashMap.mqh"
#include "BTRUtils.mqh"

//+------------------------------------------------------------------+
//| Global Hash Maps for Dynamic Asset Resolution                   |
//+------------------------------------------------------------------+

Hash* g_symbolCache = NULL;          // Symbol cleanup cache
Hash* g_assetSymbolMap = NULL;       // Symbol -> BTR Asset ID mapping
Hash* g_marketProviderCache = NULL;  // Broker name -> Provider ID mapping
Hash* g_assetClassMap = NULL;        // Asset class name -> ID mapping
Hash* g_instrumentTypeMap = NULL;    // Instrument type name -> ID mapping

bool g_assetsInitialized = false;

//+------------------------------------------------------------------+
//| Asset Class Mapping Configuration                               |
//+------------------------------------------------------------------+

// Only hardcoded mapping: filename -> asset class name
struct AssetFileMapping
{
   string filename;
   string asset_class_name;
};

AssetFileMapping g_assetFileMappings[] = {
   {"currencies.csv", "Forex"},      // Load currencies first to establish key symbols
   {"commodities.csv", "Commodities"},
   {"indices.csv", "Indices & Index Products"},
   {"tokens.csv", "Crypto Assets"}
};

//+------------------------------------------------------------------+
//| Dynamic Asset Loading Functions                                  |
//+------------------------------------------------------------------+

// Load asset classes from CSV
bool LoadAssetClasses()
{
   CSVData csv_data;
   if(!LoadCSVData("ids/asset-classes.csv", csv_data)) return false;
   
   int btr_id_col = GetColumnIndex(csv_data, "btr_id");
   int name_col = GetColumnIndex(csv_data, "name");
   
   if(btr_id_col < 0 || name_col < 0)
   {
      Print("ERROR: asset-classes.csv missing required columns");
      return false;
   }
   
   int loaded = 0;
   for(int i = 0; i < csv_data.rows; i++)
   {
      string btr_id_str = GetCellByIndex(csv_data, i, btr_id_col);
      string name = GetCellByIndex(csv_data, i, name_col);
      
      if(StringLen(btr_id_str) > 0 && StringLen(name) > 0)
      {
         uint btr_id = (uint)StringToInteger(btr_id_str);
         g_assetClassMap.hPutLong(name, btr_id);
         loaded++;
      }
   }
   
   Print("Loaded " + IntegerToString(loaded) + " asset classes");
   return loaded > 0;
}

// Load instrument types from CSV
bool LoadInstrumentTypes()
{
   CSVData csv_data;
   if(!LoadCSVData("ids/instrument-types.csv", csv_data)) return false;
   
   int btr_id_col = GetColumnIndex(csv_data, "btr_id");
   int name_col = GetColumnIndex(csv_data, "name");
   
   if(btr_id_col < 0 || name_col < 0)
   {
      Print("ERROR: instrument-types.csv missing required columns");
      return false;
   }
   
   int loaded = 0;
   for(int i = 0; i < csv_data.rows; i++)
   {
      string btr_id_str = GetCellByIndex(csv_data, i, btr_id_col);
      string name = GetCellByIndex(csv_data, i, name_col);
      
      if(StringLen(btr_id_str) > 0 && StringLen(name) > 0)
      {
         uint btr_id = (uint)StringToInteger(btr_id_str);
         g_instrumentTypeMap.hPutLong(name, btr_id);
         loaded++;
      }
   }
   
   Print("Loaded " + IntegerToString(loaded) + " instrument types");
   return loaded > 0;
}

// Get asset class ID by name (dynamic lookup)
uint GetAssetClassID(string asset_class_name)
{
   HashLong* asset_class = (HashLong*)g_assetClassMap.hGet(asset_class_name);
   if(asset_class != NULL) return (uint)asset_class.getVal();
   return 0;
}

// Get instrument type ID by name (dynamic lookup)
uint GetInstrumentTypeID(string instrument_type_name)
{
   HashLong* instrument_type = (HashLong*)g_instrumentTypeMap.hGet(instrument_type_name);
   if(instrument_type != NULL) return (uint)instrument_type.getVal();
   return 0;
}

// Generic asset loading function
bool LoadAssetType(string filename, string asset_class_name)
{
   CSVData csv_data;
   if(!LoadCSVData("ids/" + filename, csv_data)) return false;
   
   int btr_id_col = GetColumnIndex(csv_data, "btr_id");
   int name_col = GetColumnIndex(csv_data, "name");
   int aliases_col = GetColumnIndex(csv_data, "aliases");
   
   if(btr_id_col < 0 || name_col < 0)
   {
      Print("ERROR: " + filename + " missing required columns (btr_id, name)");
      return false;
   }
   
   // Get asset class ID dynamically
   uint asset_class_id = GetAssetClassID(asset_class_name);
   if(asset_class_id == 0)
   {
      Print("ERROR: Asset class not found: " + asset_class_name);
      return false;
   }
   
   Print("DEBUG: Loading " + filename + " with asset class '" + asset_class_name + "' (ID: " + IntegerToString(asset_class_id) + ")");
   
   int loaded = 0;
   for(int i = 0; i < csv_data.rows; i++)
   {
      string btr_id_str = GetCellByIndex(csv_data, i, btr_id_col);
      string name = GetCellByIndex(csv_data, i, name_col);
      string aliases = (aliases_col >= 0) ? GetCellByIndex(csv_data, i, aliases_col) : "";
      
      if(StringLen(btr_id_str) > 0 && StringLen(name) > 0)
      {
         uint btr_id = (uint)StringToInteger(btr_id_str);
         
         // Create MITCH asset ID: 4 bits class + 16 bits BTR ID (stored in 32-bit with 12 bits padding)
         // Format: 0x000CXXXX where C is class (4 bits) and XXXX is BTR ID (16 bits)
         uint asset_id = (asset_class_id << 16) | (btr_id & 0xFFFF);
         
         // Store primary name with collision detection
         string clean_name;
         CleanupSymbol(name, clean_name);
         
         // Check for collisions with important currency symbols
         HashLong* existing = (HashLong*)g_assetSymbolMap.hGet(clean_name);
         bool is_forex_override = (asset_class_name == "Forex");
         bool is_protected_symbol = (clean_name == "EUR" || clean_name == "USD" || clean_name == "GBP" || 
                                   clean_name == "JPY" || clean_name == "CHF" || clean_name == "CAD" || 
                                   clean_name == "AUD" || clean_name == "NZD");
         
         // Debug collision detection
         if(clean_name == "EUR" || clean_name == "USD")
         {
            Print("DEBUG COLLISION: " + clean_name + " in " + filename + 
                  " | existing=" + (existing != NULL ? "YES" : "NO") + 
                  " | protected=" + (is_protected_symbol ? "YES" : "NO") + 
                  " | forex=" + (is_forex_override ? "YES" : "NO"));
         }
         
         if(existing != NULL && is_protected_symbol && !is_forex_override)
         {
            Print("WARNING: Skipping collision for protected currency symbol '" + clean_name + 
                  "' in " + filename + " (protected by existing currency mapping)");
            // Don't increment loaded counter for skipped assets
         }
         else
         {
            if(existing != NULL && !is_forex_override)
            {
               Print("DEBUG: Overwriting existing mapping for '" + clean_name + "' with " + asset_class_name + " asset");
            }
            g_assetSymbolMap.hPutLong(clean_name, asset_id);
            loaded++;
            
            // Debug output for key currencies
            if(name == "Euro" || name == "US Dollar" || clean_name == "EUR" || clean_name == "USD")
            {
               Print("DEBUG: " + name + " (" + clean_name + ") -> Class: " + IntegerToString(asset_class_id) + 
                     ", BTR ID: " + IntegerToString(btr_id) + ", Asset ID: 0x" + IntegerToString(asset_id, 16));
            }
         }
         
         // Store aliases with collision detection
         if(StringLen(aliases) > 0)
         {
            string alias_array[];
            int alias_count = StringSplit(aliases, '|', alias_array);
            for(int j = 0; j < alias_count; j++)
            {
               string clean_alias;
               CleanupSymbol(alias_array[j], clean_alias);
               if(StringLen(clean_alias) > 0)
               {
                  // Apply same collision protection for aliases
                  HashLong* existing_alias = (HashLong*)g_assetSymbolMap.hGet(clean_alias);
                  bool is_protected_alias = (clean_alias == "EUR" || clean_alias == "USD" || clean_alias == "GBP" || 
                                           clean_alias == "JPY" || clean_alias == "CHF" || clean_alias == "CAD" || 
                                           clean_alias == "AUD" || clean_alias == "NZD");
                  
                  if(existing_alias != NULL && is_protected_alias && !is_forex_override)
                  {
                     Print("WARNING: Skipping alias collision for protected currency symbol '" + clean_alias + 
                           "' (" + alias_array[j] + ") in " + filename);
                  }
                  else
                  {
                     g_assetSymbolMap.hPutLong(clean_alias, asset_id);
                     
                     // Debug output for key aliases
                     if(clean_alias == "EUR" || clean_alias == "USD")
                     {
                        Print("DEBUG: Alias " + alias_array[j] + " (" + clean_alias + ") -> Asset ID: 0x" + IntegerToString(asset_id, 16));
                     }
                  }
               }
            }
         }
      }
   }
   
   Print("Loaded " + IntegerToString(loaded) + " assets from " + filename + " (class: " + asset_class_name + ")");
   return loaded > 0;
}

// Load market providers
bool LoadMarketProviders()
{
   CSVData csv_data;
   if(!LoadCSVData("ids/market-providers.csv", csv_data)) return false;
   
   int btr_id_col = GetColumnIndex(csv_data, "btr_id");
   int name_col = GetColumnIndex(csv_data, "name");
   
   if(btr_id_col < 0 || name_col < 0)
   {
      Print("ERROR: market-providers.csv missing required columns");
      return false;
   }
   
   int loaded = 0;
   for(int i = 0; i < csv_data.rows; i++)
   {
      string btr_id_str = GetCellByIndex(csv_data, i, btr_id_col);
      string name = GetCellByIndex(csv_data, i, name_col);
      
      if(StringLen(btr_id_str) > 0 && StringLen(name) > 0)
      {
         uint btr_id = (uint)StringToInteger(btr_id_str);
         StringToUpper(name);
         g_marketProviderCache.hPutLong(name, btr_id);
         loaded++;
      }
   }
   
   Print("Loaded " + IntegerToString(loaded) + " market providers");
   return loaded > 0;
}

//+------------------------------------------------------------------+
//| Initialization Functions                                         |
//+------------------------------------------------------------------+

void InitializeBTRCaches()
{
   if(g_symbolCache == NULL)
      g_symbolCache = new Hash(53, true);
   if(g_assetSymbolMap == NULL)
      g_assetSymbolMap = new Hash(503, true); // Larger for all assets
   if(g_marketProviderCache == NULL)
      g_marketProviderCache = new Hash(53, true);
   if(g_assetClassMap == NULL)
      g_assetClassMap = new Hash(17, true);
   if(g_instrumentTypeMap == NULL)
      g_instrumentTypeMap = new Hash(17, true);
}

bool InitializeBTRAssets()
{
   if(g_assetsInitialized) return true;
   
   Print("=== Initializing BTR Asset Mappings ===");
   
   InitializeBTRCaches();
   
   bool success = true;
   success &= LoadAssetClasses();
   success &= LoadInstrumentTypes();
   
   // Load all asset types using dynamic mapping
   for(int i = 0; i < ArraySize(g_assetFileMappings); i++)
   {
      success &= LoadAssetType(g_assetFileMappings[i].filename, g_assetFileMappings[i].asset_class_name);
   }
   
   success &= LoadMarketProviders();
   
   if(success)
   {
      g_assetsInitialized = true;
      Print("=== BTR Asset Mappings Initialized Successfully ===");
      Print("Total asset symbols loaded: " + IntegerToString(g_assetSymbolMap.getCount()));
   }
   else
   {
      Print("=== ERROR: Failed to initialize BTR Asset Mappings ===");
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Symbol Cleanup and Caching                                      |
//+------------------------------------------------------------------+

// Get cleaned symbol (caching layer)
string GetCleanedSymbol(string symbol)
{
   if(g_symbolCache == NULL) InitializeBTRCaches();

   HashString* cached = (HashString*)g_symbolCache.hGet(symbol);
   if(cached != NULL) return cached.getVal();

   string cleaned_symbol;
   CleanupSymbol(symbol, cleaned_symbol);

   g_symbolCache.hPutString(symbol, cleaned_symbol);
   return cleaned_symbol;
}

//+------------------------------------------------------------------+
//| Unified Asset Resolution Functions                               |
//+------------------------------------------------------------------+

// Get BTR asset ID from symbol (unified resolver)
ulong GetBTRAssetFromSymbol(const string symbol)
{
   if(!g_assetsInitialized) InitializeBTRAssets();
   
   string cleaned = GetCleanedSymbol(symbol);
   
   HashLong* asset = (HashLong*)g_assetSymbolMap.hGet(cleaned);
   if(asset != NULL) return asset.getVal();
   
   return 0; // Unknown asset
}

// Parse symbol into base and quote assets (enhanced for all asset types)
bool ParseSymbolAssets(string symbol, ulong &base_asset, ulong &quote_asset)
{
   string cleaned = GetCleanedSymbol(symbol);
   
   // Try forex pair parsing first (6 characters)
   if(StringLen(cleaned) == 6)
   {
      string base_symbol = StringSubstr(cleaned, 0, 3);
      string quote_symbol = StringSubstr(cleaned, 3, 3);
      
      base_asset = GetBTRAssetFromSymbol(base_symbol);
      quote_asset = GetBTRAssetFromSymbol(quote_symbol);
      
      if(base_asset > 0 && quote_asset > 0)
      {
         // Debug output commented out to reduce test log verbosity
         // Print("DEBUG: Parsed forex pair " + cleaned + " -> Base: " + base_symbol + 
         //       " (0x" + IntegerToString(base_asset, 16) + "), Quote: " + quote_symbol + 
         //       " (0x" + IntegerToString(quote_asset, 16) + ")");
         return true;
      }
   }
   
   // Try as single asset (commodity, index, etc.)
   base_asset = GetBTRAssetFromSymbol(cleaned);
   if(base_asset > 0)
   {
      // Default to USD as quote asset
      quote_asset = GetBTRAssetFromSymbol("USD");
      if(quote_asset == 0)
      {
         // Fallback: Create USD asset ID manually (Forex class=3, USD ID=461)
         // Use hardcoded Forex class=3 to avoid dependency issues during initialization
         quote_asset = (3 << 16) | 461;  // 0x301CD
         // Debug output commented out to reduce test log verbosity
         // Print("DEBUG: Created fallback USD asset ID: 0x" + IntegerToString(quote_asset, 16) + " (should be 0x301CD)");
      }
      
      // Debug output commented out to reduce test log verbosity
      // Print("DEBUG: Parsed single asset " + cleaned + " -> Base: 0x" + IntegerToString(base_asset, 16) + 
      //       ", Quote: USD (0x" + IntegerToString(quote_asset, 16) + ")");
      return true;
   }
   
   Print("DEBUG: Failed to parse symbol: " + cleaned);
   return false;
}

// Generate MITCH ticker ID (fully dynamic)
ulong GetMitchTickerID(string symbol)
{
   ulong base_asset, quote_asset;
   
   if(ParseSymbolAssets(symbol, base_asset, quote_asset))
   {
      // Use dynamic instrument type lookup (default to SPOT)
      uint spot_inst_type = GetInstrumentTypeID("Spot");
      if(spot_inst_type == 0) spot_inst_type = 0; // Fallback to 0 if not found
      
      ulong sub_type = 0;
      
      // MITCH Ticker ID Format (64 bits):
      // Bits 63-60: Instrument Type (4 bits)
      // Bits 59-40: Base Asset (20 bits) - 4 bits class + 16 bits ID
      // Bits 39-20: Quote Asset (20 bits) - 4 bits class + 16 bits ID
      // Bits 19-0:  Sub-Type (20 bits)
      
      // The base_asset and quote_asset are already 20-bit values (class + ID)
      // We need to mask them to ensure they fit in 20 bits
      ulong base_20bit = base_asset & 0xFFFFF;   // 20 bits
      ulong quote_20bit = quote_asset & 0xFFFFF; // 20 bits
      
      ulong ticker_id = ((ulong)spot_inst_type << 60) |
                        (base_20bit << 40) |
                        (quote_20bit << 20) |
                        sub_type;
      
      // Debug output for key symbols (only for initial validation)
      // Commented out to reduce test log verbosity
      /*
      string cleaned = GetCleanedSymbol(symbol);
      if(cleaned == "EURUSD" || cleaned == "EUR" || cleaned == "USD")
      {
         Print("DEBUG: " + symbol + " -> " + cleaned);
         Print("  Instrument Type: 0x" + IntegerToString(spot_inst_type, 16));
         Print("  Base Asset: 0x" + IntegerToString(base_asset, 16) + " (20-bit: 0x" + IntegerToString(base_20bit, 16) + ")");
         Print("  Quote Asset: 0x" + IntegerToString(quote_asset, 16) + " (20-bit: 0x" + IntegerToString(quote_20bit, 16) + ")");
         Print("  Sub-Type: 0x" + IntegerToString(sub_type, 16));
         Print("  Final Ticker ID: 0x" + IntegerToString(ticker_id, 16) + " (" + IntegerToString(ticker_id) + ")");
      }
      */
      
      return ticker_id;
   }
   
   // Fallback hash logic for unknown symbols
   ulong hash = 0;
   string cleaned = GetCleanedSymbol(symbol);
   for(int i = 0; i < StringLen(cleaned); i++)
      hash = hash * 31 + StringGetCharacter(cleaned, i);

   // Use dynamic lookups for fallback
   uint spot_inst_type = GetInstrumentTypeID("Spot");
   uint forex_class_id = GetAssetClassID("Forex");
   if(spot_inst_type == 0) spot_inst_type = 0;
   if(forex_class_id == 0) forex_class_id = 3; // Last resort fallback

   return ((ulong)spot_inst_type << 60) |
          ((ulong)forex_class_id << 56) | 
          (hash & 0x00FFFFFFFFFFFFFF);
}

//+------------------------------------------------------------------+
//| Market Provider Functions                                        |
//+------------------------------------------------------------------+

// Get BTR market provider ID from broker name
uint GetBTRMarketProviderFromBroker(const string broker_name)
{
   if(!g_assetsInitialized) InitializeBTRAssets();
   
   string name = broker_name;
   StringToUpper(name);
   
   HashLong* cached = (HashLong*)g_marketProviderCache.hGet(name);
   if(cached != NULL) return (uint)cached.getVal();
   
   return 0; // Unknown market provider
}

// Get current market provider ID from AccountCompany()
uint GetCurrentMarketProviderID()
{
   return GetBTRMarketProviderFromBroker(AccountCompany());
}

//+------------------------------------------------------------------+
//| MITCH Ticker ID Analysis Functions                              |
//+------------------------------------------------------------------+

// Extract components from MITCH ticker ID
uint GetMitchInstrumentType(ulong ticker_id)
{
   return (uint)((ticker_id >> 60) & 0xF);
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

// Extract asset class and ID from asset field  
uint GetAssetClassFromMitchAsset(ulong asset)
{
   return (uint)((asset >> 16) & 0xF); // Upper 4 bits of the 20-bit asset
}

uint GetAssetIDFromMitchAsset(ulong asset)
{
   return (uint)(asset & 0xFFFF); // Lower 16 bits of the 20-bit asset
}

// Analyze MITCH ticker ID
string AnalyzeMitchTickerID(ulong ticker_id)
{
   uint inst_type = GetMitchInstrumentType(ticker_id);
   ulong base_asset = GetMitchBaseAsset(ticker_id);
   ulong quote_asset = GetMitchQuoteAsset(ticker_id);
   ulong sub_type = GetMitchSubType(ticker_id);
   
   uint base_class = GetAssetClassFromMitchAsset(base_asset);
   uint quote_class = GetAssetClassFromMitchAsset(quote_asset);
   uint base_id = GetAssetIDFromMitchAsset(base_asset);
   uint quote_id = GetAssetIDFromMitchAsset(quote_asset);
   
   return StringFormat("MITCH ID: 0x%016llX | Type: 0x%X | Base: 0x%05X(class:0x%X, id:%d) | Quote: 0x%05X(class:0x%X, id:%d) | Sub: 0x%05X",
                       ticker_id, inst_type, base_asset, base_class, base_id, quote_asset, quote_class, quote_id, sub_type);
}

// Analyze symbol cleanup (for debugging)
string AnalyzeSymbolCleanup(string original_symbol)
{
   string cleaned = GetCleanedSymbol(original_symbol);
   ulong ticker_id = GetMitchTickerID(cleaned);
   
   return StringFormat("%s -> %s | %s", original_symbol, cleaned, AnalyzeMitchTickerID(ticker_id));
}

//+------------------------------------------------------------------+
//| Utility Functions                                               |
//+------------------------------------------------------------------+

// Get symbol cache size
int GetSymbolCacheSize()
{
   if(g_symbolCache == NULL) return 0;
   return g_symbolCache.getCount();
}

// Get asset mapping size
int GetAssetMappingSize()
{
   if(g_assetSymbolMap == NULL) return 0;
   return g_assetSymbolMap.getCount();
}

// Cleanup caches
void CleanupBTRCaches()
{
   if(g_symbolCache != NULL)
   {
      delete g_symbolCache;
      g_symbolCache = NULL;
   }
   if(g_assetSymbolMap != NULL)
   {
      delete g_assetSymbolMap;
      g_assetSymbolMap = NULL;
   }
   if(g_marketProviderCache != NULL)
   {
      delete g_marketProviderCache;
      g_marketProviderCache = NULL;
   }
   if(g_assetClassMap != NULL)
   {
      delete g_assetClassMap;
      g_assetClassMap = NULL;
   }
   if(g_instrumentTypeMap != NULL)
   {
      delete g_instrumentTypeMap;
      g_instrumentTypeMap = NULL;
   }
   g_assetsInitialized = false;
}

//+------------------------------------------------------------------+
//| Legacy Compatibility Functions                                   |
//+------------------------------------------------------------------+

// Legacy function for backward compatibility
ulong GenerateBTRForexTickerID(string symbol)
{
   return GetMitchTickerID(symbol);
}

uint GetInstrumentType(ulong ticker_id)
{
   return GetMitchInstrumentType(ticker_id);
}

uint GetAssetClass(ulong ticker_id)
{
   return GetAssetClassFromMitchAsset(GetMitchBaseAsset(ticker_id));
}

uint GetBaseCurrency(ulong ticker_id)
{
   return GetAssetIDFromMitchAsset(GetMitchBaseAsset(ticker_id));
}

uint GetQuoteCurrency(ulong ticker_id)
{
   return GetAssetIDFromMitchAsset(GetMitchQuoteAsset(ticker_id));
}

// Basic asset validation
bool IsValidAsset(string symbol)
{
   return GetBTRAssetFromSymbol(symbol) > 0;
} 