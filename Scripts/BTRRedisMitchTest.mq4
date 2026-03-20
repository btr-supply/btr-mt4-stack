//+------------------------------------------------------------------+
//|                                            BTRRedisMitchTest.mq4 |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright BTR Supply"
#property link      "https://btr.supply"
#property version   "1.0"
#property strict
#property script_show_inputs

#include <BTRRedisClient.mqh>
#include <BTRMitchSerializer.mqh>
#include <BTRIds.mqh>

input string RedisUrl = "redis://localhost:6379";
input string RedisUsername = "";
input string RedisPassword = "";
input int PublishCount = 20;
input int IntervalSeconds = 1;

//+------------------------------------------------------------------+
//| Build dynamic connection string with credentials                 |
//+------------------------------------------------------------------+
string BuildConnectionString()
{
   string base_url = RedisUrl;

   if(StringLen(RedisUsername) == 0 || StringLen(RedisPassword) == 0)
   {
      return base_url;
   }

   if(StringFind(base_url, "redis://") == 0)
   {
      string remaining = StringSubstr(base_url, 8);
      int atPos = StringFind(remaining, "@");

      string hostPort;
      if(atPos >= 0)
      {
         hostPort = StringSubstr(remaining, atPos + 1);
      }
      else
      {
         hostPort = remaining;
      }

      int colonPos = StringFind(hostPort, ":");
      string host, port;

      if(colonPos >= 0)
      {
         host = StringSubstr(hostPort, 0, colonPos);
         string portPart = StringSubstr(hostPort, colonPos + 1);
         int slashPos = StringFind(portPart, "/");
         if(slashPos >= 0)
         {
            port = StringSubstr(portPart, 0, slashPos);
         }
         else
         {
            port = portPart;
         }
      }
      else
      {
         int slashPos = StringFind(hostPort, "/");
         if(slashPos >= 0)
         {
            host = StringSubstr(hostPort, 0, slashPos);
         }
         else
         {
            host = hostPort;
         }
         port = "6379";
      }

      return "redis://" + RedisUsername + ":" + RedisPassword + "@" + host + ":" + port + "/";
   }

   return base_url;
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   Print("====== BTR Redis MITCH Publisher (v1.0) ======");
   Print("Publishing EURUSD ticker data in MITCH binary format");
   Print("Iterations: ", PublishCount);
   Print("Interval: ", IntervalSeconds, " seconds");

   // Initialize symbol cache
   InitializeSymbolCache();

   // Connect to Redis
   string redis_url;
   if(StringLen(RedisUsername) > 0)
   {
      // Parse the RedisUrl to extract host and port
      string base_url = RedisUrl;

      // Remove redis:// prefix if present
      if(StringFind(base_url, "redis://") == 0)
      {
         base_url = StringSubstr(base_url, 8); // Remove "redis://"
      }

      // Construct URL with credentials
      redis_url = "redis://" + RedisUsername;
      if(StringLen(RedisPassword) > 0)
         redis_url += ":" + RedisPassword;
      redis_url += "@" + base_url;
   }
   else
   {
      redis_url = RedisUrl;
   }

   Print("Connecting to Redis: ", redis_url);

   RedisClient redis;
   if(!redis.Connect(redis_url))
   {
      Print("❌ Failed to connect to Redis: ", redis.GetLastError());
      CleanupSymbolCache();
      return;
   }

   Print("✅ Authentication successful");
   Print("✅ Connected to Redis successfully");

   // Create EURUSD ticker for testing
   ulong eurusd_ticker_id = GetMitchticker_id("EURUSD");
   Print("EURUSD Ticker ID: ", eurusd_ticker_id, " (0x", StringFormat("%016X", eurusd_ticker_id), ")");

   // Create hex channel name from ticker ID
   string hex_channel = StringFormat("%016X", eurusd_ticker_id);
   StringToLower(hex_channel);
   Print("Publishing to hex channel: ", hex_channel);

   Print("\n🚀 Starting MITCH ticker publishing...");

   // Publishing loop
   for(int i = 1; i <= PublishCount; i++)
   {
      // Create ticker from symbol using existing function
      TickerBody ticker = CreateTickerFromSymbol("EURUSD");

      // Pack ticker into MITCH binary format
      uchar ticker_data[40];
      if(!PackTickerMessage(ticker, ticker_data))
      {
         Print("❌ Iteration ", i, ": Failed to pack ticker message");
         continue;
      }

      // Publish to Redis using hex channel name
      if(redis.PublishBinary(hex_channel, ticker_data))
      {
         Print("✅ Iteration ", i, "/", PublishCount,
               ": Published EURUSD ticker (Bid: ", DoubleToString(ticker.bidPrice, 5),
               ", Ask: ", DoubleToString(ticker.askPrice, 5), ")");
      }
      else
      {
         Print("❌ Iteration ", i, ": Failed to publish ticker: ", redis.GetLastError());
      }

      // Wait for next iteration (except on last one)
      if(i < PublishCount)
      {
         Sleep(IntervalSeconds * 1000);
      }
   }

   Print("\n🏁 Publishing complete!");
   Print("📊 Summary:");
   Print("  - Symbol: EURUSD");
   Print("  - Ticker ID: 0x", StringFormat("%016X", eurusd_ticker_id));
   Print("  - Channel: ", hex_channel);
   Print("  - Message size: 40 bytes (MITCH binary)");
   Print("  - Total iterations: ", PublishCount);

   Print("\n💡 To subscribe to this data stream using redis-cli:");
   Print("   redis-cli SUBSCRIBE ", hex_channel);
   Print("   # Or using binary channel name:");

   // Convert hex string to redis-cli escape format
   string redis_cli_format = "$'";
   for(int j = 0; j < StringLen(hex_channel); j += 2)
   {
      string hex_pair = StringSubstr(hex_channel, j, 2);
      redis_cli_format += "\\x" + hex_pair;
   }
   redis_cli_format += "'";

   Print("   redis-cli SUBSCRIBE ", redis_cli_format);

   redis.Disconnect();
   Print("✅ Disconnected from Redis");

   // Cleanup
   CleanupSymbolCache();
}

//+------------------------------------------------------------------+
//| Script deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Cleanup symbol cache to prevent memory leaks
   CleanupSymbolCache();
   Print("✅ Symbol cache cleaned up");
}
