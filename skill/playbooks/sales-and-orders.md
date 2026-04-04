# Playbook: Sales, Orders & Products

## Triggers

"How many orders?", "Total sales?", "Average order value?", "Gross sales?", "Net sales?", "Returns?", "Refunds?", "Best selling products?", "Order details?", "Find order #1234", "Sales trend?", "Revenue by day?", "Discounts given?"

## Strategy

**Primary:** Report API
- `shopifyOrderAgg` for aggregated sales metrics
- `ga4ProductPerformances` for product-level data
- `shopifyOrders` for individual order lookup

**Fallback:** `shopifyProxy` via Main API for live Shopify Admin data (product catalog, inventory, etc.)

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
      orderLineItems { name sku quantity variantPrice }
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
  shopifyProxy(query: "{ products(first: 25, sortKey: BEST_SELLING) { edges { node { id title handle status totalInventory priceRangeV2 { maxVariantPrice { amount currencyCode } } } } } }") {
    data errors
  }
}
```

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
- **Net Payment** = What you actually collected
- **Gross Revenue** = Revenue after line item discounts

## Common Follow-ups

- "Show by week/month" → adjust `dateArgs: [{ groupBy: WEEK }]`
- "Which products have high views but low sales?" → GA4 product performance, sort by views, filter low purchase rate
- "Show me order #1234" → shopifyOrders with ORDER_NAME filter
- "What's my return rate?" → `totalReturnedQty / subTotalLineItemsQty × 100`
