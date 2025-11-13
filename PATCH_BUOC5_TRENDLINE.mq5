//+------------------------------------------------------------------+
//| PATCH FOR BƯỚC 5 - Add Trendline Check Before Order Placement   |
//| Replace the section in OnTick() where pending signals are       |
//| processed (around line 1350+)                                    |
//+------------------------------------------------------------------+

// ========================================
// BƯỚC 5: VẼ MŨI TÊN + VÀO LỆNH NGAY TẠI OPEN N+1
// ========================================
if(pendingSignal != 0)
{
   bool isBuyPS = (pendingSignal == 1);

   // ✅ KIỂM TRA: KHÔNG VẼ LẠI NẾN ĐÃ VẼ
   datetime arrowBarTime = iTime(_Symbol, PERIOD_CURRENT, 1);

   Print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
   Print("BƯỚC 5 - XỬ LÝ PENDING SIGNAL:");
   Print("   pendingSignal = ", pendingSignal, " (", (isBuyPS ? "BUY" : "SELL"), ")");
   Print("   arrowBarTime  = ", TimeToString(arrowBarTime));
   Print("   lastArrowBar  = ", TimeToString(lastArrowBar));
   Print("   lastSignalWasBuy = ", lastSignalWasBuy);

   // ✅ SỬA LẠI LOGIC: Chỉ bỏ qua nếu CÙNG bar VÀ CÙNG chiều
   if(lastArrowBar == arrowBarTime && lastSignalWasBuy == isBuyPS)
   {
      Print("⚠️⚠️⚠️ ĐÃ VẼ MŨI TÊN CHO BAR NÀY + CHIỀU NÀY RỒI");
      Print("   → KHÔNG RESET pendingSignal để giữ tín hiệu");
      Print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // ❌ KHÔNG RESET pendingSignal ở đây
      // Để nó tiếp tục xử lý ở nến sau nếu cần
   }
   else
   {
      Print("✓✓✓ VẼ MŨI TÊN MỚI cho bar[1] = ", TimeToString(arrowBarTime));

      // Vẽ mũi tên tại bar[1] (nến N vừa đóng, có QQE signal)
      if(isBuyPS)
         DrawSignalAtBar(1, true, false);
      else
         DrawSignalAtBar(1, false, true);

      Print(isBuyPS ? "✓ ĐÃ VẼ MŨI TÊN BUY" : "✓ ĐÃ VẼ MŨI TÊN SELL");

      // ✅ LƯU BAR ĐÃ VẼ
      lastArrowBar = arrowBarTime;
      lastSignalWasBuy = isBuyPS;

      // ✅ KIỂM TRA 1: NẾN N (bar[1]) CÓ CÙNG CHIỀU KHÔNG?
      bool candleMatch = IsCandleMatchSignal(isBuyPS, 1);
      bool wickPass = CheckCandleWick(isBuyPS, 1);

      // ✅ KIỂM TRA 2: TRENDLINE FILTER TẠI BAR[1]
      bool tlPass = true;
      if(UseTrendlineFilter)
      {
         tlPass = TrendPassAtBar(isBuyPS, 1);
         Print("   🎯 Trendline check (bar[1]): ", tlPass ? "✓ PASS" : "✗ FAIL");
         if(!tlPass)
         {
            Print("      → Reason: ", TrendMode == TL_BREAKOUT ? "Did not BREAK trendline" :
                                       TrendMode == TL_BOUNCE ? "Did not BOUNCE from trendline" :
                                       "Failed BOTH breakout and bounce conditions");
         }
      }

      if(!UseCandleConfirmation)
         Print("   Candle confirmation: DISABLED (auto pass)");
      else
         Print("   Nến có mũi tên (bar[1]): ", candleMatch ? "✓ CÙNG CHIỀU" : "✗ NGƯỢC CHIỀU");

      Print("   Wick check (bar[1]): ", wickPass ? "✓ PASS" : "✗ FAIL");

      datetime arrowTime = iTime(_Symbol, PERIOD_CURRENT, 1);
      string name = EA_PREFIX + (isBuyPS ? "BUY_" : "SELL_") + TimeToString(arrowTime);

      // ✅ KIỂM TRA TẤT CẢ FILTERS
      if(!candleMatch || !wickPass || !tlPass)
      {
         if(!candleMatch)
            Print("✗ KHÔNG VÀO LỆNH - Nến ngược chiều - Đổi màu XÁM");
         else if(!wickPass)
            Print("✗ KHÔNG VÀO LỆNH - Râu nến quá dài - Đổi màu VÀNG");
         else if(!tlPass)
            Print("✗ KHÔNG VÀO LỆNH - Không pass Trendline - Đổi màu XÁM ĐẬM");

         // Đổi màu mũi tên theo lý do
         if(ObjectFind(0, name) >= 0)
         {
            if(!candleMatch)
               ObjectSetInteger(0, name, OBJPROP_COLOR, clrSilver);        // Xám = ngược chiều
            else if(!wickPass)
               ObjectSetInteger(0, name, OBJPROP_COLOR, clrGold);          // Vàng = râu dài
            else if(!tlPass)
               ObjectSetInteger(0, name, OBJPROP_COLOR, clrDarkSlateGray); // Xám đậm = trendline fail

            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         }
      }
      else
      {
         // ✅ TẤT CẢ CHECKS PASS → VÀO LỆNH NGAY TẠI OPEN NẾN N+1 (bar[0])
         Print("✅✅✅ TẤT CẢ CHECKS PASS (Candle + Wick + Trendline)");
         Print("→ MỞ LỆNH NGAY TẠI OPEN NẾN N+1");

         int ordType = isBuyPS ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

         if(CanOpenOrder(ordType))
         {
            bool ok = PlaceOrder(ordType);

            if(ok)
            {
               Print("✓✓✓ MỞ LỆNH THÀNH CÔNG tại OPEN nến N+1");
               OnArrowAccepted(isBuyPS); // Cập nhật quota
            }
            else
            {
               Print("✗✗✗ MỞ LỆNH THẤT BẠI - LỖI BROKER");

               // Đổi màu mũi tên thành ĐEN
               if(ObjectFind(0, name) >= 0)
               {
                  ObjectSetInteger(0, name, OBJPROP_COLOR, clrDarkGray);
                  ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
               }
            }
         }
         else
         {
            Print("✗ QUOTA ĐẦY hoặc LIMIT REACHED");

            // Đổi màu mũi tên thành CAM
            if(ObjectFind(0, name) >= 0)
            {
               ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrange);
               ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            }
         }
      }

      // ✅ CHỈ RESET PENDING SAU KHI ĐÃ XỬ LÝ XONG
      Print("→ Reset pendingSignal = 0");
      pendingSignal = 0;
      Print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
   }
}
