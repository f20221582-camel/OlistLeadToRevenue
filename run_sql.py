"""Run a SQL file. Queries tagged '-- name: x' are saved to outputs/x.csv and printed."""
import duckdb, re, sys, pathlib
con = duckdb.connect('olist.duckdb')
pathlib.Path('outputs').mkdir(exist_ok=True)
for path in sys.argv[1:]:
    text = open(path).read()
    parts = re.split(r'^-- name: (\w+)\s*$', text, flags=re.M)
    if len(parts) == 1:
        con.execute(text); print(f'ran {path}'); continue
    con.execute(parts[0]) if parts[0].strip() and not parts[0].strip().startswith('--') else None
    for name, body in zip(parts[1::2], parts[2::2]):
        df = con.execute(body.strip()).fetchdf()
        df.to_csv(f'outputs/{name}.csv', index=False)
        print(f'\n== {name} ==\n{df.to_string(index=False)}')
