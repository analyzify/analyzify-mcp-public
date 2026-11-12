# Playbook: Customer Insights & Segmentation

## Triggers

"New vs returning customers?", "Customer acquisition?", "Customer lifetime value?", "Repeat purchase rate?", "Customer segments?", "Who are my best customers?", "Audience segments?", "Customer cohorts?", "How many new customers?", "Customer retention?"

## Strategy

**Primary:** Report API
- `profitMerReport` — new customer count, new customer %, CAC, NCAC
- `shopifyCampaignAttributionReport` — new vs returning by marketing channel
- `shopifyPurchaseAttributionReport` — per-order new/returning flag
- `segments` / `segmentTemplates` — the store's segments and templates (definitions and counts; the customers inside a segment are not available)

**Fallback:** `shopifyProxy` for customer-level Shopify data.

## Queries

### 1. New vs Returning Customer Overview

Use `profitMerReport` with `groupByDate: true`:

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated
    orders newCustomers newCustomerPercentage
    aov cac ncac netRevenue
  }
}
```

### 2. New Customer Acquisition by Channel

Use campaign attribution filtered to new customers:

```graphql
query($input: ShopifyCampaignAttributionInput!) {
  shopifyCampaignAttributionReport(input: $input) {
    nodes {
      campaignName source medium
      analyzifyNewCustomers analyzifyReturningCustomers
      analyzifyRevenue averageOrderValue
      cost cpa roas
    }
    summary { totalOrders averageOrderValue }
  }
}
```

With `presetFilter: NEW_CUSTOMER_FIRST_TOUCH_ATTRIBUTION` to focus on first-touch channels.

### 3. Customer Segments

List available segments:
```graphql
query {
  segments(spaceId: "{{reportSpaceId}}") {
    id name description queryConfig stats createdAt
  }
}
```

Browse pre-built templates:
```graphql
query {
  segmentTemplates {
    id name description category icon useCase
  }
}
```

Categories: `LOYALTY`, `RETENTION`, `BEHAVIOR`

The customers inside a segment (names, e-mails) are not available through the assistant. Point the user to the Analyzify app for customer lists.

### 4. High-Value Orders (from attribution)

```graphql
query($input: ShopifyPurchaseAttributionInput!) {
  shopifyPurchaseAttributionReport(input: $input) {
    nodes {
      orderId orderName orderDate isNewCustomer total orderItemsCount
      analyzifyFirstTouchSource analyzifyFirstTouchCampaign
    }
    totalCount
  }
}
```

With `presetFilter: HIGH_VALUE_ORDERS_UTM_TRACKED`.

### 5. Customer Details (via Shopify Proxy)

For individual customer lookup — live proxy:

```graphql
{
  shopifyProxy(query: "{ customers(first: 10, query: \"email:customer@example.com\") { edges { node { id displayName email ordersCount totalSpentV2 { amount currencyCode } createdAt tags } } } }") {
    data errors
  }
}
```

## How to Present

### Customer Overview

| Metric | Value |
|--------|-------|
| Total Orders | X |
| New Customers | X (X% of total) |
| Returning Customers | X |
| Avg Order Value | $X |
| New Customer CAC | $X |
| Overall CAC | $X |

### Acquisition Channels for New Customers

| Channel | New Customers | Revenue | CAC |
|---------|--------------|---------|-----|
| Google Ads | X | $X | $X |
| Meta Ads | X | $X | $X |
| Organic | X | $X | — |
| Direct | X | $X | — |

### New vs Returning Trend

| Period | New | Returning | New % | AOV (New) | AOV (Returning) |
|--------|-----|-----------|-------|-----------|-----------------|
| Week 1 | X | X | X% | $X | $X |
| Week 2 | X | X | X% | $X | $X |

### LTV Estimation

While Analyzify doesn't calculate LTV directly, you can estimate from available data:
- **Avg Order Value** from `profitMerReport`
- **Repeat Rate** from new vs returning ratio
- **Simple LTV** = AOV × Average Orders per Customer

For more precise LTV, suggest the user check Shopify's customer analytics.

## Common Follow-ups

- "Which campaign acquires best customers?" → attribution with new customer filter, sorted by AOV
- "Show me repeat customers" → attribution with `RETURNING_CUSTOMER_LAST_TOUCH_ATTRIBUTION` preset
- "Create a high-value customer segment" → show the LOYALTY templates from segmentTemplates; creating the segment is done in the Analyzify app
- "Email list of customers who..." → not available through the assistant; point to the Analyzify app
