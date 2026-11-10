# Playbook: Product Performance & Optimization

## Triggers

"Best selling products?", "Worst performing products?", "Which products should I promote?", "Product conversion rate?", "Products with high views but low sales?", "What should I advertise?", "Dead stock?", "Product performance?", "Which products to discount?", "Product trends?", "What's selling?"

## Strategy

Combine GA4 product data (views → cart → purchase funnel) with Shopify order data and ad platform product performance to give a full picture.

**Queries to run:**

1. `ga4ProductPerformances` — view/cart/purchase funnel per product
2. `shopifyOrderAgg` — revenue and order metrics
3. `v2GadsProducts` — Google Shopping/PMax performance per item (variant), if connected
4. `v2MetaProducts` — Meta catalogue ads per product (spend and purchases, no purchase value), if connected

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

One row per item. An item is usually a **variant**, not a product. `limit` must be 1000 or less (a larger value quietly falls back to 20).

### 3. Meta Product Performance (paginated)

```graphql
query($input: V2MetaProductsInput!) {
  v2MetaProducts(input: $input) {
    summary { impressions clicks spend purchases cpa }
    rows { productId productName impressions clicks spend purchases cpa }
    pageInfo { page totalCount totalPages hasNextPage }
  }
}
```

`productId` is Meta's catalogue ID, not Shopify's. There is no purchase value, so no ROAS per product on Meta.

### 4. Google Ads Results by Product (roll-up recipe)

Google Ads reports items (variants) and has no "parent product" field. To answer "which products…" for Google Ads, roll the variants up yourself. Don't page through the whole Shopify catalogue (that takes 40–200 calls on a large store) and don't try a bulk export (the file can't be read in a chat).

1. **Top items by spend.** Run query 2 sorted by `COST` descending with `limit: 250`. Most stores' spend sits in the first 250–1,000 items; stop when the remaining items' spend is small, and say how much of total spend (`summary.cost`) your list covers.
2. **Read the item IDs.**
   - `shopify_<country>_<productId>_<variantId>` (Shopify's Google & YouTube app): the product ID is already in the item ID. Skip step 3.
   - A bare number: it is the Shopify variant ID. Go to step 3.
   - Anything else (SKUs, custom IDs): the feed uses its own IDs. Don't match on titles. Tell the merchant and ask how their feed IDs map to products.
3. **Look up the variants, 250 per call** (Shopify's limit for `nodes`), via `execute_graphql`:

```graphql
query($vars: JSON) { shopifyProxy(query: "query($ids: [ID!]!) { nodes(ids: $ids) { ... on ProductVariant { id sku title product { id title status } } } }", variables: $vars) { data errors } }
```

Variables: `{ "vars": { "ids": ["gid://shopify/ProductVariant/41234567890", "..."] } }`

   A `null` node means the variant no longer exists in Shopify (deleted). Keep its spend in an "unknown or deleted variants" line instead of dropping it.
4. **Add up per product:** sum cost, clicks, impressions, conversions and conversion value over the product's variants. Then compute ROAS = value / cost, CPA = cost / conversions and CTR = clicks / impressions from those sums. Never add or average the per-variant rates. The same product in Shopping and Performance Max is summed together.

500 items take 2 lookup calls; 2,000 items take 8.

**Present:** product, number of variants with spend, spend, conversions, conversion value, ROAS, plus a line on coverage: "These 40 products cover 92% of Google Ads spend in the period."

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
| Product A | Meta | $X | — | — | $X |
| Product B | Google | $X | $X | X.Xx | $X |

Google rows are per product only after the roll-up (recipe 4). Meta reports purchases per product but no purchase value, so show CPA there, not ROAS.

### Products and Ad Spend ("which products lose money on ads?")

Follow `references/judging-performance.md`, with these product-specific rules:

- **Unit:** the product, with its variants added up (recipe 4 above), never a single variant.
- **Windows:** two settled windows of 90 days each (the latest ending 8 days before today). A store with less history: say how many days are missing.
- **No sale:** a product with spend and zero conversions in **both** windows is worth listing only if its spend would have bought two to three sales at the account's cost per conversion. Then check Shopify: if it sold through other channels, list it apart as "sells, but not through its ads".
- **Below break-even:** below the store's break-even ROAS in both windows, separately, with at least one sale. Show the largest gaps first, at most 20.
- **Leave out:** products first advertised less than 60 days ago, products on promotion, and out-of-stock products (that is a different finding: "ads on products you can't sell").
- **Churn as counts, not a list:** "40 products dropped below break-even last quarter and 25 went back above it". Most move back on their own.
- **Never a long-tail total as the headline** ("2,000 spent on products that never sold" adds up hundreds of tiny amounts that each mean nothing).
- **Limits line:** "Google credits the whole order to the clicked product. A product here may be the way in to larger baskets."

The preset filters (`HIGHER_COST_LOWER_ROAS`, `UNDERPERFORMERS`) compare with ROAS 1 over one range. Use them only to find products to check, never as the answer.

| Product | Variants | Spend (both windows) | Conversions | ROAS (window 1 / window 2) | Break-even |
|---------|----------|----------------------|-------------|----------------------------|------------|
| Product X | 4 | $X | X | 1.8x / 2.1x | 3.1x |

Name the usual levers without choosing one: "a separate feed label or a lower-bid product group are the usual ways to handle this; review the product first".

### Product Groups

Describe products by what the data shows, not by labels such as "dogs" or "stars":

- **Sells well, steady:** high revenue over both windows.
- **Interest without sales:** many views, low add-to-cart or purchase rate (look at the product page, price, photos).
- **Ad spend without sales:** see the section above, with its checks.

Don't suggest discontinuing a product or clearing it at a discount from ad data alone; that depends on stock, margin and the range, which the merchant knows.

## Common Follow-ups

- "Show me just Google Shopping products" → `v2GadsProducts`
- "Results by product, not variant" → recipe 4 above
- "Which products should I run ads on?" → high organic conversion + not yet advertised
- "Product trends over time" → GA4 products with `groupByDate: true`
- "What's this product's details?" → `shopifyProxy` for inventory, variants, descriptions
