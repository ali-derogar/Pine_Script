//+------------------------------------------------------------------+
//|                       signal_manager.mq4                         |
//|                       Copyright 2024, Ali Derogar                |
//|                       https://www.mql4.com                       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Ali Derogar"
#property link      "https://www.mql4.com"
#property version   "1.00"

#define MAGIC_NUMBER 123456
extern double lotSize = 0.05;
extern int slippage = 5;
extern int time_frame = PERIOD_M1;
extern double stopLossPips = 50;  // مقدار حد ضرر به پیپ
extern double takeProfitRatio = 1; // نسبت حد سود به حد ضرر

datetime lastBarTime;  // زمان آخرین کندل
int positionsOpened = 0; // تعداد پوزیشن‌های باز شده در کندل فعلی

// ساختار برای نگهداری تریلینگ استاپ‌ها
struct TrailingStopData
{
    int ticket;           // شماره تیکت سفارش
    double stopDistance;  // فاصله تریلینگ استاپ
};
TrailingStopData trailingStopDistances[]; // آرایه برای ذخیره مقدار فاصله تریلینگ استاپ هر پوزیشن

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("Expert initialized.");
   lastBarTime = iTime(Symbol(), time_frame, 0);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   RefreshRates(); // تازه سازی نرخ‌ها

   // بررسی می‌کنیم که آیا کندل جدید شروع شده است
   if(iTime(Symbol(), time_frame, 0) != lastBarTime)
   {
       lastBarTime = iTime(Symbol(), time_frame, 0); // بروزرسانی زمان آخرین کندل
       positionsOpened = 0; // تعداد پوزیشن‌های باز شده در کندل جدید را ریست می‌کنیم
   }

   // اگر تعداد پوزیشن‌های باز شده در کندل فعلی کمتر از 2 باشد، اجازه باز کردن پوزیشن جدید داریم
   if(positionsOpened < 2)
   {
       string signal = GetSignalFromAPI();
       Print(signal);

       if(MarketInfo(Symbol(), MODE_TRADEALLOWED) == 0)
       {
          Print("Market is closed. Cannot place orders.");
          return;
       }

       double stopLoss, takeProfit;

       if (signal == "buy")
       {
          stopLoss = iLow(Symbol(), time_frame, 1) - (stopLossPips * Point);
          takeProfit = Ask + (Ask - stopLoss) * takeProfitRatio; // استفاده از نسبت حد سود

          // پوزیشن اول با حد سود
          int buyTicket1 = OrderSend(Symbol(), OP_BUY, lotSize, Ask, slippage, stopLoss, takeProfit, "Buy Signal 1", MAGIC_NUMBER, 0, Blue);

          if (buyTicket1 < 0)
          {
             int buyErrorCode1 = GetLastError();
             Print("Buy OrderSend 1 failed with error code: ", buyErrorCode1);
          }
          else
          {
             Print("Buy order 1 placed successfully. Ticket: ", buyTicket1);
             positionsOpened++; // افزایش تعداد پوزیشن‌های باز شده در این کندل

             // ذخیره مقدار تریلینگ استاپ بر اساس حد سود پوزیشن اول
             TrailingStopData data1;
             data1.ticket = buyTicket1;
             data1.stopDistance = (takeProfit - Ask) * 0.5; // فاصله تریلینگ استاپ بدون stopLossPips
             ArrayResize(trailingStopDistances, ArraySize(trailingStopDistances) + 1);
             trailingStopDistances[ArraySize(trailingStopDistances) - 1] = data1;
          }

          // پوزیشن دوم بدون حد سود و با تریلینگ استاپ
          int buyTicket2 = OrderSend(Symbol(), OP_BUY, lotSize, Ask, slippage, stopLoss, 0, "Buy Signal 2", MAGIC_NUMBER, 0, Blue);

          if (buyTicket2 < 0)
          {
             int buyErrorCode2 = GetLastError();
             Print("Buy OrderSend 2 failed with error code: ", buyErrorCode2);
          }
          else
          {
             Print("Buy order 2 placed successfully. Ticket: ", buyTicket2);
             positionsOpened++; // افزایش تعداد پوزیشن‌های باز شده در این کندل

             // ذخیره مقدار تریلینگ استاپ برای پوزیشن دوم
             TrailingStopData data2;
             data2.ticket = buyTicket2;
             // محاسبه stopDistance برای پوزیشن دوم
             data2.stopDistance = (Ask - stopLoss) + (stopLossPips * Point); // نقطه ورود - حد ضرر
             ArrayResize(trailingStopDistances, ArraySize(trailingStopDistances) + 1);
             trailingStopDistances[ArraySize(trailingStopDistances) - 1] = data2;
          }
       }
       else if (signal == "sell")
       {
          stopLoss = iHigh(Symbol(), time_frame, 1) + (stopLossPips * Point);
          takeProfit = Bid - (stopLoss - Bid) * takeProfitRatio; // استفاده از نسبت حد سود

          // پوزیشن اول با حد سود
          int sellTicket1 = OrderSend(Symbol(), OP_SELL, lotSize, Bid, slippage, stopLoss, takeProfit, "Sell Signal 1", MAGIC_NUMBER, 0, Red);

          if (sellTicket1 < 0)
          {
             int sellErrorCode1 = GetLastError();
             Print("Sell OrderSend 1 failed with error code: ", sellErrorCode1);
          }
          else
          {
             Print("Sell order 1 placed successfully. Ticket: ", sellTicket1);
             positionsOpened++; // افزایش تعداد پوزیشن‌های باز شده در این کندل

             // ذخیره مقدار تریلینگ استاپ بر اساس حد سود پوزیشن اول
             TrailingStopData data1;
             data1.ticket = sellTicket1;
             data1.stopDistance = (Bid - takeProfit) * 0.5; // فاصله تریلینگ استاپ بدون stopLossPips
             ArrayResize(trailingStopDistances, ArraySize(trailingStopDistances) + 1);
             trailingStopDistances[ArraySize(trailingStopDistances) - 1] = data1;
          }

          // پوزیشن دوم بدون حد سود و با تریلینگ استاپ
          int sellTicket2 = OrderSend(Symbol(), OP_SELL, lotSize, Bid, slippage, stopLoss, 0, "Sell Signal 2", MAGIC_NUMBER, 0, Red);

          if (sellTicket2 < 0)
          {
             int sellErrorCode2 = GetLastError();
             Print("Sell OrderSend 2 failed with error code: ", sellErrorCode2);
          }
          else
          {
             Print("Sell order 2 placed successfully. Ticket: ", sellTicket2);
             positionsOpened++; // افزایش تعداد پوزیشن‌های باز شده در این کندل

             // ذخیره مقدار تریلینگ استاپ برای پوزیشن دوم
             TrailingStopData data2;
             data2.ticket = sellTicket2;
             // محاسبه stopDistance برای پوزیشن دوم
             data2.stopDistance = (stopLoss - Bid) + (stopLossPips * Point); // حد ضرر - نقطه ورود
             ArrayResize(trailingStopDistances, ArraySize(trailingStopDistances) + 1);
             trailingStopDistances[ArraySize(trailingStopDistances) - 1] = data2;
          }
       }
       else if (signal == "false")
       {
          Print("No trading signal received.");
       }
   }
   else
   {
       Print("Maximum positions for this bar reached. No new positions will be opened.");
   }

   TrailingStop(); // اجرای تریلینگ استاپ
}

//+------------------------------------------------------------------+
//| Trailing stop function                                           |
//+------------------------------------------------------------------+
void TrailingStop()
{
   for(int i1 = 0; i1 < OrdersTotal(); i1++)
   {
      if(OrderSelect(i1, SELECT_BY_POS) && OrderMagicNumber() == MAGIC_NUMBER && OrderSymbol() == Symbol())
      {
         // بررسی اینکه آیا پوزیشن دارای حد سود است یا خیر
         double takeProfit = OrderTakeProfit();
         if (takeProfit > 0) // اگر حد سود مشخص شده باشد
            continue; // از این پوزیشن عبور کن، زیرا نمی‌خواهیم تریل شود

         // ادامه محاسبات تریلینگ استاپ برای پوزیشن‌های بدون حد سود
         for(int j1 = 0; j1 < ArraySize(trailingStopDistances); j1++)
         {
            if(trailingStopDistances[j1].ticket == OrderTicket())
            {
               if(OrderType() == OP_BUY)
               {
                  double newStopLossBuy = Bid - trailingStopDistances[j1].stopDistance;

                  if(newStopLossBuy > OrderStopLoss())
                  {
                     if (OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossBuy, 0, 0, CLR_NONE))
                     {
                         Print("Trailing Stop updated for Buy Order: ", OrderTicket(), " to ", newStopLossBuy);
                     }
                     else
                     {
                         int errorCode = GetLastError();
                         Print("Failed to update trailing stop for Buy Order: ", OrderTicket(), " with error code: ", errorCode);
                     }
                  }
               }
               else if(OrderType() == OP_SELL)
               {
                  double newStopLossSell = Bid + trailingStopDistances[j1].stopDistance;

                  if(newStopLossSell < OrderStopLoss())
                  {
                     if (OrderModify(OrderTicket(), OrderOpenPrice(), newStopLossSell, 0, 0, CLR_NONE))
                     {
                         Print("Trailing Stop updated for Sell Order: ", OrderTicket(), " to ", newStopLossSell);
                     }
                     else
                     {
                         int errorCode1 = GetLastError();
                         Print("Failed to update trailing stop for Sell Order: ", OrderTicket(), " with error code: ", errorCode1);
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get signal from API                                              |
//+------------------------------------------------------------------+
string GetSignalFromAPI()
{
    string url = "https://fastapi-ofjxhm.chbk.run/get-signal";
    char result[];
    string headers = "";
    string responseHeaders;
    int timeout = 5000;

    ArrayResize(result, 1024);

    int res = WebRequest("GET", url, headers, timeout, result, result, responseHeaders);
    Print("WebRequest result: ", res);

    if (res == -1)
    {
        int errorCode = GetLastError();
        Print("Error in WebRequest: ", errorCode);
        return "";
    }

    string response = CharArrayToString(result);
    Print("API Response: ", response);

    string processedSignal = "";
    for(int i3 = 0; i3 < StringLen(response); i3++)
    {
        if (StringGetChar(response, i3) != '\"')
        {
            processedSignal += StringSubstr(response, i3, 1);
        }
    }

    Print("Processed signal: ", processedSignal, ", Length: ", StringLen(processedSignal));

    if(processedSignal == "buy" || processedSignal == "sell")
    {
        return processedSignal;
    }
    else
    {
        Print("Invalid signal received: ", processedSignal);
        return "";
    }
}
