# Playbook: Google Ads Conversion Health & Tracking Audit

## Triggers

"Are my conversions tracking correctly?", "Conversion health?", "When was the last conversion?", "Is my tracking broken?", "Conversion tags working?", "Google Ads shows zero conversions", "Conversion data mismatch", "Tracking audit", "Are my conversion actions set up right?", "PMax not converting?"

## Strategy

Silent tracking failures are one of the most expensive problems in ecommerce — if conversion data stops flowing, Smart Bidding and PMax campaigns go blind and waste budget. This playbook audits conversion health.

**Queries to run:**

1. `gadsLastSeenConversions` — when each conversion action last fired (the critical check)
2. `gadsConversions` — conversion action details and values
3. `gadsCustomerMetrics` — overall conversion trend (is it dropping?)
4. `gadsCampaignsPerformance` — which campaigns are affected?

## Queries

### 1. Last Seen Conversions (Critical Health Check)

```graphql
query($input: GadsLastConversionsInput!) {
  gadsLastSeenConversions(input: $input) {
    name
    ctype
    categoryId
    metricsConversionLastConversionDate
  }
}
```

```json
{
  "input": {
    "default": {
      "spaceId": "{{reportSpaceId}}",
      "refId": "{{workspaceId}}"
    }
  }
}
```

This shows the **last date** each conversion action fired. If a purchase conversion hasn't fired in days, tracking is broken.

### 2. Conversion Actions & Values

```graphql
query($input: GadsConversionsInput!) {
  gadsConversions(input: $input) {
    dated id name categoryId primaryForGoal
    metricsAllConversionsValue metricsAllConversions
  }
}
```

With `groupByDate: true` for the last 30 days.

### 3. Overall Conversion Trend

```graphql
query($input: GadsCustomerMetricsInput!) {
  gadsCustomerMetrics(input: $input) {
    dated
    metricsClicks metricsConversions metricsConversionsValue
    metricsCostMicros metricsCostPerConversion
  }
}
```

With `groupByDate: true` for last 14 days.

### 4. Campaign-Level Conversion Check

```graphql
query($input: GadsCampaignsPerformanceInput!) {
  gadsCampaignsPerformance(input: $input) {
    name advertisingChannelType
    metricsClicks metricsConversions metricsConversionsValue
    metricsCostMicros
  }
}
```

With `groupByDate: false` for summary.

## How to Present

### Conversion Health Dashboard

| Conversion Action | Type | Primary? | Last Fired | Status |
|-------------------|------|----------|-----------|--------|
| Purchase | PURCHASE | Yes | 2024-03-28 | OK |
| Add to Cart | ADD_TO_CART | No | 2024-03-28 | OK |
| Begin Checkout | BEGIN_CHECKOUT | No | 2024-03-25 | Warning — 3 days ago |
| Page View | PAGE_VIEW | No | 2024-03-28 | OK |

**Status rules:**
- **OK:** Last fired within 1 day
- **Warning:** Last fired 2-3 days ago
- **Critical:** Last fired 4+ days ago or never
- **Missing:** No conversion action for this type exists

### Conversion Trend (Last 14 Days)

| Date | Clicks | Conversions | Conv. Rate | Revenue | CPA |
|------|--------|-------------|------------|---------|-----|
| Mar 28 | X | X | X% | $X | $X |
| Mar 27 | X | X | X% | $X | $X |
| Mar 26 | X | 0 | 0% | $0 | — |
| ... | | | | | |

Flag any day with 0 conversions but normal clicks — likely tracking failure.

### Campaign Impact

| Campaign | Type | Clicks | Conversions | Spend (No Conv Data) |
|----------|------|--------|-------------|---------------------|
| PMax Campaign | PERFORMANCE_MAX | X | 0 | $X wasted |
| Brand Search | SEARCH | X | X | OK |
| Shopping | SHOPPING | X | 0 | $X wasted |

### Diagnosis

**If purchase conversion hasn't fired in 2+ days:**
- "Your purchase conversion tag hasn't fired since [date]. This means Google's Smart Bidding and PMax campaigns are running blind — they can't optimize without conversion data."
- "Estimated wasted spend since tracking broke: $X (ad spend with no conversion signal)"
- "Action: Check your Google Tag / Analyzify tag setup on the checkout confirmation page."

**If conversions exist but values are $0:**
- "Conversions are tracking but with $0 value — this means the value parameter isn't being passed."
- "This hurts ROAS bidding strategies — Google doesn't know which conversions are worth more."

**If some campaigns convert but others don't:**
- "Only [campaign names] are showing conversions. Check if other campaigns are landing on pages with the conversion tag installed."

**If conversion count dropped suddenly:**
- "Conversions dropped X% on [date] while clicks stayed stable — this is a tracking issue, not a performance issue."
- "Common causes: site update removed tag, consent manager blocking tag, checkout page changed."

### Common Conversion Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| 0 conversions, normal clicks | Tag removed or broken | Check tag on checkout confirmation page |
| Conversions but $0 value | Value parameter missing | Check purchase event value configuration |
| Sudden drop on specific date | Site update broke tag | Check what changed on that date |
| PMax 0 conversions | Feed or tracking issue | Check merchant center + conversion tag |
| Conversion count >> Shopify orders | Duplicate firing | Check tag fires only once per purchase |
| Conversion count << Shopify orders | Consent/blocking | Check consent mode and ad blockers |

## Common Follow-ups

- "How much did this cost me?" → calculate spend during days with broken tracking
- "Which tag is broken?" → outside Analyzify scope — suggest Google Tag Assistant or Analyzify dashboard
- "Is my PMax campaign wasting money?" → check PMax conversion count vs spend
- "How do I fix this?" → suggest checking Analyzify tracking setup in their dashboard
