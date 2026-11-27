# Playbook: Sales, Orders & Products

## Triggers

"How many orders?", "Total sales?", "Average order value?", "Gross sales?", "Net sales?", "Returns?", "Refunds?", "Best selling products?", "Order details?", "Find order #1234", "Sales trend?", "Revenue by day?", "Discounts given?"

## Strategy

**A period's sales and orders, or a change against another period:** the `performance_summary` tool first.

**Primary:** Report API
- `shopifyOrderAgg` for aggregated sales metrics
- `ga4ProductPerformances` for product-level data
- `shopifyOrders` for individual order lookup

**Fallback:** `shopifyProxy` via Main API for live Shopify Admin data (product catalog, inventory, etc.)

**GA4 and Search Console days not stored yet:** Analyzify's stored GA4 and Search Console data can stop a few days before today. When it stops before the end of the asked range (source_status gives the newest stored day), read the missing days live, at most 3 days: GA4 with `ga4Proxy` (`properties/{propertyID}:runReport`, `references/ga4.md`), Search Console with `gscProxy` (`searchAnalytics/query` with `"dataState": "all"`, `references/gsc.md`), for those days only. Label those figures "read live, provisional" and name the days. Google publishes Search Console data about 2 to 3 days late: a day with no rows in the live read is a day Google has not published yet, so name it as not published yet, never 0. With more than 3 days missing, or when source_status says the source is failing, read none live: name the missing days as not known yet, never 0.

## Queries

### 1. Sales Overview (aggregated)

```graphql
query($input: ShopifyOrderAggInput!) {
  shopifyOrderAgg(input: $input) {
    nodes {
      dated year quarter month week day
      totalCount
      totalSales grossSales netSales grossRevenue
      totalPrice currentTotalPrice
      totalDiscounts currentTotalDiscounts
      totalShipping currentTotalShipping
      totalTax currentTotalTax
      totalRefunded totalRefundedShipping
      netPayment
      averageOrderValue averageUnitsOrdered
      totalReturnedQty
      subTotalLineItemsQty currentSubTotalLineItemsQty
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
      "endDate": "2024-03-31",
      "groupByDate": true
    }
  }
}
```

### 2. Product Performance (GA4-based)

```graphql
query($input: Ga4ProductPerformanceInput!) {
  ga4ProductPerformances(input: $input) {
    products {
      itemName
      metricsItemsViewed metricsItemsAddedToCart
      metricsItemsPurchased metricsItemsRevenue
    }
    metricsTotalItemsViewed metricsTotalItemsAddedToCart
    metricsTotalItemsPurchased metricsTotalItemsRevenue
  }
}
```

Use `groupByFields: ["item_name"]` and `groupByDate: false` for product ranking.

### 3. Individual Order Lookup

```graphql
query($input: ShopifyOrderInput!) {
  shopifyOrders(input: $input) {
    nodes {
      id name orderAt currencyCode
      currentTotalPrice totalPrice totalDiscounts totalShipping totalTax
      statusFinancial statusFulfillment
      utmSource utmMedium utmCampaign
      finalSource finalUtmSource finalUtmMedium finalUtmCampaign
      billingCountry billingCity
      netPayment netSales
      orderLineItems { name sku quantity discountedTotal }
    }
    totalCount totalPage currentPage
  }
}
```

```json
{
  "input": {
    "default": {
      "spaceId": "{{reportSpaceId}}",
      "refId": "{{workspaceId}}",
      "startDate": "2024-01-01",
      "endDate": "2024-12-31"
    },
    "page": 1,
    "limit": 50,
    "filters": [
      { "field": "ORDER_NAME", "operator": "CONTAINS", "value": "1234" }
    ]
  }
}
```

### 4. Live Product Catalog (via Shopify proxy)

Use Main API when user asks about product details, inventory, collections:

```graphql
{
  shopifyProxy(query: "{ products(first: 25, sortKey: TITLE) { edges { node { id title handle status totalInventory priceRangeV2 { maxVariantPrice { amount currencyCode } } } } } }") {
    data errors
  }
}
```

The `products` query has no best-selling sort (only a collection's products can be sorted `BEST_SELLING`). For best sellers, add up the order line items above by `discountedTotal`, the line's own price after line-level discounts (discount codes, order-level discounts and returns are not taken off; tax included where prices include tax), never `quantity × variantPrice`: that is the catalog price, wrong for B2B price lists, draft orders and a price changed since. Where the store granted Analyzify `read_reports` (not granted by default; `currentAppInstallation { accessScopes { handle } }` lists it), Shopify's own net sales by product is one live read instead: `shopifyqlQuery(query: "FROM sales SHOW net_sales GROUP BY product_title SINCE -30d ORDER BY net_sales DESC LIMIT 10") { tableData { columns { name } rows } parseErrors }`; without it, add up the line items.

## How to Present

### Sales Dashboard

| Metric | This Period | vs Previous |
|--------|------------|-------------|
| Total Orders | X | +X% |
| Gross Sales | $X | +X% |
| Discounts | -$X | |
| Returns/Refunds | -$X | |
| **Net Sales** | **$X** | **+X%** |
| Shipping Revenue | $X | |
| Tax Collected | $X | |
| **Net Payment** | **$X** | |
| AOV | $X | +X% |
| Units per Order | X.X | |

### Product Rankings

| Product | Views | Add to Cart | Purchased | Revenue | Conversion |
|---------|-------|-------------|-----------|---------|------------|
| Product A | X | X | X | $X | X% |
| Product B | X | X | X | $X | X% |

Calculate conversion: `purchased / viewed × 100`
Highlight products with high views but low conversion (opportunity).

### Sales Breakdown

- **Gross Sales** = Original price before any deductions
- **Net Sales** = Gross - Discounts - Returns
- **Total Sales** = Net Sales + Shipping + Taxes + Duties + Fees, after returns (a live order's total is before returns)
- **Net Payment** = What you actually collected
- **Gross Revenue** = Revenue after line item discounts

## Common Follow-ups

- "Show by week/month" → adjust `dateArgs: [{ groupBy: WEEK }]`
- "Which products have high views but low sales?" → GA4 product performance, sort by views, filter low purchase rate
- "Show me order #1234" → shopifyOrders with ORDER_NAME filter
- "What's my return rate?" → `totalReturnedQty / subTotalLineItemsQty × 100`
