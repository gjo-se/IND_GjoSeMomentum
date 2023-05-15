/*

   IND_GjoSeMomentum.mq5
   Copyright 2021, Gregory Jo
   https://www.gjo-se.com

   Version History
   ===============

   1.0.0 Initial version

   ===============

//*/

#include <Mql5Book\Price.mqh>
#include <GjoSe\\Objects\\InclVLine.mqh>
#include <GjoSe\\Objects\\InclArrowBuy.mqh>
#include <GjoSe\\Objects\\InclArrowSell.mqh>

#property   copyright   "2021, GjoSe"
#property   link        "http://www.gjo-se.com"
#property   description "GjoSe Momentum"
#define     VERSION "1.0.0"
#property   version VERSION
#property   strict

#property indicator_separate_window

#property indicator_buffers   2
#property indicator_plots     1

#property indicator_label1  "Momentum"
#property indicator_type1   DRAW_HISTOGRAM2
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

input double InpMinMomentum = 20;

double   BuyMomentumBuffer[];
double   SellMomentumBuffer[];
datetime lastBarTime = 0;

double   buyMomentum = 0;
double   buyMomentumTmp = 0;
double   lowestLowM1Value = 100 / Point();
double   lowestLowM1ValueTmp = 0;
int      lowestLowTime = 0;
bool     momentumIsHigherMINMomentumBuyInSignalIsTriggert = false;

double   sellMomentum = 0;
double   sellMomentumTmp = 0;
double   highestHighM1Value = 0;
double   highestHighM1ValueTmp = 0;
int      highestHighTime = 0;
bool     momentumIsHigherMINMomentumSellInSignalIsTriggert = false;

const int    LOWEST_LOW_DEFAULT_VALUE = 100 / Point();
const int    HIGHEST_HIGH_DEFAULT_VALUE = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit() {
   SetIndexBuffer(0, BuyMomentumBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SellMomentumBuffer, INDICATOR_DATA);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, 20);

   IndicatorSetDouble(INDICATOR_MINIMUM, -50);
   IndicatorSetDouble(INDICATOR_MAXIMUM, 50);
   IndicatorSetInteger(INDICATOR_LEVELS, 4);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR, clrRed);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_SOLID);
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, 20);
   IndicatorSetString(INDICATOR_LEVELTEXT, 0, "20 Punkte/Sekunde");
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, 40);
   IndicatorSetString(INDICATOR_LEVELTEXT, 1, "40 Punkte /Sekunde");
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, -20);
   IndicatorSetString(INDICATOR_LEVELTEXT, 2, "20 Punkte / Sekunde");
   IndicatorSetDouble(INDICATOR_LEVELVALUE, 3, -40);
   IndicatorSetString(INDICATOR_LEVELTEXT, 3, "40 Punkte /Periode");

   string short_name = "Momentum";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int pRatesTotal,
                const int pPrevCalculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]         ) {

   int      start, i;

   int      currentTime = 0;
   double   currentValue = 0;
   int      secondsSinceLowestLow = 0;
   int      secondsSinceHighestHigh = 0;


   string   lineText = "";

   if(pPrevCalculated == 0) {
      start = 0;
   } else {
      start = pPrevCalculated - 1;
   }

   for(i = start; i < pRatesTotal && !IsStopped(); i++) {

      currentTime = (int)TimeCurrent();
      currentValue = Bid() / Point();

      // buyDynamic
      lowestLowM1ValueTmp = iLow(Symbol(), PERIOD_M1, 0) / Point();

      if(lowestLowM1Value > lowestLowM1ValueTmp) {
         lowestLowM1Value = lowestLowM1ValueTmp;
         lowestLowTime = (int)TimeCurrent();
      }

      secondsSinceLowestLow = currentTime - lowestLowTime;
      if(secondsSinceLowestLow > 0) {
         buyMomentumTmp = (currentValue - lowestLowM1Value) / secondsSinceLowestLow;

         if(buyMomentumTmp > buyMomentum) {
            buyMomentum = buyMomentumTmp;
         }
      }

      if(buyMomentum > 0) {
         BuyMomentumBuffer[i] = buyMomentum;

         if(buyMomentum > InpMinMomentum) {
            if(momentumIsHigherMINMomentumBuyInSignalIsTriggert == false) {
               lineText = TimeToString(TimeCurrent(), TIME_SECONDS) + " // " + DoubleToString(buyMomentum, 2);
               createVLine("buyDynamic" + TimeToString(TimeCurrent()), time[i], clrGreen, 1, STYLE_DASH, lineText);
               createArrowBuy("buyArrow" + __FUNCTION__ + TimeToString(TimeCurrent(), TIME_SECONDS));
               momentumIsHigherMINMomentumBuyInSignalIsTriggert = true;
            }
         }
      }

      // sellDynamic
      highestHighM1ValueTmp = iHigh(Symbol(), PERIOD_M1, 0) / Point();

      if(highestHighM1Value < highestHighM1ValueTmp) {
         highestHighM1Value = highestHighM1ValueTmp;
         highestHighTime = (int)TimeCurrent();
      }

      secondsSinceHighestHigh = currentTime - highestHighTime;
      if(secondsSinceHighestHigh > 0) {
         sellMomentumTmp = (currentValue - highestHighM1Value) / secondsSinceHighestHigh;

         if(sellMomentumTmp < sellMomentum) {
            sellMomentum = sellMomentumTmp;
         }
      }

      if(sellMomentum < 0) {
         SellMomentumBuffer[i] = sellMomentum;

         if(sellMomentum < InpMinMomentum * -1) {
            if(momentumIsHigherMINMomentumSellInSignalIsTriggert == false) {
               lineText = TimeToString(TimeCurrent(), TIME_SECONDS) + " // " + DoubleToString(sellMomentum, 2);
               createVLine("sellDynamic" + TimeToString(TimeCurrent()), time[i], clrRed, 1, STYLE_DASH, lineText);
               createArrowSell("sellArrow" + __FUNCTION__ + TimeToString(TimeCurrent(), TIME_SECONDS));
               momentumIsHigherMINMomentumSellInSignalIsTriggert = true;
            }
         }
      }

      if(NewBar() == true) {

         lowestLowM1Value = LOWEST_LOW_DEFAULT_VALUE;
         buyMomentum = 0;
         buyMomentumTmp = 0;
         momentumIsHigherMINMomentumBuyInSignalIsTriggert = false;

         highestHighM1Value = HIGHEST_HIGH_DEFAULT_VALUE;
         sellMomentum = 0;
         sellMomentumTmp = 0;
         momentumIsHigherMINMomentumSellInSignalIsTriggert = false;
      }
   }

   return(pRatesTotal);
}
//+------------------------------------------------------------------+

bool  NewBar() {

   datetime currentTime =  iTime(Symbol(), Period(), 0);
   bool     result      =  (currentTime != lastBarTime);
   lastBarTime   =   currentTime;

   return(result);

}
//+------------------------------------------------------------------+
