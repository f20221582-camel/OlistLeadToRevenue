# Runs the SQL files in order, then builds the dashboard.
import duckdb, os, subprocess

os.makedirs('results', exist_ok=True)
con = duckdb.connect('olist.duckdb')

for path in ['sql/01_load.sql', 'sql/02_checks.sql', 'sql/03_funnel.sql',
             'sql/04_activation.sql', 'sql/05_revenue.sql']:
    text = open(path).read()
    for statement in text.split(';'):
        # skip chunks that contain only comments or blank lines
        lines = [l for l in statement.splitlines() if l.strip() and not l.strip().startswith('--')]
        if lines:
            con.execute(statement)
    print('ran', path)

subprocess.run(['python', 'make_dashboard.py'], check=True)
