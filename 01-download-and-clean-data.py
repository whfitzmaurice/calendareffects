# student id: 100429635

###############################

from bs4 import BeautifulSoup
import requests
import csv
import pandas as pd
import yfinance as yf
import numpy as np
import os
os.getcwd()

###############################

# generates list of tickers from csv file containing 20 identified firms
firms = pd.read_csv("firms.csv")
tickers = firms['Ticker'].tolist()

# generates historical price data from yfinance grouped by tickers
hist_prices = yf.download(tickers, start="2010-01-01", end="2019-12-31", interval="1d", group_by='ticker') # downloads tickers from list in yfinance in range and groups by tickers
hist_prices = hist_prices.stack(0)
hist_prices.reset_index(level=None, inplace=True)
hist_prices = hist_prices[["level_1", "Date", "Open", "High", "Low", "Close", "Adj Close", "Volume"]] # harmonises column order for later merge

# function to check for nan values
def nan_check():
    if hist_prices.isnull().values.any()==False:
        print("No nans detected!")
        return
    else:
        print("Nans detected!")
nan_check()

# generates market tracker for SP500
market_tracker = yf.download("^GSPC", start="2010-01-01", end="2019-12-31", interval="1d", group_by="ticker")
market_tracker.reset_index(level=None, inplace=True)
market_tracker.insert(0, "Ticker","SP500")

# generates market cap data
# scrapes financials from finviz.com into csv file grouped by tickers
url_base = "https://finviz.com/quote.ashx?t="
url_list = [(i, url_base + i) for i in tickers]

headers = {"User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:76.0) Gecko/20100101 Firefox/76.0"}

with open("marketcaps.csv", 'w', newline='') as f_out:
    writer = csv.writer(f_out, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    for t, url in url_list:
        print(t, url)
        print("Scraping ticker {}".format(t))
        soup = BeautifulSoup(requests.get(url, headers=headers).content, "html.parser")
        writer.writerow([t])
        for row in soup.select(".snapshot-table2 tr"):
            writer.writerow([td.text for td in row.select("td")])

# extracts market caps from csv, assigns to tickers and converts from object to float

finviz_data = pd.read_csv("marketcaps.csv")
finviz_data.reset_index(inplace=True)
finviz_data.set_index("level_0", inplace=True)
marketcaps = finviz_data["level_1"]["Market Cap"].to_frame()
marketcaps.insert(0, "Ticker",tickers)
marketcaps.set_index("Ticker", inplace=True)

# function to check data type of "level_1" as object, if true returns to convert to float
def float_conversion():
    if isinstance(marketcaps["level_1"], object):
        print("Datatype is object - converting to float") # confirms data type as object
        return
    else:
        print("Error with converting to object")
marketcaps["level_1"] = marketcaps.level_1.str.replace("B","").astype(float) # converts to float
float_conversion()

marketcaps.select_dtypes(np.float64).columns
marketcaps["level_1"] = marketcaps["level_1"].mul(1e9) # multiplies to billions of dollars
marketcaps.rename(columns={"level_1" : "marketcap"}, inplace=True)

################################

# merges prices and market cap into long data structure
hist_prices.reset_index(level=None, inplace=True)
hist_prices.rename(columns={"level_1" : "Ticker"}, inplace=True)
hist_prices.drop(["index"], axis=1, inplace=True) 
hist_prices.set_index("Ticker", inplace=True)
hist_prices = hist_prices.merge(marketcaps, left_index=True, right_index=True, how='inner')

# appends tracker on to historical prices
hist_prices.reset_index(level=None, inplace=True) 
hist_prices.rename(columns={"index" : "Ticker"}, inplace=True) # rename columns to append market tracker
prices_final = hist_prices.append(market_tracker) 
prices_final.reset_index(inplace=True)
prices_final.drop(["index"], axis=1, inplace=True) # drops extra index column not required

################################

# function to check data type of "Date" as datetime64, if true converts to string for later conversion to stata date
def date_conversion():
    if pd.api.types.is_datetime64_ns_dtype(prices_final["Date"])==True:
        print("Datatype is datetime64[ns] - converting to string")
        return
    else:
        print("Error with converting date")
prices_final['date_string'] = prices_final.Date.astype(str)
date_conversion()

# function to export prices_final dataframe to stata .dta file
def stata_export():
    data.to_stata("pricesfinal.dta")
    print("Successfully exported to STATA")
    
data = prices_final
stata_export()

#################################



