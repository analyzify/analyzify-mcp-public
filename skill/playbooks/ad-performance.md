# Playbook: Ad Performance & ROAS

## Triggers

"How are my ads doing?", "Google Ads performance?", "Facebook ads?", "TikTok ads?", "Campaign performance", "ROAS?", "Ad spend?", "Which campaigns are profitable?", "Wasted ad spend?", "Cost per conversion?", "Best performing ads?", "Worst performing campaigns?"

## Strategy

**Primary:** Report API for each ad platform — `gadsCustomerMetrics`, `gadsCampaignsPerformance`, `fbAccountInsights`, `fbCampaignInsights`, `tiktokAdvertiserInsights`, `tiktokCampaignInsights`.

**For cross-platform totals:** Use `profitMerReport` which sums spend across all platforms.

**Fallback to live proxy:** Only if report data isn't synced yet or user needs very recent (today's) data.

## Queries

### Google Ads — Account Overview

```graphql
query($input: GadsCustomerMetricsInput!) {
  gadsCustomerMetrics(input: $input) {
    dated year month week day
    metricsImpressions metricsClicks metricsCtr
    metricsCostMicros metricsAverageCpc
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
    metricsCostPerConversion
  }
}
```

**Note:** Divide `metricsCostMicros` by 1,000,000 for actual cost.

### Google Ads — By Campaign

```graphql
query($input: GadsCampaignsPerformanceInput!) {
  gadsCampaignsPerformance(input: $input) {
    dated id name advertisingChannelType
    metricsImpressions metricsClicks metricsCtr
    metricsCostMicros metricsAverageCpc
    metricsConversions metricsConversionsValue
    metricsCostPerConversion
  }
}
```

### Google Ads — Product Performance (paginated)

```graphql
query($input: GadsProductPerformanceInput!) {
  gadsProductPerformance(input: $input) {
    nodes {
      itemId productTitle campaignName
      metricsImpressions metricsClicks metricsCtr
      metricsCostMicros metricsConversions metricsConversionsValue
      metricsAverageCpc metricsCostPerConversion
    }
    aggregates {
      totalCost totalImpressions totalClicks totalConversions
      totalConversionValue avgCpa avgRoas avgConversionRate
    }
    totalCount hasMore currentPage totalPages
  }
}
```

Useful preset filters:
- `HIGH_PERFORMERS` — high conversions + good ROAS
- `UNDERPERFORMERS` — high spend, low returns
- `HIGHER_COST_LOWER_ROAS` — money drains
- `LOW_CPA_HIGH_CVR` — efficient performers

### Meta/Facebook — Account Overview

```graphql
query($input: FbInput!) {
  fbAccountInsights(input: $input) {
    dated impressions clicks spend reach cpc cpm ctr frequency uniqueClicks
  }
}
```

For revenue data, also query:
```graphql
query($input: FbInput!) {
  fbAccountActionValues(input: $input) {
    dated actionType value
  }
}
```

Filter `actionType: "purchase"` for purchase revenue.

### Meta/Facebook — By Campaign

```graphql
query($input: FbInput!) {
  fbCampaignInsights(input: $input) {
    dated campaignId campaignName objective
    impressions clicks spend reach cpc cpm ctr frequency uniqueClicks
  }
}
```

### TikTok — Account Overview

```graphql
query($input: TiktokInput!) {
  tiktokAdvertiserInsights(input: $input) {
    dated impressions clicks spend cpc ctr cvr cpm conversion cpa
  }
}
```

### TikTok — By Campaign

```graphql
query($input: TiktokInput!) {
  tiktokCampaignInsights(input: $input) {
    dated campaignId campaignName
    impressions clicks spend cpc ctr cvr cpm conversion cpa
  }
}
```

## How to Present

### Cross-Platform Summary

| Platform | Spend | Clicks | Conversions | ROAS | CPA |
|----------|-------|--------|-------------|------|-----|
| Google Ads | $X | X | X | X.Xx | $X |
| Meta | $X | X | X | X.Xx | $X |
| TikTok | $X | X | X | X.Xx | $X |
| **Total** | **$X** | **X** | **X** | **X.Xx** | **$X** |

### Campaign Rankings (when asked "best/worst campaigns")

Sort by ROAS descending, show top 10:

| Campaign | Platform | Spend | Revenue | ROAS | CPA |
|----------|----------|-------|---------|------|-----|
| Best Campaign | Google | $X | $X | X.Xx | $X |
| ... | ... | ... | ... | ... | ... |

### Efficiency Analysis (when asked about wasted spend)

Highlight campaigns where:
- ROAS < 1.0 (losing money)
- CPA > AOV (acquisition cost exceeds order value)
- High impressions but low CTR (poor creative)
- High clicks but low conversions (poor landing page)

## Common Follow-ups

- "Break down by day" → add `groupByDate: true`
- "Show me just Google Ads" → use only gads queries
- "Which products are wasting money?" → `gadsProductPerformance` with `HIGHER_COST_LOWER_ROAS` preset
- "Compare this month vs last" → run with two date ranges
