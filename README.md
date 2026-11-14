# Lead to revenue: where does the sales funnel leak?

A small SQL project using Olist's public data. Olist sells to online shops (sellers). A lead comes in,
a salesperson works on it, and if it is won the seller starts selling on the marketplace.
I wanted to see where leads are lost along the way, using SQL (DuckDB).

Open `dashboard.html` in a browser to see the charts.

## Data
Two Kaggle datasets by Olist (see `data/README.md`): the Marketing Funnel dataset (8,000 leads, 842 won deals)
and the Brazilian E-Commerce dataset (orders and items). Money is in Brazilian reais (R$).

## What I did
| File | What it does |
|------|--------------|
| `sql/01_load.sql` | loads the CSV files into tables |
| `sql/02_checks.sql` | row counts, duplicate ids, missing values, date ranges |
| `sql/03_funnel.sql` | lead to won deal: win rate overall, by origin, by landing page |
| `sql/04_activation.sql` | after winning, does the seller sell something within 90 days? |
| `sql/05_revenue.sql` | how sales are spread across accounts and lead types |

Every query writes its result to a CSV in `results/`. `make_dashboard.py` turns those CSVs into `dashboard.html`.

## Results
- **11.3%** of leads were won within 90 days (678 of 5,998).
- Of the won accounts, only **43.6%** sold anything within 90 days (286 of 656). So more than half of the deals that were already won do not turn into sales quickly.
- Two landing pages win about **20%** of leads. All other pages win **8.3%**. The third biggest page wins only **4.4%**.
- Social and email leads are **23%** of leads but **10%** of wins (win rates 5.2% and 3.5%, against 12.3% for organic search).
- 14% of leads have no recorded origin, and they have the highest win rate (19.6%). The origin is probably just not being tracked.
- The top 10% of accounts make **65%** of the sales. Lead type `online_big` is 43% of sales and 63% of those accounts start selling, against 25% for `offline`.
- Accounts from paid search start selling more often than organic ones (55.6% vs 40.2%), even though they are won at the same rate.

## Suggestions
1. Work on what happens after a deal is won (first 30 days). Only 111 of 656 accounts sold in their first 30 days. These deals are already won, so I think helping them start is probably cheaper than finding new leads, but I did not measure the cost.
2. Send more traffic to the two landing pages that win about 20%, and look at why the others do worse.
3. Record the origin of every lead.

A rough size of the first one: about 1,200 leads come in per month, so about 136 are won and 59 start selling.
If 55.6% started selling (the paid search rate), that is about 75, so 16 more accounts a month.
An active account sells about R$1,188 in its first 90 days (`results/sales_first_90_days.csv`), so that is about R$19,000 more sales
per month of leads. This is a rough guess. The average is pulled up by a few big sellers, and the 55.6% is only what one group achieved.

## Things to know about the data
- Deals are only recorded from December 2017, so older leads look like they never convert (`results/win_rate_by_month.csv`).
  I only use leads first contacted from January to May 2018.
- The order data thins out at the end of August 2018, so I ignore orders placed on or after 28 August. To give every account a full 90 days
  I only use deals won on or before 29 May 2018 for the activation numbers.
- Only 380 of the 842 deals belong to sellers found in the orders data. "Not selling" can also mean "not in this sample".
- Lead type is only filled in for won deals, so I cannot compare win rates by lead type.
- These are patterns, not proof of cause. I did not run any statistical tests.
- This is Olist data from 2017-2018, not data from a company I worked for.

## How to run
```
pip install duckdb
# put the CSV files in data/ (see data/README.md)
python run.py
```
Data: Olist, CC BY-NC-SA 4.0.
