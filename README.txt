The purpose of the project is to examine 10 years of daily returns for 20 firms to ascertain the existence of month effects.
The project uses a python script to download, clean, and assemble the dataset and STATA to perform analysis and generate visualisations.

The project folder contains:
	the downloading and cleaning python script
	analysis and visualisation .do file
	.csv file containing firm raw data
	analysis report in .pdf format
	requirements .txt file detailing library versions  

To reproduce:
	Open 01-download-and-clean-data.py in an IDE (you may have to set line 12 to the project folder as the current working directory)
	Run the entire script, which will install necessary libraries, retrieve returns from yfinance, scrape market caps from finviz.com and assemble into a dataset "pricesfinal.dta"
	Open 02-generate-visualisations-and-regressions.do in STATA 17
	Run the entire .do file, which will generate 3 graphs and 3 regression output tables
	