//+------------------------------------------------------------------+
//|                                               BTRMitchRedisDemo.mq4 |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright BTR Supply"
#property link      "https://btr.supply"
#property version   "1.00"
#property strict

#include <BTRMitchModel.mqh>
#include <BTRMitchSerializer.mqh>
#include <BTRRedisClient.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input string RedisHost = "127.0.0.1";          // Redis server host
input int RedisPort = 6379;                    // Redis server port
input string RedisUsername = "";               // Redis username (empty for no auth)
input string RedisPassword = "";               // Redis password (empty for no auth)
input string ChannelPrefix = "mitch";          // Redis channel prefix
input int UpdateIntervalSeconds = 2;           // Ticker update interval
input bool EnableLogging = true;               // Enable detailed logging

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
RedisClient* redis;
datetime lastUpdateTime = 0;
int tickerSnapshotCount = 0;
string currentSymbol = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== MITCH Redis Integration Demo Starting ===");
   
   // Initialize Redis client
   redis = new RedisClient(RedisHost, RedisPort, RedisUsername, RedisPassword);
   
   if(!redis.Connect())
   {
      Print("ERROR: Failed to connect to Redis server at ", RedisHost, ":", RedisPort);
      delete redis;
      return INIT_FAILED;
   }
   
   // Test Redis connection
   if(!redis.Ping())
   {
      Print("ERROR: Redis server not responding to PING");
      delete redis;
      return INIT_FAILED;
   }
   
   Print("✓ Redis connection established successfully");
   
   // Get first symbol from MarketWatch
   currentSymbol = GetFirstMarketWatchSymbol();
   
   if(currentSymbol == "")
   {
      Print("ERROR: No symbols found in MarketWatch!");
      return INIT_FAILED;
   }
   
   Print("Selected symbol: ", currentSymbol);
   Print("Redis channels: ", ChannelPrefix, ":ticker, ", ChannelPrefix, ":binary");
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
   Print("=== MITCH Redis Demo Stopping ===");
   
   if(redis != NULL)
   {
      redis.Disconnect();
      delete redis;
   }
   
   Print("Total ticker snapshots published: ", tickerSnapshotCount);
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
   int totalSymbols = SymbolsTotal(true);
   
   if(totalSymbols > 0)
   {
      return SymbolName(0, true);
   }
   else
   {
      return Symbol(); // Fallback to current chart symbol
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
   
   // Set volumes to 0 as MT4 doesn't provide volume since last snapshot
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
//| Process and publish ticker snapshot                             |
//+------------------------------------------------------------------+
void ProcessTickerSnapshot()
{
   tickerSnapshotCount++;
   
   Print("--- Processing Ticker Snapshot #", tickerSnapshotCount, " ---");
   
   // Step 1: Create ticker snapshot
   TickerBody originalTicker;
   CreateTickerSnapshot(originalTicker);
   
   // Step 2: Serialize to MITCH binary format
   uchar serializedData[];
   int messageSize = PackTickerMessage(originalTicker, serializedData);
   
   if(messageSize <= 0)
   {
      Print("ERROR: Failed to serialize ticker message!");
      return;
   }
   
   Print("Serialized MITCH message: ", messageSize, " bytes");
   
   // Step 3: Publish to Redis
   PublishToRedis(originalTicker, serializedData);
   
   // Step 4: Verify data integrity (optional)
   if(EnableLogging)
   {
      VerifyDeserialization(serializedData);
   }
   
   Print("--- Ticker Snapshot #", tickerSnapshotCount, " Complete ---");
}

//+------------------------------------------------------------------+
//| Publish ticker data to Redis                                    |
//+------------------------------------------------------------------+
void PublishToRedis(const TickerBody &ticker, uchar &binaryData[])
{
   if(!redis.IsConnected())
   {
      Print("WARNING: Redis not connected, skipping publish");
      return;
   }
   
   // Publish human-readable ticker data
   string tickerChannel = ChannelPrefix + ":ticker";
   string tickerJson = CreateTickerJSON(ticker);
   
   if(redis.Publish(tickerChannel, tickerJson))
   {
      Print("✓ Published ticker JSON to: ", tickerChannel);
   }
   else
   {
      Print("✗ Failed to publish ticker JSON");
   }
   
   // Publish binary MITCH data
   string binaryChannel = ChannelPrefix + ":binary";
   
   if(redis.PublishBinary(binaryChannel, binaryData))
   {
      Print("✓ Published MITCH binary to: ", binaryChannel);
   }
   else
   {
      Print("✗ Failed to publish MITCH binary");
   }
   
   // Publish individual metrics for monitoring
   string metricsChannel = ChannelPrefix + ":metrics";
   string metrics = CreateMetricsString(ticker);
   
   if(redis.Publish(metricsChannel, metrics))
   {
      Print("✓ Published metrics to: ", metricsChannel);
   }
   
   // Store latest ticker data in Redis key-value
   string tickerKey = ChannelPrefix + ":latest:" + currentSymbol;
   redis.Set(tickerKey, tickerJson);
}

//+------------------------------------------------------------------+
//| Create JSON representation of ticker                            |
//+------------------------------------------------------------------+
string CreateTickerJSON(const TickerBody &ticker)
{
   return "{" +
          "\"symbol\":\"" + currentSymbol + "\"," +
          "\"tickerId\":" + ULongToString(ticker.tickerId) + "," +
          "\"bidPrice\":" + DoubleToString(ticker.bidPrice, 5) + "," +
          "\"askPrice\":" + DoubleToString(ticker.askPrice, 5) + "," +
          "\"spread\":" + DoubleToString(ticker.askPrice - ticker.bidPrice, 5) + "," +
          "\"timestamp\":" + IntegerToString(TimeCurrent()) + "," +
          "\"count\":" + IntegerToString(tickerSnapshotCount) +
          "}";
}

//+------------------------------------------------------------------+
//| Create metrics string for monitoring                            |
//+------------------------------------------------------------------+
string CreateMetricsString(const TickerBody &ticker)
{
   return currentSymbol + "|" +
          DoubleToString(ticker.bidPrice, 5) + "|" +
          DoubleToString(ticker.askPrice, 5) + "|" +
          DoubleToString(ticker.askPrice - ticker.bidPrice, 5) + "|" +
          IntegerToString(TimeCurrent()) + "|" +
          IntegerToString(tickerSnapshotCount);
}

//+------------------------------------------------------------------+
//| Verify deserialization (for testing)                           |
//+------------------------------------------------------------------+
void VerifyDeserialization(uchar &serializedData[])
{
   MitchHeader header;
   TickerBody deserializedTicker;
   
   if(UnpackTickerMessage(serializedData, header, deserializedTicker))
   {
      Print("✓ Deserialization verification successful");
      Print("  Ticker ID: ", deserializedTicker.tickerId);
      Print("  Bid: ", DoubleToString(deserializedTicker.bidPrice, 5));
      Print("  Ask: ", DoubleToString(deserializedTicker.askPrice, 5));
   }
   else
   {
      Print("✗ Deserialization verification failed!");
   }
} 