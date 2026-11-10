# Playbook: Why Did My Sales/Revenue Drop?

## Triggers

"Why are my sales down?", "Revenue dropped", "Why did sales decrease?", "Conversion rate dropped", "What happened to my traffic?", "Why is ROAS falling?", "Something broke", "Sales are declining", "Why are we doing worse this month?", "What changed?"

## Strategy

This is a **diagnostic playbook** — the user noticed something went wrong and needs root cause analysis. Work through a decomposition tree: Revenue = Traffic × Conversion Rate × AOV. Find which component moved, then drill deeper.

**Run these queries in sequence — stop drilling when you find the cause:**

### Step 1: Identify What Changed (Big Picture)

Run `profitMerReport` for current period AND the comparison period:

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated netRevenue orders aov
    googleAdsSpend metaAdsSpend tiktokAdsSpend totalAdSpend
    mer newCustomers newCustomerPercentage
    cpa ncac cac cvr
  }
}
```

Run twice: once for the "bad" period, once for the "good" period the user is comparing to.

Then run `ga4Scorecards` (gives automatic percentage diffs):

```graphql
query($input: Ga4ScorecardsInput!) {
  ga4Scorecards(input: $input) {
    scorecards {
      dated metricsSessions metricsUsers metricsPurchases metricsRevenue
    }
    metricsSessionsPercentageDiff metricsUsersPercentageDiff
    metricsPurchasesPercentageDiff metricsRevenuePercentageDiff
  }
}
```

**Present the decomposition:**

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Revenue | $X | $X | -X% |
| Sessions | X | X | -X% |
| Conversion Rate | X% | X% | -X% |
| AOV | $X | $X | -X% |
| Orders | X | X | -X% |

**Identify the culprit:** Which factor dropped the most? That's where to drill next.

### Step 2A: If Traffic Dropped → Which Channel?

Run `ga4Channels` for both periods:

```graphql
query($input: Ga4ChannelInput!) {
  ga4Channels(input: $input) {
    channels {
      channelName metricsSessions metricsUsers metricsPurchases metricsRevenue
    }
  }
}
```

Compare each channel between periods:

| Channel | Sessions (Now) | Sessions (Before) | Change | Revenue Impact |
|---------|---------------|-------------------|--------|----------------|
| Organic Search | X | X | -X% | -$X |
| Paid Search | X | X | -X% | -$X |
| Social | X | X | +X% | +$X |
| Direct | X | X | -X% | -$X |

**If organic dropped:** Check `scAnalytics` for search impression/click changes → may be Google algorithm update.

**If paid dropped:** Check ad platform metrics → CPM increase? Budget exhausted? Ad disapproved?

### Step 2B: If Conversion Rate Dropped → Where in the Funnel?

Run `ga4EcommFunnel` for both periods:

```graphql
query($input: Ga4EcommFunnelInput!) {
  ga4EcommFunnel(input: $input) {
    eventName metricsEventCount
  }
}
```

Compare funnel steps:

| Funnel Step | Now | Before | Drop-off |
|-------------|-----|--------|----------|
| Sessions | X | X | — |
| View Item | X (X%) | X (X%) | -X% |
| Add to Cart | X (X%) | X (X%) | -X% |
| Begin Checkout | X (X%) | X (X%) | -X% |
| Purchase | X (X%) | X (X%) | -X% |

**If view→cart drops:** Product page issue (pricing, photos, reviews, out of stock)
**If cart→checkout drops:** Shipping costs surprise, checkout friction
**If checkout→purchase drops:** Payment issues, trust signals

Also check device breakdown with `ga4DeviceCategory` — mobile conversion often drops independently.

### Step 2C: If AOV Dropped → Product Mix Shift

Run `ga4ProductPerformances`:

```graphql
query($input: Ga4ProductPerformanceInput!) {
  ga4ProductPerformances(input: $input) {
    products {
      itemName metricsItemsPurchased metricsItemsRevenue
    }
  }
}
```

Compare product mix:
- Are cheaper products making up a larger share?
- Did a high-AOV product go out of stock?
- Is a heavy discount/promotion running that wasn't before?

Also check `shopifyOrderAgg`:
- `totalDiscounts` — did discounting increase?
- `averageUnitsOrdered` — are people buying fewer items per order?

### Step 2D: If Ad Performance Dropped → Platform Drill-down

First check `v2MarketingSourceStatuses` (`references/reports.md`): a failed sync or a tracking break looks exactly like a performance drop. If a source failed or conversions stopped, that is the finding.

Run each query with `default` = the period with the drop and `comparison` = the period before (same length). Recent days are not settled yet: conversions keep arriving for about a week, so a drop in the last few days may partly fill in.

**Google Ads:**
```graphql
query($input: V2GadsCustomerMetricsInput!) {
  v2GadsCustomerMetrics(input: $input) {
    meta { coverage { latestAvailableDate missingDays } freshness { status lastFailureAt failureMessage } }
    summary { impressions clicks cost conversions conversionValue ctr cpc cpa roas }
    comparison { summary { impressions clicks cost conversions conversionValue ctr cpc cpa roas } }
    rows { dated impressions clicks cost conversions conversionValue }
  }
}
```

Check: Did CPCs increase? Did CTR drop (ad fatigue)? Did impressions drop (budget issue)?

**Meta Ads:**
```graphql
query($input: V2MetaAccountMetricsInput!) {
  v2MetaAccountMetrics(input: $input) {
    meta { coverage { latestAvailableDate missingDays } freshness { status lastFailureAt failureMessage } }
    summary { impressions clicks spend reach purchases purchaseValue cpc cpm ctr frequency cpa }
    comparison { summary { impressions clicks spend reach purchases purchaseValue cpc cpm ctr frequency cpa } }
  }
}
```

Check: Did CPMs spike? Did reach decrease? Did frequency rise (the same people seeing the ads more often)? Over a period, `reach` is a sum of daily reach and `frequency` roughly the average daily frequency: compare the two periods with each other, not with a fixed number.

**TikTok:**
```graphql
query($input: V2TiktokAdvertiserMetricsInput!) {
  v2TiktokAdvertiserMetrics(input: $input) {
    meta { coverage { latestAvailableDate missingDays } freshness { status lastFailureAt failureMessage } }
    summary { impressions clicks spend conversions ctr cpc cvr cpm cpa }
    comparison { summary { impressions clicks spend conversions ctr cpc cvr cpm cpa } }
  }
}
```

### Step 3: Landing Page Check

If conversion dropped, check which landing pages degraded:

```graphql
query($input: Ga4LandingPageInput!) {
  ga4LandingPages(input: $input) {
    landingPage metricsSessions metricsBounceRate
    metricsEcommPurchases metricsTotalRevenue
  }
}
```

Compare bounce rates between periods. A spike on a key page = something broke.

### Step 4: Check for 404 Errors

```graphql
query($input: Ga4404PagesInput!) {
  ga4404Pages(input: $input) {
    pages {
      landingPage pagePath sessionSourceMedium
      metricsSessions metricsEventCount
    }
    metricsTotalSessions
  }
}
```

If 404 count spiked → broken links, removed products, or URL changes causing traffic loss.

## How to Present the Diagnosis

Structure the response as a clear investigation:

**1. The Problem:**
"Your revenue dropped X% ($X → $X) comparing [period] to [period]."

**2. The Primary Cause:**
"The main driver was a **X% drop in [traffic/conversion/AOV]**, which accounts for ~X% of the revenue decline."

**3. The Root Cause:**
"Specifically, [channel] traffic decreased by X% / conversion on [device/page] dropped / [product] sales declined because..."

**4. Secondary Factors:**
"Additionally, [other smaller factors]..."

**5. Recommended Actions:**
- Specific, actionable steps based on findings
- "Check your [X] — it may need [Y]"
- "Consider [action] to recover [metric]"

## Common Diagnostic Patterns

| Symptom | Likely Cause | Where to Look |
|---------|-------------|---------------|
| Revenue down, traffic same | Conversion or AOV dropped | Funnel + product mix |
| Revenue down, traffic down | Channel issue | Channel breakdown |
| All metrics down | Seasonal, site issue, or tracking broken | YoY comparison + 404 check |
| Revenue down, orders same | AOV dropped | Discount usage + product mix |
| Paid revenue down, organic same | Ad platform issue | Platform-specific metrics |
| Conversion down, mobile only | Mobile UX issue | Device category breakdown |
| Sudden cliff | Something broke | 404s + landing page bounce rates |
| Gradual decline | Competitive or seasonal | Month-over-month trend |

## Common Follow-ups

- "Is it just one channel?" → channel breakdown comparison
- "Is it a product issue?" → product performance comparison
- "Is my site broken?" → 404 check + landing page bounce rates
- "Is it seasonal?" → suggest comparing YoY instead of MoM
- "What should I fix first?" → prioritize by revenue impact: biggest drop × easiest fix
