"""Significance tests + confidence intervals. Counts come from the DuckDB model (same definitions as the SQL).
Tests are OBSERVATIONAL comparisons (no randomisation) - they tell us a gap is unlikely to be noise,
not that the channel/page/rep caused it."""
import duckdb, pandas as pd, math
from scipy.stats import chi2_contingency, fisher_exact
con = duckdb.connect('olist.duckdb')

def wilson(k, n, z=1.96):
    p = k/n; d = 1+z*z/n
    c = (p + z*z/(2*n))/d; h = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n))/d
    return c-h, c+h

rows = []
def compare(label, k1, n1, k2, n2, exact=False):
    t = [[k1, n1-k1], [k2, n2-k2]]
    p = fisher_exact(t)[1] if exact else chi2_contingency(t, correction=False)[1]
    l1,u1 = wilson(k1,n1); l2,u2 = wilson(k2,n2)
    rows.append(dict(comparison=label, group_a_rate_pct=round(100*k1/n1,1), group_a_n=n1,
                     group_a_ci95=f"{100*l1:.1f}-{100*u1:.1f}", group_b_rate_pct=round(100*k2/n2,1), group_b_n=n2,
                     group_b_ci95=f"{100*l2:.1f}-{100*u2:.1f}", p_value=float(f"{p:.2g}"), test='Fisher' if exact else 'chi-square'))

# --- lead -> won within 90d (Jan-May 2018 leads)
w = con.execute("""SELECT origin, COUNT(*) n, SUM((is_won AND days_to_close<=90)::INT) k FROM dim_lead
                   WHERE first_contact_date>=DATE '2018-01-01' GROUP BY 1""").fetchdf().set_index('origin')
def o(a): return int(w.loc[a,'k']), int(w.loc[a,'n'])
compare('Win<=90d: organic_search vs paid_search', *o('organic_search'), *o('paid_search'))
compare('Win<=90d: organic_search vs social', *o('organic_search'), *o('social'))
compare('Win<=90d: organic_search vs email', *o('organic_search'), *o('email'))
compare('Win<=90d: organic_search vs unknown(origin)', *o('organic_search'), *o('unknown'))
lp = con.execute("""SELECT landing_page_id, COUNT(*) n, SUM((is_won AND days_to_close<=90)::INT) k FROM dim_lead
                    WHERE first_contact_date>=DATE '2018-01-01' GROUP BY 1""").fetchdf()
top = ['b76ef37428e6799c421989521c0e5077','22c29808c4f815213303f8933030604c']
a = lp[lp.landing_page_id.isin(top)]; b = lp[~lp.landing_page_id.isin(top)]
compare('Win<=90d: top-2 landing pages vs all other pages', int(a.k.sum()), int(a.n.sum()), int(b.k.sum()), int(b.n.sum()))
big = lp[lp.landing_page_id=='58326e62183c14b0c03085c33b9fdc44'].iloc[0]
compare('Win<=90d: largest low page (58326e..) vs top-2 pages', int(big.k), int(big.n), int(a.k.sum()), int(a.n.sum()))

# --- activation within 90d (accounts won on/before 2018-05-29)
base = "SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params)"
def act(where_a, where_b):
    q = lambda wh: con.execute(f"SELECT COUNT(*) n, SUM((activated AND days_won_to_first_order<=90)::INT) k FROM ({base}) WHERE {wh}").fetchone()
    na,ka = q(where_a); nb,kb = q(where_b); return int(ka),int(na),int(kb),int(nb)
compare('Activated<=90d: paid_search vs organic_search', *act("origin='paid_search'","origin='organic_search'"))
compare('Activated<=90d: online_big vs all other lead types', *act("lead_type='online_big'","lead_type<>'online_big'"))
compare('Activated<=90d: offline vs all other lead types', *act("lead_type='offline'","lead_type<>'offline'"))

# --- SDR check: lowest-activation large SDR vs all other SDRs (32 SDRs -> multiple comparisons; Bonferroni noted)
sdr = '56bf83c4bb35763a51c2baab501b4c67'
compare('Activated<=90d: SDR 56bf83.. vs all other SDRs (exploratory, 32 SDRs)', *act(f"sdr_id='{sdr}'", f"sdr_id<>'{sdr}'"), exact=True)

df = pd.DataFrame(rows); df.to_csv('outputs/stat_tests.csv', index=False)
print(df.to_string(index=False))
# sizing inputs
print(con.execute("""
WITH base AS (SELECT * FROM fact_account WHERE won_date::DATE <= (SELECT obs90_cutoff FROM params)),
g AS (SELECT b.mql_id, b.activated AND b.days_won_to_first_order<=90 AS act90, COALESCE(SUM(f.price),0) gmv90
      FROM base b LEFT JOIN fact_sale_item f ON f.seller_id=b.seller_id AND f.order_date>=b.won_date::DATE AND f.order_date<=b.won_date::DATE+90
      GROUP BY 1,2)
SELECT COUNT(*) won_accounts, SUM(act90::INT) activated90, ROUND(SUM(gmv90),0) gmv90_total, ROUND(AVG(gmv90),1) gmv90_per_won,
       ROUND(AVG(gmv90) FILTER (WHERE gmv90>0),1) gmv90_per_active, ROUND(MEDIAN(gmv90) FILTER (WHERE gmv90>0),1) median_gmv90_active
FROM g""").fetchdf().to_string(index=False))
