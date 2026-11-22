# Playbook: Marketing Attribution

## Triggers

"Where do my orders come from?", "Which channels bring the most orders?", "Attribution report", "First touch vs last touch", "Which campaigns drive sales?", "Channel attribution", "Which marketing channels work?", "New customer acquisition channels", "What's working in my marketing?", "Organic vs paid?"

A platform's ROAS, spend or cost per conversion by campaign is not here: see `playbooks/ad-performance.md`.

**Which channels bring the most orders: the `channel_breakdown` tool first.** Its "Orders by channel" block gives Analyzify's attributed orders per channel (last non-direct click), next to each platform's spend and ROAS, in one call. Rank from it and name the model. When the answer has no Orders by channel block (an older connector), use the channel attribution query below with `attributionModel: "LAST_NON_DIRECT"` and the filter `INCLUDE_DIRECT_TRAFFIC` (below): without it the report leaves out the orders with no channel, so its totals are not the store's orders. The queries below are also for another model, campaigns and single orders (for campaigns add `"includeCampaigns": true`; it is slow on a long list of channels).

## Strategy

**Primary:** Report API attribution queries — these combine Shopify order data with Analyzify's multi-touch tracking.

Three levels of attribution available:
1. **Purchase Attribution** — per-order level, shows each order's touchpoints
2. **Campaign Attribution** — aggregated by campaign name/source/medium
3. **Channel Attribution** — aggregated by marketing channel (Paid, Organic, etc.)

Start with campaign or channel attribution for overview. Drill into purchase attribution for order-level detail.

**No ad-platform figures here.** The attribution reports carry Shopify's orders, revenue and customers by campaign or channel, and Analyzify's attribution of them. They do not carry ad spend: `cost`, `clicks`, `impressions`, `ctr`, `cpc`, `cpm`, `roas`, `cpa`, `sessions` and (campaign report) `campaignType` come back empty (`v2ShopifyChannelAttribution` gives 0), and a filter or sort on them is refused. For spend, ROAS and cost per conversion by channel use the `channel_breakdown` tool; by campaign, the ad platforms' campaign reports (`v2GadsCampaigns`, `v2MetaCampaigns`, `v2TiktokCampaigns`; `playbooks/ad-performance.md`).

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
      campaignName source medium dated
      analyzifyTotalOrders analyzifyFirstTouchOrders analyzifyLastTouchOrders
      analyzifyRevenue analyzifyFirstTouchRevenue analyzifyLastNonDirectRevenue
      analyzifyNewCustomers analyzifyReturningCustomers
      shopifyTotalOrders shopifyRevenue
      averageOrderValue totalUniqueCustomers
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
    "filters": [{ "field": "INCLUDE_DIRECT_TRAFFIC", "operator": "EQ", "value": "true" }],
    "sort": [{ "field": "ANALYZIFY_TOTAL_ORDERS", "direction": "DESC" }]
  }
}
```

With direct orders included and a single-touch model (`LAST_NON_DIRECT`, `LAST_TOUCH`, `FIRST_TOUCH`), the summary's `totalOrders` is every order and a `DIRECT` row holds the orders with no channel: direct visits, returns from a payment page (PayPal, Klarna) and orders with no tracked visit (POS, draft, subscription). Never call them all direct visits. The orders credited to a channel are `totalOrders` minus the `DIRECT` row, at most the other rows' sum (an order with no campaign is on no row: say so), not `summary.analyzifyAttributedOrders`, which counts by another rule. The multi-touch models (`LINEAR`, `U_SHAPED`, `ANY_CLICK`) never have a `DIRECT` row: there, never read the summary's total as credited orders. Meta's orders can sit on Facebook, Instagram and Meta rows. A channel is a name and a type (Google paid and Google organic are two rows), and `OTHER` is every source Analyzify did not recognise, not one channel. `analyzifyRevenue` is order totals (with tax and shipping, before returns), not net sales.

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

| Channel | Orders | Revenue | New Customers |
|---------|--------|---------|---------------|
| Google Ads | X | $X | X |
| Meta Ads | X | $X | X |
| Organic Search | X | $X | X |
| No channel (Analyzify's Direct) | X | $X | X |
| **Total** | **X** | **$X** | **X** |

Orders and revenue are Analyzify's attribution of Shopify orders under the model you ran; name the model. For spend, ROAS or cost per conversion next to them, take each platform's own figures from `channel_breakdown` and show them as the platform's numbers, in their own columns or a second table. Never divide Analyzify's attributed order totals by a platform's spend as its ROAS, or a platform's spend by attributed orders as its cost per order.

### Campaign Breakdown

| Campaign | Source | Orders | Revenue | New Customers |
|----------|--------|--------|---------|---------------|
| Brand Search | google | X | $X | X |
| Summer Sale | facebook | X | $X | X |

For a campaign's spend, ROAS or cost per conversion, read the platform's campaign report (`v2GadsCampaigns`, `v2MetaCampaigns`, `v2TiktokCampaigns`) and match by campaign name; say the two come from different sources.

### Attribution Comparison

| Model | Orders | Revenue |
|-------|--------|---------|
| First Touch | X | $X |
| Last Touch | X | $X |
| Last Non-Direct | X | $X |

## Common Follow-ups

- "Show me just paid channels" → add the filter `{ "field": "CHANNEL_TYPE", "operator": "EQ", "value": "paid" }`
- "Which campaign acquires the most new customers?" → sort by `analyzifyNewCustomers DESC`
- "Show order-level detail for campaign X" → purchase attribution with `ANALYZIFY_ANY_CAMPAIGN` filter
- "Compare first touch vs last touch" → run same query with different `attributionModel`
