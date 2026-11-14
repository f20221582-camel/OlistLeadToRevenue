# Lead-to-Revenue: where a B2B sales funnel leaks

A SQL analysis (DuckDB) of Olist's public marketing-funnel and marketplace data. Question: **of the leads a sales team
works, where do we lose them, and which fixes are worth the most?** Everything is reproducible from `sql/` with one command.

**Live dashboard:** open `dashboard/index.html` (self-contained, no dependencies, light/dark).
**One-page memo:** [`FINDINGS.md`](FINDINGS.md).

## Headline results (Olist data, 2017-2018, Brazil; currency R$)

| # | Finding | Evidence |
|---|---------|----------|
| 1 | **Activation is the bigger leak than conversion.** 11.3% of leads win within 90 days, but only 43.6% of won accounts make a first sale within 90 days. | 678 of 5,998 leads; 286 of 656 accounts |
| 2 | **Two landing pages convert at ~20%; the rest at 8%; the biggest low page at 4%.** | 301 wins from 1,477 leads vs 8.3% on 4,521 (p<0.001, observational) |
| 3 | **Social and email leads are 23% of leads but ~10% of wins** (5.2% and 3.5% win rate vs 12.3% organic). | 1,398 leads, 67 wins |
| 4 | **Revenue is extremely concentrated:** top 10% of active accounts = 65% of GMV; one lead type ("online_big") = 43% of GMV and activates at 63% vs 25% for offline. | 379 active accounts, R$673k GMV |
| 5 | **Attribution gap:** 14% of leads have no recorded origin and have the *best* win rate (19.6%), so channel analysis is incomplete until origin is instrumented. | 861 leads |

## Method in brief

1. `00_load` / `01_data_quality`: load 6 CSVs, run integrity checks (keys, orphans, date ranges, join coverage).
2. `02_model`: `dim_lead`, `fact_sale_item`, `fact_account` views and a `params` table (data end date, 90-day observability cutoff).
3. `03_funnel` ... `06_reps_and_whales`: funnel, channel, landing page, activation, cohort and concentration queries
   (CTEs, window functions, `NTILE`, `FILTER`, `DATE_DIFF`). Each query is tagged `-- name: x` and written to `outputs/x.csv`.
4. `analysis/07_stat_tests.py`: Wilson 95% intervals and chi-square / Fisher tests for the comparisons quoted.
5. `analysis/08_sizing.py`: back-of-envelope value of two levers (assumption-labelled).
6. `dashboard/build_dashboard.py`: builds `dashboard/index.html` from `outputs/`.

### Definitions
- **Valid sale:** order status not `canceled` / `unavailable`. **GMV:** sum of item price (freight excluded), in R$.
- **Won within 90 days:** closed-deal date within 90 days of first contact. **Activated:** first valid sale within 90 days of the win.
- **Data end:** order volume collapses after 2018-08-28, so that is the effective end (found from daily counts, not the file's last date).

### Data traps found and handled (this is where most of the work was)
- **Left truncation:** closed deals are only recorded from 2017-12-05, so earlier leads look like they never convert (0-6% "win rate"). All conversion metrics use leads first contacted **Jan-May 2018** with a 90-day window.
- **Right censoring:** accounts won in the last 90 days cannot be judged on 90-day activation, so they are excluded via an explicit cutoff.
- **Segments, lead types and reps exist only on won deals:** win rates by segment or rep are impossible; only post-win quality can be compared. Stated, not hidden.
- **Sample coverage:** only 380 of 842 closed-deal sellers appear in the orders file, so "not activated" means *not observed* (a lower bound).

## Limitations
- Associations, not causes: channel, page and lead-type gaps are observational. A test (e.g. page swap) is needed to claim impact.
- The SDR comparison is exploratory (one of 32 SDRs; does not survive a multiple-comparison correction).
- 90-day GMV per active account is heavily skewed (mean R$1,188, median R$327); sizing uses the mean and is therefore optimistic.
- This is Olist data, not any other company's. The value is the method.

## Run it
```bash
pip install -r requirements.txt
# put the Kaggle CSVs in data/ (see data/README.md)
./run_all.sh          # ~5 seconds; rebuilds olist.duckdb, outputs/*.csv, dashboard/index.html
```
Explore interactively: `python -c "import duckdb; duckdb.connect('olist.duckdb').sql('SELECT * FROM fact_account LIMIT 5').show()"`

## Repo layout
```
sql/        numbered SQL files (load, quality checks, model, analyses)
analysis/   stats tests and sizing (Python)
outputs/    CSV result of every named query
dashboard/  build script + generated index.html
data/       raw CSVs go here (not committed)
```

Data: Olist, CC BY-NC-SA 4.0 (Kaggle `olistbr`). Code in this repo is original work.
