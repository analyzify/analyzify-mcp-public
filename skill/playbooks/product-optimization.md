# Playbook: Product Performance & Optimization

## Triggers

"Best selling products?", "Worst performing products?", "Which products should I promote?", "Product conversion rate?", "Products with high views but low sales?", "What should I advertise?", "Dead stock?", "Product performance?", "Which products to discount?", "Product trends?", "What's selling?"

## Strategy

Combine GA4 product data (views → cart → purchase funnel) with Shopify order data and ad platform product performance to give a full picture.

**Queries to run:**

1. `ga4ProductPerformances` — view/cart/purchase funnel per product
2. `shopifyOrderAgg` — revenue and order metrics
3. `gadsProductPerformance` — Google Shopping/PMax product performance (if connected)
4. `fbProductPerformance` — Meta dynamic ads product performance (if connected)

## Queries

### 1. Product Funnel (GA4)

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

With `groupByDate: false, groupByFields: ["item_name"]`.

### 2. Google Ads Product Performance (paginated)

```graphql
query($input: GadsProductPerformanceInput!) {
  gadsProductPerformance(input: $input) {
    nodes {
      itemId productTitle campaignName
      metricsImpressions metricsClicks metricsCtr
      metricsCostMicros metricsConversions metricsConversionsValue
      metricsAverageCpc metricsCostPerConversion
    }
    aggregates {
      totalCost totalImpressions totalClicks totalConversions
      totalConversionValue avgCpa avgRoas avgConversionRate
    }
    totalCount currentPage totalPages
  }
}
```

### 3. Meta Product Performance (paginated)

```graphql
query($input: FbInput!) {
  fbProductPerformance(input: $input) {
    nodes {
      productId productName
      impressions clicks spend purchases linkClicks cpc ctr
    }
    aggregates {
      totalSpend totalImpressions totalClicks totalPurchases avgCpc avgCtr
    }
    totalCount currentPage totalPages
  }
}
```

## How to Present

### Product Rankings (Top Sellers)

| Product | Views | Add to Cart | Purchased | Revenue | Cart Rate | Buy Rate |
|---------|-------|-------------|-----------|---------|-----------|----------|
| Product A | X | X | X | $X | X% | X% |
| Product B | X | X | X | $X | X% | X% |

Calculate:
- **Cart Rate** = Add to Cart / Views × 100
- **Buy Rate** = Purchased / Views × 100

### Hidden Gems (High Views, Low Sales)

Filter products where `views > median` AND `buyRate < median`:

| Product | Views | Cart Rate | Buy Rate | Opportunity |
|---------|-------|-----------|----------|-------------|
| Product X | 500 | 2% | 0.5% | Low cart rate — pricing/photo issue? |
| Product Y | 300 | 8% | 1% | People cart but don't buy — checkout friction? |

### Ad Product Performance (Cross-Platform)

| Product | Platform | Spend | Revenue | ROAS | CPA |
|---------|----------|-------|---------|------|-----|
| Product A | Google | $X | $X | X.Xx | $X |
| Product A | Meta | $X | $X | X.Xx | $X |
| Product B | Google | $X | $X | X.Xx | $X |

### Products Wasting Ad Spend

Use preset filter `HIGHER_COST_LOWER_ROAS` for Google Ads:

| Product | Spend | Revenue | ROAS | Action |
|---------|-------|---------|------|--------|
| Product X | $500 | $100 | 0.2x | Pause or reduce bid |
| Product Y | $300 | $150 | 0.5x | Review landing page |

### Recommendations Framework

After analyzing product data, categorize products:

**Stars** (high revenue, high margin, growing): Increase ad spend, expand to more channels
**Cash Cows** (high revenue, steady): Maintain current strategy, don't over-discount
**Question Marks** (high views/interest, low conversion): Fix product page, test pricing, improve photos
**Dogs** (low revenue, high ad spend, declining): Reduce ad spend, consider discontinuing or heavy discount to clear

## Common Follow-ups

- "Show me just Google Shopping products" → `gadsProductPerformance`
- "Which products should I run ads on?" → high organic conversion + not yet advertised
- "Product trends over time" → GA4 products with `groupByDate: true`
- "What's this product's details?" → `shopifyProxy` for inventory, variants, descriptions
