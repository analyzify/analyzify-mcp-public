# Playbook: Ad Performance & ROAS

## Triggers

"How are my ads doing?", "Google Ads performance?", "Facebook ads?", "TikTok ads?", "Campaign performance", "ROAS?", "Ad spend?", "Which campaigns are profitable?", "Wasted ad spend?", "Losing campaigns?", "Cost per conversion?", "Best performing ads?", "Worst performing campaigns?"

## Strategy

**Channels compared** ("how are my channels doing", ROAS or spend by channel): call the `channel_breakdown` tool first (Analyzify MCP 0.4.8 or later; see SKILL.md, "Channels compared"). It already returns each channel against Shopify, the currency check and each channel's state. The queries below are for one channel's detail, and for an older connector without that tool.

**Primary:** the `v2*` Report API queries: `v2GadsCustomerMetrics`, `v2GadsCampaigns`, `v2MetaCampaigns`, `v2MetaAccountMetrics`, `v2TiktokCampaigns`, `v2TiktokAdvertiserMetrics`. Their `summary` and rows already compute CTR, CPC, CPA and ROAS from totals. Don't read rates from multi-day rows of the legacy reports (`gadsCampaignsPerformance`, `fbCampaignInsights`, `tiktokCampaignInsights`): those are added up across days.

**For cross-platform totals:** add up spend across platforms only when every platform's `meta.currencyCode` is the same as the shop's (otherwise give each platform's spend in its own currency and say a total needs converting first), but **don't add up the platforms' conversion value or compute a "blended ROAS"**: each platform claims the same orders, so the sum overstates sales. For an overall figure use MER = Shopify net revenue / total ad spend from `profitMerReport` (computed from its totals).

**If a platform comes back empty:** check `v2MarketingSourceStatuses` before saying there was no spend (see `references/reports.md`).

**Fallback to live proxy:** Only if report data isn't synced yet or user needs very recent (today's) data. Say the number is a live read and not settled. Exception: counts and complete lists of Google Ads items with spend always come from the live Shopping performance view (`references/gads.md`, "Products (items) over a period").

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
- Compare ROAS with the store's break-even ROAS = 1 / (margin × net share), never with 1.0. Write both factors in the answer and say which net share you used, even when it is 1; never shorten it to 1 / margin (worked example in `references/judging-performance.md`, section 3).
- Check tracking first; a broken tag makes every campaign look like a loser.
- Ask for enough volume (30+ conversions, or a clear shortfall against the conversions expected at break-even).
- State the facts and what they don't mean. Don't say pause, cut or scale.

Signals worth pointing out as facts (not verdicts):
- A campaign's cost per purchase above the store's average gross profit per order. Gross profit per order is `grossProfit / orders`, each added up over `profitMerReport`'s rows for the same settled window. Cost per purchase is a campaign's spend / its own purchases: Meta's stored `cpa` (`v2MetaCampaigns`, spend / purchases), or for Google Ads a live read split by `segments.conversion_action_category` (the purchases line of `channel_breakdown`, when it is there, is the whole account, not a campaign). Compare them only when both are in the same currency (an ad account billing in another currency than the shop is never compared), and not when `costOfGoodsSold` is 0 or near it: then gross profit per order is not known (it would equal the average order value), so ask for the merchant's margin or leave the line out. Google Ads' stored conversions and TikTok's conversions are not purchases, so their cost per conversion is never set against an order figure. The platforms claim overlapping orders, and stored Meta days can stay below Meta's own report, so this is a pointer, not a verdict: below break-even is decided by the ROAS test in `references/judging-performance.md`
- Many impressions and a CTR well below the account's
- Many clicks and few conversions (look at the landing page)

## Common Follow-ups

- "Break down by day" → account level: `v2GadsCustomerMetrics` / `v2MetaAccountMetrics` / `v2TiktokAdvertiserMetrics` rows (one per day). Per campaign per day: legacy `gadsCampaignsPerformance` with `groupByDate: true`, rates computed from totals
- "Show me just Google Ads" → use only gads queries
- "Which products are losing money?" → `playbooks/product-optimization.md` ("Products and ad spend"), with the checks in `references/judging-performance.md`
- "Compare this month vs last" → add `comparison` with the previous period
- "Is my tracking working?" → `playbooks/conversion-health-tracking.md`
