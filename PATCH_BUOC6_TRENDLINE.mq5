//+------------------------------------------------------------------+
//| PATCH FOR BƯỚC 6 - Enhanced Trendline Logging in Signal Creation|
//| Replace the section in OnTick() where new pending signals are   |
//| created (around line 1400+)                                      |
//+------------------------------------------------------------------+

// ========================================
// BƯỚC 6: TẠO PENDING SIGNAL MỚI
// ========================================
if(qqeBuySignal)
{
   Print("🔔 PHÁT HIỆN TÍN HIỆU BUY TỪ QQE!");
   Print("   Trạng thái hiện tại: pendingSignal = ", pendingSignal);

   // ✅ KIỂM TRA: NẾU ĐÃ CÓ PENDING CÙNG CHIỀU, BỎ QUA
   if(pendingSignal == 1)
   {
      Print("→ ⚠️ Đã có pending BUY từ trước - KHÔNG GHI ĐÈ");
   }
   else if(waitingConfirmation == 1)
   {
      Print("→ ⚠️ Đang chờ confirmation BUY - BỎ QUA");
   }
   // ✅ NẾU CÓ PENDING NGƯỢC CHIỀU, XỬ LÝ RIÊNG
   else if(pendingSignal == -1)
   {
      Print("→ ⚠️ Có pending SELL, nhưng xuất hiện tín hiệu BUY");
      Print("→ 🔄 XỬ LÝ: Hủy pending SELL, tạo pending BUY mới");
      pendingSignal = 0;  // Reset để tạo mới bên dưới
   }

   // ✅ CHỈ TẠO PENDING MỚI KHI pendingSignal == 0
   if(pendingSignal == 0)
   {
      Print("→ 🔍 Kiểm tra filters...");

      // ✅ KIỂM TRA TRENDLINE FILTER CHO BUY
      bool tlBuyPass = TrendPassRealtime(true);

      if(UseTrendlineFilter)
      {
         Print("   → 🎯 Trendline Filter (BUY): ", tlBuyPass ? "✓ PASS" : "✗ FAIL");
         if(!tlBuyPass)
         {
            Print("      ├─ Reason: Price did not ",
                  TrendMode == TL_BREAKOUT ? "BREAK resistance trendline" :
                  TrendMode == TL_BOUNCE ? "BOUNCE from support trendline" :
                  "satisfy BREAKOUT or BOUNCE conditions");

            // Debug info
            double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
            double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);

            Print("      ├─ Close[1]: ", DoubleToString(close1, _Digits));
            Print("      ├─ Close[0]: ", DoubleToString(close0, _Digits));
            Print("      ├─ Mode: ", TrendMode == TL_BREAKOUT ? "BREAKOUT" :
                                      TrendMode == TL_BOUNCE ? "BOUNCE" : "BOTH");
            Print("      └─ Buffer: ", TrendBufferPoints, " points, Tolerance: ", TouchTolerancePoints, " points");
         }
         else
         {
            Print("      └─ ✓ BUY trendline condition satisfied");
         }
      }

      // Kiểm tra tất cả filters (ADX, RSI, Dead-zone, MA200, etc.)
      bool otherFiltersPass = CheckAllFilterConditions(true);

      if(otherFiltersPass && tlBuyPass)
      {
         if(CanDrawArrowVirt(true) && CanOpenOrder(ORDER_TYPE_BUY))
         {
            pendingSignal = 1;
            Print("→ ✅✅✅ BUY signal chấp nhận, sẽ vẽ mũi tên ở nến tiếp theo");
         }
         else
         {
            Print("→ ❌ BUY signal bị chặn bởi quota/limit");
            Print("      CanDrawArrowVirt: ", CanDrawArrowVirt(true) ? "YES" : "NO");
            Print("      CanOpenOrder: ", CanOpenOrder(ORDER_TYPE_BUY) ? "YES" : "NO");
         }
      }
      else
      {
         if(!tlBuyPass && UseTrendlineFilter)
            Print("→ ❌ BUY bị chặn bởi TRENDLINE FILTER");
         else if(!otherFiltersPass)
            Print("→ ❌ BUY bị chặn bởi FILTERS (ADX/RSI/DeadZone/MA200)");
         else
            Print("→ ❌ Filter KHÔNG PASS cho BUY");
      }
   }
}
else if(qqeSellSignal)
{
   Print("🔔 PHÁT HIỆN TÍN HIỆU SELL TỪ QQE!");
   Print("   Trạng thái hiện tại: pendingSignal = ", pendingSignal);

   // ✅ KIỂM TRA: NẾU ĐÃ CÓ PENDING CÙNG CHIỀU, BỎ QUA
   if(pendingSignal == -1)
   {
      Print("→ ⚠️ Đã có pending SELL từ trước - KHÔNG GHI ĐÈ");
   }
   else if(waitingConfirmation == -1)
   {
      Print("→ ⚠️ Đang chờ confirmation SELL - BỎ QUA");
   }
   // ✅ NẾU CÓ PENDING NGƯỢC CHIỀU, XỬ LÝ RIÊNG
   else if(pendingSignal == 1)
   {
      Print("→ ⚠️ Có pending BUY, nhưng xuất hiện tín hiệu SELL");
      Print("→ 🔄 XỬ LÝ: Hủy pending BUY, tạo pending SELL mới");
      pendingSignal = 0;  // Reset để tạo mới bên dưới
   }

   // ✅ CHỈ TẠO PENDING MỚI KHI pendingSignal == 0
   if(pendingSignal == 0)
   {
      Print("→ 🔍 Kiểm tra filters...");

      // ✅ KIỂM TRA TRENDLINE FILTER CHO SELL
      bool tlSellPass = TrendPassRealtime(false);

      if(UseTrendlineFilter)
      {
         Print("   → 🎯 Trendline Filter (SELL): ", tlSellPass ? "✓ PASS" : "✗ FAIL");
         if(!tlSellPass)
         {
            Print("      ├─ Reason: Price did not ",
                  TrendMode == TL_BREAKOUT ? "BREAK support trendline" :
                  TrendMode == TL_BOUNCE ? "BOUNCE from resistance trendline" :
                  "satisfy BREAKOUT or BOUNCE conditions");

            // Debug info
            double close0 = iClose(_Symbol, PERIOD_CURRENT, 0);
            double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);

            Print("      ├─ Close[1]: ", DoubleToString(close1, _Digits));
            Print("      ├─ Close[0]: ", DoubleToString(close0, _Digits));
            Print("      ├─ Mode: ", TrendMode == TL_BREAKOUT ? "BREAKOUT" :
                                      TrendMode == TL_BOUNCE ? "BOUNCE" : "BOTH");
            Print("      └─ Buffer: ", TrendBufferPoints, " points, Tolerance: ", TouchTolerancePoints, " points");
         }
         else
         {
            Print("      └─ ✓ SELL trendline condition satisfied");
         }
      }

      // Kiểm tra tất cả filters (ADX, RSI, Dead-zone, MA200, etc.)
      bool otherFiltersPass = CheckAllFilterConditions(false);

      if(otherFiltersPass && tlSellPass)
      {
         if(CanDrawArrowVirt(false) && CanOpenOrder(ORDER_TYPE_SELL))
         {
            pendingSignal = -1;
            Print("→ ✅✅✅ SELL signal chấp nhận, sẽ vẽ mũi tên ở nến tiếp theo");
         }
         else
         {
            Print("→ ❌ SELL signal bị chặn bởi quota/limit");
            Print("      CanDrawArrowVirt: ", CanDrawArrowVirt(false) ? "YES" : "NO");
            Print("      CanOpenOrder: ", CanOpenOrder(ORDER_TYPE_SELL) ? "YES" : "NO");
         }
      }
      else
      {
         if(!tlSellPass && UseTrendlineFilter)
            Print("→ ❌ SELL bị chặn bởi TRENDLINE FILTER");
         else if(!otherFiltersPass)
            Print("→ ❌ SELL bị chặn bởi FILTERS (ADX/RSI/DeadZone/MA200)");
         else
            Print("→ ❌ Filter KHÔNG PASS cho SELL");
      }
   }
}
else
{
   Print("Không có tín hiệu QQE mới");
}
