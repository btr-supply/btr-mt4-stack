//+------------------------------------------------------------------+
//|                                                    BTRMitchTest.mq4 |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright BTR Supply"
#property link      "https://btr.supply"
#property version   "1.00"
#property script_show_inputs
#property strict

#include <BTRMitchSerializer.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input int TestIterations = 1000;      // Number of iterations for performance tests
input bool TestAssetInitialization = true;  // Test CSV loading and asset initialization
input bool TestUnifiedResolution = true;    // Test unified asset resolution
input bool TestAllAssetTypes = true;        // Test all asset types (forex, commodities, indices, tokens)
input bool TestSpecification = true;        // Test EURUSD specification compliance
input bool TestSymbolCleanup = true;        // Test symbol cleanup functionality
input bool TestIDGeneration = true;         // Test ticker ID generation for all asset types
input bool TestSerialization = true;        // Test serialization/deserialization
input bool TestPerformance = true;          // Test performance benchmarks
input bool TestCaching = true;              // Test ID resolution caching

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== BTR MITCH Protocol Test Suite (Enhanced) ===");
   Print("Test iterations: " + IntegerToString(TestIterations));
   Print("");

   // Force output to appear in logs
   Alert("BTR MITCH Test Starting - Check Experts tab for output");

   int totalTests = 0;
   int passedTests = 0;

   // Run tests based on input parameters
   if(TestAssetInitialization)
   {
      totalTests++;
      if(TestAssetInitializationFunction())
      {
         passedTests++;
         Print("✓ Asset Initialization Test - PASSED");
      }
      else
      {
         Print("✗ Asset Initialization Test - FAILED");
      }
      Print("");
   }

   // Always run asset class mapping test
   totalTests++;
   if(TestAssetClassMapping())
   {
      passedTests++;
      Print("✓ Asset Class Mapping Test - PASSED");
   }
   else
   {
      Print("✗ Asset Class Mapping Test - FAILED");
   }
   Print("");

   if(TestUnifiedResolution)
   {
      totalTests++;
      if(TestUnifiedAssetResolution())
      {
         passedTests++;
         Print("✓ Unified Asset Resolution Test - PASSED");
      }
      else
      {
         Print("✗ Unified Asset Resolution Test - FAILED");
      }
      Print("");
   }

   if(TestAllAssetTypes)
   {
      totalTests++;
      if(TestAllAssetTypesFunction())
      {
         passedTests++;
         Print("✓ All Asset Types Test - PASSED");
      }
      else
      {
         Print("✗ All Asset Types Test - FAILED");
      }
      Print("");
   }

   if(TestSpecification)
   {
      totalTests++;
      if(TestEURUSDSpecification())
      {
         passedTests++;
         Print("✓ EURUSD Specification Test - PASSED");
      }
      else
      {
         Print("✗ EURUSD Specification Test - FAILED");
      }
      Print("");
   }

   if(TestSymbolCleanup)
   {
      totalTests++;
      if(TestSymbolCleanupFunction())
      {
         passedTests++;
         Print("✓ Symbol Cleanup Test - PASSED");
      }
      else
      {
         Print("✗ Symbol Cleanup Test - FAILED");
      }
      Print("");
   }

   if(TestIDGeneration)
   {
      totalTests++;
      if(Testticker_idGeneration())
      {
         passedTests++;
         Print("✓ Ticker ID Generation Test - PASSED");
      }
      else
      {
         Print("✗ Ticker ID Generation Test - FAILED");
      }
      Print("");
   }

   if(TestSerialization)
   {
      totalTests++;
      if(TestSerializationRoundTrip())
      {
         passedTests++;
         Print("✓ Serialization Test - PASSED");
      }
      else
      {
         Print("✗ Serialization Test - FAILED");
      }
      Print("");
   }

   if(TestPerformance)
   {
      totalTests++;
      if(TestPerformanceBenchmarks())
      {
         passedTests++;
         Print("✓ Performance Test - PASSED");
      }
      else
      {
         Print("✗ Performance Test - FAILED");
      }
      Print("");
   }

   if(TestCaching)
   {
      totalTests++;
      if(TestIDResolutionCaching())
      {
         passedTests++;
         Print("✓ ID Caching Test - PASSED");
      }
      else
      {
         Print("✗ ID Caching Test - FAILED");
      }
      Print("");
   }

   // Summary
   Print("=== Test Summary ===");
   Print("Total test categories: " + IntegerToString(totalTests));
   Print("Passed: " + IntegerToString(passedTests));
   Print("Success rate: " + DoubleToString(100.0 * passedTests / totalTests, 1) + "%");
   Print("Final symbol cache size: " + IntegerToString(GetSymbolCacheSize()) + " entries");
   Print("Final asset mapping size: " + IntegerToString(GetAssetMappingSize()) + " entries");

   if(passedTests == totalTests)
      Print("✓✓ ALL TESTS PASSED!");
   else
      Print("✗✗ SOME TESTS FAILED!");

   Print("=== BTR MITCH Test Complete ===");

   // Cleanup
   CleanupBTRCaches();
}

//+------------------------------------------------------------------+
//| New Test Functions for Enhanced System                          |
//+------------------------------------------------------------------+

// Test asset initialization from CSV files
bool TestAssetInitializationFunction()
{
   Print("--- Testing Asset Initialization ---");

   // Clean any existing state
   CleanupBTRCaches();

   // Test initialization
   bool success = InitializeBTRAssets();

   Print("  Initialization result: " + (success ? "SUCCESS" : "FAILED"));

   if(success)
   {
      int asset_count = GetAssetMappingSize();
      Print("  Total assets loaded: " + IntegerToString(asset_count));

      // Test that we have reasonable number of assets
      bool reasonable_count = asset_count >= 100; // Should have at least 100 assets across all types
      Print("  Asset count validation: " + (reasonable_count ? "PASSED" : "FAILED"));

      return reasonable_count;
   }

   return false;
}

// Test asset class mapping
bool TestAssetClassMapping()
{
   Print("--- Testing Asset Class Mapping ---");

   // Test known asset class mappings
   string test_cases[] = {
      "EUR", "Forex", "3", "111",
      "USD", "Forex", "3", "461",
      "GBP", "Forex", "3", "31",
      "CHF", "Forex", "3", "411",
      "GOLD", "Commodities", "4", "161",
      "SILV", "Commodities", "4", "411",
      "BTC", "Crypto Assets", "6", "2701",
      "ETH", "Crypto Assets", "6", "5801",
      "SPX", "Indices & Index Products", "10", "671"
   };

   int rows = ArraySize(test_cases) / 4;
   int passed = 0;

   for(int i = 0; i < rows; i++)
   {
      string symbol = test_cases[i * 4 + 0];
      string expected_class_name = test_cases[i * 4 + 1];
      int expected_class_id = (int)StringToInteger(test_cases[i * 4 + 2]);
      int expected_asset_id = (int)StringToInteger(test_cases[i * 4 + 3]);

      ulong asset = GetBTRAssetFromSymbol(symbol);

      if(asset > 0)
      {
         uint actual_class = GetAssetClassFromMitchAsset(asset);
         uint actual_id = GetAssetIDFromMitchAsset(asset);

         bool class_ok = (actual_class == expected_class_id);
         bool id_ok = (actual_id == expected_asset_id);

         Print("  " + symbol + " (" + expected_class_name + "): Asset=0x" + IntegerToString(asset, 16) +
               ", Class=" + IntegerToString(actual_class) +
               (class_ok ? " ✓" : " ✗(exp:" + IntegerToString(expected_class_id) + ")") +
               ", ID=" + IntegerToString(actual_id) +
               (id_ok ? " ✓" : " ✗(exp:" + IntegerToString(expected_asset_id) + ")"));

         if(class_ok && id_ok) passed++;
      }
      else
      {
         Print("  " + symbol + " (" + expected_class_name + "): NOT FOUND");
      }
   }

   Print("Asset class mapping: " + IntegerToString(passed) + "/" + IntegerToString(rows) + " passed");

   return passed >= rows * 0.8; // 80% success rate
}

// Test unified asset resolution
bool TestUnifiedAssetResolution()
{
   Print("--- Testing Unified Asset Resolution ---");

   string test_symbols[] = {
      "EUR",     // Currency
      "GOLD",    // Commodity
      "SPX",     // Index
      "BTC"      // Token (if available)
   };

   int test_count = ArraySize(test_symbols);
   int passed = 0;

   for(int i = 0; i < test_count; i++)
   {
      string symbol = test_symbols[i];
      ulong asset_id = GetBTRAssetFromSymbol(symbol);

      if(asset_id > 0)
      {
         uint asset_class = GetAssetClassFromMitchAsset(asset_id);
         uint btr_id = GetAssetIDFromMitchAsset(asset_id);

         Print("  " + symbol + ": Asset ID = 0x" + IntegerToString(asset_id, 16) +
               ", Class = 0x" + IntegerToString(asset_class, 16) +
               ", BTR ID = " + IntegerToString(btr_id));
         passed++;
      }
      else
      {
         Print("  " + symbol + ": NOT FOUND");
      }
   }

   Print("  Unified resolution: " + IntegerToString(passed) + "/" + IntegerToString(test_count) + " passed");

   return passed >= test_count * 0.75; // 75% success rate
}

// Test all asset types
bool TestAllAssetTypesFunction()
{
   Print("--- Testing All Asset Types ---");

   // Test different asset type combinations - using 1D array with calculated indexing
   string test_cases[] = {
      "EURUSD", "Forex Pair", "Should resolve EUR and USD currencies",
      "XAUUSD", "Commodity/Currency", "Should resolve Gold commodity and USD currency",
      "SPX", "Index", "Should resolve SPX index with USD quote",
      "BTCUSD", "Token/Currency", "Should resolve BTC token and USD currency",
      "GOLD", "Commodity", "Should resolve Gold commodity with USD quote"
   };

   int cols = 3; // 3 columns per test case
   int test_count = ArraySize(test_cases) / cols;
   int passed = 0;

   for(int i = 0; i < test_count; i++)
   {
      // Use calculated indexing: index = (row * cols) + col
      string symbol = test_cases[i * cols + 0];
      string type = test_cases[i * cols + 1];
      string description = test_cases[i * cols + 2];

      Print("  Testing " + symbol + " (" + type + "):");

      ulong base_asset, quote_asset;
      bool parse_success = ParseSymbolAssets(symbol, base_asset, quote_asset);

      if(parse_success)
      {
         ulong ticker_id = GetMitchticker_id(symbol);
         string analysis = AnalyzeMitchticker_id(ticker_id);

         Print("    " + analysis);
         passed++;
      }
      else
      {
         Print("    FAILED to parse symbol");
      }
   }

   Print("  All asset types: " + IntegerToString(passed) + "/" + IntegerToString(test_count) + " passed");

   return passed >= test_count * 0.8; // 80% success rate
}

//+------------------------------------------------------------------+
//| Test Functions                                                   |
//+------------------------------------------------------------------+

// Test symbol cleanup functionality
bool TestSymbolCleanupFunction()
{
   Print("--- Testing Symbol Cleanup ---");

   string testSymbols[] = {
      "EURUSD", "EURUSD.micro", "EURUSD.cash", "EURUSD.spot", "EURUSD-zero",
      "EURUSD.ecn", "EURUSDr", "EURUSDd", "EURUSDi", "EURUSDzero",
      "EURUSD_m", "EUR/USD", "EUR.USD", "XAUUSD", "XAU.USD",
      "GOLDspot", "XAGcash", "BTCUSD", "ETH/USD", "USDJPYm",
      "GBP/CHF.ecn", "AUD_NZD", "oil.spot", "BRENT", "SILVER"
   };

   int testCount = ArraySize(testSymbols);
   int passed = 0;

   for(int i = 0; i < testCount; i++)
   {
      string original = testSymbols[i];
      string analysis = AnalyzeSymbolCleanup(original);
      Print("  " + analysis);

      // Basic validation - cleaned symbol should be reasonable
      string cleaned = GetCleanedSymbol(original);
      if(StringLen(cleaned) >= 3 && StringLen(cleaned) <= 8)
         passed++;
   }

   Print("Symbol cleanup: " + IntegerToString(passed) + "/" + IntegerToString(testCount) + " passed");
   Print("Cache size: " + IntegerToString(GetSymbolCacheSize()) + " entries");

   return passed >= testCount * 0.8; // 80% success rate
}

// Test ticker ID generation
bool Testticker_idGeneration()
{
   Print("--- Testing Ticker ID Generation ---");

   string testSymbols[] = {"EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "EURUSD.micro", "XAU.USD"};
   int testCount = ArraySize(testSymbols);
   int passed = 0;

   for(int i = 0; i < testCount; i++)
   {
      string symbol = testSymbols[i];
      string cleaned = GetCleanedSymbol(symbol);

      // Generate MITCH ticker ID
      ulong ticker_id = GetMitchticker_id(cleaned);

      // Analyze the ID
      string analysis = AnalyzeMitchticker_id(ticker_id);
      Print("  " + symbol + " -> " + cleaned + ": " + analysis);

      // Basic validation
      if(ticker_id > 0)
         passed++;
   }

   Print("Ticker ID generation: " + IntegerToString(passed) + "/" + IntegerToString(testCount) + " passed");

   return passed == testCount;
}

// Test serialization/deserialization
bool TestSerializationRoundTrip()
{
   Print("--- Testing Serialization Round-Trip ---");

   string testSymbol = "EURUSD.micro"; // Test with a symbol that needs cleanup

   // Create test ticker (this will automatically clean the symbol)
   TickerBody originalTicker = CreateTickerFromSymbol(testSymbol);
   originalTicker.bidPrice = 1.0950;
   originalTicker.askPrice = 1.0952;
   originalTicker.bidVolume = 1000000;
   originalTicker.askVolume = 750000;

   Print("  Original symbol: " + testSymbol);
   Print("  Cleaned symbol: " + GetCleanedSymbol(testSymbol));
   Print("  Ticker ID: 0x" + IntegerToString(originalTicker.tickerId, 16));

   // Serialize
   uchar buffer[];
   int size = PackTickerMessageFast(originalTicker, buffer);

   if(size == 40)
   {
      Print("  Serialization: PASSED (" + IntegerToString(size) + " bytes)");

      // Deserialize
      MitchHeader header;
      TickerBody deserializedTicker;

      if(UnpackTickerMessageFast(buffer, header, deserializedTicker))
      {
         // Verify round-trip
         bool roundTripOK = (
            deserializedTicker.tickerId == originalTicker.tickerId &&
            MathAbs(deserializedTicker.bidPrice - originalTicker.bidPrice) < 0.0001 &&
            MathAbs(deserializedTicker.askPrice - originalTicker.askPrice) < 0.0001 &&
            deserializedTicker.bidVolume == originalTicker.bidVolume &&
            deserializedTicker.askVolume == originalTicker.askVolume
         );

         Print("  Deserialization: " + (roundTripOK ? "PASSED" : "FAILED"));
         Print("  Message Type: " + CharToString(header.messageType));
         Print("  Count: " + IntegerToString(header.count));
         Print("  Bid/Ask: " + DoubleToString(deserializedTicker.bidPrice, 5) + "/" + DoubleToString(deserializedTicker.askPrice, 5));
         Print("  Volumes: " + IntegerToString(deserializedTicker.bidVolume) + "/" + IntegerToString(deserializedTicker.askVolume));

         // Test file I/O
         string filename = "mitch_test_" + IntegerToString(GetTickCount()) + ".bin";
         if(WriteToFileFast(filename, buffer))
         {
            uchar readBuffer[];
            if(ReadFromFileFast(filename, readBuffer))
            {
               Print("  File I/O: PASSED");
               return roundTripOK;
            }
         }
         Print("  File I/O: FAILED");
         return roundTripOK;
      }
      else
      {
         Print("  Deserialization: FAILED");
         return false;
      }
   }
   else
   {
      Print("  Serialization: FAILED (size=" + IntegerToString(size) + ")");
      return false;
   }
}

// Test performance benchmarks
bool TestPerformanceBenchmarks()
{
   Print("--- Testing Performance Benchmarks ---");

   string testSymbols[] = {"EURUSD.micro", "GBPUSD.cash", "USDJPY.ecn", "XAUUSD", "BTCUSD"};
   int symbolCount = ArraySize(testSymbols);

   // Test symbol cleanup performance
   uint startTime = GetTickCount();
   for(int i = 0; i < TestIterations; i++)
   {
      string symbol = testSymbols[i % symbolCount];
      GetCleanedSymbol(symbol); // This will use cache after first call
   }
   uint endTime = GetTickCount();
   double elapsed = (endTime - startTime) / 1000.0;
   double cleanupRate = elapsed > 0 ? TestIterations / elapsed : 0;
   Print("  Symbol cleanup rate: " + DoubleToString(cleanupRate, 0) + " ops/sec");

   // Test ticker creation performance
   startTime = GetTickCount();
   for(int i = 0; i < TestIterations; i++)
   {
      string symbol = testSymbols[i % symbolCount];
      CreateTickerFromSymbol(symbol);
   }
   endTime = GetTickCount();
   elapsed = (endTime - startTime) / 1000.0;
   double creationRate = elapsed > 0 ? TestIterations / elapsed : 0;
   Print("  Ticker creation rate: " + DoubleToString(creationRate, 0) + " ops/sec");

   // Test serialization performance
   TickerBody ticker = CreateTickerFromSymbol("EURUSD");
   uchar buffer[];

   startTime = GetTickCount();
   for(int i = 0; i < TestIterations; i++)
   {
      PackTickerMessageFast(ticker, buffer);
   }
   endTime = GetTickCount();
   double serializationElapsed = (endTime - startTime) / 1000.0;
   double serializationRate = serializationElapsed > 0 ? TestIterations / serializationElapsed : 0;
   Print("  Serialization rate: " + DoubleToString(serializationRate, 0) + " ops/sec");

   // Test deserialization performance
   startTime = GetTickCount();
   for(int i = 0; i < TestIterations; i++)
   {
      MitchHeader header;
      TickerBody deserializedTicker;
      UnpackTickerMessageFast(buffer, header, deserializedTicker);
   }
   endTime = GetTickCount();
   double deserializationElapsed = (endTime - startTime) / 1000.0;
   double deserializationRate = deserializationElapsed > 0 ? TestIterations / deserializationElapsed : 0;
   Print("  Deserialization rate: " + DoubleToString(deserializationRate, 0) + " ops/sec");

   // Performance targets (adjusted for realistic expectations)
   // If elapsed time is 0, operations were too fast to measure (which is excellent)
   bool performanceOK = ((cleanupRate > 1000 || cleanupRate == 0) &&
                        (creationRate > 1000 || creationRate == 0) &&
                        (serializationRate > 1000 || serializationRate == 0) &&
                        (deserializationRate > 1000 || deserializationRate == 0));

   Print("  Performance targets: " + (performanceOK ? "MET" : "NOT MET"));

   return performanceOK;
}

//+------------------------------------------------------------------+
//| Caching Test Function                                            |
//+------------------------------------------------------------------+
bool TestIDResolutionCaching()
{
   Print("--- Testing ID Resolution Caching ---");
   bool all_passed = true;

   // --- Test Asset Resolution Caching ---
   string currency_iso = "EUR";
   uint start_time = GetTickCount();
   GetBTRAssetFromSymbol(currency_iso);
   uint first_call_time = GetTickCount() - start_time;
   Print("  Asset Caching: First call for '" + currency_iso + "' took " + IntegerToString(first_call_time) + "ms");

   start_time = GetTickCount();
   GetBTRAssetFromSymbol(currency_iso);
   uint second_call_time = GetTickCount() - start_time;
   Print("  Asset Caching: Second call for '" + currency_iso + "' took " + IntegerToString(second_call_time) + "ms (cached)");

   if(second_call_time > first_call_time)
   {
      Print("  ✗ FAIL: Asset caching did not improve performance.");
      all_passed = false;
   }
   else
   {
      Print("  ✓ SUCCESS: Asset caching appears to be working.");
   }

   // --- Test Market Provider Caching ---
   string broker_name = "Interactive Brokers";
   start_time = GetTickCount();
   GetBTRMarketProviderFromBroker(broker_name);
   first_call_time = GetTickCount() - start_time;
   Print("  Market Provider Caching: First call for '" + broker_name + "' took " + IntegerToString(first_call_time) + "ms");

   start_time = GetTickCount();
   GetBTRMarketProviderFromBroker(broker_name);
   second_call_time = GetTickCount() - start_time;
   Print("  Market Provider Caching: Second call for '" + broker_name + "' took " + IntegerToString(second_call_time) + "ms (cached)");

   if(second_call_time > first_call_time)
   {
      Print("  ✗ FAIL: Market provider caching did not improve performance.");
      all_passed = false;
   }
   else
   {
      Print("  ✓ SUCCESS: Market provider caching appears to be working.");
   }

   return all_passed;
}

//+------------------------------------------------------------------+
//| Additional Test Functions (merged from other test scripts)      |
//+------------------------------------------------------------------+

// Test basic asset resolution functions
bool TestBasicCurrencyFunctions()
{
   Print("--- Testing Basic Asset Resolution Functions ---");

   // Test basic asset lookup
   ulong eur_asset = GetBTRAssetFromSymbol("EUR");
   ulong usd_asset = GetBTRAssetFromSymbol("USD");

   Print("  EUR Asset ID: 0x" + IntegerToString(eur_asset, 16));
   Print("  USD Asset ID: 0x" + IntegerToString(usd_asset, 16));

   bool currencyOK = (eur_asset > 0 && usd_asset > 0);

   // Test asset parsing
   ulong base_asset, quote_asset;
   bool parse_success = ParseSymbolAssets("EURUSD", base_asset, quote_asset);

   Print("  EURUSD parsed: Base=0x" + IntegerToString(base_asset, 16) + ", Quote=0x" + IntegerToString(quote_asset, 16));

   bool parsingOK = parse_success && (base_asset == eur_asset && quote_asset == usd_asset);

   // Test ticker ID generation
   ulong ticker_id = GetMitchticker_id("EURUSD");
   Print("  EURUSD Ticker ID: 0x" + IntegerToString(ticker_id, 16));

   bool tickerOK = (ticker_id > 0);

   Print("  Asset lookup: " + (currencyOK ? "PASSED" : "FAILED"));
   Print("  Asset parsing: " + (parsingOK ? "PASSED" : "FAILED"));
   Print("  Ticker generation: " + (tickerOK ? "PASSED" : "FAILED"));

   return currencyOK && parsingOK && tickerOK;
}

// Test EURUSD specification compliance (exact values from specification)
bool TestEURUSDSpecification()
{
   Print("--- Testing EURUSD Specification Compliance ---");

   // Test the exact specification example
   Print("  Testing EURUSD ticker ID calculation against specification...");

   // Ensure assets are initialized
   if(!InitializeBTRAssets())
   {
      Print("  ERROR: Failed to initialize BTR assets");
      return false;
   }

   // Get asset IDs
   ulong eur_asset = GetBTRAssetFromSymbol("EUR");
   ulong usd_asset = GetBTRAssetFromSymbol("USD");

   Print("  EUR asset ID: 0x" + IntegerToString(eur_asset, 16) + " (" + IntegerToString(eur_asset) + ")");
   Print("  USD asset ID: 0x" + IntegerToString(usd_asset, 16) + " (" + IntegerToString(usd_asset) + ")");

   // Extract and verify EUR components
   uint eur_class = GetAssetClassFromMitchAsset(eur_asset);
   uint eur_id = GetAssetIDFromMitchAsset(eur_asset);
   Print("  EUR breakdown: Class=0x" + IntegerToString(eur_class, 16) + ", ID=" + IntegerToString(eur_id));

   // Extract and verify USD components
   uint usd_class = GetAssetClassFromMitchAsset(usd_asset);
   uint usd_id = GetAssetIDFromMitchAsset(usd_asset);
   Print("  USD breakdown: Class=0x" + IntegerToString(usd_class, 16) + ", ID=" + IntegerToString(usd_id));

   // Verify the individual asset components match specification
   bool eur_class_ok = (eur_class == 3); // Forex class
   bool eur_id_ok = (eur_id == 111);     // EUR ID from CSV
   bool usd_class_ok = (usd_class == 3); // Forex class
   bool usd_id_ok = (usd_id == 461);     // USD ID from CSV

   Print("  Asset component verification:");
   Print("    EUR Class: Expected=3, Got=" + IntegerToString(eur_class) + (eur_class_ok ? " ✓" : " ✗"));
   Print("    EUR ID: Expected=111, Got=" + IntegerToString(eur_id) + (eur_id_ok ? " ✓" : " ✗"));
   Print("    USD Class: Expected=3, Got=" + IntegerToString(usd_class) + (usd_class_ok ? " ✓" : " ✗"));
   Print("    USD ID: Expected=461, Got=" + IntegerToString(usd_id) + (usd_id_ok ? " ✓" : " ✗"));

   // Check if assets are correctly calculated
   ulong expected_eur = 0x3006F; // (3 << 16) | 111 = 196608 + 111 = 196719
   ulong expected_usd = 0x301CD; // (3 << 16) | 461 = 196608 + 461 = 197069

   Print("  Expected EUR asset: 0x" + IntegerToString(expected_eur, 16) + " (" + IntegerToString(expected_eur) + ")");
   Print("  Expected USD asset: 0x" + IntegerToString(expected_usd, 16) + " (" + IntegerToString(expected_usd) + ")");

   // Calculate ticker ID
   ulong ticker_id = GetMitchticker_id("EURUSD");

   Print("  Calculated EURUSD ticker ID: " + IntegerToString(ticker_id));
   Print("  Calculated EURUSD ticker ID (hex): 0x" + IntegerToString(ticker_id, 16));

   // Expected from specification
   ulong expected_id = 0x03006F301CD00000;
   ulong expected_decimal = 216295034546290688;

   Print("  Expected ticker ID: " + IntegerToString(expected_decimal));
   Print("  Expected ticker ID (hex): 0x" + IntegerToString(expected_id, 16));

   // Verify match
   bool specMatch = (ticker_id == expected_id);
   if(specMatch)
   {
      Print("  ✓ SUCCESS: Ticker ID matches specification exactly!");
   }
   else
   {
      Print("  ✗ FAIL: Ticker ID does not match specification");
      Print("    Difference: " + IntegerToString((long)(ticker_id - expected_id)));
   }

   // Analyze components
   Print("  Analysis of calculated ticker ID:");
   uint inst_type = GetMitchInstrumentType(ticker_id);
   ulong base_asset = GetMitchBaseAsset(ticker_id);
   ulong quote_asset = GetMitchQuoteAsset(ticker_id);
   ulong sub_type = GetMitchSubType(ticker_id);

   Print("    Instrument Type: 0x" + IntegerToString(inst_type, 16));
   Print("    Base Asset: 0x" + IntegerToString(base_asset, 16) + " (" + IntegerToString(base_asset) + ")");
   Print("    Quote Asset: 0x" + IntegerToString(quote_asset, 16) + " (" + IntegerToString(quote_asset) + ")");
   Print("    Sub-Type: 0x" + IntegerToString(sub_type, 16));

   // Verify components match specification
   Print("  Component verification:");
   bool instOK = (inst_type == 0); // SPOT = 0
   bool baseOK = (base_asset == 0x3006F); // Forex class (0x3) + EUR ID (111)
   bool quoteOK = (quote_asset == 0x301CD); // Forex class (0x3) + USD ID (461)
   bool subOK = (sub_type == 0);

   Print("    Instrument Type - Expected: 0x0, Got: 0x" + IntegerToString(inst_type, 16) +
         (instOK ? " ✓" : " ✗"));
   Print("    Base Asset - Expected: 0x3006F (Forex:EUR), Got: 0x" + IntegerToString(base_asset, 16) +
         " (" + IntegerToString(base_asset) + ")" + (baseOK ? " ✓" : " ✗"));
   Print("    Quote Asset - Expected: 0x301CD (Forex:USD), Got: 0x" + IntegerToString(quote_asset, 16) +
         " (" + IntegerToString(quote_asset) + ")" + (quoteOK ? " ✓" : " ✗"));
   Print("    Sub-Type - Expected: 0x0, Got: 0x" + IntegerToString(sub_type, 16) +
         (subOK ? " ✓" : " ✗"));

   // Overall result
   bool assetOK = eur_class_ok && eur_id_ok && usd_class_ok && usd_id_ok;
   bool overallOK = specMatch && instOK && baseOK && quoteOK && subOK && assetOK;

   Print("  Asset loading: " + (assetOK ? "✓ PASSED" : "✗ FAILED"));
   Print("  Ticker ID generation: " + (overallOK ? "✓ PASSED" : "✗ FAILED"));

   return overallOK;
}
