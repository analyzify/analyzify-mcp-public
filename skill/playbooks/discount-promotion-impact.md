# Playbook: Discount & Promotion Impact Analysis

## Triggers

"Are my discounts working?", "Promotion impact?", "Did the sale help?", "Discount analysis", "Are we giving away too much margin?", "Coupon performance?", "Should I run a sale?", "How did the promotion do?", "Discount vs full price?", "Am I discounting too much?", "Flash sale results?"

## Strategy

Business owners run promotions constantly but rarely measure whether they actually increase profit or just cannibalize full-price sales. Compare promotion periods vs non-promotion periods using order and revenue data.

**Queries to run:**

1. `shopifyOrderAgg` — has `totalDiscounts`, `grossSales`, `netSales`, `averageOrderValue`, `totalCount`
2. `profitMerReport` — net profit including ad spend during promotion
3. `ga4Scorecards` — traffic and conversion during vs before promotion
4. `ga4EcommFunnel` — did the promotion improve funnel conversion?

## Queries

### 1. Sales Metrics During Promotion vs Before

Run `shopifyOrderAgg` for two periods — promotion period and same-length period before:

```graphql
query($input: ShopifyOrderAggInput!) {
  shopifyOrderAgg(input: $input) {
    nodes {
      dated
      totalCount
      grossSales totalSales netSales
      totalDiscounts currentTotalDiscounts
      averageOrderValue
      totalPrice currentTotalPrice
      subTotalLineItemsQty currentSubTotalLineItemsQty
      averageUnitsOrdered
      netPayment
    }
  }
}
```

Run with `groupByDate: true` to see daily trend through the promotion.

### 2. Profit Impact

Run `profitMerReport` for both periods:

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated
    netRevenue netProfit grossProfit grossMargin
    orders aov
    totalAdSpend googleAdsSpend metaAdsSpend
    newCustomers newCustomerPercentage
    mer cpa
    adSpendComplete incompleteAdSources
  }
}
```

### 3. Traffic & Conversion Impact

Run `ga4Scorecards` for both periods:

```graphql
query($input: Ga4ScorecardsInput!) {
  ga4Scorecards(input: $input) {
    scorecards {
      dated metricsSessions metricsUsers metricsPurchases metricsRevenue
    }
  }
}
```

### 4. Funnel Impact

Run `ga4EcommFunnel` for both periods to see if the promotion improved any funnel step:

```graphql
query($input: Ga4EcommFunnelInput!) {
  ga4EcommFunnel(input: $input) {
    eventName metricsEventCount
  }
}
```

## How to Present

### Promotion Scorecard

| Metric | During Promo | Before Promo | Change | Verdict |
|--------|-------------|-------------|--------|---------|
| Revenue | $X | $X | +X% | |
| Orders | X | X | +X% | |
| AOV | $X | $X | -X% | |
| Discounts Given | $X | $X | +X% | |
| Gross Margin | X% | X% | -Xpp | |
| **Net Profit** | **$X** | **$X** | **+X%** | |
| Sessions | X | X | +X% | |
| Conversion Rate | X% | X% | +Xpp | |
| Units per Order | X.X | X.X | +X% | |
| New Customers | X | X | +X% | |
| Ad Spend | $X | $X | +X% | |

### The Real Question: Was It Profitable?

Calculate promotion effectiveness:

```
Incremental Revenue = Promo Revenue - Baseline Revenue (pre-promo average)
Discount Cost = Total Discounts Given
Extra Ad Spend = Promo Ad Spend - Baseline Ad Spend
Incremental Profit = Incremental Revenue - Discount Cost - Extra Ad Spend - COGS on incremental orders
```

| | Amount |
|---|-------|
| Incremental Revenue (above baseline) | +$X |
| − Discount Cost | -$X |
| − Extra Ad Spend | -$X |
| − COGS on Extra Orders | -$X |
| **= Incremental Profit from Promo** | **$X** |

If negative: "The promotion generated more revenue but less profit — the discounts cost more than the extra sales earned."

If positive: "The promotion was profitable — it drove enough extra volume to offset the margin hit."

### Discount Depth Analysis

From `shopifyOrderAgg`:

```
Average Discount per Order = totalDiscounts / totalCount
Discount as % of Gross = totalDiscounts / grossSales × 100
```

| Metric | This promotion | Comparable period without a promotion |
|--------|----------------|----------------------------------------|
| Avg Discount per Order | $X | $X |
| Discount % of Gross | X% | X% |
| Revenue Lift vs Pre-Promo | +X% | — |

Revenue lift needed to keep gross profit flat = discount ÷ (margin − discount), with both as shares of price (for example a 10% discount at a 40% margin needs about 33% more sales). Use the store's own margin and say which you used.

### Customer Quality Check

| Metric | Promo Customers | Non-Promo Customers |
|--------|----------------|-------------------|
| New Customer % | X% | X% |
| AOV | $X | $X |

Point out if the promotion brought mostly new customers with a lower AOV. Whether they come back is a separate question: check their repeat orders after 60–90 days before calling them low-value.

### Daily Trend Through Promotion

| Date | Orders | Revenue | Discounts | Net Revenue | Conv. Rate |
|------|--------|---------|-----------|-------------|------------|
| Day 1 (launch) | X | $X | $X | $X | X% |
| Day 2 | X | $X | $X | $X | X% |
| Day 3 | X | $X | $X | $X | X% |
| ... | | | | | |
| Day after end | X | $X | $X | $X | X% |

Show the "hangover effect": did sales drop below the baseline after the promotion ended? That can mean demand was pulled forward rather than created; say "can mean", since seasonality or other campaigns may also explain it.

### What the Data Shows

State the findings, compared with a baseline period of the same length without a promotion, and let the merchant decide what to do next:

- **Profit:** "Gross profit in the promotion period was $X, against $X in the baseline period" (after discounts and product cost; say if product costs are missing).
- **Volume vs margin:** "Revenue rose X% while the average discount was X%; at your margin, sales needed to rise about X% to keep gross profit flat."
- **Basket:** "AOV was $X during the promotion, against $X before."
- **Customers:** "X% of promotion orders were from new customers, against X% normally."
- **After the end:** "Daily sales in the week after were X% below / above the baseline."

The baseline is a comparison, not proof of what would have happened without the promotion: seasonality, ads and stock changes also move sales. If the merchant asks what to try next, list the usual options (a shallower discount, a gift or free shipping, a minimum order value, targeting existing customers) with what each would need to be true, and ask what they know about their goal for the promotion.

## Common Follow-ups

- "What's the right discount amount?" → compare different promo periods and their ROI
- "Free shipping vs percentage off?" → compare order data from different promo types
- "Did we get new customers or just existing ones buying earlier?" → check newCustomerPercentage
- "How long did the lift last?" → daily trend showing decay after promo ends
- "Should I discount this product?" → check product-specific margin from product optimization playbook
