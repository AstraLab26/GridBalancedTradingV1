//+------------------------------------------------------------------+
//|                              GridBalancedTradingV1.mq5           |
//|                       EA Grid Trading với cân bằng lưới tự động  |
//+------------------------------------------------------------------+
#property copyright "Grid Balanced Trading"
#property version   "1.00"
#property description "Grid Trading EA với hệ thống cân bằng lưới tự động"

#include <Trade\Trade.mqh>

//--- Input parameters - Cài đặt lưới
input group "=== CÀI ĐẶT LƯỚI ==="
input double GridDistancePips = 20.0;           // Khoảng cách lưới (pips)
input int MaxGridLevels = 10;                   // Số lượng lưới tối đa
input bool AutoRefillOrders = true;             // Tự động bổ sung lệnh khi đóng

//--- Input parameters - Cài đặt lệnh
input group "=== CÀI ĐẶT LỆNH ==="
input double LotSize = 0.01;                    // Khối lượng giao dịch
input double StopLossPips = 50.0;               // Stop Loss (pips, 0=off)
input double TakeProfitPips = 30.0;             // Take Profit (pips, 0=off)

//--- Input parameters - Cài đặt chung
input group "=== CÀI ĐẶT CHUNG ==="
input int MagicNumber = 123456;                 // Magic Number
input string CommentOrder = "Grid Balanced";    // Comment cho lệnh
input bool EnableBuyOrders = true;              // Cho phép lệnh Buy
input bool EnableSellOrders = true;             // Cho phép lệnh Sell

//--- Global variables
CTrade trade;
double pnt;
int dgt;
double basePrice;                               // Giá cơ sở để tính các level
double gridLevels[];                            // Mảng chứa các level giá cố định

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   dgt = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   pnt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Khởi tạo giá cơ sở
   basePrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Tạo mảng các level giá cố định
   InitializeGridLevels();
   
   Print("========================================");
   Print("Grid Balanced Trading EA V1 đã khởi động");
   Print("Symbol: ", _Symbol);
   Print("Base Price: ", basePrice);
   Print("Grid Distance: ", GridDistancePips, " pips");
   Print("Max Levels: ", MaxGridLevels);
   Print("Lot Size: ", LotSize);
   Print("SL: ", StopLossPips, " pips | TP: ", TakeProfitPips, " pips");
   Print("Auto Refill: ", AutoRefillOrders ? "ON" : "OFF");
   Print("Tổng số levels: ", ArraySize(gridLevels));
   Print("========================================");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("Grid Balanced Trading EA V1 đã dừng. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   ManageGridOrders();
}

//+------------------------------------------------------------------+
//| Khởi tạo các level giá cố định cho lưới                        |
//+------------------------------------------------------------------+
void InitializeGridLevels()
{
   double gridDistance = GridDistancePips * pnt * 10.0;
   int totalLevels = MaxGridLevels * 2 + 1; // Cả 2 phía + giá cơ sở
   
   ArrayResize(gridLevels, totalLevels);
   
   int index = 0;
   
   // Level phía trên giá cơ sở
   for(int i = 1; i <= MaxGridLevels; i++)
   {
      gridLevels[index] = NormalizeDouble(basePrice + (i * gridDistance), dgt);
      index++;
   }
   
   // Level giá cơ sở
   gridLevels[index] = NormalizeDouble(basePrice, dgt);
   index++;
   
   // Level phía dưới giá cơ sở
   for(int i = 1; i <= MaxGridLevels; i++)
   {
      gridLevels[index] = NormalizeDouble(basePrice - (i * gridDistance), dgt);
      index++;
   }
   
   Print("Đã khởi tạo ", totalLevels, " grid levels");
}

//+------------------------------------------------------------------+
//| Quản lý hệ thống lưới                                           |
//+------------------------------------------------------------------+
void ManageGridOrders()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Duyệt qua tất cả các level và đảm bảo có lệnh
   for(int i = 0; i < ArraySize(gridLevels); i++)
   {
      double level = gridLevels[i];
      
      // Bỏ qua level quá gần giá hiện tại
      double minDistance = GridDistancePips * pnt * 5.0;
      if(MathAbs(level - currentPrice) < minDistance)
         continue;
      
      // Quyết định loại lệnh dựa trên vị trí level so với giá hiện tại
      if(level > currentPrice)
      {
         // Level phía trên giá hiện tại
         if(EnableBuyOrders)
            EnsureOrderAtLevel(ORDER_TYPE_BUY_STOP, level);
         if(EnableSellOrders)
            EnsureOrderAtLevel(ORDER_TYPE_SELL_LIMIT, level);
      }
      else if(level < currentPrice)
      {
         // Level phía dưới giá hiện tại
         if(EnableBuyOrders)
            EnsureOrderAtLevel(ORDER_TYPE_BUY_LIMIT, level);
         if(EnableSellOrders)
            EnsureOrderAtLevel(ORDER_TYPE_SELL_STOP, level);
      }
   }
}

//+------------------------------------------------------------------+
//| Đảm bảo có lệnh tại level - tạo nếu chưa có                    |
//+------------------------------------------------------------------+
void EnsureOrderAtLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   // Kiểm tra xem đã có lệnh hoặc position tại level này chưa
   if(OrderOrPositionExistsAtLevel(orderType, priceLevel))
      return;
   
   // Kiểm tra cân bằng lưới
   if(!CanPlaceOrderAtLevel(orderType, priceLevel))
      return;
   
   // Đặt lệnh mới
   PlacePendingOrder(orderType, priceLevel);
}

//+------------------------------------------------------------------+
//| Kiểm tra có lệnh hoặc position tại level không                 |
//+------------------------------------------------------------------+
bool OrderOrPositionExistsAtLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   double tolerance = GridDistancePips * pnt * 5.0;
   bool isBuyOrder = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP);
   
   // Kiểm tra pending orders
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         if(OrderGetInteger(ORDER_MAGIC) == MagicNumber &&
            OrderGetString(ORDER_SYMBOL) == _Symbol)
         {
            double orderPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            if(MathAbs(orderPrice - priceLevel) < tolerance)
            {
               ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
               bool isOrderBuy = (ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP);
               
               if(isBuyOrder == isOrderBuy)
                  return true;
            }
         }
      }
   }
   
   // Kiểm tra positions đang mở
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            double posPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            if(MathAbs(posPrice - priceLevel) < tolerance)
            {
               ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               bool isPosBuy = (pt == POSITION_TYPE_BUY);
               
               if(isBuyOrder == isPosBuy)
                  return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra có thể đặt lệnh tại level không (cân bằng lưới)       |
//+------------------------------------------------------------------+
bool CanPlaceOrderAtLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   double tolerance = GridDistancePips * pnt * 5.0;
   bool isBuyOrder = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP);
   
   int buyCount = 0;
   int sellCount = 0;
   
   // Đếm pending orders tại level này
   for(int i = 0; i < OrdersTotal(); i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         if(OrderGetInteger(ORDER_MAGIC) == MagicNumber && 
            OrderGetString(ORDER_SYMBOL) == _Symbol)
         {
            double orderPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            if(MathAbs(orderPrice - priceLevel) < tolerance)
            {
               ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
               if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP)
                  buyCount++;
               else if(ot == ORDER_TYPE_SELL_LIMIT || ot == ORDER_TYPE_SELL_STOP)
                  sellCount++;
            }
         }
      }
   }
   
   // Đếm positions tại level này
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && 
            PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            double posPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            if(MathAbs(posPrice - priceLevel) < tolerance)
            {
               ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               if(pt == POSITION_TYPE_BUY)
                  buyCount++;
               else if(pt == POSITION_TYPE_SELL)
                  sellCount++;
            }
         }
      }
   }
   
   // Kiểm tra cân bằng: mỗi level tối đa 1 Buy và 1 Sell
   if(isBuyOrder && buyCount >= 1)
      return false;
   if(!isBuyOrder && sellCount >= 1)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Đặt lệnh chờ với SL/TP                                          |
//+------------------------------------------------------------------+
void PlacePendingOrder(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   double price = NormalizeDouble(priceLevel, dgt);
   double sl = 0, tp = 0;
   
   // Tính Stop Loss
   if(StopLossPips > 0)
   {
      if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
         sl = NormalizeDouble(price - StopLossPips * pnt * 10.0, dgt);
      else
         sl = NormalizeDouble(price + StopLossPips * pnt * 10.0, dgt);
   }
   
   // Tính Take Profit
   if(TakeProfitPips > 0)
   {
      if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
         tp = NormalizeDouble(price + TakeProfitPips * pnt * 10.0, dgt);
      else
         tp = NormalizeDouble(price - TakeProfitPips * pnt * 10.0, dgt);
   }
   
   // Đặt lệnh
   bool result = false;
   if(orderType == ORDER_TYPE_BUY_LIMIT)
      result = trade.BuyLimit(LotSize, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, CommentOrder);
   else if(orderType == ORDER_TYPE_SELL_LIMIT)
      result = trade.SellLimit(LotSize, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, CommentOrder);
   else if(orderType == ORDER_TYPE_BUY_STOP)
      result = trade.BuyStop(LotSize, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, CommentOrder);
   else if(orderType == ORDER_TYPE_SELL_STOP)
      result = trade.SellStop(LotSize, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, CommentOrder);
   
   if(result)
   {
      Print("✓ Đã đặt lệnh: ", EnumToString(orderType), " tại ", price, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("✗ Lỗi đặt lệnh: ", EnumToString(orderType), " | Error: ", GetLastError());
   }
}
//+------------------------------------------------------------------+
