# Playbook: Conversion Rate Optimization (CRO)

## Triggers

"How do I improve my conversion rate?", "Why aren't people buying?", "Cart abandonment?", "Checkout drop-off?", "Bounce rate too high?", "Mobile conversion is low", "People add to cart but don't buy", "Funnel analysis", "Where am I losing customers?", "How to get more sales from existing traffic?"

## Strategy

CRO is the highest-leverage growth activity — doubling conversion rate is the same as doubling traffic but costs nothing. Diagnose the full funnel, identify the biggest leak, and suggest fixes.

**Query sequence:**

1. `ga4Scorecards` — overall conversion rate (purchases / sessions)
2. `ga4EcommFunnel` — step-by-step funnel (view → cart → checkout → purchase)
3. `ga4DeviceCategory` — mobile vs desktop sessions
4. `ga4LandingPages` — page-level bounce rates and conversion
5. `ga4Channels` — conversion rate by traffic channel
6. `ga4ReferralRevenue` — conversion by source/medium
7. `shopifyOrderAgg` — AOV context (is cart value a barrier?)

Run all with same date range. Run again with previous period for comparison.

## Queries

### 1. Overall Conversion Rate

```graphql
query($input: Ga4ScorecardsInput!) {
  ga4Scorecards(input: $input) {
    scorecards {
      dated metricsSessions metricsPurchases metricsRevenue metricsUsers
    }
    metricsSessionsPercentageDiff metricsPurchasesPercentageDiff
  }
}
```

Calculate: `conversionRate = purchases / sessions × 100`

Compare it with the store's own previous period and the same period last year. Conversion rates vary widely by category, price point, device mix and traffic source, so don't grade the store against a generic "Shopify average".

### 2. Funnel Analysis

```graphql
query($input: Ga4EcommFunnelInput!) {
  ga4EcommFunnel(input: $input) {
    eventName metricsEventCount
  }
}
```

With `groupByDate: false` for totals.

**Expected events:** `view_item`, `add_to_cart`, `begin_checkout`, `purchase`

### 3. Device Breakdown

```graphql
query($input: Ga4DeviceCategoryInput!) {
  ga4DeviceCategory(input: $input) {
    deviceName metricsCount
  }
}
```

Then run `ga4Scorecards` or `ga4Channels` to understand conversion by device (if the data allows segmenting).

### 4. Landing Page Performance

```graphql
query($input: Ga4LandingPageInput!) {
  ga4LandingPages(input: $input) {
    landingPage currencyCode
    metricsSessions metricsBounceRate
    metricsEcommPurchases metricsTotalRevenue
    metricsActiveUsers metricsNewUsers
  }
}
```

With `groupByDate: false` for page ranking. The result is a flat list of pages; add up sessions and purchases yourself for totals, and compute conversion rate as purchases / sessions per page.

### 5. Conversion by Channel

```graphql
query($input: Ga4ChannelInput!) {
  ga4Channels(input: $input) {
    channels {
      channelName metricsSessions metricsPurchases metricsRevenue metricsUsers
    }
    metricsTotalSessions metricsTotalPurchases
  }
}
```

With `groupByDate: false, groupByFields: ["channel_name"]`.

## How to Present

### Funnel Visualization

```
Sessions:       10,000 (100%)
  ↓
View Product:    4,500 (45% of sessions)
  ↓ ─── 55% never view a product (traffic quality or navigation issue)
Add to Cart:     1,200 (27% of viewers)
  ↓ ─── 73% view but don't add (pricing, photos, trust, or product-market fit)
Begin Checkout:    800 (67% of carts)
  ↓ ─── 33% abandon cart (shipping surprise, account required, complexity)
Purchase:          350 (44% of checkouts)
  ↓ ─── 56% abandon checkout (payment issues, final price shock, trust)

Overall Conversion: 3.5%
```

**Identify the biggest leak** — the step with the largest absolute drop. That's where to focus.

### Funnel Over Time

| Step | This period | Previous period | Same period last year |
|------|-------------|-----------------|-----------------------|
| Session → View Product | X% | X% | X% |
| View → Add to Cart | X% | X% | X% |
| Cart → Checkout | X% | X% | X% |
| Checkout → Purchase | X% | X% | X% |
| **Overall CVR** | **X%** | **X%** | **X%** |

Point out the step that changed most against the store's own history. A step that dropped suddenly (rather than slowly) often means something broke: a page, a payment method, or tracking.

### Device Comparison

| Device | Sessions | % of Traffic | Conv. Rate | Revenue Share |
|--------|----------|-------------|------------|---------------|
| Desktop | X | X% | X% | X% |
| Mobile | X | X% | X% | X% |
| Tablet | X | X% | X% | X% |

Flag if mobile CVR < 50% of desktop CVR — common issue, usually UX/speed related.

### Top Landing Pages (by conversion opportunity)

| Page | Sessions | Bounce Rate | Conv. Rate | Revenue | Fix Priority |
|------|----------|-------------|------------|---------|-------------|
| /collections/main | X | X% | X% | $X | |
| /products/top-seller | X | X% | X% | $X | |

Prioritize pages with: high traffic + high bounce rate OR high traffic + low conversion.

### Conversion by Channel

| Channel | Sessions | Purchases | Conv. Rate | Revenue/Session |
|---------|----------|-----------|------------|-----------------|
| Email | X | X | X% | $X |
| Organic Search | X | X | X% | $X |
| Paid Search | X | X | X% | $X |
| Paid Social | X | X | X% | $X |
| Direct | X | X | X% | $X |

### Diagnosis & Recommendations

Based on where the biggest funnel leak is:

**Low session → view product (< 40%):**
- Traffic quality issue — are ads sending the right audience?
- Homepage/collection page navigation may be confusing
- Site speed may be driving people away before they browse

**Low view → add to cart (< 20%):**
- Product pages need work: better photos, clearer pricing, reviews, size guides
- Price may be too high vs perceived value
- Missing trust signals (shipping info, returns policy, reviews)

**Low cart → checkout (< 55%):**
- Shipping cost surprise — show shipping earlier or offer free shipping threshold
- No guest checkout option
- Cart page doesn't build urgency

**Low checkout → purchase (< 40%):**
- Payment options too limited (add Shop Pay, Apple Pay, PayPal)
- Final price different from expected (taxes, duties)
- Security trust issue — missing trust badges

**Mobile-specific low conversion:**
- Test checkout flow on mobile — look for tiny buttons, slow loads, hard-to-fill forms
- Ensure product images load fast on mobile
- Simplify mobile navigation

## Common Follow-ups

- "How does mobile compare?" → device breakdown + channel by device
- "Which products have the worst conversion?" → `ga4ProductPerformances` sorted by views with low purchase rate
- "Show me the trend" → run funnel with `groupByDate: true, dateArgs: [{groupBy: WEEK}]`
- "What about cart abandonment emails?" → if Klaviyo is connected, show the abandoned-cart flow's results with `v2KlaviyoFlows` (`references/klaviyo.md`); Analyzify can't change the flow itself
- "Compare to last month" → run same queries with previous period dates
