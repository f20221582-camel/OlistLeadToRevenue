#!/usr/bin/env bash
# Rebuild everything from the raw CSVs in data/ (see data/README.md). Needs: pip install -r requirements.txt
set -euo pipefail
rm -f olist.duckdb
python run_sql.py sql/00_load.sql sql/01_data_quality.sql sql/02_model.sql sql/03_funnel.sql \
                  sql/04_accounts.sql sql/05_cohorts.sql sql/06_reps_and_whales.sql > outputs/_run_log.txt
python analysis/07_stat_tests.py
python analysis/08_sizing.py
python dashboard/build_dashboard.py
echo "done: outputs/*.csv and dashboard/index.html rebuilt"
