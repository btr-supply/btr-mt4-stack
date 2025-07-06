//+------------------------------------------------------------------+
//|                                              BTRMitchTickerDemo.mq4 |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright BTR Supply"
#property link      "https://btr.supply"
#property version   "1.00"
#property strict

#include <BTRMitchModel.mqh>
#include <BTRMitchSerializer.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input int UpdateIntervalSeconds = 2;  // Update interval in seconds
input bool EnableLogging = true;      // Enable detailed logging

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
datetime lastUpdateTime = 0;
int tickerSnapshotCount = 0;
string currentSymbol = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== MITCH Ticker Demo Starting ===");
   
   // Get first symbol from MarketWatch
   currentSymbol = GetFirstMarketWatchSymbol();
   
   if(currentSymbol == "")
   {
      Print("ERROR: No symbols found in MarketWatch!");
      return INIT_FAILED;
   }
   
   Print("Selected symbol: ", currentSymbol);
   Print("Update interval: ", UpdateIntervalSeconds, " seconds");
   
   // Initialize first update
   lastUpdateTime = TimeCurrent() - UpdateIntervalSeconds;
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("=== MITCH Ticker Demo Stopping ===");
   Print("Total ticker snapshots processed: ", tickerSnapshotCount);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if it's time to update
   if(TimeCurrent() - lastUpdateTime >= UpdateIntervalSeconds)
   {
      ProcessTickerSnapshot();
      lastUpdateTime = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Get first symbol from MarketWatch                               |
//+------------------------------------------------------------------+
string GetFirstMarketWatchSymbol()
{
   // Try to get first symbol from MarketWatch
   // If MarketWatch is empty, use current chart symbol
   int totalSymbols = SymbolsTotal(true);
   
   if(totalSymbols > 0)
   {
      return SymbolName(0, true);
   }
   else
   {
      // Fallback to current chart symbol
      return Symbol();
   }
}

//+------------------------------------------------------------------+
//| Create ticker snapshot from current market data                 |
//+------------------------------------------------------------------+
void CreateTickerSnapshot(TickerBody &ticker)
{
   // Generate ticker ID for the symbol
   ticker.tickerId = GenerateForexTickerID(currentSymbol);
   
   // Get current market data
   ticker.bidPrice = MarketInfo(currentSymbol, MODE_BID);
   ticker.askPrice = MarketInfo(currentSymbol, MODE_ASK);
   
   // Set volumes to 0 as requested (MT4 doesn't provide volume since last snapshot)
   ticker.bidVolume = 0;
   ticker.askVolume = 0;
   
   if(EnableLogging)
   {
      Print("Created ticker snapshot for ", currentSymbol, 
            " - Bid: ", DoubleToString(ticker.bidPrice, 5),
            " Ask: ", DoubleToString(ticker.askPrice, 5),
            " ID: ", ticker.tickerId);
   }
}

//+------------------------------------------------------------------+
//| Process ticker snapshot: serialize, deserialize, and verify     |
//+------------------------------------------------------------------+
void ProcessTickerSnapshot()
{
   tickerSnapshotCount++;
   
   Print("--- Processing Ticker Snapshot #", tickerSnapshotCount, " ---");
   
   // Step 1: Create ticker snapshot
   TickerBody originalTicker;
   CreateTickerSnapshot(originalTicker);
   
   // Step 2: Serialize to binary
   uchar serializedData[];
   int messageSize = PackTickerMessage(originalTicker, serializedData);
   
   if(messageSize <= 0)
   {
      Print("ERROR: Failed to serialize ticker message!");
      return;
   }
   
   Print("Serialized ticker message: ", messageSize, " bytes");
   
   // Step 3: Write to file (demonstration)
   string filename = "ticker_snapshot_" + IntegerToString(tickerSnapshotCount) + ".bin";
   if(WriteToFile(filename, serializedData))
   {
      Print("Ticker snapshot saved to: ", filename);
   }
   else
   {
      Print("WARNING: Failed to save ticker snapshot to file");
   }
   
   // Step 4: Deserialize the binary data
   MitchHeader deserializedHeader;
   TickerBody deserializedTicker;
   
   if(!UnpackTickerMessage(serializedData, deserializedHeader, deserializedTicker))
   {
      Print("ERROR: Failed to deserialize ticker message!");
      return;
   }
   
   // Step 5: Verify data integrity
   bool isValid = ValidateTickerData(originalTicker, deserializedTicker, deserializedHeader);
   
   if(isValid)
   {
      Print("✓ SUCCESS: Ticker snapshot serialization/deserialization validated!");
      
      if(EnableLogging)
      {
         PrintDetailedComparison(originalTicker, deserializedTicker, deserializedHeader);
      }
   }
   else
   {
      Print("✗ ERROR: Ticker snapshot validation failed!");
   }
   
   Print("--- Ticker Snapshot #", tickerSnapshotCount, " Complete ---");
}

//+------------------------------------------------------------------+
//| Validate ticker data integrity                                  |
//+------------------------------------------------------------------+
bool ValidateTickerData(const TickerBody &original, const TickerBody &deserialized, const MitchHeader &header)
{
   // Validate header
   if(header.messageType != MITCH_MSG_TYPE_TICKER)
   {
      Print("ERROR: Invalid message type: ", header.messageType);
      return false;
   }
   
   if(header.count != 1)
   {
      Print("ERROR: Invalid count: ", header.count);
      return false;
   }
   
   // Validate ticker ID
   if(original.tickerId != deserialized.tickerId)
   {
      Print("ERROR: Ticker ID mismatch - Original: ", original.tickerId, " Deserialized: ", deserialized.tickerId);
      return false;
   }
   
   // Validate prices (with small tolerance for floating point precision)
   double tolerance = 0.000001;
   if(MathAbs(original.bidPrice - deserialized.bidPrice) > tolerance)
   {
      Print("ERROR: Bid price mismatch - Original: ", original.bidPrice, " Deserialized: ", deserialized.bidPrice);
      return false;
   }
   
   if(MathAbs(original.askPrice - deserialized.askPrice) > tolerance)
   {
      Print("ERROR: Ask price mismatch - Original: ", original.askPrice, " Deserialized: ", deserialized.askPrice);
      return false;
   }
   
   // Validate volumes
   if(original.bidVolume != deserialized.bidVolume)
   {
      Print("ERROR: Bid volume mismatch - Original: ", original.bidVolume, " Deserialized: ", deserialized.bidVolume);
      return false;
   }
   
   if(original.askVolume != deserialized.askVolume)
   {
      Print("ERROR: Ask volume mismatch - Original: ", original.askVolume, " Deserialized: ", deserialized.askVolume);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Print detailed comparison of original vs deserialized data      |
//+------------------------------------------------------------------+
void PrintDetailedComparison(const TickerBody &original, const TickerBody &deserialized, const MitchHeader &header)
{
   Print("=== DETAILED COMPARISON ===");
   Print("Header:");
   Print("  Message Type: ", (char)header.messageType);
   Print("  Count: ", header.count);
   
   // Create a temporary non-const copy of the timestamp array
   uchar timestampCopy[];
   ArrayCopy(timestampCopy, header.timestamp, 0, 0, 6);
   Print("  Timestamp: ", ReadTimestamp48(timestampCopy));
   
   Print("Original Ticker:");
   Print("  Ticker ID: ", original.tickerId);
   Print("  Bid Price: ", DoubleToString(original.bidPrice, 5));
   Print("  Ask Price: ", DoubleToString(original.askPrice, 5));
   Print("  Bid Volume: ", original.bidVolume);
   Print("  Ask Volume: ", original.askVolume);
   
   Print("Deserialized Ticker:");
   Print("  Ticker ID: ", deserialized.tickerId);
   Print("  Bid Price: ", DoubleToString(deserialized.bidPrice, 5));
   Print("  Ask Price: ", DoubleToString(deserialized.askPrice, 5));
   Print("  Bid Volume: ", deserialized.bidVolume);
   Print("  Ask Volume: ", deserialized.askVolume);
   
   Print("=== END COMPARISON ===");
}

//+------------------------------------------------------------------+
//| Timer function (alternative to OnTick for regular updates)      |
//+------------------------------------------------------------------+
void OnTimer()
{
   ProcessTickerSnapshot();
} 