# Playbook: Profit & Revenue Analysis

## Triggers

"What's my profit?", "Am I making money?", "Revenue this month?", "Show me P&L", "Net profit?", "Gross margin?", "How much am I spending on ads?", "MER?", "Marketing efficiency?", "Break down my costs", "COGS?", "Shipping costs?", "Ad spend breakdown"

## Strategy

**Primary:** `profitMerReport` via Report API — this single query combines Shopify orders + Google Ads + Meta + TikTok into one unified profit view.

**Fallback:** If profitMerReport returns empty (no data synced), use `shopifyOrderAgg` for revenue + `gadsCustomerMetrics`/`fbAccountInsights`/`tiktokAdvertiserInsights` separately.

## Queries

### 1. Full Profit Report (daily trend)

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated year month week day
    netRevenue netProfit currency
    googleAdsSpend metaAdsSpend tiktokAdsSpend totalAdSpend
    costOfGoodsSold shippingCost
    mer grossProfit grossMargin
    orders aov
    newCustomers newCustomerPercentage
    cpa ncac cac cvr
  }
}
```

```json
{
  "input": {
    "default": {
      "spaceId": "{{reportSpaceId}}",
      "refId": "{{workspaceId}}",
      "startDate": "2024-03-01",
      "endDate": "2024-03-31",
      "groupByDate": true
    }
  }
}
```

### 2. Monthly Summary (for period comparison)

Same query but with `groupByFields: ["month"]` instead of `groupByDate: true`.

### 3. Total Summary (single number)

Same query but with `groupByDate: false` — returns one row with totals.

## How to Present

### Quick Summary (when user asks "how's my profit?")

Present a clean summary table:

| Metric | Value |
|--------|-------|
| Net Revenue | $X |
| Ad Spend | $X (Google: $X, Meta: $X, TikTok: $X) |
| COGS | $X |
| Shipping | $X |
| **Net Profit** | **$X** |
| Gross Margin | X% |
| MER | X.Xx |

### Trend (when user asks "revenue trend" or "this month vs last")

Run the daily query and present as a time series. Highlight:
- Best and worst days
- Overall trend direction
- Any significant spikes or drops

### Cost Breakdown (when user asks "where is my money going?")

| Cost Category | Amount | % of Revenue |
|---------------|--------|-------------|
| COGS | $X | X% |
| Google Ads | $X | X% |
| Meta Ads | $X | X% |
| TikTok Ads | $X | X% |
| Shipping | $X | X% |
| **Total Costs** | **$X** | **X%** |
| **Net Profit** | **$X** | **X%** |

### Unit Economics (when user asks about CAC, CPA, AOV)

| Metric | Value | What It Means |
|--------|-------|---------------|
| AOV | $X | Average order value |
| CPA | $X | Cost to acquire one order |
| CAC | $X | Cost to acquire one customer |
| NCAC | $X | Cost to acquire one NEW customer |
| MER | X.Xx | $X revenue per $1 ad spend |
| CVR | X% | Visitors who become buyers |

## Key Calculations

- **MER** = Net Revenue / Total Ad Spend (higher is better, >3x is good)
- **Gross Margin** = (Revenue - COGS) / Revenue × 100
- **Net Profit** = Revenue - COGS - Ad Spend - Shipping
- **CPA** = Total Ad Spend / Total Orders
- **CAC** = Total Ad Spend / Total Customers
- **NCAC** = Total Ad Spend / New Customers Only
- **CVR** = Orders / Total Clicks × 100

## Common Follow-ups

- "Break it down by day/week/month" → adjust `groupByDate`/`dateArgs`
- "Compare to last month" → run same query with previous period dates
- "Which ads are most profitable?" → pivot to `gadsCampaignsPerformance` + `fbCampaignInsights`
- "What's my best selling product?" → pivot to `ga4ProductPerformances` or `shopifyOrderAgg`
