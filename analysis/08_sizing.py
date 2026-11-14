"""Back-of-envelope sizing of two levers. Measured inputs come from the DuckDB model; the lever targets are ASSUMPTIONS
(clearly labelled) taken from observed gaps, not from experiments. Output: outputs/sizing.csv"""
import duckdb, pandas as pd
con = duckdb.connect('olist.duckdb')
leads, wins = con.execute("""SELECT COUNT(*), SUM((is_won AND days_to_close<=90)::INT) FROM dim_lead
                              WHERE first_contact_date>=DATE '2018-01-01'""").fetchone()
months = 5
acc, act, g90 = con.execute("""
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params)),
g AS (SELECT b.mql_id, (b.activated AND b.days_won_to_first_order<=90) AS act90, COALESCE(SUM(f.price),0) AS gmv90
      FROM base b LEFT JOIN fact_sale_item f ON f.seller_id=b.seller_id AND f.order_date >= b.won_date::DATE
       AND f.order_date <= b.won_date::DATE + 90 GROUP BY 1,2)
SELECT COUNT(*), SUM(act90::INT), SUM(gmv90) FROM g""").fetchone()
lp = con.execute("""SELECT landing_page_id, COUNT(*) n, SUM((is_won AND days_to_close<=90)::INT) k FROM dim_lead
                    WHERE first_contact_date>=DATE '2018-01-01' GROUP BY 1""").fetchdf()
rest = 100*lp.sort_values('n',ascending=False).iloc[2:].k.sum()/lp.sort_values('n',ascending=False).iloc[2:].n.sum()
top2 = lp.sort_values('n',ascending=False).head(2)  # largest pages are not the best; define explicitly below
best2 = lp.assign(r=lp.k/lp.n).query('n>=200').sort_values('r',ascending=False).head(2).landing_page_id.tolist()
rest_rate = lp[~lp.landing_page_id.isin(best2)].k.sum()/lp[~lp.landing_page_id.isin(best2)].n.sum()
low = lp[(lp.n>=100)&(~lp.landing_page_id.isin(best2))&(lp.k/lp.n < rest_rate)]
extra_wins_m = ((rest_rate - low.k/low.n)*low.n).sum()/months
base_leads_m = leads/months; base_win = wins/leads; base_act = act/acc; gpa = g90/act
def row(name, win_rate, act_rate):
    w = base_leads_m*win_rate; a = w*act_rate
    return dict(scenario=name, leads_per_month=round(base_leads_m), win_rate_pct=round(100*win_rate,1), wins_per_month=round(w,1),
                activation90_pct=round(100*act_rate,1), activated_per_month=round(a,1), gmv90_per_active_BRL=round(gpa),
                gmv90_added_per_monthly_cohort_BRL=None)
base = row('Baseline (measured)', base_win, base_act)
s1 = row('A: low landing pages lifted to rest-of-pages rate (assumption)', base_win + extra_wins_m/base_leads_m, base_act)
s2 = row('B: activation 43.6% -> 55.6% (paid-search level; assumption)', base_win, 0.556)
s3 = row('A + B', base_win + extra_wins_m/base_leads_m, 0.556)
out = pd.DataFrame([base,s1,s2,s3])
b = out.activated_per_month.iloc[0]
out['gmv90_added_per_monthly_cohort_BRL'] = ((out.activated_per_month-b)*gpa).round()
out.to_csv('outputs/sizing.csv', index=False)
print(f"leads/month {base_leads_m:.0f}, win90 {base_win:.3%}, activation {base_act:.3%}, GMV90/active {gpa:.0f} (mean; heavily skewed)")
print(f"low pages: {len(low)} pages, {int(low.n.sum())} leads, rest-of-pages rate {rest_rate:.2%}, extra wins/month {extra_wins_m:.1f}")
print(out.to_string(index=False))
