# Playbook: Weekly / Monthly Business Report

## Triggers

"Give me a weekly report", "Monthly recap", "Send me a summary", "Weekly numbers", "Monthly performance report", "How did we do this week/month?", "Executive summary", "Board report", "Business review"

## Strategy

Compose data from multiple queries into a structured business report. Run all queries for the requested period, then present in a standardized format.

**Required queries (run in sequence):**

1. The `performance_summary` tool — the period's sales, orders, profit, MER and cost per order against the comparison period, with each change (or why it is not computed). Give `compare_start_date` / `compare_end_date` from the Period Defaults table below (the week before, the same days last week, the month before); the default (the same number of days just before) fits only "the last N days"
2. The `channel_breakdown` tool — each ad platform's spend and results, and Analyzify's attributed orders per channel
3. `profitMerReport` daily rows — only for the trend inside the period
4. `ga4Scorecards` — traffic + conversion with auto-comparison
5. `ga4Channels` — channel breakdown (groupByDate: false, groupByFields: ["channel_name"])
6. `v2GadsCampaigns` — top campaigns (if Google Ads connected)
7. `v2MetaCampaigns` — top Meta campaigns (if Meta connected)
8. `v2TiktokCampaigns` — top TikTok campaigns (if TikTok connected)
9. `ga4ProductPerformances` — top products (groupByDate: false, groupByFields: ["item_name"])
10. `shopifyCampaignAttributionReport` — attribution by campaign

**Only query channels that whoami (or `source_status`) shows as connected.** Never recompute a figure or a change `performance_summary` gives, and never call a change it does not compute a drop.

**The ad platforms' conversions for a recent week are not settled.** Google Ads keeps crediting conversions to the day of the click for each conversion action's window (30 days by default), so last week's and last month's Google Ads conversions, conversion value and ROAS will still rise: say so for Google Ads, give them as provisional, and never read their change against the period before as final. Meta and TikTok credit within their attribution setting (7 days after the click by default), so their part of a week that ended more than 7 days ago is nearly settled. Spend is final once it is synced, and Shopify's orders and sales are known.

**GA4 and Search Console days not stored yet:** Analyzify's stored GA4 and Search Console data can stop a few days before today. When it stops before the end of the asked range (source_status gives the newest stored day), read the missing days live, at most 3 days: GA4 with `ga4Proxy` (`properties/{propertyID}:runReport`, `references/ga4.md`), Search Console with `gscProxy` (`searchAnalytics/query` with `"dataState": "all"`, `references/gsc.md`), for those days only. Label those figures "read live, provisional" and name the days. Google publishes Search Console data about 2 to 3 days late: a day with no rows in the live read is a day Google has not published yet, so name it as not published yet, never 0. With more than 3 days missing, or when source_status says the source is failing, read none live: name the missing days as not known yet, never 0.

## Report Template

Present in this exact structure:

---

### [Store Name] — [Period] Performance Report

**Period:** [Start Date] — [End Date]
**Compared to:** [Previous Period]

---

#### Revenue & Profit

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Gross Revenue | $X | $X | +X% |
| Net Revenue | $X | $X | +X% |
| Net Profit | $X | $X | +X% |
| Gross Margin | X% | X% | +Xpp |
| MER | X.Xx | X.Xx | |

#### Costs

| Cost | Amount | % of Revenue |
|------|--------|-------------|
| COGS | $X | X% |
| Google Ads | $X | X% |
| Meta Ads | $X | X% |
| TikTok Ads | $X | X% |
| **Total ad spend** (the tool's, not a sum you make) | **$X** | **X%** |

Shipping in the profit report is shipping charged to the customer, not a cost: never list it as one.

#### Orders & Customers

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Total Orders | X | X | +X% |
| AOV | $X | $X | +X% |
| New Customers | X | X | +X% |
| New Customer % | X% | X% | |
| Cost per order | $X | $X | |

#### Traffic & Conversion

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Sessions | X | X | +X% |
| Users | X | X | +X% |
| Conversion Rate | X% | X% | +Xpp |

#### Channel Performance

| Channel | Sessions | Revenue (GA4) | Conv. Rate |
|---------|----------|---------|------------|
| Organic Search | X | $X | X% |
| Paid Search | X | $X | X% |
| Paid Social | X | $X | X% |
| Email/Direct | X | $X | X% |
| Other | X | $X | X% |

These are GA4's channels and revenue. Each ad platform's spend and ROAS come from `channel_breakdown`, in their own section.

#### Top 5 Campaigns (by Revenue)

| Campaign | Platform | Spend | Revenue | ROAS |
|----------|----------|-------|---------|------|
| Campaign A | Google | $X | $X | X.Xx |
| Campaign B | Meta | $X | $X | X.Xx |
| Campaign C | Google | $X | $X | X.Xx |
| Campaign D | TikTok | $X | — | — |
| Campaign E | Meta | $X | $X | X.Xx |

Revenue and ROAS here are the platform's own numbers (TikTok reports conversions but no value). A recent week's Google Ads conversions aren't settled yet (above): say so instead of calling a campaign weak.

#### Top 5 Products (by Revenue)

| Product | Units Sold | Revenue | Views | Cart Rate |
|---------|-----------|---------|-------|-----------|
| Product A | X | $X | X | X% |
| Product B | X | $X | X | X% |
| Product C | X | $X | X | X% |
| Product D | X | $X | X | X% |
| Product E | X | $X | X | X% |

#### Key Takeaways

After reviewing all data, provide 3-5 bullet points:

- **Wins:** What improved and why (be specific)
- **Concerns:** What declined and the likely cause
- **Opportunities:** Untapped potential spotted in the data
- **Worth a look:** 2-3 facts the merchant may want to act on, each with what was measured (no verdicts from a raw ROAS: `references/judging-performance.md`)

---

## Period Defaults

| Request | Start Date | End Date | Compare To |
|---------|-----------|---------|------------|
| "Weekly report" | Last Monday | Last Sunday | Week before |
| "This week" | This Monday | Today | Same days last week |
| "Monthly report" | 1st of last month | Last day of last month | Month before |
| "This month" | 1st of this month | Today | Same days last month |
| "Quarterly" | Quarter start | Quarter end or today | Previous quarter |

Use the store's timezone (`shopifyIanaTimezone` from extMe) to determine day boundaries.

## Notes

- Always show both absolute values AND percentage changes
- Highlight the most significant changes (>20% swing) positively or negatively
- If a metric is missing (channel not connected), skip that section — don't show zeros
- For weekly reports, use daily grouping for trend context
- For monthly reports, use weekly grouping for trend context
- End with "Worth a look": facts the merchant may want to act on, each with what was measured, not just numbers
