//+------------------------------------------------------------------+
//|                                             BTRMitchModel.mqh |
//| Copyright BTR Supply                                             |
//| https://btr.supply                                               |
//+------------------------------------------------------------------+
#property strict

#include "BTRIds.mqh"

// --- Message Type Codes ---
#define MITCH_MSG_TYPE_TRADE        't'
#define MITCH_MSG_TYPE_ORDER        'o'
#define MITCH_MSG_TYPE_TICKER       's'
#define MITCH_MSG_TYPE_ORDER_BOOK   'q'

// --- Side Constants ---
#define MITCH_SIDE_BUY              0
#define MITCH_SIDE_SELL             1

// --- Order Type Constants ---
#define MITCH_ORDER_TYPE_MARKET     0
#define MITCH_ORDER_TYPE_LIMIT      1
#define MITCH_ORDER_TYPE_STOP       2
#define MITCH_ORDER_TYPE_CANCEL     3

// Legacy MITCH constants (mapped to BTR constants for compatibility)
#define MITCH_INST_SPOT             BTR_INST_SPOT
#define MITCH_INST_FUTURE           BTR_INST_FUTURE
#define MITCH_INST_FORWARD          BTR_INST_FORWARD
#define MITCH_INST_SWAP             BTR_INST_SWAP
#define MITCH_INST_PERPETUAL        BTR_INST_PERPETUAL
#define MITCH_INST_CFD              BTR_INST_CFD
#define MITCH_INST_CALL_OPTION      BTR_INST_CALL_OPTION
#define MITCH_INST_PUT_OPTION       BTR_INST_PUT_OPTION

#define MITCH_ASSET_EQUITIES        BTR_ASSET_EQUITIES
#define MITCH_ASSET_CORP_BONDS      BTR_ASSET_CORP_BONDS
#define MITCH_ASSET_SOVEREIGN_DEBT  BTR_ASSET_SOVEREIGN_DEBT
#define MITCH_ASSET_FOREX           BTR_ASSET_FOREX
#define MITCH_ASSET_COMMODITIES     BTR_ASSET_COMMODITIES
#define MITCH_ASSET_PRECIOUS_METALS BTR_ASSET_PRECIOUS_METALS
#define MITCH_ASSET_REAL_ESTATE     BTR_ASSET_REAL_ESTATE
#define MITCH_ASSET_CRYPTO          BTR_ASSET_CRYPTO

// --- Unified Message Header (8 bytes) ---
struct MitchHeader
{
   uchar   messageType;      // ASCII message type code
   uchar   timestamp[6];     // 48-bit nanoseconds since midnight
   uchar   count;            // Number of body entries (1-255)
};

// --- Extended TickerBody for MT4 with volume tracking (32 bytes) ---
struct TickerBody
{
   ulong   tickerId;         // 8-byte unique ticker identifier
   double  bidPrice;         // Best bid price
   double  askPrice;         // Best ask price
   uint    bidVolume;        // Volume at best bid (vbid since last snapshot)
   uint    askVolume;        // Volume at best ask (vask since last snapshot)
};

// --- Trade Body (32 bytes) ---
struct TradeBody
{
   ulong   tickerId;         // 8-byte unique ticker identifier
   double  price;            // Execution price
   uint    quantity;         // Executed volume/quantity
   uint    tradeId;          // Required unique trade identifier
   uchar   side;             // 0: Buy, 1: Sell
   uchar   padding[7];       // Padding to 32 bytes
};

// --- Order Body (32 bytes) ---
struct OrderBody
{
   ulong   tickerId;         // 8-byte unique ticker identifier
   uint    orderId;          // Required unique order identifier
   double  price;            // Limit/stop price
   uint    quantity;         // Order volume/quantity
   uchar   typeAndSide;      // Bit 0: Side, Bits 1-7: Order Type
   uchar   expiry[6];        // 48-bit expiry timestamp
   uchar   padding;          // Padding to 32 bytes
};

// --- Order Book Body Header (32 bytes) ---
struct OrderBookBody
{
   ulong   tickerId;         // 8-byte unique ticker identifier
   double  firstTick;        // Starting price level
   double  tickSize;         // Price increment per tick
   ushort  numTicks;         // Number of volume entries that follow
   uchar   side;             // 0: Bids, 1: Asks
   uchar   padding[5];       // Padding to 32 bytes
   // uint volumes[] follows
};

//+------------------------------------------------------------------+
//| Utility Functions                                               |
//+------------------------------------------------------------------+

// Extract side from type_and_side field
uchar ExtractSide(uchar typeAndSide)
{
   return typeAndSide & 0x01;
}

// Extract order type from type_and_side field
uchar ExtractOrderType(uchar typeAndSide)
{
   return (typeAndSide >> 1) & 0x7F;
}

// Combine order type and side into type_and_side field
uchar CombineTypeAndSide(uchar orderType, uchar side)
{
   return (orderType << 1) | side;
}

// Generate ticker ID for forex pair using proper MITCH specification
ulong GenerateForexTickerID(string symbol)
{
   // Use the consolidated MITCH ticker ID generation from BTRIds.mqh
   return GetMitchTickerID(symbol);
} 