# Playbook: Marketing Attribution

## Triggers

"Where do my orders come from?", "Attribution report", "First touch vs last touch", "Which campaigns drive sales?", "Channel attribution", "Which marketing channels work?", "New customer acquisition channels", "Show me campaign ROAS", "What's working in my marketing?", "Organic vs paid?"

## Strategy

**Primary:** Report API attribution queries — these combine Shopify order data with Analyzify's multi-touch tracking.

Three levels of attribution available:
1. **Purchase Attribution** — per-order level, shows each order's touchpoints
2. **Campaign Attribution** — aggregated by campaign name/source/medium
3. **Channel Attribution** — aggregated by marketing channel (Paid, Organic, etc.)

Start with campaign or channel attribution for overview. Drill into purchase attribution for order-level detail.

## Attribution Models

| Model | Use When | Description |
|-------|----------|-------------|
| `FIRST_TOUCH` | "How do people discover us?" | Credits the first interaction |
| `LAST_TOUCH` | "What closes the sale?" | Credits the final interaction |
| `LAST_NON_DIRECT` | Best default — "What marketing effort drove this?" | Credits last non-direct touchpoint |
| `LINEAR` | "Give every touch a share" | Equal credit across all touchpoints; adds up to the order value |
| `U_SHAPED` | "Credit discovery and the close" | 40% first, 40% last, 20% split across the middle; adds up to the order value |
| `ANY_CLICK` | "Which channels took part at all?" | Full order value to every touchpoint. Not additive: the total exceeds revenue, so never add these up or compare them with sales |

There is no `ALL` model. To compare models, run the report once per model and show them side by side.

**Analyzify vs Shopify attribution:** Analyzify tracks the full customer journey via UTM history (68%+ coverage). Shopify only tracks first and last touch natively. Always present Analyzify attribution as primary, Shopify as secondary/comparison.

## Queries

### 1. Campaign Attribution (most common ask)

```graphql
query($input: ShopifyCampaignAttributionInput!) {
  shopifyCampaignAttributionReport(input: $input) {
    nodes {
      campaignName source medium campaignType dated
      analyzifyTotalOrders analyzifyFirstTouchOrders analyzifyLastTouchOrders
      analyzifyRevenue analyzifyFirstTouchRevenue analyzifyLastNonDirectRevenue
      analyzifyNewCustomers analyzifyReturningCustomers
      shopifyTotalOrders shopifyRevenue
      averageOrderValue totalUniqueCustomers
      cost clicks impressions ctr cpc cpm roas cpa
    }
    totalCount totalPage currentPage
    summary {
      totalSales totalOrders
      analyzifyAttributedOrders analyzifyAttributedOrdersPercent
      analyzifyFirstTouchRevenue analyzifyFirstTouchRevenuePercent
      analyzifyLastNonDirectRevenue analyzifyLastNonDirectRevenuePercent
      averageOrderValue
    }
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
      "endDate": "2024-03-31"
    },
    "page": 1,
    "limit": 50,
    "attributionModel": "LAST_NON_DIRECT"
  }
}
```

### 2. Channel Attribution (high-level overview)

```graphql
query($input: ShopifyChannelAttributionInput!) {
  shopifyChannelAttributionReport(input: $input) {
    nodes {
      channelName channelType dated
      analyzifyTotalOrders analyzifyRevenue
      analyzifyNewCustomers analyzifyReturningCustomers
      shopifyTotalOrders shopifyRevenue
      averageOrderValue totalUniqueCustomers
      cost clicks impressions ctr cpc cpm roas cpa
    }
    totalCount totalPage currentPage
    summary {
      totalSales totalOrders paidChannels organicChannels
      analyzifyAttributedOrders analyzifyAttributedOrdersPercent
      averageOrderValue
    }
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
      "endDate": "2024-03-31"
    },
    "page": 1,
    "limit": 50,
    "attributionModel": "LAST_NON_DIRECT",
    "includeCampaigns": true
  }
}
```

### 3. Purchase Attribution (order-level detail)

```graphql
query($input: ShopifyPurchaseAttributionInput!) {
  shopifyPurchaseAttributionReport(input: $input) {
    nodes {
      orderId orderName orderDate orderAt customerId isNewCustomer
      total orderItemsCount
      analyzifyFirstTouchSource analyzifyFirstTouchMedium analyzifyFirstTouchCampaign
      analyzifyLastTouchSource analyzifyLastTouchMedium analyzifyLastTouchCampaign
      analyzifyLastNonDirectSource analyzifyLastNonDirectMedium analyzifyLastNonDirectCampaign
      shopifyFirstTouchSource shopifyFirstTouchMedium shopifyFirstTouchCampaign
      shopifyLastTouchSource shopifyLastTouchMedium shopifyLastTouchCampaign
    }
    totalCount totalPage currentPage
  }
}
```

### 4. Check Data Availability First

```graphql
query {
  shopifyAttributionDateRange(spaceId: "{{reportSpaceId}}") {
    activeRanges { startDate endDate daysCount }
    gaps { startDate endDate daysCount }
  }
}
```

Always check this first if attribution returns empty — data may not be available for the requested date range.

## Preset Filters

Use these to answer specific questions fast:

| Preset | Use When |
|--------|----------|
| `NEW_CUSTOMER_FIRST_TOUCH_ATTRIBUTION` | "How are we acquiring new customers?" |
| `RETURNING_CUSTOMER_LAST_TOUCH_ATTRIBUTION` | "What brings customers back?" |
| `HIGH_VALUE_ORDERS_UTM_TRACKED` | "Where do big orders come from?" |
| `ORGANIC_TRAFFIC_PURCHASES` | "How much comes from organic?" |
| `PAID_ACQUISITION_CONVERSIONS` | "How effective is paid marketing?" |
| `HIGH_VALUE_CAMPAIGNS` | Campaign revenue > $5000 + orders > 10 |
| `TOP_REVENUE_GENERATORS` | Top 20% campaigns by revenue |

## How to Present

### Channel Overview

| Channel | Orders | Revenue | New Customers | ROAS | CPA |
|---------|--------|---------|---------------|------|-----|
| Google Ads | X | $X | X | X.Xx | $X |
| Meta Ads | X | $X | X | X.Xx | $X |
| Organic Search | X | $X | X | — | — |
| Direct | X | $X | X | — | — |
| **Total** | **X** | **$X** | **X** | — | — |

### Campaign Breakdown

| Campaign | Source | Orders | Revenue | ROAS | CPA | New Customers |
|----------|--------|--------|---------|------|-----|---------------|
| Brand Search | google | X | $X | X.Xx | $X | X |
| Summer Sale | facebook | X | $X | X.Xx | $X | X |

### Attribution Comparison

| Model | Orders | Revenue |
|-------|--------|---------|
| First Touch | X | $X |
| Last Touch | X | $X |
| Last Non-Direct | X | $X |

## Common Follow-ups

- "Show me just paid channels" → add filter `channelType: "Paid"`
- "Which campaign acquires the most new customers?" → sort by `analyzifyNewCustomers DESC`
- "Show order-level detail for campaign X" → purchase attribution with `ANALYZIFY_ANY_CAMPAIGN` filter
- "Compare first touch vs last touch" → run same query with different `attributionModel`
