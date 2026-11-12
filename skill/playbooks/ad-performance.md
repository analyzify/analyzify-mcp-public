# Playbook: Ad Performance & ROAS

## Triggers

"How are my ads doing?", "Google Ads performance?", "Facebook ads?", "TikTok ads?", "Campaign performance", "ROAS?", "Ad spend?", "Which campaigns are profitable?", "Wasted ad spend?", "Losing campaigns?", "Cost per conversion?", "Best performing ads?", "Worst performing campaigns?"

## Strategy

**Primary:** the `v2*` Report API queries: `v2GadsCustomerMetrics`, `v2GadsCampaigns`, `v2MetaCampaigns`, `v2MetaAccountMetrics`, `v2TiktokCampaigns`, `v2TiktokAdvertiserMetrics`. Their `summary` and rows already compute CTR, CPC, CPA and ROAS from totals. Don't read rates from multi-day rows of the legacy reports (`gadsCampaignsPerformance`, `fbCampaignInsights`, `tiktokCampaignInsights`): those are added up across days.

**For cross-platform totals:** add up spend across platforms, but **don't add up the platforms' conversion value or compute a "blended ROAS"**: each platform claims the same orders, so the sum overstates sales. For an overall figure use MER = Shopify net revenue / total ad spend from `profitMerReport` (computed from its totals).

**If a platform comes back empty:** check `v2MarketingSourceStatuses` before saying there was no spend (see `references/reports.md`).

**Fallback to live proxy:** Only if report data isn't synced yet or user needs very recent (today's) data. Say the number is a live read and not settled.

## Queries

Variables for all `v2*` queries: `{ "input": { "default": { "spaceId": "...", "startDate": "...", "endDate": "...", "groupByDate": false } } }`. Add `"comparison"` with the previous period to compare in one call.

### Google Ads — Account Overview

```graphql
query($input: V2GadsCustomerMetricsInput!) {
  v2GadsCustomerMetrics(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks cost conversions conversionValue ctr cpc cpa roas cvr }
    rows { dated cost conversions conversionValue }
  }
}
```

`cost` is in the account currency. `ctr` and `cvr` are percentages.

### Google Ads — By Campaign

```graphql
query($input: V2GadsCampaignsInput!) {
  v2GadsCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks cost conversions conversionValue ctr cpc cpa roas }
    rows { campaignId campaignName campaignType impressions clicks cost conversions conversionValue ctr cpc cpa roas }
  }
}
```

### Google Ads — Product Performance (paginated)

```graphql
query($input: V2GadsProductsInput!) {
  v2GadsProducts(input: $input) {
    summary { cost conversions conversionValue cpa roas }
    rows { itemId productTitle impressions clicks cost conversions conversionValue ctr cpc cpa roas }
    pageInfo { page totalCount totalPages hasNextPage }
  }
}
```

Add `"groupByFields": ["item_id", "product_title"]` to `default` for one row per item, and `"sort": [{ "field": "COST", "direction": "DESC" }], "limit": 250` next to it. Items are variants: for results by product, use the roll-up recipe in `playbooks/product-optimization.md`.

### Meta — Account and Campaigns

```graphql
query($input: V2MetaCampaignsInput!) {
  v2MetaCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks linkClicks spend purchases purchaseValue ctr cpc cpm cpa roas }
    rows { campaignId campaignName impressions clicks linkClicks spend purchases purchaseValue ctr cpc cpm cpa roas }
  }
}
```

For a daily trend use `v2MetaAccountMetrics` (same input, `rows { dated spend purchases purchaseValue }`).

### TikTok — Account and Campaigns

```graphql
query($input: V2TiktokCampaignsInput!) {
  v2TiktokCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks spend conversions ctr cpc cvr cpm cpa }
    rows { campaignId campaignName impressions clicks spend conversions ctr cpc cvr cpm cpa }
  }
}
```

TikTok reports conversions but no conversion value, so there is no TikTok ROAS. Show CPA.

## How to Present

### Cross-Platform Summary

| Platform | Spend | Clicks | Conversions (platform's count) | ROAS (platform's numbers) | CPA |
|----------|-------|--------|-------------|------|-----|
| Google Ads | $X | X | X | X.Xx | $X |
| Meta | $X | X | X | X.Xx | $X |
| TikTok | $X | X | X | — (no value reported) | $X |
| **Total** | **$X** | **X** | — | **MER X.Xx** (Shopify net revenue / total spend) | — |

Platforms count overlapping orders, so conversions and ROAS are per platform only.

### Campaign Rankings (when asked "best/worst campaigns")

Sort by ROAS descending, show top 10. Always show spend next to ROAS: a high ROAS on tiny spend says little. For the bottom of the list, label it "lowest ROAS on the platform's numbers", not "worst" or "losing", unless the checks in `references/judging-performance.md` hold.

| Campaign | Platform | Spend | Revenue | ROAS | CPA |
|----------|----------|-------|---------|------|-----|
| Best Campaign | Google | $X | $X | X.Xx | $X |
| ... | ... | ... | ... | ... | ... |

### "Wasted spend", "losing campaigns", "what should I cut?"

Follow `references/judging-performance.md`. In short:

- Judge settled days only (the window ends 8 days before today), over two periods of 30 days.
- Compare ROAS with the store's break-even ROAS = 1 / (margin × net share), never with 1.0.
- Check tracking first; a broken tag makes every campaign look like a loser.
- Ask for enough volume (30+ conversions, or a clear shortfall against the conversions expected at break-even).
- State the facts and what they don't mean. Don't say pause, cut or scale.

Signals worth pointing out as facts (not verdicts):
- CPA above the store's average order value
- Many impressions and a CTR well below the account's
- Many clicks and few conversions (look at the landing page)

## Common Follow-ups

- "Break down by day" → account level: `v2GadsCustomerMetrics` / `v2MetaAccountMetrics` / `v2TiktokAdvertiserMetrics` rows (one per day). Per campaign per day: legacy `gadsCampaignsPerformance` with `groupByDate: true`, rates computed from totals
- "Show me just Google Ads" → use only gads queries
- "Which products are losing money?" → `playbooks/product-optimization.md` ("Products and ad spend"), with the checks in `references/judging-performance.md`
- "Compare this month vs last" → add `comparison` with the previous period
- "Is my tracking working?" → `playbooks/conversion-health-tracking.md`
