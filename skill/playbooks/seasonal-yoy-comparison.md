# Playbook: Seasonal & Year-over-Year Comparison

## Triggers

"Compare to last year", "Year over year?", "YoY growth?", "Same period last year?", "How did BFCM compare?", "Am I on track for the year?", "Seasonal trends?", "When is my peak season?", "How does this quarter compare?", "Holiday planning", "Is this normal for this time of year?", "Monthly growth rate?"

## Strategy

Business owners need historical context — is a dip seasonal or a real problem? Is growth accelerating or decelerating? Use the same report queries but with strategic date ranges.

**Key principle:** Always compare equal-length periods. When doing YoY, match the exact number of days.

## Date Range Patterns

| Comparison | Current Period | Previous Period |
|-----------|---------------|-----------------|
| Week over week | Last 7 days | 7 days before that |
| Month over month | This month | Last month |
| Year over year | Mar 1-31 this year | Mar 1-31 last year |
| Quarter over quarter | Q1 this year | Q1 last year (or Q4 last year) |
| BFCM comparison | Nov 24-27 this year | Nov 24-27 last year |
| Holiday season | Nov 1 - Dec 31 | Same dates last year |

Use the store's timezone (`shopifyIanaTimezone`) for day boundaries.

## Queries

### 1. Revenue & Profit YoY

Run `profitMerReport` for both periods:

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated year month
    netRevenue netProfit orders aov
    googleAdsSpend metaAdsSpend tiktokAdsSpend totalAdSpend
    mer grossMargin
    newCustomers newCustomerPercentage
    cpa cac
  }
}
```

Run twice with current year dates and last year dates.

For monthly grouping, use `groupByFields: ["month"]` only within one calendar year (it groups by month number and would merge the same month of two years). Otherwise add up the daily rows per month yourself. Rows are one per day by default: add them up for each period's totals, then compute ratios from the sums.

### 2. Traffic YoY

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

### 3. Channel Mix YoY

Run `ga4Channels` for both periods:

```graphql
query($input: Ga4ChannelInput!) {
  ga4Channels(input: $input) {
    channels {
      channelName metricsSessions metricsPurchases metricsRevenue
    }
  }
}
```

### 4. Monthly Trend (Full Year View)

Run `profitMerReport` for the last 12 months and add up the daily rows per calendar month (don't use `groupByFields: ["month"]` here: a 12-month range crosses a year boundary, and month-number grouping would merge the same month of both years):

```json
{
  "input": {
    "default": {
      "spaceId": "...", "refId": "...",
      "startDate": "2023-04-01",
      "endDate": "2024-03-31",
      "groupByFields": ["month"]
    }
  }
}
```

## How to Present

### Year-over-Year Summary

| Metric | This Year | Last Year | Change | Growth Rate |
|--------|-----------|-----------|--------|-------------|
| Revenue | $X | $X | +$X | +X% |
| Orders | X | X | +X | +X% |
| AOV | $X | $X | +$X | +X% |
| Sessions | X | X | +X | +X% |
| Conversion Rate | X% | X% | +Xpp | |
| Ad Spend | $X | $X | +$X | +X% |
| MER | X.Xx | X.Xx | | |
| Net Profit | $X | $X | +$X | +X% |
| New Customers | X | X | +X | +X% |

### Monthly Trend (12-Month View)

| Month | Revenue | Orders | AOV | Ad Spend | Profit |
|-------|---------|--------|-----|----------|--------|
| Apr 2023 | $X | X | $X | $X | $X |
| May 2023 | $X | X | $X | $X | $X |
| ... | ... | ... | ... | ... | ... |
| Mar 2024 | $X | X | $X | $X | $X |

Highlight:
- **Peak months** (highest revenue)
- **Growth trend** (accelerating or decelerating)
- **Seasonal patterns** (do the same months spike every year?)

### Channel Mix Shift

| Channel | Revenue (This Year) | % | Revenue (Last Year) | % | Shift |
|---------|--------------------|----|--------------------|----|-------|
| Organic | $X | X% | $X | X% | +Xpp |
| Paid Search | $X | X% | $X | X% | -Xpp |
| Paid Social | $X | X% | $X | X% | +Xpp |
| Email | $X | X% | $X | X% | +Xpp |

### Growth Rate Tracking

| Period | Revenue | MoM Growth | YoY Growth |
|--------|---------|-----------|------------|
| Jan | $X | +X% | +X% |
| Feb | $X | +X% | +X% |
| Mar | $X | +X% | +X% |

**On-track calculation:** If annual target is $X, and we're Y months in with $Z revenue, run rate = $Z / Y × 12.

### Seasonal Planning Insights

After analyzing 12+ months of data:

- "Your peak months are historically [X, Y] — plan inventory and ad budgets 4-6 weeks ahead"
- "Revenue typically dips X% in [month] — this is normal, not a crisis"
- "Your YoY growth rate is X% — at this pace you'll hit $X by year end"
- "BFCM accounted for X% of annual revenue last year — start planning by [date]"

## Common Follow-ups

- "Am I on track to hit $X this year?" → calculate run rate from YTD revenue
- "When should I start BFCM ads?" → look at when traffic spikes started in previous years
- "Is this seasonal or a real decline?" → compare same month last year
- "Quarter over quarter?" → adjust date ranges to quarter boundaries
- "Show me just Q4 last year vs this year" → specific date range comparison
