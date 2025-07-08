//+------------------------------------------------------------------+
//|                                                 BTRRedisTest.mq4 |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright BTR Supply"
#property link      "https://btr.supply"
#property version   "2.3"
#property strict
#property script_show_inputs

#include <BTRRedisClient.mqh>

input string RedisUrl = "redis://localhost:6379";
input string RedisUsername = "";
input string RedisPassword = "";
input bool TestStringOperations = true;
input bool TestBinaryOperations = true;
input bool TestCacheStatistics = false;

//+------------------------------------------------------------------+
//| Build dynamic connection string with credentials                 |
//| Logic matches construct_redis_url() from test_runner.rs          |
//+------------------------------------------------------------------+
string BuildConnectionString()
{
   string base_url = RedisUrl;
   
   // If either username OR password is empty, return base URL as-is
   // This matches the Rust logic: if user.is_empty() || password.is_empty()
   if(StringLen(RedisUsername) == 0 || StringLen(RedisPassword) == 0)
   {
      return base_url;
   }
   
   // Both username and password are provided, parse URL and inject credentials
   // Format: redis://username:password@host:port/
   if(StringFind(base_url, "redis://") == 0)
   {
      string remaining = StringSubstr(base_url, 8); // Remove "redis://"
      int atPos = StringFind(remaining, "@");
      
      string hostPort;
      if(atPos >= 0)
      {
         // URL already has credentials, extract just host:port
         hostPort = StringSubstr(remaining, atPos + 1);
      }
      else
      {
         // No existing credentials
         hostPort = remaining;
      }
      
      // Extract host and port, ensure port is present
      int colonPos = StringFind(hostPort, ":");
      string host, port;
      
      if(colonPos >= 0)
      {
         host = StringSubstr(hostPort, 0, colonPos);
         string portPart = StringSubstr(hostPort, colonPos + 1);
         // Remove trailing slash if present
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
         // No port specified, extract host and use default port 6379
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
      
      // Construct final URL: redis://username:password@host:port/
      return "redis://" + RedisUsername + ":" + RedisPassword + "@" + host + ":" + port + "/";
   }
   
   return base_url;
}

void OnStart()
{
   Print("====== Comprehensive Redis Diagnostics (v2.3 - Aligned) ======");
   string finalConnectionString = BuildConnectionString();
   Print("Base Redis URL: ", RedisUrl);
   Print("Final Connection String: ", finalConnectionString);
   Print("Username: ", RedisUsername);
   Print("Password: ", RedisPassword != "" ? "***" : "(empty)");
   Print("String Operations Test: ", TestStringOperations ? "Enabled" : "Disabled");
   Print("Binary Operations Test: ", TestBinaryOperations ? "Enabled" : "Disabled");
   Print("Cache Statistics Test: ", TestCacheStatistics ? "Enabled" : "Disabled");
   
   RedisClient redis;

   // --- Part 1: Connection and Authentication Test ---
   Print("\n--- [Part 1] Connection and Authentication Test ---");

   // 1.1. Test Connection
   Print("1.1. Testing redis.Connect()...");
   if(!redis.Connect(finalConnectionString))
   {
      Print("     ✗ FAILURE: Connection failed: ", redis.GetLastError());
      Print("     Note: This is expected if no Redis server is running.");
   }
   else
   {
      Print("     ✓ SUCCESS: Connected via RedisClient.");
   }

   // 1.2. Test Authentication
   Print("\n1.2. Testing redis.Auth()...");
   if(!redis.Auth(RedisUsername, RedisPassword))
   {
      Print("     ✗ FAILURE: Authentication failed: ", redis.GetLastError());
      Print("     Note: This is expected if not connected to Redis server.");
   }
   else
   {
      Print("     ✓ SUCCESS: Authenticated.");
   }

   // 1.3. Test Ping
   Print("\n1.3. Testing redis.Ping()...");
   if(!redis.Ping())
   {
      Print("     ✗ FAILURE: PING failed: ", redis.GetLastError());
      Print("     Note: This is expected if not connected to Redis server.");
   }
   else
   {
      Print("     ✓ SUCCESS: PING successful.");
   }

   // Show connection status
   Print("\n1.4. Connection Status: ", redis.GetStatusString());

   // --- Part 2: String Operations Test ---
   if(TestStringOperations)
   {
      Print("\n--- [Part 2] String Operations Test ---");
      
      // Test SET operation
      Print("2.1. Testing SET operation...");
      if(redis.Set("test_key", "test_value"))
      {
         Print("     ✓ SUCCESS: SET operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: SET operation failed: ", redis.GetLastError());
      }
      
      // Test GET operation
      Print("2.2. Testing GET operation...");
      string retrieved_value = redis.Get("test_key");
      if(retrieved_value == "test_value")
      {
         Print("     ✓ SUCCESS: GET returned correct value: ", retrieved_value);
      }
      else if(retrieved_value == "")
      {
         Print("     ✗ FAILURE: GET operation failed: ", redis.GetLastError());
      }
      else
      {
         Print("     ✗ FAILURE: GET returned unexpected value: ", retrieved_value, " (expected: test_value)");
      }
      
      // Test SETEX operation
      Print("2.3. Testing SETEX operation...");
      if(redis.SetEx("test_key_ex", "test_value_ex", 60))
      {
         Print("     ✓ SUCCESS: SETEX operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: SETEX operation failed: ", redis.GetLastError());
      }
      
      // Test PUBLISH operation
      Print("2.4. Testing PUBLISH operation...");
      if(redis.Publish("test_channel", "Hello Redis!"))
      {
         Print("     ✓ SUCCESS: PUBLISH operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: PUBLISH operation failed: ", redis.GetLastError());
      }
      
      // Test MSET operation
      Print("2.5. Testing MSET operation...");
      string mset_keys[] = {"mtest_key1", "mtest_key2"};
      string mset_values[] = {"mtest_value1", "mtest_value2"};
      if(redis.MSet(mset_keys, mset_values))
      {
         Print("     ✓ SUCCESS: MSET operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: MSET operation failed: ", redis.GetLastError());
      }
      
      // Test MGET operation
      Print("2.6. Testing MGET operation...");
      string mget_keys[] = {"mtest_key1", "mtest_key2"};
      string mget_values[];
      if(redis.MGet(mget_keys, mget_values))
      {
         Print("     ✓ SUCCESS: MGET operation completed");
         for(int i = 0; i < ArraySize(mget_values); i++)
         {
            Print("       Value ", i + 1, ": ", mget_values[i]);
         }
      }
      else
      {
         Print("     ✗ FAILURE: MGET operation failed: ", redis.GetLastError());
      }
   }

   // --- Part 3: Binary Operations Test ---
   if(TestBinaryOperations)
   {
      Print("\n--- [Part 3] Binary Operations Test ---");
      
      uchar binary_data[] = {0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE, 0xFD, 0xFC};
      
      // Test binary SET
      Print("3.1. Testing SetBinary operation...");
      if(redis.SetBinary("binary_key", binary_data))
      {
         Print("     ✓ SUCCESS: SetBinary operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: SetBinary operation failed: ", redis.GetLastError());
      }
      
      // Test binary GET
      Print("3.2. Testing GetBinary operation...");
      uchar result_buffer[20];
      int result_len = redis.GetBinary("binary_key", result_buffer);
      if(result_len == ArraySize(binary_data))
      {
         // Verify data integrity
         bool data_matches = true;
         for(int i = 0; i < result_len; i++)
         {
            if(result_buffer[i] != binary_data[i])
            {
               data_matches = false;
               break;
            }
         }
         
         if(data_matches)
         {
            Print("     ✓ SUCCESS: GetBinary returned ", result_len, " bytes with correct data");
         }
         else
         {
            Print("     ✗ FAILURE: GetBinary returned ", result_len, " bytes but data doesn't match");
         }
      }
      else if(result_len > 0)
      {
         Print("     ✗ FAILURE: GetBinary returned ", result_len, " bytes (expected: ", ArraySize(binary_data), ")");
      }
      else
      {
         Print("     ✗ FAILURE: GetBinary failed: ", redis.GetLastError());
      }
      
      // Test binary PUBLISH
      Print("3.3. Testing PublishBinary operation...");
      if(redis.PublishBinary("binary_channel", binary_data))
      {
         Print("     ✓ SUCCESS: PublishBinary operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: PublishBinary operation failed: ", redis.GetLastError());
      }
      
      // Test UInt64 operations
      Print("3.4. Testing UInt64 operations...");
      ulong test_value = 0x123456789ABCDEF0;
      
      if(redis.PublishUInt64("uint64_channel", test_value))
      {
         Print("     ✓ SUCCESS: PublishUInt64 operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: PublishUInt64 operation failed: ", redis.GetLastError());
      }
      
      if(redis.PublishUInt64ToHexChannel(test_value))
      {
         Print("     ✓ SUCCESS: PublishUInt64ToHexChannel operation completed");
      }
      else
      {
         Print("     ✗ FAILURE: PublishUInt64ToHexChannel operation failed: ", redis.GetLastError());
      }
   }

   // --- Part 4: DLL-Specific Function Tests ---
   Print("\n--- [Part 4] DLL-Specific Function Tests ---");
   
   // Test string echo function
   Print("4.1. Testing TestByteEcho function...");
   string test_inputs[] = {
      "Hello World",
      "UTF-8 test: ñáéíóú",
      "Binary data test",
      "Mixed: Hello 世界"
   };
   
   for(int i = 0; i < ArraySize(test_inputs); i++)
   {
      string echo_result = redis.TestByteEcho(test_inputs[i]);
      if(echo_result == test_inputs[i])
      {
         Print("     ✓ Byte echo test ", i, " PASSED: '", test_inputs[i], "'");
      }
      else
      {
         Print("     ✗ Byte echo test ", i, " FAILED: Expected '", test_inputs[i], "', Got '", echo_result, "'");
      }
   }

   // --- Part 5: Cache Statistics Test ---
   if(TestCacheStatistics)
   {
      Print("\n--- [Part 5] Cache Statistics Test ---");
      Print("5.1. Cache statistics functionality removed in simplified implementation");
   }
   
   // --- Part 6: Connection State Tests ---
   Print("\n--- [Part 6] Connection State Tests ---");
   Print("6.1. Testing IsConnected()...");
   if(redis.IsConnected())
   {
      Print("     ✓ IsConnected() returned true");
   }
   else
   {
      Print("     ✗ IsConnected() returned false");
   }
   
   Print("6.2. Testing IsAuthenticated()...");
   if(redis.IsAuthenticated())
   {
      Print("     ✓ IsAuthenticated() returned true");
   }
   else
   {
      Print("     ✗ IsAuthenticated() returned false");
   }
   
   Print("6.3. Final Connection Status: ", redis.GetStatusString());
   
   // Clean up
   redis.Disconnect();
   Print("\n6.4. Disconnected from Redis");
   
   Print("\n====== Comprehensive Diagnostics Complete ======");
   Print("Note: All operations use the actual Redis DLL implementation.");
   Print("The DLL provides full Redis functionality with UTF-8 byte handling and connection management.");
} 