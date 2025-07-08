//+------------------------------------------------------------------+
//|                                                     BTRUtils.mqh |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| CSV Data Structure                                               |
//+------------------------------------------------------------------+
struct CSVData
{
   string headers[];    // Column names from first row
   string data[];       // 1D array storing 2D data using formula: index = (row * cols) + col
   int rows;            // Number of data rows (excluding header)
   int cols;            // Number of columns
};

//+------------------------------------------------------------------+
//| CSV Parsing Functions                                            |
//+------------------------------------------------------------------+

// Parse a single CSV line into fields array
int ParseCSVLine(string line, string &fields[])
{
   ArrayResize(fields, 0);
   
   if(StringLen(line) == 0) return 0;
   
   string current_field = "";
   bool in_quotes = false;
   int field_count = 0;
   
   for(int i = 0; i < StringLen(line); i++)
   {
      string ch = StringSubstr(line, i, 1);
      
      if(ch == "\"")
      {
         in_quotes = !in_quotes;
      }
      else if(ch == "," && !in_quotes)
      {
         ArrayResize(fields, field_count + 1);
         fields[field_count] = BTRStringTrimLeft(BTRStringTrimRight(current_field));
         field_count++;
         current_field = "";
      }
      else
      {
         current_field += ch;
      }
   }
   
   // Add final field
   ArrayResize(fields, field_count + 1);
   fields[field_count] = BTRStringTrimLeft(BTRStringTrimRight(current_field));
   
   return field_count + 1;
}

// Load and parse CSV file into structured data
bool LoadCSVData(string filename, CSVData &csv_data)
{
   csv_data.rows = 0;
   csv_data.cols = 0;
   ArrayResize(csv_data.headers, 0);
   ArrayResize(csv_data.data, 0);
   
   int handle = FileOpen(filename, FILE_READ | FILE_TXT);
   if(handle == INVALID_HANDLE)
   {
      Print("ERROR: Cannot open CSV file: " + filename);
      return false;
   }
   
   string lines[];
   int line_count = 0;
   
   // Read all lines
   while(!FileIsEnding(handle))
   {
      string line = FileReadString(handle);
      if(StringLen(line) > 0)
      {
         ArrayResize(lines, line_count + 1);
         lines[line_count] = line;
         line_count++;
      }
   }
   
   FileClose(handle);
   
   if(line_count == 0)
   {
      Print("ERROR: Empty CSV file: " + filename);
      return false;
   }
   
   // Parse header row
   string header_fields[];
   csv_data.cols = ParseCSVLine(lines[0], header_fields);
   ArrayResize(csv_data.headers, csv_data.cols);
   ArrayCopy(csv_data.headers, header_fields);
   
   // Parse data rows
   csv_data.rows = line_count - 1;
   // Resize 1D array to hold all data: total_elements = rows * cols
   ArrayResize(csv_data.data, csv_data.rows * csv_data.cols);
   
   for(int i = 1; i < line_count; i++)
   {
      string row_fields[];
      int field_count = ParseCSVLine(lines[i], row_fields);
      
      // Store data in 1D array using calculated indexing
      int row_index = i - 1; // Convert to 0-based row index
      for(int j = 0; j < csv_data.cols && j < field_count; j++)
      {
         // Formula: index = (row * cols) + col
         int linear_index = (row_index * csv_data.cols) + j;
         csv_data.data[linear_index] = row_fields[j];
      }
   }
   
   Print("Loaded CSV: " + filename + " - " + IntegerToString(csv_data.rows) + " rows, " + IntegerToString(csv_data.cols) + " columns");
   return true;
}

// Get column index by header name
int GetColumnIndex(const CSVData &csv_data, string column_name)
{
   for(int i = 0; i < csv_data.cols; i++)
   {
      if(csv_data.headers[i] == column_name)
         return i;
   }
   return -1;
}

// Get cell value by row and column name
string GetCellValue(const CSVData &csv_data, int row, string column_name)
{
   int col_index = GetColumnIndex(csv_data, column_name);
   if(col_index >= 0 && row >= 0 && row < csv_data.rows)
   {
      // Use calculated indexing: index = (row * cols) + col
      int linear_index = (row * csv_data.cols) + col_index;
      return csv_data.data[linear_index];
   }
   return "";
}

// Get cell value by row and column index
string GetCellByIndex(const CSVData &csv_data, int row, int col)
{
   if(row >= 0 && row < csv_data.rows && col >= 0 && col < csv_data.cols)
   {
      // Use calculated indexing: index = (row * cols) + col
      int linear_index = (row * csv_data.cols) + col;
      return csv_data.data[linear_index];
   }
   return "";
}

//+------------------------------------------------------------------+
//| String Utility Functions                                         |
//+------------------------------------------------------------------+

// Enhanced string trimming functions (renamed to avoid conflicts with built-in functions)
string BTRStringTrimLeft(string text)
{
   while(StringLen(text) > 0 && (StringGetCharacter(text, 0) == ' ' || StringGetCharacter(text, 0) == '\t'))
      text = StringSubstr(text, 1);
   return text;
}

string BTRStringTrimRight(string text)
{
   while(StringLen(text) > 0)
   {
      int last_char = StringGetCharacter(text, StringLen(text) - 1);
      if(last_char == ' ' || last_char == '\t')
         text = StringSubstr(text, 0, StringLen(text) - 1);
      else
         break;
   }
   return text;
}

string BTRStringTrim(string text)
{
   return BTRStringTrimLeft(BTRStringTrimRight(text));
}

// Check if string ends with suffix
bool StringEndsWith(const string text, const string suffix)
{
   int text_len = StringLen(text);
   int suffix_len = StringLen(suffix);
   if(suffix_len > text_len) return false;
   return(StringSubstr(text, text_len - suffix_len) == suffix);
}

//+------------------------------------------------------------------+
//| Symbol Cleanup Functions                                         |
//+------------------------------------------------------------------+

// Enhanced symbol cleanup function with compound suffix handling (as per README.md)
void CleanupSymbol(const string symbol, string &target)
{
   // Unified delimiter constants
   const string DELIMITERS = "^$.-_#";
   const string delimiter_suffixes[] = {"US", "USD", "USX", "C", "M", "MINI", "MICRO", "CASH", "SPOT", "ECN", "ZERO"};
   const string standalone_suffixes[] = {"MINI", "MICRO", "CASH", "SPOT", "ECN", "ZERO"};
   const string single_char_suffixes = "MCZBRI$#";
   
   target = symbol;
   StringToUpper(target);
   
   // --- Prefix Removal (left trim) ---
   int len = StringLen(target);
   if(len > 1)
   {
      string first_char = StringSubstr(target, 0, 1);
      if(StringFind(DELIMITERS, first_char) != -1)
      {
         target = StringSubstr(target, 1);
         len = StringLen(target);
      }
   }
   
   // Run cleanup twice to handle compound suffixes (e.g., "XAG.CASH" -> "XAG." -> "XAG")
   for(int pass = 0; pass < 2; pass++)
   {
      len = StringLen(target);
      if(len < 1) break;
      
      bool suffix_removed = false;
      
      // --- Delimiter-based suffix removal (when following delimiters) ---
      if(len > 1)
      {
         for(int i = 0; i < ArraySize(delimiter_suffixes); i++)
         {
            string suffix = delimiter_suffixes[i];
            int suffix_len = StringLen(suffix);
            
            if(len > suffix_len + 1) // Need at least delimiter + suffix
            {
               if(StringEndsWith(target, suffix))
               {
                  // Check if preceded by delimiter
                  string delimiter_char = StringSubstr(target, len - suffix_len - 1, 1);
                  if(StringFind(DELIMITERS, delimiter_char) != -1)
                  {
                     target = StringSubstr(target, 0, len - suffix_len);
                     len = StringLen(target);
                     suffix_removed = true;
                     break;
                  }
               }
            }
         }
      }
      
      // --- Standalone suffix removal (regardless of delimiters) ---
      if(!suffix_removed)
      {
         for(int i = 0; i < ArraySize(standalone_suffixes); i++)
         {
            if(StringEndsWith(target, standalone_suffixes[i]))
            {
               target = StringSubstr(target, 0, StringLen(target) - StringLen(standalone_suffixes[i]));
               len = StringLen(target);
               suffix_removed = true;
               break;
            }
         }
      }
      
      // --- Single character suffix removal (only when preceded by delimiters) ---
      if(!suffix_removed && len > 1)
      {
         string last_char = StringSubstr(target, len - 1, 1);
         
         if(StringFind(single_char_suffixes, last_char) != -1)
         {
            // Check if preceded by delimiter
            if(len > 1)
            {
               string delimiter_char = StringSubstr(target, len - 2, 1);
               if(StringFind(DELIMITERS, delimiter_char) != -1)
               {
                  target = StringSubstr(target, 0, len - 1);
                  len = StringLen(target);
                  suffix_removed = true;
               }
            }
         }
      }
      
      // --- Delimiter removal (second pass cleanup) ---
      if(!suffix_removed && len > 0)
      {
         string last_char = StringSubstr(target, len - 1, 1);
         if(StringFind(DELIMITERS, last_char) != -1)
         {
            target = StringSubstr(target, 0, len - 1);
         }
      }
   }
   
   // Final cleanup - remove any remaining embedded delimiters
   StringReplace(target, "/", "");
} 