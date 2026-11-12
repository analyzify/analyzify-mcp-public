# Analytics Reports (Historical Data)

The Report API stores historical analytics data synced from all connected platforms. Use `execute_report_graphql` to run the queries below. `introspect_report_schema` can lag behind: if it doesn't list a query shown here (for example the `v2*`, Klaviyo or source-status queries), the query still works; run it as written.

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
- If `reportSpaceId` is null, Analyzify has no stored reports for this store yet: say so, and use the live reads instead

## Priority: Always Try Report API First

Report API queries are pre-aggregated in ClickHouse — they're fast and don't hit external rate limits. Only fall back to live proxies (ga4Proxy, gadsProxy, etc.) when the Report API doesn't have what the user needs (e.g., realtime data, data not yet synced).

## Read This First

- **For Google Ads, Meta and TikTok, use the `v2*` reports** (section "Marketing Reports (v2)" below). They return a `summary` with rates already computed from totals, plus `meta` that says how fresh and complete the data is.
- **Rates come from totals.** In the legacy ad reports, don't read a rate field (CTR, CPC, CPM, CPA, cost per conversion, conversion rate, frequency) from a row covering more than one day: compute it from the totals in the same row. When you combine rows, add up the totals first, then divide. For `profitMerReport`, see its section below.
- **Empty is not zero.** No rows, or zero spend, can mean the source isn't connected, its sync is failing, or the date range isn't synced yet. Check `v2MarketingSourceStatuses` (below) before saying "you spent nothing" or "no orders".
- **A failed read is not zero.** If a query returns errors, say the data couldn't be read and why. Never present a failed read as 0.
- **Say where a number came from:** stored report (synced daily) or live read, and up to which date.
- **Before calling anything "losing money"** or suggesting cuts, follow `references/judging-performance.md`.

### v2MarketingSourceStatuses — Is each source connected and current?

```graphql
query($input: V2MarketingSourceStatusesInput!) {
  v2MarketingSourceStatuses(input: $input) {
    statuses {
      source connected reportEnabled accountLabel currencyCode timezone
      freshness { connected status lastRunAt lastFailureAt failureMessage }
      coverage {
        firstAvailableDate latestAvailableDate availableDays missingDays
        gapRanges { startDate endDate }
        partialData staleData
      }
      warnings { code level message }
    }
  }
}
```

Variables: `{ "input": { "default": { "spaceId": "...", "startDate": "2024-01-01", "endDate": "2024-01-31" } } }`

Sources: `ga4`, `gads`, `meta`, `tiktok`, `shopify`, `sc`, `klaviyo`. `freshness.status` is usually `disconnected`, `syncing`, `failed` or `enabled` (also possible: `created`, `archived`).

**Use when:** a report comes back empty or low, before any "you spent nothing" or "no orders" answer, and before judging ad performance. Tell the user what you found: "Meta isn't connected", "Meta's sync has been failing since 30 Sep", or "Meta is connected and current, and there was no spend".

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
    dated landingPage currencyCode
    metricsActiveUsers metricsNewUsers metricsTotalUsers metricsSessions
    metricsEventCount metricsEcommPurchases metricsTotalRevenue metricsBounceRate
  }
}
```

Returns a flat list of rows (no totals object). Add up the rows yourself for totals.

**Use when:** "Top landing pages?", "Which pages have highest bounce rate?"
**Note:** over a multi-day range, `metricsBounceRate` is a plain average of the daily rates, not weighted by sessions. Treat it as approximate.

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

## Marketing Reports (v2) — Preferred for Google Ads, Meta and TikTok

Every `v2*` report takes `{ "input": { "default": StandardQueryInput, "comparison": StandardQueryInput } }` (comparison is optional: give it the previous period to get both in one call) and returns:

- `summary`: totals for the whole range, with rates computed from those totals. Use these for "overall" answers.
- `rows`: one row per campaign (or product, or day). Rates in each row are computed from that row's totals.
- `meta`: `currencyCode`, `freshness` and `coverage` (latest synced date, gaps, `partialData`, `staleData`). Mention a gap or stale data in your answer.
- `comparison`: the same `summary` and `rows` for the comparison range.

Units in `v2*` reports: `cost` and `spend` are in the account currency (no micros). `ctr`, `cvr` and `linkCtr` are percentages (2.5 means 2.5%). `roas` = conversion value / cost. `cpa` = cost / conversions.

Variables:
```json
{
  "input": {
    "default": { "spaceId": "...", "startDate": "2024-02-01", "endDate": "2024-02-29", "groupByDate": false },
    "comparison": { "spaceId": "...", "startDate": "2024-01-01", "endDate": "2024-01-31", "groupByDate": false }
  }
}
```

### v2GadsCustomerMetrics — Google Ads account totals and daily trend

```graphql
query($input: V2GadsCustomerMetricsInput!) {
  v2GadsCustomerMetrics(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks cost conversions conversionValue allConversions allConversionValue ctr cpc cpa roas cvr }
    rows { dated impressions clicks cost conversions conversionValue ctr cpc cpa roas }
    comparison { summary { cost conversions conversionValue cpa roas } }
  }
}
```

**Use when:** "How are my Google Ads doing?", "Total ad spend?", "Overall ROAS?", daily trend of spend or conversions.

### v2GadsCampaigns — Google Ads by campaign

```graphql
query($input: V2GadsCampaignsInput!) {
  v2GadsCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks cost conversions conversionValue ctr cpc cpa roas }
    rows { campaignId campaignName campaignType impressions clicks cost conversions conversionValue ctr cpc cpa roas }
    comparison { rows { campaignId cost conversions conversionValue cpa roas } }
  }
}
```

Use `groupByDate: false`. Rows are one per campaign over the whole range. `campaignType` is a label such as Search, Shopping or Performance Max.

**Use when:** "Which campaigns perform best?", "Campaign spend breakdown?", "CPA by campaign?"

### v2GadsProducts — Google Ads by product (item) (paginated)

```graphql
query($input: V2GadsProductsInput!) {
  v2GadsProducts(input: $input) {
    meta { currencyCode coverage { latestAvailableDate partialData staleData } }
    summary { impressions clicks cost conversions conversionValue ctr cpc cvr cpa roas }
    rows { itemId productTitle impressions clicks cost conversions conversionValue ctr cpc cvr cpa roas }
    pageInfo { page limit totalCount totalPages hasNextPage }
  }
}
```

Variables:
```json
{
  "input": {
    "default": { "spaceId": "...", "startDate": "...", "endDate": "...", "groupByDate": false, "groupByFields": ["item_id", "product_title"] },
    "sort": [{ "field": "COST", "direction": "DESC" }],
    "limit": 250,
    "page": 1
  }
}
```

- Without `groupByFields`, rows are one per item **per campaign** (`item_id`, `product_title`, `campaign_name`), and `pageInfo.totalCount` counts those item × campaign rows, not items. Use `groupByFields: ["item_id", "product_title"]` (exactly these names) for one row per item; then leave out `campaignId` and `campaignName` (they would show one arbitrary campaign).
- With that grouping, `pageInfo.totalCount` counts every item stored for the range, including items with no impressions or spend. An item whose title changed in the range can appear twice (once per title). For "how many products had spend", use the live count in `references/gads.md` ("Products (items) over a period").
- An item is a variant, not a product. To answer "by product", follow the roll-up recipe in `playbooks/product-optimization.md`.
- `limit` defaults to 20 and must be 1000 or less (a larger value quietly falls back to 20). Check `pageInfo.totalCount` before saying "these are all your products".
- Also accepts `search`, `filters` and `presetFilter` (see the legacy product report below).

**Use when:** "Which products get the most ad spend?", "Product ROAS?", "Results by product?"

### v2GadsConversionActions — Conversion actions and when each last fired

```graphql
query($input: V2GadsConversionActionsInput!) {
  v2GadsConversionActions(input: $input) {
    summary { trackedActionCount primaryGoalActionCount allConversions allConversionValue }
    rows { conversionAction categoryName primaryForGoal allConversions allConversionValue lastSeen }
  }
}
```

**Use when:** "Is conversion tracking working?", "Which actions count as conversions?", before judging any campaign.

### v2MetaCampaigns / v2MetaAccountMetrics — Meta

```graphql
query($input: V2MetaCampaignsInput!) {
  v2MetaCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks linkClicks spend purchases purchaseValue ctr linkCtr cpc cpm cpa roas }
    rows { campaignId campaignName impressions clicks linkClicks spend purchases purchaseValue ctr linkCtr cpc cpm cpa roas }
  }
}
```

`v2MetaAccountMetrics(input: V2MetaAccountMetricsInput!)` has the same `meta`, a `summary { impressions clicks spend reach purchases purchaseValue linkClicks cpc cpm ctr frequency cvr cpa }` (no `roas`: compute `purchaseValue / spend`) and daily `rows { dated impressions clicks spend reach purchases purchaseValue cpc cpm ctr frequency cvr cpa }`.

**Reach and frequency over more than one day:** `reach` is the sum of daily reach, so it overstates the people reached; `frequency` is impressions / that sum, roughly the average daily frequency. Use them for trends, not as "people reached this month".

**Use when:** "How are my Meta ads doing?", "Meta ROAS?", "Which Meta campaigns perform best?"

### v2TiktokCampaigns / v2TiktokAdvertiserMetrics — TikTok

```graphql
query($input: V2TiktokCampaignsInput!) {
  v2TiktokCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate missingDays partialData staleData } freshness { status lastFailureAt } }
    summary { impressions clicks spend conversions ctr cpc cvr cpm cpa }
    rows { campaignId campaignName impressions clicks spend conversions ctr cpc cvr cpm cpa }
  }
}
```

`v2TiktokAdvertiserMetrics(input: V2TiktokAdvertiserMetricsInput!)` gives the same per day (`rows { dated ... }`). TikTok reports conversions but no conversion value, so there is no TikTok ROAS here.

**Use when:** "How are my TikTok ads doing?", "TikTok CPA?"

### Klaviyo (email and SMS)

See `references/klaviyo.md`.

---

## Google Ads Reports (legacy)

Prefer the `v2*` reports above. Use these legacy reports for what v2 doesn't have: search terms, per-campaign daily history, and PMax by network per campaign. **Their rate fields are wrong over multi-day rows**, so the examples below leave them out: compute rates from the totals.

### gadsCustomerMetrics — Account-level performance

```graphql
query($input: GadsCustomerMetricsInput!) {
  gadsCustomerMetrics(input: $input) {
    dated year quarter month week day
    optimizationScore
    metricsImpressions metricsClicks
    metricsCostMicros
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
    metricsEngagements
  }
}
```

**Use when:** daily account history (prefer `v2GadsCustomerMetrics`).
**Note:** `metricsCostMicros` must be divided by 1,000,000 for actual cost.

### gadsCampaignsPerformance — Campaign breakdown

```graphql
query($input: GadsCampaignsPerformanceInput!) {
  gadsCampaignsPerformance(input: $input) {
    dated year quarter month week day
    id name advertising_channel_type
    metricsImpressions metricsClicks
    metricsCostMicros
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
  }
}
```

**Use when:** per-campaign history by day (prefer `v2GadsCampaigns`). `advertising_channel_type` is a number (2 = Search, 3 = Display, 4 = Shopping, 10 = Performance Max…); `v2GadsCampaigns` gives the label.

### gadsSearchTermViews — Search term performance

```graphql
query($input: GadsSearchTermViewsInput!) {
  gadsSearchTermViews(input: $input) {
    dated searchTerm
    metricsImpressions metricsClicks
    metricsCostMicros
    metricsConversions metricsConversionsValue
    metricsAllConversions metricsAllConversionsValue
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
      metricsImpressions metricsClicks
      metricsCostMicros
      metricsConversions metricsConversionsValue
    }
    aggregates {
      totalCost totalImpressions totalClicks totalConversions
      totalConversionValue avgCpa avgRoas avgConversionRate
    }
    totalCount hasMore currentPage totalPages
  }
}
```

Variables include: `limit`, `offset`, `page`, `sort` (`{ field: COST, direction: DESC }`), `filters`, `presetFilter`. Prefer `v2GadsProducts`.

`aggregates` are computed from totals and are safe to read. Node rate fields are not.

**Preset filters:** `HIGHER_COST_LOWER_ROAS` (spend above the range's average and ROAS below 1), `LOWER_COST_LOWER_ROAS`, `UNDERPERFORMERS` (spend above average, under 1 conversion), `HIGH_PERFORMERS`, `HIGH_CPC_LOW_CTR`, `LOW_CPA_HIGH_CVR`. ROAS 1 is not the store's break-even, so these presets give a list to look at, never a verdict (see `references/judging-performance.md`).

**Use when:** "Which products perform best in ads?", "High spend low ROAS products?"

### gadsPmaxChannelPerformance — Performance Max channel breakdown (paginated)

```graphql
query($input: GadsPmaxChannelPerformanceInput!) {
  gadsPmaxChannelPerformance(input: $input) {
    nodes {
      dated campaignId campaignName adNetworkType
      metricsClicks metricsImpressions metricsCostMicros
      metricsConversions metricsConversionsValue
    }
    aggregates {
      totalCost totalImpressions totalClicks totalConversions
      totalConversionValue avgCtr avgCpc
    }
    totalCount hasMore currentPage totalPages
  }
}
```

**Use when:** "How is Performance Max doing?", "PMax channel breakdown?" (or `v2GadsPmaxChannels` for totals per network)

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

## Meta/Facebook Ads Reports (legacy)

Prefer `v2MetaCampaigns` and `v2MetaAccountMetrics` above. Rate fields here (`cpc`, `cpm`, `ctr`, `frequency`) are added up across days, so the examples leave them out: compute rates from the totals.

All Meta queries use `FbInput` with `default: StandardQueryInput!` plus optional `limit`, `offset`, `page`.

### fbAccountInsights — Account-level metrics

```graphql
query($input: FbInput!) {
  fbAccountInsights(input: $input) {
    dated year quarter month week day
    adAccountId objective
    impressions clicks spend reach uniqueClicks
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
    impressions clicks spend reach uniqueClicks
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
      impressions clicks spend purchases linkClicks
    }
    aggregates {
      totalSpend totalImpressions totalClicks totalPurchases totalLinkClicks
    }
    totalCount hasMore currentPage totalPages
  }
}
```

**Use when:** "Which products perform best on Facebook ads?"
**Note:** `productId` is Meta's catalogue ID, not the Shopify product ID, and this report has no purchase value, so no product ROAS.

---

## TikTok Ads Reports (legacy)

Prefer `v2TiktokCampaigns` and `v2TiktokAdvertiserMetrics` above. Rate fields here (`cpc`, `ctr`, `cvr`, `cpm`, `cpa`) are added up across days, so the examples leave them out.

### tiktokAdvertiserInsights — Account-level metrics

```graphql
query($input: TiktokInput!) {
  tiktokAdvertiserInsights(input: $input) {
    dated year quarter month week day
    advertiserId impressions clicks spend conversion
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
    impressions clicks spend conversion
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
Attribution models: `FIRST_TOUCH`, `LAST_TOUCH`, `LAST_NON_DIRECT`, `LINEAR` (equal credit across touchpoints), `U_SHAPED` (40% first, 40% last, 20% split across the middle), `ANY_CLICK` (full order value to every touchpoint: not additive, the sum exceeds revenue). There is no `ALL` model; to compare models, run the report once per model.

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
      campaigns { campaignName source medium shopifyTotalOrders shopifyRevenue analyzifyTotalOrders analyzifyRevenue cost }
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
    newCustomers newCustomerPercentage totalCustomers
    cpa ncac cac cvr adClicks
    adSpendComplete incompleteAdSources incompleteAdSpendDays
  }
}
```

**Use when:** "What's my profit?", "MER?", "Customer acquisition cost?", "Ad spend breakdown?"

This is the **most valuable report** — it combines data from Shopify orders + Google Ads + Meta + TikTok into a single profitability view.

**Key metrics explained:**
- `mer` = Marketing Efficiency Ratio (Revenue / Total Ad Spend)
- `cac` = Customer Acquisition Cost (Total Ad Spend / customers who ordered, `totalCustomers`)
- `ncac` = New Customer Acquisition Cost (Total Ad Spend / `newCustomers`)
- `cvr` = orders / ad clicks × 100, a **percentage**
- `cpa` = Cost Per Acquisition (Total Spend / Total Orders)
- `aov` = Average Order Value
- `grossMargin` = (Revenue - COGS) / Revenue × 100, a **percentage** (40 means 40%)

**Rows are one per day**, whatever `groupByDate` says, or one per calendar month with `groupByFields: ["month"]`. On a monthly row every ratio is computed from the month's totals. For any other period, **add up the rows** (`netRevenue`, `grossProfit`, `costOfGoodsSold`, `totalAdSpend` and each platform's spend, `orders`, `newCustomers`, `totalCustomers`, `adClicks`), then compute: MER = `netRevenue / totalAdSpend`, margin = `grossProfit / netRevenue`, AOV = `netRevenue / orders`, CPA = `totalAdSpend / orders`, NCAC = `totalAdSpend / newCustomers`, CAC = `totalAdSpend / totalCustomers`, CVR = `orders / adClicks × 100`. Never average daily ratios. `totalCustomers` counts customers per day, so summed over days a customer who ordered on two days counts twice. Dates must be `YYYY-MM-DD`. The newest day comes first, and at most 1,000 days are returned.

**Provisional days:** `adSpendComplete: false` means the ad spend of the sources in `incompleteAdSources` may not have synced yet for that row (today and up to two days before, in UTC). Its net profit may be too high: say so, or end the period before those days. On a monthly row the five ad ratios leave those days out while `netProfit` and `totalAdSpend` include them. `true` does not prove older days are complete: check `v2MarketingSourceStatuses` for the period. Only days with Shopify orders or refunds are in the report, so ad spend on a day with neither is not counted.

**Missing product costs:** a product without a cost in Shopify counts as zero COGS, so gross profit and margin come out too high. If `costOfGoodsSold` is 0 or very low, say so and ask the merchant for their margin.

---

## Segments

You can list segments and their templates. The customers inside a segment are not available through the assistant, and you cannot create, change, delete or sync a segment: for those, point the user to the Analyzify app.

### segments — List all segments

```graphql
query {
  segments(spaceId: "...") {
    id name description queryConfig stats createdAt updatedAt
  }
}
```

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
