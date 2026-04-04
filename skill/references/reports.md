# Analytics Reports (Historical Data)

The Report API stores historical analytics data synced from all connected platforms. Use `introspect_report_schema` to discover queries and `execute_report_graphql` to run them.

Authentication is handled automatically — a report token is fetched before each request.

## Tools

- **Discover queries**: `introspect_report_schema` (search by keyword)
- **Get full schema**: `report_schema_full`
- **Execute queries**: `execute_report_graphql`

## Standard Query Input

Almost every report query wraps its input in a `default` field using `StandardQueryInput`:

```graphql
input StandardQueryInput {
  spaceId: String!        # From extMe.reportSpaceId
  refId: String           # From extMe.workspaceId
  taskId: String          # Channel-specific task ID (from introspection)
  startDate: String       # YYYY-MM-DD
  endDate: String         # YYYY-MM-DD
  groupByDate: Boolean    # Group results by date period
  groupByFields: [String] # Fields to aggregate by (e.g., ["channel_name"])
  orderByFields: [String] # Sort (e.g., ["clicks desc"])
  dateArgs: [DateArgs]    # Calendar grouping
}

input DateArgs {
  groupBy: Calendar       # YEAR | MONTH | QUARTER | WEEK | DAY
  orderBy: SortDirection  # ASC | DESC
}
```

**Key IDs from extMe:**
- `reportSpaceId` → use as `spaceId`
- `workspaceId` → use as `refId`
- If `reportSpaceId` is null, call `reportSpaceToken` mutation first via `execute_graphql`

## Priority: Always Try Report API First

Report API queries are pre-aggregated in ClickHouse — they're fast and don't hit external rate limits. Only fall back to live proxies (ga4Proxy, gadsProxy, etc.) when the Report API doesn't have what the user needs (e.g., realtime data, data not yet synced).

---

## GA4 Reports

### ga4Scorecards — Key ecommerce metrics

```graphql
query($input: Ga4ScorecardsInput!) {
  ga4Scorecards(input: $input) {
    scorecards {
      dated year quarter month week day
      currencyCode
      metricsAddToCart metricsPurchases metricsSessions
      metricsRevenue metricsUsers metricsTransactions
    }
    metricsAddToCartPercentageDiff metricsPurchasesPercentageDiff
    metricsSessionsPercentageDiff metricsRevenuePercentageDiff
    metricsUsersPercentageDiff metricsTransactionsPercentageDiff
  }
}
```

Variables:
```json
{
  "input": {
    "default": {
      "spaceId": "...", "refId": "...", "taskId": "...",
      "startDate": "2024-01-01", "endDate": "2024-01-31",
      "groupByDate": true
    }
  }
}
```

**Use when:** "What's my revenue?", "How many sessions?", "Conversion rate?", "Compare this month vs last month"
**Percentage diffs** compare current period vs previous period automatically.

### ga4Channels — Traffic by channel

```graphql
query($input: Ga4ChannelInput!) {
  ga4Channels(input: $input) {
    channels {
      dated year quarter month week day
      channelName currencyCode
      metricsPurchases metricsSessions metricsRevenue metricsUsers
    }
    currencyCode metricsTotalPurchases metricsTotalSessions
    metricsTotalRevenue metricsTotalUsers
  }
}
```

**Use when:** "Where is my traffic coming from?", "Organic vs paid?", "Which channel converts best?"
**groupByFields:** `["channel_name"]` to group by channel

### ga4ProductPerformances — Product-level ecommerce

```graphql
query($input: Ga4ProductPerformanceInput!) {
  ga4ProductPerformances(input: $input) {
    products {
      dated itemName
      metricsItemsViewed metricsItemsAddedToCart
      metricsItemsPurchased metricsItemsRevenue
    }
    metricsTotalItemsViewed metricsTotalItemsAddedToCart
    metricsTotalItemsPurchased metricsTotalItemsRevenue
  }
}
```

**Use when:** "Top selling products?", "Which products get viewed but not purchased?"
**groupByFields:** `["item_name"]`

### ga4EcommFunnel — Conversion funnel

```graphql
query($input: Ga4EcommFunnelInput!) {
  ga4EcommFunnel(input: $input) {
    dated eventName metricsEventCount
  }
}
```

**Use when:** "What's my funnel?", "Drop-off between add to cart and purchase?"
**Events:** view_item → add_to_cart → begin_checkout → purchase

### ga4ReferralRevenue — Traffic source attribution

```graphql
query($input: Ga4ReferralRevenueInput!) {
  ga4ReferralRevenue(input: $input) {
    dated sessionSource sessionMedium currencyCode
    metricsEcommPurchases metricsSessions metricsRevenue metricsUsers
  }
}
```

**Use when:** "Which referral sources drive revenue?", "Traffic by source/medium?"

### ga4LandingPages — Landing page performance

```graphql
query($input: Ga4LandingPageInput!) {
  ga4LandingPages(input: $input) {
    landingPages {
      dated landingPage currencyCode
      metricsActiveUsers metricsNewUsers metricsTotalUsers metricsSessions
      metricsEventCount metricsEcommPurchases metricsTotalRevenue metricsBounceRate
    }
    currencyCode metricsTotalActiveUsers metricsTotalNewUsers metricsTotalUsers
    metricsTotalSessions metricsTotalEventCount metricsTotalEcommPurchases
    metricsTotalRevenue metricsAverageBounceRate
  }
}
```

**Use when:** "Top landing pages?", "Which pages have highest bounce rate?"

### ga4DeviceCategory — Device breakdown

```graphql
query($input: Ga4DeviceCategoryInput!) {
  ga4DeviceCategory(input: $input) {
    dated deviceName metricsCount
  }
}
```

**Use when:** "Mobile vs desktop?", "Device breakdown?"

### ga4404Pages — 404 error tracking

```graphql
query($input: Ga4404PagesInput!) {
  ga4404Pages(input: $input) {
    pages {
      dated landingPage pagePath sessionSourceMedium
      metricsSessions metricsTotalUsers metricsEventCount
    }
    metricsTotalSessions metricsTotalUsers metricsTotalEventCount
  }
}
```

**Use when:** "Any broken pages?", "404 errors?"

---

## Google Ads Reports

### gadsCustomerMetrics — Account-level performance

```graphql
query($input: GadsCustomerMetricsInput!) {
  gadsCustomerMetrics(input: $input) {
    dated year quarter month week day
    optimizationScore
    metricsImpressions metricsClicks metricsCtr
    metricsCostMicros metricsAverageCpc metricsAverageCost
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
    metricsCostPerConversion metricsCostPerAllConversions
    metricsEngagementRate metricsEngagements
  }
}
```

**Use when:** "How are my ads performing?", "Total ad spend?", "Overall ROAS?"
**Note:** `metricsCostMicros` must be divided by 1,000,000 for actual cost.

### gadsCampaignsPerformance — Campaign breakdown

```graphql
query($input: GadsCampaignsPerformanceInput!) {
  gadsCampaignsPerformance(input: $input) {
    dated year quarter month week day
    id name advertisingChannelType
    metricsImpressions metricsClicks metricsCtr
    metricsCostMicros metricsAverageCpc
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
    metricsCostPerConversion
  }
}
```

**Use when:** "Which campaigns perform best?", "Campaign spend breakdown?"

### gadsSearchTermViews — Search term performance

```graphql
query($input: GadsSearchTermViewsInput!) {
  gadsSearchTermViews(input: $input) {
    dated searchTerm
    metricsImpressions metricsClicks metricsCtr
    metricsCostMicros metricsAverageCpc
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
    metricsCostPerConversion
  }
}
```

**Use when:** "What search terms trigger my ads?", "Top keywords?"

### gadsProductPerformance — Shopping product performance (paginated)

```graphql
query($input: GadsProductPerformanceInput!) {
  gadsProductPerformance(input: $input) {
    nodes {
      dated itemId productTitle campaignId campaignName
      metricsImpressions metricsClicks metricsCtr
      metricsCostMicros metricsAverageCpc
      metricsConversions metricsConversionsValue
      metricsConversionsFromInteractionsRate
      metricsCostPerConversion
    }
    aggregates {
      totalCost totalImpressions totalClicks totalConversions
      totalConversionValue avgCpa avgRoas avgConversionRate
    }
    totalCount hasMore currentPage totalPages
  }
}
```

Variables include: `limit`, `offset`, `page`, `sort` (`{ field: COST, direction: DESC }`), `filters`, `presetFilter`

**Preset filters:** `HIGHER_COST_LOWER_ROAS`, `HIGH_PERFORMERS`, `UNDERPERFORMERS`, `HIGH_CPC_LOW_CTR`, `LOW_CPA_HIGH_CVR`

**Use when:** "Which products perform best in ads?", "High spend low ROAS products?"

### gadsPmaxChannelPerformance — Performance Max channel breakdown (paginated)

```graphql
query($input: GadsPmaxChannelPerformanceInput!) {
  gadsPmaxChannelPerformance(input: $input) {
    nodes {
      dated campaignId campaignName adNetworkType
      metricsClicks metricsImpressions metricsCostMicros
      metricsConversions metricsConversionsValue metricsCtr metricsAverageCpc
    }
    aggregates {
      totalCost totalImpressions totalClicks totalConversions
      totalConversionValue avgCtr avgCpc
    }
    totalCount hasMore currentPage totalPages
  }
}
```

**Use when:** "How is Performance Max doing?", "PMax channel breakdown?"

### gadsConversions — Conversion actions

```graphql
query($input: GadsConversionsInput!) {
  gadsConversions(input: $input) {
    dated id name categoryId primaryForGoal
    metricsAllConversionsValue metricsAllConversions
  }
}
```

### gadsLastSeenConversions — Last conversion dates

```graphql
query($input: GadsLastConversionsInput!) {
  gadsLastSeenConversions(input: $input) {
    name ctype categoryId metricsConversionLastConversionDate
  }
}
```

**Use when:** "Conversion health check?", "When was the last conversion?"

---

## Meta/Facebook Ads Reports

All Meta queries use `FbInput` with `default: StandardQueryInput!` plus optional `limit`, `offset`, `page`.

### fbAccountInsights — Account-level metrics

```graphql
query($input: FbInput!) {
  fbAccountInsights(input: $input) {
    dated year quarter month week day
    adAccountId objective
    impressions clicks spend reach cpc cpm ctr frequency uniqueClicks
  }
}
```

**Use when:** "How are my Facebook ads doing?", "Meta ad spend?"

### fbCampaignInsights — Campaign breakdown

```graphql
query($input: FbInput!) {
  fbCampaignInsights(input: $input) {
    dated year quarter month week day
    adAccountId campaignId campaignName objective
    impressions clicks spend reach cpc cpm ctr frequency uniqueClicks
  }
}
```

**Use when:** "Which Meta campaigns perform best?"

### fbAccountActions / fbCampaignActions — Action events

```graphql
query($input: FbInput!) {
  fbAccountActions(input: $input) {
    dated adAccountId actionType value
  }
}
```

**Action types:** page_engagement, post_engagement, link_click, purchase, add_to_cart, etc.

### fbAccountActionValues / fbCampaignActionsValues — Action monetary values

```graphql
query($input: FbInput!) {
  fbAccountActionValues(input: $input) {
    dated adAccountId actionType value
  }
}
```

**Use when:** "Revenue from Facebook ads?", "Purchase value by campaign?"

### fbProductPerformance — Product-level Meta ads (paginated)

```graphql
query($input: FbInput!) {
  fbProductPerformance(input: $input) {
    nodes {
      dated productId productName
      impressions clicks spend purchases linkClicks cpc ctr
    }
    aggregates {
      totalSpend totalImpressions totalClicks totalPurchases totalLinkClicks avgCpc avgCtr
    }
    totalCount hasMore currentPage totalPages
  }
}
```

**Use when:** "Which products perform best on Facebook ads?"

---

## TikTok Ads Reports

### tiktokAdvertiserInsights — Account-level metrics

```graphql
query($input: TiktokInput!) {
  tiktokAdvertiserInsights(input: $input) {
    dated year quarter month week day
    advertiserId impressions clicks spend cpc ctr cvr cpm conversion cpa
  }
}
```

**Use when:** "How are my TikTok ads doing?"

### tiktokCampaignInsights — Campaign breakdown

```graphql
query($input: TiktokInput!) {
  tiktokCampaignInsights(input: $input) {
    dated year quarter month week day
    advertiserId campaignId campaignName
    impressions clicks spend cpc ctr cvr cpm conversion cpa
  }
}
```

**Use when:** "Which TikTok campaigns perform best?"

---

## Shopify Reports

### shopifyOrderAgg — Aggregated order metrics

```graphql
query($input: ShopifyOrderAggInput!) {
  shopifyOrderAgg(input: $input) {
    nodes {
      dated year quarter month week day
      totalCount
      currentSubTotalPrice currentTotalPrice currentTotalDiscounts
      currentTotalShipping currentTotalTax
      subTotalPrice totalPrice totalDiscounts totalReceived
      totalRefunded totalRefundedShipping totalShipping totalTax
      netPayment netSales totalSales grossSales grossRevenue
      averageOrderValue averageUnitsOrdered
      totalLineItemDiscount totalLineItemOriginalPrice totalLineItemTax
      currentSubTotalLineItemsQty subTotalLineItemsQty
      totalReturnedQty
    }
  }
}
```

**Use when:** "Total sales?", "Average order value?", "Gross vs net sales?", "Returns?"

**Key calculated metrics:**
- `averageOrderValue` = revenue / orders
- `grossSales` = original price before discounts
- `netSales` = total after discounts and returns
- `netPayment` = what actually collected

### shopifyOrders — Individual order list (paginated)

```graphql
query($input: ShopifyOrderInput!) {
  shopifyOrders(input: $input) {
    nodes {
      id name orderAt currencyCode
      currentTotalPrice totalPrice totalDiscounts totalShipping totalTax
      statusFinancial statusFulfillment
      utmSource utmMedium utmCampaign
      fvSource fvUtmSource fvUtmMedium fvUtmCampaign
      lvSource lvUtmSource lvUtmMedium lvUtmCampaign
      finalSource finalUtmSource finalUtmMedium finalUtmCampaign
      billingCountry billingCity
      netPayment netSales
      orderLineItems { name sku quantity variantPrice }
    }
    totalCount totalPage currentPage
  }
}
```

Variables: `page: 1, limit: 50`
Filters: `[{ field: ORDER_NAME, operator: CONTAINS, value: "1234" }]`

**Use when:** "Show recent orders", "Find order #1234"

### shopifyPurchaseAttributionReport — Order-level attribution (paginated)

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

Variables: `page: 1, limit: 50`
Sort: `{ field: ORDER_AT, direction: DESC }`
Preset filters: `NEW_CUSTOMER_FIRST_TOUCH_ATTRIBUTION`, `HIGH_VALUE_ORDERS_UTM_TRACKED`, `ORGANIC_TRAFFIC_PURCHASES`, `PAID_ACQUISITION_CONVERSIONS`

**Use when:** "Where do my orders come from?", "First touch vs last touch attribution?"

### shopifyCampaignAttributionReport — Campaign-level attribution (paginated)

```graphql
query($input: ShopifyCampaignAttributionInput!) {
  shopifyCampaignAttributionReport(input: $input) {
    nodes {
      campaignName source medium dated campaignType
      shopifyTotalOrders shopifyFirstTouchOrders shopifyLastTouchOrders
      shopifyRevenue shopifyNewCustomers shopifyReturningCustomers
      analyzifyTotalOrders analyzifyFirstTouchOrders analyzifyLastTouchOrders
      analyzifyFirstTouchRevenue analyzifyLastNonDirectRevenue analyzifyRevenue
      analyzifyNewCustomers analyzifyReturningCustomers
      averageOrderValue totalUniqueCustomers sessions
      cost clicks impressions ctr cpc cpm roas cpa
    }
    totalCount totalPage currentPage
    summary {
      totalSales totalOrders
      analyzifyAttributedOrders analyzifyAttributedOrdersPercent
      analyzifyFirstTouchRevenue analyzifyFirstTouchRevenuePercent
      analyzifyLastNonDirectRevenue analyzifyLastNonDirectRevenuePercent
      shopifyAttributedOrders shopifyAttributedOrdersPercent
      averageOrderValue
    }
  }
}
```

Variables: `page: 1, limit: 50, attributionModel: LAST_NON_DIRECT`
Attribution models: `FIRST_TOUCH`, `LAST_TOUCH`, `LAST_NON_DIRECT`, `ALL`

**Use when:** "Campaign attribution?", "Which campaigns drive new customers?"

### shopifyChannelAttributionReport — Channel-level attribution (paginated)

```graphql
query($input: ShopifyChannelAttributionInput!) {
  shopifyChannelAttributionReport(input: $input) {
    nodes {
      channelName channelType dated
      shopifyTotalOrders shopifyRevenue shopifyNewCustomers shopifyReturningCustomers
      analyzifyTotalOrders analyzifyRevenue analyzifyNewCustomers analyzifyReturningCustomers
      averageOrderValue totalUniqueCustomers sessions
      cost clicks impressions ctr cpc cpm roas cpa
      campaigns { campaignName source medium ... }
    }
    totalCount totalPage currentPage
    summary {
      totalSales totalOrders paidChannels organicChannels
      analyzifyAttributedOrders analyzifyAttributedOrdersPercent
      shopifyAttributedOrders shopifyAttributedOrdersPercent
      averageOrderValue
    }
  }
}
```

Variables: `page: 1, limit: 50, includeCampaigns: true`

**Use when:** "Channel attribution?", "Paid vs organic channels?"

### shopifyAttributionDateRange — Data availability

```graphql
query {
  shopifyAttributionDateRange(spaceId: "...") {
    activeRanges { startDate endDate daysCount }
    gaps { startDate endDate daysCount }
  }
}
```

**Use when:** Need to know what date range has attribution data available.

---

## Search Console Reports

### scTraffics — Search query performance

```graphql
query($input: ScTrafficInput!) {
  scTraffics(input: $input) {
    dated year quarter month week day
    queried urlId countryIso3 deviceId
    clicks impressions ctr position
  }
}
```

**groupByFields options:** `["queried"]`, `["url_id"]`, `["country_iso3"]`, `["device_id"]`
**orderByFields:** `["clicks desc"]`, `["impressions desc"]`, `["position asc"]`

**Use when:** "Top search queries?", "Which pages rank?", "Search performance by country?"

### scAnalytics — Aggregated search analytics

```graphql
query($input: ScAnalyticInput!) {
  scAnalytics(input: $input) {
    dated year quarter month week day
    clicks impressions ctr position
  }
}
```

**Use when:** "Overall search traffic trend?", "Clicks and impressions over time?"

---

## Profit & MER Report (Cross-Platform)

### profitMerReport — Combined profitability analysis

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated year quarter month week day
    netRevenue netProfit currency
    googleAdsSpend metaAdsSpend tiktokAdsSpend totalAdSpend
    costOfGoodsSold shippingCost
    mer grossProfit grossMargin
    orders aov
    newCustomers newCustomerPercentage
    cpa ncac cac cvr
  }
}
```

**Use when:** "What's my profit?", "MER?", "Customer acquisition cost?", "Ad spend breakdown?"

This is the **most valuable report** — it combines data from Shopify orders + Google Ads + Meta + TikTok into a single profitability view.

**Key metrics explained:**
- `mer` = Marketing Efficiency Ratio (Revenue / Total Ad Spend)
- `cac` = Customer Acquisition Cost (Total Spend / New Customers)
- `ncac` = New Customer Acquisition Cost
- `cpa` = Cost Per Acquisition (Total Spend / Total Orders)
- `aov` = Average Order Value
- `grossMargin` = (Revenue - COGS) / Revenue

---

## Segments

### segments — List all segments

```graphql
query {
  segments(spaceId: "...") {
    id name description queryConfig stats createdAt updatedAt
  }
}
```

### executeSegmentQuery — Run a segment query

```graphql
query($input: SegmentQueryInput!) {
  executeSegmentQuery(input: $input) {
    columns { name displayName dataType }
    rows
    totals
    totalCount hasMore query
  }
}
```

Variables: `{ "input": { "spaceId": "...", "query": { ... } } }`

### segmentTemplates — Pre-built segment templates

```graphql
query {
  segmentTemplates {
    id name description category icon query useCase
  }
}
```

Categories: `LOYALTY`, `RETENTION`, `BEHAVIOR`

---

## Frontend Report Slug Mapping

The frontend uses these slugs for report detail pages (`/reports/:channel/:slug`):

| Channel | Slug | Maps to Query |
|---------|------|---------------|
| ga4 | channels | ga4Channels |
| ga4 | products | ga4ProductPerformances |
| ga4 | referrals | ga4ReferralRevenue |
| ga4 | sessions | ga4Scorecards |
| ga4 | not-found-pages | ga4404Pages |
| gads | campaigns | gadsCampaignsPerformance |
| gads | cost | gadsCustomerMetrics |
| gads | conversions | gadsConversions |
| gads | conversion-health | gadsLastSeenConversions |
| gads | pmax-channel-breakdown | gadsPmaxChannelPerformance |
| meta | campaigns | fbCampaignInsights |
| meta | clicks | fbAccountInsights (clicks focus) |
| meta | cost | fbAccountInsights (spend focus) |
| meta | purchases | fbAccountActions (purchase type) |
| tiktok | campaigns | tiktokCampaignInsights |
| tiktok | clicks | tiktokAdvertiserInsights (clicks focus) |
| tiktok | cost | tiktokAdvertiserInsights (spend focus) |
| tiktok | conversions | tiktokAdvertiserInsights (conversion focus) |
| sc | pages | scTraffics (groupBy: url_id) |
| sc | queries | scTraffics (groupBy: queried) |
| sc | clicks | scAnalytics |
| shopify | total-orders | shopifyOrderAgg (totalCount) |
| shopify | total-sales | shopifyOrderAgg (totalSales) |
| shopify | gross-sales | shopifyOrderAgg (grossSales) |
| shopify | average-order | shopifyOrderAgg (averageOrderValue) |
| shopify | net-profit | profitMerReport (netProfit) |

## Notes

- Date format is always `YYYY-MM-DD`
- Use the store's timezone from extMe (`shopifyIanaTimezone`) when interpreting relative dates like "this week" or "last month"
- Google Ads `metricsCostMicros` must be divided by 1,000,000 for actual dollar amount
- Paginated queries accept `page`, `limit` (and sometimes `offset`)
- `groupByDate: true` returns time-series data; `false` returns totals
- When user asks for trends/charts, use `groupByDate: true` with `dateArgs: [{ groupBy: DAY }]`
- When user asks for totals/summaries, use `groupByDate: false`
