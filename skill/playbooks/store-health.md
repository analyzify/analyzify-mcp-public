# Playbook: Store Health & Business Overview

## Triggers

"How's my store doing?", "Give me an overview", "Store dashboard", "Business summary", "Weekly report", "Monthly recap", "KPIs?", "Key metrics?", "What should I know?", "Health check", "Ecommerce funnel?", "Conversion funnel?"

## Strategy

This is the "catch-all" — when the user wants a general overview, run multiple queries in sequence and compose a comprehensive report.

**Query sequence:**
1. `profitMerReport` — profit, revenue, costs (totals for period)
2. `ga4Scorecards` — traffic + conversion metrics with period comparison
3. `ga4Channels` — channel breakdown (top 5)
4. `v2GadsCampaigns` — top campaigns (if Google Ads connected)
5. `v2MetaCampaigns` — Meta performance (if Meta connected)
6. `shopifyCampaignAttributionReport` — top attribution sources

Only query channels that are connected (check extMe response for null services).

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
| Gross Revenue | $X |
| − COGS | -$X |
| − Ad Spend | -$X |
| − Shipping | -$X |
| **= Net Profit** | **$X (X% margin)** |

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

| Platform | Spend | Revenue | ROAS |
|----------|-------|---------|------|
| Google Ads | $X | $X | X.Xx |
| Meta | $X | $X | X.Xx |
| TikTok | $X | $X | X.Xx |
| **Total** | **$X** | **$X** | **X.Xx (MER)** |

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
- **"This month vs last month":** Use month boundaries
- **"This week vs last week":** Mon-Sun comparison
- **"YoY":** Same dates previous year

Calculate percentage change: `((current - previous) / |previous|) × 100`

## Common Follow-ups

- "Drill into Google Ads" → pivot to ad-performance playbook
- "Why did revenue drop?" → check channel breakdown + campaign performance for declines
- "Tell me more about attribution" → pivot to attribution playbook
- "What about SEO?" → pivot to traffic-and-seo playbook
- "Show me products" → pivot to sales-and-orders playbook
