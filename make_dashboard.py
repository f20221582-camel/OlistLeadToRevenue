# Builds dashboard.html from the CSV files in results/.
# The page is plain HTML and CSS. Bars are just coloured boxes whose width is the value.
import csv


def read(name):
    with open('results/' + name + '.csv') as f:
        return list(csv.DictReader(f))


def bars(rows, label_col, value_col, suffix=''):
    # one row per bar: label, coloured box, value
    biggest = max(float(r[value_col]) for r in rows)
    html = ''
    for r in rows:
        value = float(r[value_col])
        width = 100 * value / biggest
        html += '<div class="row"><span class="label">%s</span>' % r[label_col]
        html += '<span class="track"><span class="bar" style="width:%.0f%%"></span></span>' % width
        html += '<span class="value">%s%s</span></div>\n' % (r[value_col], suffix)
    return html


def table(rows, columns):
    html = '<table><tr>' + ''.join('<th>%s</th>' % c for c in columns) + '</tr>\n'
    for r in rows:
        html += '<tr>' + ''.join('<td>%s</td>' % r[c] for c in columns) + '</tr>\n'
    return html + '</table>'


funnel = read('funnel')[0]
activation = read('activation')[0]
top10 = read('gmv_top_10_percent')[0]
by_month = read('win_rate_by_month')
by_origin = read('win_rate_by_origin')
pages = read('win_rate_by_landing_page')[:10]
act_type = read('activation_by_lead_type')
act_origin = read('activation_by_origin')
gmv_type = read('gmv_by_lead_type')

# shorten the long landing page ids so the table fits
for p in pages:
    p['landing_page_id'] = p['landing_page_id'][:8]

page = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Lead to revenue: where the funnel leaks</title>
<style>
  body { font-family: Arial, sans-serif; max-width: 820px; margin: 30px auto; padding: 0 15px; color: #222; }
  h1 { font-size: 26px; }
  h2 { font-size: 19px; margin-top: 35px; border-bottom: 1px solid #ccc; padding-bottom: 4px; }
  .cards { display: flex; gap: 12px; }
  .card { flex: 1; border: 1px solid #ccc; border-radius: 6px; padding: 12px; }
  .card b { font-size: 26px; display: block; }
  .row { display: flex; align-items: center; margin: 4px 0; font-size: 14px; }
  .label { width: 150px; }
  .track { flex: 1; background: #eee; height: 16px; }
  .bar { display: block; background: #2a78d6; height: 16px; }
  .value { width: 70px; text-align: right; }
  table { border-collapse: collapse; width: 100%%; font-size: 14px; }
  th, td { border-bottom: 1px solid #ddd; padding: 5px; text-align: left; }
  .note { color: #666; font-size: 13px; }
</style>
</head>
<body>
<h1>Lead to revenue: where the funnel leaks</h1>
<p>SQL analysis of Olist's public marketing funnel data (2017-2018, Brazil). Amounts are in Brazilian reais (R$).</p>

<div class="cards">
  <div class="card"><b>%(win)s%%</b>of leads won within 90 days<br><span class="note">%(won)s of %(leads)s leads</span></div>
  <div class="card"><b>%(act)s%%</b>of won accounts sold within 90 days<br><span class="note">%(active)s of %(accounts)s accounts</span></div>
  <div class="card"><b>%(top)s%%</b>of sales from the top 10%% of accounts<br><span class="note">%(top_n)s accounts</span></div>
</div>

<h2>1. Win rate by month of first contact (all leads)</h2>
<p class="note">Deals are only recorded from December 2017, so older leads look like they never convert.
That is a data issue, so the rest of the page only uses leads first contacted January to May 2018.</p>
%(month_bars)s

<h2>2. Win rate by lead origin (Jan-May 2018 leads)</h2>
%(origin_bars)s
<p class="note">Social and email leads are 23%% of all leads but only 10%% of the wins.
"unknown" means the origin was not recorded.</p>

<h2>3. Win rate by landing page (10 biggest pages)</h2>
%(page_table)s
<p class="note">The two biggest pages win about 20%% of leads. The next biggest page wins 4.4%%.</p>

<h2>4. Of the won accounts, how many start selling within 90 days?</h2>
<p class="note">Only accounts won on or before 29 May 2018 are counted, so each had a full 90 days. Lead types with fewer than 10 accounts are left out.</p>
%(act_bars)s

<p>By lead origin:</p>
%(act_origin_bars)s
<p class="note">Accounts that came from paid search start selling more often (55.6%%) than organic search ones (40.2%%).</p>

<h2>5. Share of total sales by lead type</h2>
%(gmv_bars)s
<p class="note">Top 10%% of accounts (38 accounts) = R$%(top_gmv)s of sales.</p>

<h2>Limits</h2>
<ul class="note">
  <li>Only 380 of the 842 deals belong to sellers found in the orders data, so "not selling" may just mean "not in this sample".</li>
  <li>This shows patterns, not causes.</li>
  <li>Lead type and segment are only recorded for won deals, so win rates by lead type cannot be calculated.</li>
</ul>
</body>
</html>
""" % dict(
    win=funnel['win_rate_pct'], won=funnel['won_90'], leads=funnel['leads'],
    act=activation['active_90_pct'], active=activation['active_90'], accounts=activation['accounts'],
    top=top10['share_of_total_pct'], top_n=top10['top_accounts'], top_gmv=format(int(float(top10['top_gmv'])), ','),
    month_bars=bars(by_month, 'month', 'win_rate_pct', '%'),
    origin_bars=bars(by_origin, 'origin', 'win_rate_pct', '%'),
    page_table=table(pages, ['landing_page_id', 'leads', 'won_90', 'win_rate_pct']),
    act_bars=bars(act_type, 'lead_type', 'active_90_pct', '%'),
    act_origin_bars=bars(act_origin, 'origin', 'active_90_pct', '%'),
    gmv_bars=bars(gmv_type, 'lead_type', 'share_of_gmv_pct', '%'),
)

with open('dashboard.html', 'w') as f:
    f.write(page)
print('wrote dashboard.html')
