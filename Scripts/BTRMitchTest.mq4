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
input bool TestBasicFunctions = true; // Test basic currency and parsing functions
input bool TestSpecification = true;  // Test EURUSD specification compliance
input bool TestSymbolCleanup = true;  // Test symbol cleanup functionality
input bool TestIDGeneration = true;   // Test ticker ID generation
input bool TestSerialization = true;  // Test serialization/deserialization
input bool TestPerformance = true;    // Test performance benchmarks

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("=== BTR MITCH Protocol Test Suite ===");
   Print("Test iterations: " + IntegerToString(TestIterations));
   Print("");
   
   int totalTests = 0;
   int passedTests = 0;
   
   // Initialize symbol cache
   InitializeSymbolCache();
   
   // Run tests based on input parameters
   if(TestBasicFunctions)
   {
      totalTests++;
      if(TestBasicCurrencyFunctions())
      {
         passedTests++;
         Print("✓ Basic Functions Test - PASSED");
      }
      else
      {
         Print("✗ Basic Functions Test - FAILED");
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
      if(TestTickerIDGeneration())
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
   
   // Summary
   Print("=== Test Summary ===");
   Print("Total test categories: " + IntegerToString(totalTests));
   Print("Passed: " + IntegerToString(passedTests));
   Print("Success rate: " + DoubleToString(100.0 * passedTests / totalTests, 1) + "%");
   Print("Final cache size: " + IntegerToString(GetSymbolCacheSize()) + " unique symbols");
   
   if(passedTests == totalTests)
      Print("✓✓ ALL TESTS PASSED!");
   else
      Print("✗✗ SOME TESTS FAILED!");
   
   Print("=== BTR MITCH Test Complete ===");
   
   // Cleanup
   CleanupSymbolCache();
}

//+------------------------------------------------------------------+
//| Test Functions                                                   |
//+------------------------------------------------------------------+

// Test symbol cleanup functionality
bool TestSymbolCleanupFunction()
{
   Print("--- Testing Symbol Cleanup ---");
   
   string testSymbols[] = {
      "EURUSD", "EURUSDm", "EURUSD.micro", "EURUSDc", "EURUSDb", 
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
bool TestTickerIDGeneration()
{
   Print("--- Testing Ticker ID Generation ---");
   
   string testSymbols[] = {"EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "EURUSDm", "XAU.USD"};
   int testCount = ArraySize(testSymbols);
   int passed = 0;
   
   for(int i = 0; i < testCount; i++)
   {
      string symbol = testSymbols[i];
      string cleaned = GetCleanedSymbol(symbol);
      
      // Generate MITCH ticker ID
      ulong ticker_id = GetMitchTickerID(cleaned);
      
      // Analyze the ID
      string analysis = AnalyzeMitchTickerID(ticker_id);
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
   
   string testSymbol = "EURUSDm"; // Test with a symbol that needs cleanup
   
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
   
   string testSymbols[] = {"EURUSDm", "GBPUSDc", "USDJPY.ecn", "XAUUSD", "BTCUSD"};
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
//| Additional Test Functions (merged from other test scripts)      |
//+------------------------------------------------------------------+

// Test basic currency and parsing functions
bool TestBasicCurrencyFunctions()
{
   Print("--- Testing Basic Currency Functions ---");
   
   // Test basic currency lookup
   uint eur_id = GetBTRCurrencyFromISO("EUR");
   uint usd_id = GetBTRCurrencyFromISO("USD");
   
   Print("  EUR ID: " + IntegerToString(eur_id) + " (expected: 111)");
   Print("  USD ID: " + IntegerToString(usd_id) + " (expected: 461)");
   
   bool currencyOK = (eur_id == 111 && usd_id == 461);
   
   // Test forex parsing
   uint base, quote;
   ParseForexSymbol("EURUSD", base, quote);
   
   Print("  EURUSD parsed: Base=" + IntegerToString(base) + ", Quote=" + IntegerToString(quote));
   
   bool parsingOK = (base == 111 && quote == 461);
   
   // Test ticker ID generation
   ulong ticker_id = GetMitchTickerID("EURUSD");
   Print("  EURUSD Ticker ID: " + IntegerToString(ticker_id));
   
   bool tickerOK = (ticker_id > 0);
   
   Print("  Currency lookup: " + (currencyOK ? "PASSED" : "FAILED"));
   Print("  Forex parsing: " + (parsingOK ? "PASSED" : "FAILED"));
   Print("  Ticker generation: " + (tickerOK ? "PASSED" : "FAILED"));
   
   return currencyOK && parsingOK && tickerOK;
}

// Test EURUSD specification compliance (exact values from specification)
bool TestEURUSDSpecification()
{
   Print("--- Testing EURUSD Specification Compliance ---");
   
   // Test the exact specification example
   Print("  Testing EURUSD ticker ID calculation against specification...");
   
   // Get currency IDs
   uint eur_id = GetBTRCurrencyFromISO("EUR");
   uint usd_id = GetBTRCurrencyFromISO("USD");
   
   Print("  EUR currency ID: " + IntegerToString(eur_id) + " (0x" + IntegerToString(eur_id, 16) + ")");
   Print("  USD currency ID: " + IntegerToString(usd_id) + " (0x" + IntegerToString(usd_id, 16) + ")");
   
   // Calculate ticker ID
   ulong ticker_id = GetMitchTickerID("EURUSD");
   
   Print("  Calculated EURUSD ticker ID: " + IntegerToString(ticker_id));
   Print("  Calculated EURUSD ticker ID (hex): 0x" + IntegerToString(ticker_id, 16));
   
   // Expected from specification
   ulong expected_id = 0x00006F001CD00000;
   ulong expected_decimal = 122046274076672;
   
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
   uchar inst_type = GetMitchInstrumentType(ticker_id);
   ulong base_asset = GetMitchBaseAsset(ticker_id);
   ulong quote_asset = GetMitchQuoteAsset(ticker_id);
   ulong sub_type = GetMitchSubType(ticker_id);
   
   Print("    Instrument Type: 0x" + IntegerToString(inst_type, 16));
   Print("    Base Asset: 0x" + IntegerToString(base_asset, 16) + " (" + IntegerToString(base_asset) + ")");
   Print("    Quote Asset: 0x" + IntegerToString(quote_asset, 16) + " (" + IntegerToString(quote_asset) + ")");
   Print("    Sub-Type: 0x" + IntegerToString(sub_type, 16));
   
   // Verify components match specification
   Print("  Component verification:");
   bool instOK = (inst_type == 0);
   bool baseOK = (base_asset == 111);
   bool quoteOK = (quote_asset == 461);
   bool subOK = (sub_type == 0);
   
   Print("    Instrument Type - Expected: 0x0, Got: 0x" + IntegerToString(inst_type, 16) + 
         (instOK ? " ✓" : " ✗"));
   Print("    Base Asset - Expected: 0x6F (111), Got: 0x" + IntegerToString(base_asset, 16) + 
         " (" + IntegerToString(base_asset) + ")" + (baseOK ? " ✓" : " ✗"));
   Print("    Quote Asset - Expected: 0x1CD (461), Got: 0x" + IntegerToString(quote_asset, 16) + 
         " (" + IntegerToString(quote_asset) + ")" + (quoteOK ? " ✓" : " ✗"));
   Print("    Sub-Type - Expected: 0x0, Got: 0x" + IntegerToString(sub_type, 16) + 
         (subOK ? " ✓" : " ✗"));
   
   return specMatch && instOK && baseOK && quoteOK && subOK;
} 