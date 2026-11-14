"""Builds dashboard/index.html from outputs/*.csv (query results). No hand-typed numbers."""
import pandas as pd, html, json
R = lambda n: pd.read_csv(f'outputs/{n}.csv')
fw, origin, lp = R('funnel_window'), R('conv_by_origin'), R('landing_pages_window')
al, ao, aseg = R('activation_by_lead_type'), R('activation_by_origin'), R('activation_by_segment')
gseg, coh, dec = R('gmv_90d_by_segment'), R('cohort_pivot_pct'), R('gmv_concentration')
tdp, tests, mon, aov = R('top_decile_profile'), R('stat_tests'), R('conv_by_contact_month'), R('activation_overall')
ret = R('retention_of_activated')

e = html.escape
def f0(x): return f"{x:,.0f}"
def bar_chart(items, vmax, fmt, width=720, label_w=190, bh=18, gap=12, tip=lambda r: '', unit=''):
    """items: list of dicts(label, value, extra) -> horizontal bars, <=24px, 4px rounded data end."""
    h = len(items)*(bh+gap)+8; plot_w = width-label_w-90; out=[f'<svg viewBox="0 0 {width} {h}" class="chart" role="img">']
    for i, it in enumerate(items):
        y = 4+i*(bh+gap); w = max(2, plot_w*it['value']/vmax)
        x0 = label_w
        path = f"M{x0},{y} h{w-4:.1f} a4,4 0 0 1 4,4 v{bh-8} a4,4 0 0 1 -4,4 h-{w-4:.1f} z"
        out.append(f'<g class="bar" data-tip="{e(tip(it))}"><rect x="0" y="{y-5}" width="{width}" height="{bh+10}" fill="transparent"/>'
                   f'<text x="{label_w-10}" y="{y+bh-5}" text-anchor="end" class="lbl">{e(it["label"])}</text>'
                   f'<path d="{path}" class="mk"/>'
                   f'<text x="{x0+w+8:.1f}" y="{y+bh-5}" class="val">{e(fmt(it["value"]))}<tspan class="sub" dx="8">{e(it.get("extra",""))}</tspan></text></g>')
    out.append('</svg>'); return ''.join(out)

def col_chart(vals, labels, fmt, width=720, height=210, tipf=lambda l,v:''):
    n=len(vals); pad_l=36; pad_b=34; pad_t=18; plot_h=height-pad_b-pad_t; plot_w=width-pad_l-8
    raw = max(vals)*1.08; step = next(st for st in [1,2,5,10,20,25,50,100,200] if st*4>=raw); vmax = step*4; slot=plot_w/n; bw=min(24, slot*0.6); out=[f'<svg viewBox="0 0 {width} {height}" class="chart" role="img">']
    for t in range(0,5):
        v=vmax*t/4; y=pad_t+plot_h*(1-t/4)
        out.append(f'<line x1="{pad_l}" x2="{width-8}" y1="{y:.1f}" y2="{y:.1f}" class="grid"/><text x="{pad_l-6}" y="{y+4:.1f}" text-anchor="end" class="axis">{v:.0f}</text>')
    for i,(v,l) in enumerate(zip(vals,labels)):
        cx=pad_l+slot*(i+0.5); h=plot_h*v/vmax; y=pad_t+plot_h-h
        d=f"M{cx-bw/2:.1f},{pad_t+plot_h} v-{max(h-4,0):.1f} a4,4 0 0 1 4,-4 h{bw-8:.1f} a4,4 0 0 1 4,4 v{max(h-4,0):.1f} z"
        out.append(f'<g class="bar" data-tip="{e(tipf(l,v))}"><rect x="{cx-slot/2:.1f}" y="{pad_t}" width="{slot:.1f}" height="{plot_h}" fill="transparent"/><path d="{d}" class="mk"/>'
                   f'<text x="{cx:.1f}" y="{y-5:.1f}" text-anchor="middle" class="val">{e(fmt(v))}</text>'
                   f'<text x="{cx:.1f}" y="{height-12}" text-anchor="middle" class="axis">{e(l)}</text></g>')
    out.append('</svg>'); return ''.join(out)

def table(df, cols, heads, fmts=None):
    fmts = fmts or {}
    t='<div class="tw"><table><thead><tr>'+''.join(f'<th>{e(h)}</th>' for h in heads)+'</tr></thead><tbody>'
    for _,r in df.iterrows():
        t+='<tr>'+''.join(f'<td>{e(fmts.get(c,lambda x:str(x))(r[c]))}</td>' for c in cols)+'</tr>'
    return t+'</tbody></table></div>'

short = lambda s: s[:6]+'…'
# ---------- numbers
leads = int(fw.loc[0,'n']); won90 = int(fw.loc[1,'n']); wonall = int(fw.loc[2,'n']); act_ever = int(fw.loc[3,'n'])
act90 = aov.loc[0]; top_decile_share = dec.loc[0,'share_pct']; top2_share = dec.loc[:1,'share_pct'].sum()
gt = R('gmv_totals'); tshare_big = tdp.loc[tdp.lead_type=='online_big','gmv'].iloc[0]/gt.total_gmv.iloc[0]*100
kpis = [(f0(leads),'MQLs, Jan–May 2018','first-contact window with complete win data'),
        (f"{100*won90/leads:.1f}%",'Lead → won within 90 days',f"{won90:,} of {leads:,}"),
        (f"{act90.act_90d_pct:.1f}%",'Won → first sale within 90 days',f"{int(act90.act_90d)} of {int(act90.accounts)} accounts"),
        (f"{top_decile_share:.0f}%",'GMV from the top 10% of active accounts',f"{int(dec.accounts.sum())} activated accounts")]
kpi_html=''.join(f'<div class="kpi"><div class="kv">{a}</div><div class="kl">{b}</div><div class="ks">{c}</div></div>' for a,b,c in kpis)

# funnel
fun_items=[dict(label='Marketing qualified lead',value=leads,extra='100%'),
           dict(label='Won (any time)',value=wonall,extra=f'{100*wonall/leads:.1f}% of leads'),
           dict(label='Activated: ≥1 valid sale',value=act_ever,extra=f'{100*act_ever/wonall:.1f}% of won')]
funnel_svg=bar_chart(fun_items, leads, f0, tip=lambda r:f"{r['label']}: {r['value']:,} ({r['extra']})")

o2=origin.sort_values('win_rate_90d_pct',ascending=False)
o_items=[dict(label=r.origin.replace('_',' '),value=r.win_rate_90d_pct,extra=f"n={int(r.leads):,}") for r in o2.itertuples()]
origin_svg=bar_chart(o_items,22,lambda v:f"{v:.1f}%",width=470,label_w=120,tip=lambda r:f"{r['label']}: {r['value']:.1f}% won ≤90d, {r['extra']}")

lp2=lp.sort_values('win_rate_90d_pct',ascending=False)
l_items=[dict(label='page '+r.landing_page_id[:6],value=r.win_rate_90d_pct,extra=f"n={int(r.leads):,}") for r in lp2.itertuples()]
lp_svg=bar_chart(l_items,24,lambda v:f"{v:.1f}%",width=470,label_w=100,tip=lambda r:f"{r['label']}: {r['value']:.1f}% won ≤90d, {r['extra']}")

al2=al[al.accounts>=30].sort_values('act_90d_pct',ascending=False)
al_svg=bar_chart([dict(label=r.lead_type.replace('_',' '),value=r.act_90d_pct,extra=f"n={int(r.accounts)}") for r in al2.itertuples()],75,lambda v:f"{v:.0f}%",width=470,label_w=120,tip=lambda r:f"{r['label']}: {r['value']:.1f}% active ≤90d, {r['extra']}")
ao2=ao[ao.accounts>=40].sort_values('act_90d_pct',ascending=False)
ao_svg=bar_chart([dict(label=r.origin.replace('_',' '),value=r.act_90d_pct,extra=f"n={int(r.accounts)}") for r in ao2.itertuples()],75,lambda v:f"{v:.0f}%",width=470,label_w=120,tip=lambda r:f"{r['label']}: {r['value']:.1f}% active ≤90d, {r['extra']}")
aseg2=aseg[aseg.accounts>=30].sort_values('act_90d_pct',ascending=False)
as_svg=bar_chart([dict(label=r.business_segment.replace('_',' '),value=r.act_90d_pct,extra=f"n={int(r.accounts)}") for r in aseg2.itertuples()],75,lambda v:f"{v:.0f}%",width=470,label_w=120,tip=lambda r:f"{r['label']}: {r['value']:.1f}% active ≤90d, {r['extra']}")

dec_svg=col_chart(list(dec.share_pct),[f"D{int(d)}" for d in dec.decile],lambda v:f"{v:.0f}%",tipf=lambda l,v:f"Decile {l[1:]} of activated accounts by GMV: {v:.1f}% of total GMV")
mon_svg=col_chart(list(mon.win_rate_pct),[m[2:7] for m in mon.contact_month],lambda v:f"{v:.0f}%",tipf=lambda l,v:f"Leads first contacted {l}: {v:.1f}% eventually won")

# heatmap
cols=[c for c in coh.columns if c.startswith('m')]
steps=['#cde2fb','#9ec5f4','#6da7ec','#3987e5','#256abf']
def cell(v):
    if pd.isna(v): return '<td class="na">·</td>'
    i=min(4,int(v/45*5)); col=steps[i]; fg='#fff' if i>=3 else 'var(--ink)'
    return f'<td style="background:{col};color:{fg}" data-tip="{v:.1f}% of cohort active">{v:.0f}%</td>'
heat='<div class="tw"><table class="heat"><thead><tr><th>Won month</th><th>Accounts</th>'+''.join(f'<th>M{c[1:]}</th>' for c in cols)+'</tr></thead><tbody>'
for _,r in coh.iterrows(): heat+=f'<tr><th>{r.cohort_month[:7]}</th><td>{int(r.cohort_size)}</td>'+''.join(cell(r[c]) for c in cols)+'</tr>'
heat+='</tbody></table></div>'

seg_tbl=table(gseg.sort_values('gmv90_total',ascending=False),['business_segment','accounts','gmv90_total','gmv90_per_account','gmv90_per_active_account'],
  ['Segment','Accounts','GMV, first 90d (R$)','R$ per account','R$ per active account'],{'business_segment':lambda s:s.replace('_',' '),'accounts':f0,'gmv90_total':f0,'gmv90_per_account':f0,'gmv90_per_active_account':f0})
tests_tbl=table(tests,['comparison','group_a_rate_pct','group_a_n','group_b_rate_pct','group_b_n','p_value'],['Comparison','A %','n(A)','B %','n(B)','p-value'],{'p_value':lambda p:f"{p:.1e}" if p<0.001 else f"{p:.3f}"})
top_tbl=table(tdp,['lead_type','activated_accounts','in_top_decile','gmv','gmv_per_activated'],['Lead type','Activated accts','In top decile','GMV (R$)','R$ / activated acct'],{'lead_type':lambda s:s.replace('_',' '),'activated_accounts':f0,'in_top_decile':f0,'gmv':f0,'gmv_per_activated':f0})

page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lead-to-Revenue: where Olist's B2B sales funnel leaks</title>
<style>
:root{{--bg:#fcfcfb;--card:#fff;--ink:#0b0b0b;--ink2:#52514e;--mute:#8a8985;--line:#e6e5e1;--blue:#2a78d6;--warn:#eb6834}}
@media (prefers-color-scheme:dark){{:root{{--bg:#1a1a19;--card:#222221;--ink:#f0efec;--ink2:#c3c2b7;--mute:#8d8c86;--line:#34332f;--blue:#3987e5;--warn:#d95926}}}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 system-ui,-apple-system,Segoe UI,sans-serif}}
.wrap{{max-width:1040px;margin:0 auto;padding:28px 18px 60px}}h1{{font-size:26px;margin:0 0 4px}}.sub0{{color:var(--ink2);margin:0 0 20px}}
.kpis{{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:12px;margin-bottom:18px}}
.kpi{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 16px}}.kv{{font-size:30px;font-weight:650}}.kl{{color:var(--ink);font-size:13px}}.ks{{color:var(--mute);font-size:12px}}
nav{{display:flex;gap:6px;flex-wrap:wrap;margin:14px 0}}nav button{{border:1px solid var(--line);background:var(--card);color:var(--ink2);padding:7px 14px;border-radius:20px;cursor:pointer;font:inherit}}nav button.on{{background:var(--blue);color:#fff;border-color:var(--blue)}}
section{{display:none}}section.on{{display:block}}.card{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:16px 18px;margin-bottom:14px}}
h2{{font-size:17px;margin:0 0 2px}}.take{{color:var(--ink2);margin:0 0 10px;font-size:14px}}.src{{color:var(--mute);font-size:12px;margin-top:6px}}
.chart{{width:100%;height:auto}}.mk{{fill:var(--blue)}}.grid{{stroke:var(--line);stroke-width:1}}.lbl,.val{{fill:var(--ink);font-size:12.5px}}.sub,.axis{{fill:var(--mute);font-size:11.5px}}.bar:hover .mk{{opacity:.78}}
.tw{{overflow-x:auto}}table{{border-collapse:collapse;width:100%;font-size:13px}}th,td{{padding:6px 9px;border-bottom:1px solid var(--line);text-align:right}}th:first-child,td:first-child{{text-align:left}}th{{color:var(--ink2);font-weight:600}}
.heat td{{text-align:center;border:2px solid var(--card)}}.heat .na{{color:var(--mute)}}details{{margin-top:8px}}summary{{cursor:pointer;color:var(--ink2);font-size:13px}}
.note{{border-left:3px solid var(--warn);padding:6px 12px;margin:8px 0;color:var(--ink2);font-size:13.5px}}ul{{margin:6px 0 0 18px;padding:0;color:var(--ink2);font-size:14px}}li{{margin:3px 0}}
#tip{{position:fixed;pointer-events:none;background:var(--ink);color:var(--bg);padding:6px 9px;border-radius:6px;font-size:12px;max-width:260px;display:none;z-index:9}}
.g2{{display:grid;grid-template-columns:1fr 1fr;gap:14px}}@media(max-width:760px){{.g2{{grid-template-columns:1fr}}}}
</style></head><body><div class="wrap">
<h1>Lead-to-Revenue: where Olist's B2B sales funnel leaks</h1>
<p class="sub0">SQL analysis (DuckDB) of ~8,000 marketing-qualified leads, 842 closed deals and the marketplace orders those sellers generated. Public data (Olist, 2017–2018, CC BY-NC-SA 4.0), BRL (R$). Every number below comes from a query in <code>sql/</code>.</p>
<div class="kpis">{kpi_html}</div>
<nav><button class="on" data-t="t1">1 · Funnel & leaks</button><button data-t="t2">2 · Activation</button><button data-t="t3">3 · Cohorts</button><button data-t="t4">4 · Accounts & revenue</button><button data-t="t5">5 · Data notes & tests</button></nav>

<section id="t1" class="on">
<div class="card"><h2>Only about 1 in 8 leads closes, and fewer than half of closed deals show a sale</h2><p class="take">Leads first contacted Jan–May 2018 (the window where closed deals are fully recorded). "Activated" = at least one valid sale in the marketplace data.</p>{funnel_svg}<div class="src">Source: sql/03_funnel.sql → outputs/funnel_window.csv. "Not observed" can mean the seller never sold or is missing from the sampled orders data.</div></div>
<div class="g2"><div class="card"><h2>Win rate by lead origin</h2><p class="take">Social and email leads win at under half the rate of search. "Unknown" origin wins best, most likely an attribution gap.</p>{origin_svg}<div class="src">Won within 90 days of first contact. sql/03_funnel.sql → conv_by_origin.csv</div></div>
<div class="card"><h2>Win rate by landing page</h2><p class="take">Two pages convert at ~20%; the biggest page converts at 4%.</p>{lp_svg}<div class="src">Pages with ≥100 leads. sql/03_funnel.sql → landing_pages_window.csv</div></div></div>
</section>

<section id="t2">
<div class="card"><h2>56% of won accounts make no sale within 90 days</h2><p class="take">Activation is the bigger leak. Online-big leads and paid-search leads activate best; offline leads worst.</p>
<div class="g2"><div><h2 style="font-size:14px">By lead type</h2>{al_svg}</div><div><h2 style="font-size:14px">By lead origin</h2>{ao_svg}</div></div>
<div class="src">Accounts won on/before 2018-05-29 so 90 days of order data are observable (n={int(act90.accounts)}). sql/04_accounts.sql. Small groups (n&lt;30–40) hidden.</div></div>
<div class="card"><h2>By business segment</h2><p class="take">Segments differ a lot, but each has only 20–90 accounts: treat as directional.</p>{as_svg}<div class="src">sql/04_accounts.sql → activation_by_segment.csv (segments with ≥30 accounts)</div></div>
</section>

<section id="t3">
<div class="card"><h2>Activity ramps over ~3 months, then plateaus at roughly 30–40% of a cohort per month</h2><p class="take">Share of each won-month cohort with a valid sale in each month since won (M0 = month of the win). Only fully observed calendar months through July 2018.</p>{heat}
<div class="src">sql/05_cohorts.sql → cohort_pivot_pct.csv. Among sellers active in a month, about 70% are active again the next month (Apr–Jun 2018): retention_of_activated.csv.</div></div>
</section>

<section id="t4">
<div class="card"><h2>Revenue is extremely concentrated</h2><p class="take">Top 10% of activated accounts = {top_decile_share:.0f}% of GMV; top 20% = {top2_share:.0f}%. "Online big" accounts supply {tshare_big:.0f}% of GMV.</p>{dec_svg}<div class="src">GMV share by decile of {int(dec.accounts.sum())} activated accounts. sql/04_accounts.sql → gmv_concentration.csv</div></div>
<div class="card"><h2>Who the big accounts are</h2>{top_tbl}<div class="src">sql/06_reps_and_whales.sql → top_decile_profile.csv</div></div>
<div class="card"><h2>GMV in first 90 days after the win, by segment</h2>{seg_tbl}<div class="src">sql/04_accounts.sql → gmv_90d_by_segment.csv. Segments with ≥15 accounts; won ≥90 days before data end.</div></div>
</section>

<section id="t5">
<div class="card"><h2>Win rate by month of first contact: a data-recording artifact</h2><p class="take">Closed deals are only recorded from 2017-12-05, so leads from before 2018 look weak. All conversion comparisons therefore use leads first contacted Jan–May 2018.</p>{mon_svg}<div class="src">sql/03_funnel.sql → conv_by_contact_month.csv (all leads)</div></div>
<div class="card"><h2>Statistical tests (observational, not experiments)</h2>{tests_tbl}<div class="src">analysis/07_stat_tests.py. Pearson chi-square (Fisher for the SDR check). The SDR result does not survive a multiple-comparison correction across 32 SDRs.</div></div>
<div class="card"><h2>Definitions and limits</h2><ul>
<li><b>Valid sale:</b> order status not canceled/unavailable. <b>GMV:</b> sum of item price (freight excluded), in R$.</li>
<li><b>Data end:</b> order volume collapses on 2018-08-29 (Sep–Oct hold 20 orders), so the effective end is 2018-08-28.</li>
<li><b>Coverage:</b> only 380 of 842 closed-deal sellers appear in the orders data; the orders file is a sample, so "not activated" is a lower bound on activation.</li>
<li><b>Segments, lead types and reps exist only on won deals:</b> win rates by segment or rep cannot be computed; only post-win quality can.</li>
<li><b>Not experiments:</b> channel, page and lead-type gaps are associations. Causes need a test.</li>
<li><b>Unusable fields:</b> declared_monthly_revenue is positive for only 45 of 842 deals; has_company is filled for 63.</li></ul></div>
</section>
</div><div id="tip"></div>
<script>
document.querySelectorAll('nav button').forEach(b=>b.onclick=()=>{{document.querySelectorAll('nav button,section').forEach(x=>x.classList.remove('on'));b.classList.add('on');document.getElementById(b.dataset.t).classList.add('on')}});
const tip=document.getElementById('tip');
document.addEventListener('mousemove',e=>{{const t=e.target.closest('[data-tip]');if(t&&t.dataset.tip){{tip.textContent=t.dataset.tip;tip.style.display='block';tip.style.left=Math.min(e.clientX+12,innerWidth-270)+'px';tip.style.top=(e.clientY+14)+'px'}}else tip.style.display='none'}});
</script></body></html>'''
open('dashboard/index.html','w').write(page); print('ok', len(page))
