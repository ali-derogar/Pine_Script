# Trading Strategies README

This repository contains two trading strategies: one written in Pine Script for TradingView and another in MQL4 for MetaTrader.

## ArminOscillator Strategy (Pine Script)

### Overview

The ArminOscillator Strategy is a Pine Script strategy for TradingView that combines RSI, Stochastic RSI, and a simple moving average (SMA) to generate buy and sell signals. The strategy identifies trends and uses specific conditions to enter and exit trades.

### Features

- **RSI and Stochastic RSI Calculation:** Calculates RSI and Stochastic RSI to identify overbought and oversold conditions.
- **Trend Identification:** Uses SMA to determine the trend (uptrend, downtrend, or sideways).
- **Buy and Sell Signals:** Generates buy and sell signals based on the crossover of Stochastic RSI lines and trend conditions.
- **Stop Loss and Take Profit:** Defines stop loss and take profit levels for trades.

### Input Parameters

- `lengthRSI`: Length for RSI calculation (default: 130).
- `lengthStoch`: Length for Stochastic RSI calculation (default: 9).
- `smoothK`: Smoothing period for %K line (default: 5).
- `smoothD`: Smoothing period for %D line (default: 2).
- `lengthMA`: Length for trend identification using SMA (default: 4).

## MQL4

### Overview

The Request3 Strategy is an MQL4 script for MetaTrader that places buy and sell orders based on signals received from an API. The strategy includes trailing stop functionality and handles multiple positions within a single bar.

### Features

-   `API Integration`: Receives trading signals from an external API.
-   `Multiple Positions`: Allows opening multiple positions within a single bar.
-   `Trailing Stop`: Implements trailing stop functionality for managing risk.
-   `Customizable Parameters`: Allows customization of lot size, slippage, stop loss, and take profit ratio.

### Input Parameters

-    `lotSize` : Size of the lot for each trade (default: 0.05).
-    `slippage`: Maximum slippage allowed (default: 5).
-    `time_frame`: Time frame for the strategy (default: PERIOD_M1).
-    `stopLossPips`: Stop loss in pips (default: 50).
-    `takeProfitRatio`: Take profit ratio relative to stop loss (default: 1).

