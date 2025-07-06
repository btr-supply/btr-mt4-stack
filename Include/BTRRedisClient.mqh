//+------------------------------------------------------------------+
//|                                               BTRRedisClient.mqh |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property copyright "Copyright BTR Supply"
#property link      "https://btr.supply"
#property version   "2.00"
#property strict

// Import Redis DLL functions with raw byte interface
#import "redis_client.dll"
   int redis_connect(uchar &conn_str[], int conn_len);
   int redis_auth(uchar &username[], int username_len, uchar &password[], int password_len);
   int redis_set(uchar &key[], int key_len, uchar &value[], int value_len);
   int redis_set_ex(uchar &key[], int key_len, uchar &value[], int value_len, int expiry);
   int redis_get(uchar &key[], int key_len, uchar &buffer[], int buffer_size);
   int redis_mset(uchar &payload[], int payload_len);
   int redis_mget(uchar &keys[], int keys_len, uchar &buffer[], int buffer_size);
   int redis_publish(uchar &channel[], int channel_len, uchar &message[], int message_len);
   int redis_ping();
   int redis_is_connected();
   int redis_disconnect();
   int redis_test_byte_echo(uchar &in[], int input_len, uchar &output[], int output_size);
#import

//+------------------------------------------------------------------+
//| Redis Client DLL Wrapper Class                                  |
//+------------------------------------------------------------------+
class RedisClient
{
private:
   bool m_connected;
   bool m_authenticated;
   string m_last_error;

   //+------------------------------------------------------------------+
   //| Convert string to UTF-8 byte array                              |
   //+------------------------------------------------------------------+
   int StringToUtf8Bytes(string str, uchar &bytes[])
   {
      int len = StringToCharArray(str, bytes, 0, WHOLE_ARRAY, CP_UTF8);
      if(len > 0 && bytes[len-1] == 0)
         len--; // Remove null terminator if present
      return len;
   }
   
   //+------------------------------------------------------------------+
   //| Convert UTF-8 byte array to string                              |
   //+------------------------------------------------------------------+
   string Utf8BytesToString(uchar &bytes[], int len)
   {
      if(len <= 0) return "";
      
      // Ensure null termination
      if(len >= ArraySize(bytes) || bytes[len-1] != 0)
      {
         ArrayResize(bytes, len + 1);
         bytes[len] = 0;
      }
      
      return CharArrayToString(bytes, 0, len, CP_UTF8);
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                      |
   //+------------------------------------------------------------------+
   RedisClient()
   {
      m_connected = false;
      m_authenticated = false;
      m_last_error = "";
   }
   
   //+------------------------------------------------------------------+
   //| Destructor                                                       |
   //+------------------------------------------------------------------+
   ~RedisClient()
   {
      Disconnect();
   }
   
   //+------------------------------------------------------------------+
   //| Connect to Redis server                                          |
   //+------------------------------------------------------------------+
   bool Connect(string connection_string)
   {
      if(m_connected) return true;
      
      uchar conn_bytes[];
      int conn_len = StringToUtf8Bytes(connection_string, conn_bytes);
      
      if(conn_len <= 0)
      {
         m_last_error = "Failed to convert connection string";
         return false;
      }
      
      if(redis_connect(conn_bytes, conn_len) == 1)
      {
         m_connected = true;
         m_last_error = "";
         return true;
      }
      
      m_connected = false;
      m_last_error = "Connection failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Authenticate with Redis                                          |
   //+------------------------------------------------------------------+
   bool Auth(string username, string password)
   {
      if(!m_connected)
      {
         m_last_error = "Not connected";
         return false;
      }
      
      uchar username_bytes[], password_bytes[];
      int username_len = StringToUtf8Bytes(username, username_bytes);
      int password_len = StringToUtf8Bytes(password, password_bytes);
      
      if(username_len <= 0 || password_len <= 0)
      {
         m_last_error = "Failed to convert credentials";
         return false;
      }
      
      if(redis_auth(username_bytes, username_len, password_bytes, password_len) == 1)
      {
         m_authenticated = true;
         m_last_error = "";
         return true;
      }
      
      m_authenticated = false;
      m_last_error = "Authentication failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Set string value                                                 |
   //+------------------------------------------------------------------+
   bool Set(string key, string value)
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      uchar key_bytes[], value_bytes[];
      int key_len = StringToUtf8Bytes(key, key_bytes);
      int value_len = StringToUtf8Bytes(value, value_bytes);
      
      if(key_len <= 0 || value_len <= 0)
      {
         m_last_error = "Failed to convert key or value";
         return false;
      }
      
      if(redis_set(key_bytes, key_len, value_bytes, value_len) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "Set failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Set string value with expiry                                     |
   //+------------------------------------------------------------------+
   bool SetEx(string key, string value, int expiry_seconds)
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      uchar key_bytes[], value_bytes[];
      int key_len = StringToUtf8Bytes(key, key_bytes);
      int value_len = StringToUtf8Bytes(value, value_bytes);
      
      if(key_len <= 0 || value_len <= 0)
      {
         m_last_error = "Failed to convert key or value";
         return false;
      }
      
      if(redis_set_ex(key_bytes, key_len, value_bytes, value_len, expiry_seconds) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "SetEx failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Get string value                                                 |
   //+------------------------------------------------------------------+
   string Get(string key)
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return "";
      }
      
      uchar key_bytes[];
      int key_len = StringToUtf8Bytes(key, key_bytes);
      
      if(key_len <= 0)
      {
         m_last_error = "Failed to convert key";
         return "";
      }
      
      uchar buffer[4096];
      int result = redis_get(key_bytes, key_len, buffer, ArraySize(buffer));
      
      if(result > 0)
      {
         m_last_error = "";
         return Utf8BytesToString(buffer, result);
      }
      
      m_last_error = "Get failed";
      return "";
   }
   
   //+------------------------------------------------------------------+
   //| Publish string message to channel                               |
   //+------------------------------------------------------------------+
   bool Publish(string channel, string message)
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      uchar channel_bytes[], message_bytes[];
      int channel_len = StringToUtf8Bytes(channel, channel_bytes);
      int message_len = StringToUtf8Bytes(message, message_bytes);
      
      if(channel_len <= 0 || message_len <= 0)
      {
         m_last_error = "Failed to convert channel or message";
         return false;
      }
      
      if(redis_publish(channel_bytes, channel_len, message_bytes, message_len) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "Publish failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Test connection with PING                                        |
   //+------------------------------------------------------------------+
   bool Ping()
   {
      if(!m_connected) return false;
      return (redis_ping() == 1);
   }
   
   //+------------------------------------------------------------------+
   //| Check if connected                                               |
   //+------------------------------------------------------------------+
   bool IsConnected()
   {
      m_connected = (redis_is_connected() == 1);
      return m_connected;
   }
   
   //+------------------------------------------------------------------+
   //| Check if authenticated                                           |
   //+------------------------------------------------------------------+
   bool IsAuthenticated()
   {
      return m_connected && m_authenticated;
   }
   
   //+------------------------------------------------------------------+
   //| Disconnect from Redis                                            |
   //+------------------------------------------------------------------+
   void Disconnect()
   {
      if(m_connected)
      {
         redis_disconnect();
         m_connected = false;
         m_authenticated = false;
      }
   }
   
   //+------------------------------------------------------------------+
   //| Test byte echo function                                          |
   //+------------------------------------------------------------------+
   string TestByteEcho(string str)
   {
      uchar input_bytes[];
      uchar output_bytes[1024];
      int input_len = StringToUtf8Bytes(str, input_bytes);
      
      if(input_len <= 0)
      {
         return "";
      }
      
      int buffer_size = ArraySize(output_bytes);
      int result = redis_test_byte_echo(input_bytes, input_len, output_bytes, buffer_size);
      
      if(result > 0)
      {
         return Utf8BytesToString(output_bytes, result);
      }
      
      return "";
   }
   
   //+------------------------------------------------------------------+
   //| Get last error message                                           |
   //+------------------------------------------------------------------+
   string GetLastError() { return m_last_error; }
   
   //+------------------------------------------------------------------+
   //| Get connection status string                                     |
   //+------------------------------------------------------------------+
   string GetStatusString()
   {
      if(!IsConnected()) return "Disconnected";
      if(!IsAuthenticated()) return "Connected (Not Authenticated)";
      return "Connected and Authenticated";
   }
   
   //+------------------------------------------------------------------+
   //| Set binary data with string key                                  |
   //+------------------------------------------------------------------+
   bool SetBinary(string key, uchar &data[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      uchar key_bytes[];
      int key_len = StringToUtf8Bytes(key, key_bytes);
      int data_len = ArraySize(data);
      
      if(key_len <= 0 || data_len <= 0)
      {
         m_last_error = "Invalid key or data";
         return false;
      }
      
      if(redis_set(key_bytes, key_len, data, data_len) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "SetBinary failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Set binary data with binary key                                  |
   //+------------------------------------------------------------------+
   bool SetBinaryKey(uchar &key[], uchar &data[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      int key_len = ArraySize(key);
      int data_len = ArraySize(data);
      
      if(key_len <= 0 || data_len <= 0)
      {
         m_last_error = "Invalid key or data";
         return false;
      }
      
      if(redis_set(key, key_len, data, data_len) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "SetBinaryKey failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Get binary data with string key                                  |
   //+------------------------------------------------------------------+
   int GetBinary(string key, uchar &buffer[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return -1;
      }
      
      uchar key_bytes[];
      int key_len = StringToUtf8Bytes(key, key_bytes);
      
      if(key_len <= 0)
      {
         m_last_error = "Failed to convert key";
         return -1;
      }
      
      int result = redis_get(key_bytes, key_len, buffer, ArraySize(buffer));
      
      if(result >= 0)
      {
         m_last_error = "";
         return result;
      }
      
      m_last_error = "GetBinary failed";
      return -1;
   }
   
   //+------------------------------------------------------------------+
   //| Get binary data with binary key                                  |
   //+------------------------------------------------------------------+
   int GetBinaryKey(uchar &key[], uchar &buffer[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return -1;
      }
      
      int key_len = ArraySize(key);
      
      if(key_len <= 0)
      {
         m_last_error = "Invalid key";
         return -1;
      }
      
      int result = redis_get(key, key_len, buffer, ArraySize(buffer));
      
      if(result >= 0)
      {
         m_last_error = "";
         return result;
      }
      
      m_last_error = "GetBinaryKey failed";
      return -1;
   }
   
   //+------------------------------------------------------------------+
   //| Publish binary data to string channel                           |
   //+------------------------------------------------------------------+
   bool PublishBinary(string channel, uchar &data[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      uchar channel_bytes[];
      int channel_len = StringToUtf8Bytes(channel, channel_bytes);
      int data_len = ArraySize(data);
      
      if(channel_len <= 0 || data_len <= 0)
      {
         m_last_error = "Invalid channel or data";
         return false;
      }
      
      if(redis_publish(channel_bytes, channel_len, data, data_len) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "PublishBinary failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Publish binary data to binary channel                           |
   //+------------------------------------------------------------------+
   bool PublishBinaryChannel(uchar &channel[], uchar &data[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      int channel_len = ArraySize(channel);
      int data_len = ArraySize(data);
      
      if(channel_len <= 0 || data_len <= 0)
      {
         m_last_error = "Invalid channel or data";
         return false;
      }
      
      if(redis_publish(channel, channel_len, data, data_len) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "PublishBinaryChannel failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Publish to UInt64 channel (converted to hex string)             |
   //+------------------------------------------------------------------+
   bool PublishToUInt64Channel(ulong channel_id, uchar &data[])
   {
      string channel = StringFormat("%016llx", channel_id);
      return PublishBinary(channel, data);
   }
   
   //+------------------------------------------------------------------+
   //| Publish uint64 value to channel                                 |
   //+------------------------------------------------------------------+
   bool PublishUInt64(string channel, ulong value)
   {
      uchar data[8];
      data[0] = (uchar)(value & 0xFF);
      data[1] = (uchar)((value >> 8) & 0xFF);
      data[2] = (uchar)((value >> 16) & 0xFF);
      data[3] = (uchar)((value >> 24) & 0xFF);
      data[4] = (uchar)((value >> 32) & 0xFF);
      data[5] = (uchar)((value >> 40) & 0xFF);
      data[6] = (uchar)((value >> 48) & 0xFF);
      data[7] = (uchar)((value >> 56) & 0xFF);
      return PublishBinary(channel, data);
   }
   
   //+------------------------------------------------------------------+
   //| Publish uint64 value to its hex representation channel          |
   //+------------------------------------------------------------------+
   bool PublishUInt64ToHexChannel(ulong value)
   {
      uchar data[8];
      data[0] = (uchar)(value & 0xFF);
      data[1] = (uchar)((value >> 8) & 0xFF);
      data[2] = (uchar)((value >> 16) & 0xFF);
      data[3] = (uchar)((value >> 24) & 0xFF);
      data[4] = (uchar)((value >> 32) & 0xFF);
      data[5] = (uchar)((value >> 40) & 0xFF);
      data[6] = (uchar)((value >> 48) & 0xFF);
      data[7] = (uchar)((value >> 56) & 0xFF);
      
      string channel = "";
      for(int i = 0; i < 8; i++)
      {
         channel += StringFormat("%02x", data[i]);
      }
      
      return PublishBinary(channel, data);
   }
   
   //+------------------------------------------------------------------+
   //| Multi-set operation with key-value pairs                        |
   //+------------------------------------------------------------------+
   bool MSet(string &keys[], string &values[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      int pairs_count = ArraySize(keys);
      if(pairs_count != ArraySize(values) || pairs_count == 0)
      {
         m_last_error = "Key and value arrays must have the same size";
         return false;
      }
      
      // Build MSET payload: [key1_len][key1_bytes][value1_len][value1_bytes]...
      uchar payload[];
      int payload_pos = 0;
      
      for(int i = 0; i < pairs_count; i++)
      {
         uchar key_bytes[], value_bytes[];
         int key_len = StringToUtf8Bytes(keys[i], key_bytes);
         int value_len = StringToUtf8Bytes(values[i], value_bytes);
         
         if(key_len <= 0 || value_len <= 0)
         {
            m_last_error = "Failed to convert key or value at index " + IntegerToString(i);
            return false;
         }
         
         // Extend payload array
         int new_size = payload_pos + 4 + key_len + 4 + value_len;
         ArrayResize(payload, new_size);
         
         // Add key length (big-endian)
         payload[payload_pos++] = (uchar)((key_len >> 24) & 0xFF);
         payload[payload_pos++] = (uchar)((key_len >> 16) & 0xFF);
         payload[payload_pos++] = (uchar)((key_len >> 8) & 0xFF);
         payload[payload_pos++] = (uchar)(key_len & 0xFF);
         
         // Add key bytes
         for(int j = 0; j < key_len; j++)
         {
            payload[payload_pos++] = key_bytes[j];
         }
         
         // Add value length (big-endian)
         payload[payload_pos++] = (uchar)((value_len >> 24) & 0xFF);
         payload[payload_pos++] = (uchar)((value_len >> 16) & 0xFF);
         payload[payload_pos++] = (uchar)((value_len >> 8) & 0xFF);
         payload[payload_pos++] = (uchar)(value_len & 0xFF);
         
         // Add value bytes
         for(int j = 0; j < value_len; j++)
         {
            payload[payload_pos++] = value_bytes[j];
         }
      }
      
      if(redis_mset(payload, ArraySize(payload)) == 1)
      {
         m_last_error = "";
         return true;
      }
      
      m_last_error = "MSET failed";
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Multi-get operation with key array                              |
   //+------------------------------------------------------------------+
   bool MGet(string &keys[], string &values[])
   {
      if(!IsAuthenticated())
      {
         m_last_error = "Not connected or authenticated";
         return false;
      }
      
      int keys_count = ArraySize(keys);
      if(keys_count == 0)
      {
         m_last_error = "Keys array is empty";
         return false;
      }
      
      // Build MGET payload: [key1_len][key1_bytes][key2_len][key2_bytes]...
      uchar payload[];
      int payload_pos = 0;
      
      for(int i = 0; i < keys_count; i++)
      {
         uchar key_bytes[];
         int key_len = StringToUtf8Bytes(keys[i], key_bytes);
         
         if(key_len <= 0)
         {
            m_last_error = "Failed to convert key at index " + IntegerToString(i);
            return false;
         }
         
         // Extend payload array
         int new_size = payload_pos + 4 + key_len;
         ArrayResize(payload, new_size);
         
         // Add key length (big-endian)
         payload[payload_pos++] = (uchar)((key_len >> 24) & 0xFF);
         payload[payload_pos++] = (uchar)((key_len >> 16) & 0xFF);
         payload[payload_pos++] = (uchar)((key_len >> 8) & 0xFF);
         payload[payload_pos++] = (uchar)(key_len & 0xFF);
         
         // Add key bytes
         for(int j = 0; j < key_len; j++)
         {
            payload[payload_pos++] = key_bytes[j];
         }
      }
      
      uchar buffer[4096];
      int result = redis_mget(payload, ArraySize(payload), buffer, ArraySize(buffer));
      
      if(result > 0)
      {
         // Parse MGET response: [value1_len][value1_bytes][value2_len][value2_bytes]...
         ArrayResize(values, keys_count);
         int buffer_pos = 0;
         
         for(int i = 0; i < keys_count && buffer_pos + 4 <= result; i++)
         {
            // Read value length (big-endian)
            int value_len = (buffer[buffer_pos] << 24) | 
                           (buffer[buffer_pos + 1] << 16) | 
                           (buffer[buffer_pos + 2] << 8) | 
                           buffer[buffer_pos + 3];
            buffer_pos += 4;
            
            if(value_len == 0)
            {
               // NULL value
               values[i] = "";
            }
            else if(buffer_pos + value_len <= result)
            {
               // Extract value bytes
               uchar value_bytes[];
               ArrayResize(value_bytes, value_len);
               
               for(int j = 0; j < value_len; j++)
               {
                  value_bytes[j] = buffer[buffer_pos + j];
               }
               
               values[i] = Utf8BytesToString(value_bytes, value_len);
               buffer_pos += value_len;
            }
            else
            {
               m_last_error = "Incomplete value data in MGET response";
               return false;
            }
         }
         
         m_last_error = "";
         return true;
      }
      
      m_last_error = "MGET failed";
      return false;
   }
}; 