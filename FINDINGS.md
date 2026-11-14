# Findings memo: Olist lead-to-revenue funnel

**Audience:** a head of sales / growth deciding where to spend the next quarter.
**Scope:** 5,998 leads first contacted Jan-May 2018; 656 won accounts observable for 90 days; R$673k GMV from 379 active accounts.

## The answer in three lines
1. Fix **activation** first. 56% of won accounts make no sale within 90 days; that is a bigger loss than any conversion gap.
2. Send more traffic to the **two landing pages that convert at ~20%** and fix or retire the ones that convert at 4-7%.
3. Be skeptical of social and email as lead sources, and **record lead origin** (14% is blank and converts best).

## Three findings that matter

### 1. Activation is the bigger leak
Of 5,998 leads, 678 (11.3%) won within 90 days. Of 656 won accounts, only 286 (43.6%) sold anything within 90 days; median time to first sale is 47 days. Month-by-month, roughly 30-40% of a cohort is selling in months 3-5 after the win, and about 70% of sellers active in one month are active the next.
*Recommendation:* an onboarding programme aimed at the first 30 days (only 17% of accounts sell in that window: 111 of 656), triggered by the win.

### 2. Landing page performance is wildly uneven
Two pages convert at 20.2% and 20.5%; together 1,477 leads, 301 wins (44% of all wins from 25% of leads). The largest low page converts at 4.4% on 495 leads (95% CI 3.0-6.6%). Lifting six sizeable low pages (1,484 leads) to the rest-of-pages rate of 8.3% would add about 8 wins/month.
*Recommendation:* route paid/organic traffic to the top two pages; A/B test the low-page copy against them.

### 3. Revenue concentrates in a few account types
Top decile of active accounts = 65% of GMV. "online_big" is 43% of GMV (R$291k of R$673k), activates at 63% vs 25% for offline sellers (p<0.001), and holds 19 of 38 top-decile accounts.
*Recommendation:* prioritise this profile in qualification and scoring; treat offline leads as lower priority or give them a different onboarding path.

## Smaller observations
- Channel: organic (12.3%) and paid (12.4%) win at the same rate; social (5.2%) and email (3.5%) are far lower. Paid-search accounts activate more (55.6% vs 40.2% organic, p=0.005).
- Unknown origin: 861 leads (14%) win at 19.6%. Likely a tracking gap, not a real channel.
- Median time to close is 12 days, but p90 is 111, hence the 90-day window.

## Sizing (measured vs assumed)
Measured baseline: ~1,200 leads/month, 11.3% win, 43.6% activation, R$1,188 mean 90-day GMV per active account (median R$327).

| Scenario | Wins/mo | Activated/mo | Added 90-day GMV per monthly cohort |
|---|---|---|---|
| Baseline | 135.6 | 59.1 | - |
| A: low pages lifted to 8.3% *(assumption)* | 143.9 | 62.8 | ~R$4.4k |
| B: activation 43.6% to 55.6% *(assumption: paid-search level)* | 135.6 | 75.4 | ~R$19.4k |
| A + B | 143.9 | 80.0 | ~R$24.8k |

The activation lever is roughly 4x the landing-page lever. Both are optimistic: the means are skewed, and the targets are borrowed from sub-groups that may differ in ways we cannot see.

## What I would not claim
- That any channel, page or lead type *causes* the gap (observational data).
- Anything about win rates by segment, lead type or sales rep (those fields exist only for won deals).
- That unactivated accounts "never sold": 380 of 842 deal sellers are observable in the orders sample.
- That the SDR with low activation is a problem (1 of 32, does not survive correction).

## Next steps if this were a real team
1. Instrument lead origin at capture. 2. A/B test landing pages. 3. Pilot 30-day onboarding on new wins and measure activation lift. 4. Add rep-level win/loss data so rep performance can be analysed properly.
