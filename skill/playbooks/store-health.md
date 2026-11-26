# Playbook: Store Health & Business Overview

## Triggers

"How's my store doing?", "Give me an overview", "Store dashboard", "Business summary", "Weekly report", "Monthly recap", "KPIs?", "Key metrics?", "What should I know?", "Health check", "Ecommerce funnel?", "Conversion funnel?"

## Strategy

This is the "catch-all" — when the user wants a general overview, run multiple queries in sequence and compose a comprehensive report.

**Query sequence:**
1. The `source_status` tool — is every source connected and current (a stopped sync looks like a drop)
2. The `performance_summary` tool — sales, orders, profit, MER and cost per order against the previous period
3. `ga4Scorecards` — traffic + conversion metrics with period comparison
4. `ga4Channels` — channel breakdown (top 5)
5. The `channel_breakdown` tool — each ad platform's spend and results, and the attributed orders per channel
6. `v2GadsCampaigns` / `v2MetaCampaigns` — top campaigns (if connected)

Only query channels that whoami (or `source_status`) shows as connected; a null service in extMe is not proof that it is not connected.

**GA4 and Search Console days not stored yet:** Analyzify's stored GA4 and Search Console data can stop a few days before today. When it stops before the end of the asked range (source_status gives the newest stored day), read the missing days live, at most 3 days: GA4 with `ga4Proxy` (`properties/{propertyID}:runReport`, `references/ga4.md`), Search Console with `gscProxy` (`searchAnalytics/query` with `"dataState": "all"`, `references/gsc.md`), for those days only. Label those figures "read live, provisional" and name the days. Google publishes Search Console data about 2 to 3 days late: a day with no rows in the live read is a day Google has not published yet, so name it as not published yet, never 0. With more than 3 days missing, or when source_status says the source is failing, read none live: name the missing days as not known yet, never 0.

## How to Present

### Executive Summary

Open with 4-6 key numbers:

**Period: March 1 - March 31, 2024**

| | Value | vs Previous Period |
|---|-------|-------------------|
| Revenue | $X | +X% |
| Orders | X | +X% |
| Net Profit | $X | +X% |
| Sessions | X | +X% |
| AOV | $X | +X% |
| New Customers | X (X% of total) | |

### Profit Snapshot

| | Amount |
|---|-------|
| Net Revenue (Shopify net sales) | $X |
| − COGS | -$X |
| − Ad Spend | -$X |
| **= Net Profit** (the profit report's: after product cost and ads; the store's own shipping costs are not in the data) | **$X** |

### Traffic & Conversion

| Channel | Sessions | Revenue | Conv. Rate |
|---------|----------|---------|------------|
| Organic Search | X | $X | X% |
| Paid Search | X | $X | X% |
| Social | X | $X | X% |
| Direct | X | $X | X% |
| Email | X | $X | X% |

### Ecommerce Funnel

Use `ga4EcommFunnel` for this:

```
Sessions: X
  → View Product: X (X% of sessions)
    → Add to Cart: X (X% of views)
      → Purchase: X (X% of carts)
Overall Conversion: X%
```

### Marketing Performance

| Platform | Spend | Conversion value (platform's own) | ROAS (platform's own) |
|----------|-------|---------|------|
| Google Ads | $X | $X | X.Xx |
| Meta | $X | $X | X.Xx |
| TikTok | $X | — | not reported |
| **Store** | **$X** | **Shopify net revenue $X** | **MER X.Xx** |

### Top Campaigns

| Campaign | Platform | Revenue | ROAS |
|----------|----------|---------|------|
| Campaign A | Google | $X | X.Xx |
| Campaign B | Meta | $X | X.Xx |
| Campaign C | Google | $X | X.Xx |

### Alerts & Opportunities

After reviewing all data, highlight:
- **Wins:** Metrics that improved significantly
- **Concerns:** Metrics that declined or underperform
- **Opportunities:** High-traffic pages with low conversion, high-impression keywords near page 1, products with many views but few purchases

## Comparison Periods

When presenting comparisons:
- **Default:** Same number of days in previous period
- **"This month vs last month":** give the month before as `compare_start_date` / `compare_end_date` to `performance_summary`
- **"This week vs last week":** Mon-Sun comparison
- **"YoY":** Same dates previous year

Take every figure and every change from `performance_summary` as given: never recompute a change, and never compute one the tool does not give.

## Common Follow-ups

- "Drill into Google Ads" → pivot to ad-performance playbook
- "Why did revenue drop?" → check channel breakdown + campaign performance for declines
- "Tell me more about attribution" → pivot to attribution playbook
- "What about SEO?" → pivot to traffic-and-seo playbook
- "Show me products" → pivot to sales-and-orders playbook
