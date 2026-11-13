# Google Ads

All Google Ads queries use `execute_graphql` with the `gadsProxy` query. The OAuth token and developer token are injected automatically.

## Query Format

```graphql
query($body: JSON) {
  gadsProxy(input: { path: "<api_path>", body: $body }) { statusCode data }
}
```

For GET requests:
```graphql
{ gadsProxy(input: { path: "<api_path>", method: "GET" }) { statusCode data } }
```

## Path Format

Do NOT include base URL or version prefix. Just the resource path:
- `customers/{accountID}/googleAds:search` (use this one: up to 10,000 rows a page, with `nextPageToken` for the next page)
- `customers/{accountID}/googleAds:searchStream` (returns everything in one answer; avoid it for long lists)
- `customers:listAccessibleCustomers`

Get the `accountID` from the extMe response (`googleAds.accountID`).

## Common Queries

### Campaign Performance
Path: `customers/{accountID}/googleAds:search`

Variables:
```json
{
  "body": {
    "query": "SELECT campaign.name, campaign.status, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value FROM campaign WHERE segments.date DURING LAST_7_DAYS ORDER BY metrics.impressions DESC"
  }
}
```

### Ad Group Performance
Path: `customers/{accountID}/googleAds:search`

Variables:
```json
{
  "body": {
    "query": "SELECT ad_group.name, campaign.name, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.ctr, metrics.average_cpc FROM ad_group WHERE segments.date DURING LAST_30_DAYS ORDER BY metrics.clicks DESC LIMIT 20"
  }
}
```

### Keyword Performance
Path: `customers/{accountID}/googleAds:search`

Variables:
```json
{
  "body": {
    "query": "SELECT ad_group_criterion.keyword.text, ad_group_criterion.keyword.match_type, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions FROM keyword_view WHERE segments.date DURING LAST_7_DAYS ORDER BY metrics.clicks DESC LIMIT 20"
  }
}
```

### Daily Spend Overview
Path: `customers/{accountID}/googleAds:search`

Variables:
```json
{
  "body": {
    "query": "SELECT segments.date, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions FROM customer WHERE segments.date DURING LAST_30_DAYS ORDER BY segments.date DESC"
  }
}
```

### Products (items) over a period: count and top items

Questions like "how many products had ad spend last month" or "list every product with spend" need one row per item. The Shopping performance view gives exactly that, summed over the period.

**Items are not products.** An item is usually one variant in one country feed: `shopify_us_123_456` and `shopify_gb_123_456` are two items of the same product. Always say "items (variants)" in the answer. For a count of *products*, when the item IDs look like `shopify_<country>_<productId>_<variantId>`, count the distinct `productId` values (that needs every part and page of the answer); for other ID formats, use the roll-up recipe in `playbooks/product-optimization.md`.

Count of items with spend (path `customers/{accountID}/googleAds:search`):
```json
{
  "body": {
    "query": "SELECT segments.product_item_id, metrics.cost_micros FROM shopping_performance_view WHERE segments.date BETWEEN '2026-10-01' AND '2026-10-31' AND metrics.cost_micros > 0"
  }
}
```
- Each page holds up to 10,000 items. A long page comes back in parts: part 1 already says how many rows the page has (`_rowsInThisAnswer`, with Analyzify MCP 0.4.0 or later), so you don't need the other parts to count items. A short page comes back whole, without `_rowsInThisAnswer`: count the rows in its `results` (a table's `rows`).
- If the answer has a `nextPageToken`, send it as `"pageToken"` in the same body for the next page. Read every page: there is no count until the page without a `nextPageToken` is read.
- **The total comes from the connector, not from your own sum.** With Analyzify MCP 0.4.5 or later, from page 2 on a `MORE PAGES` line says how many rows the pages read so far hold together, and the last page says `ALL PAGES READ` with the total: give that number as the count. A query that fits in one page (no `nextPageToken`) gets no such line: its row count is the count.
- With an older connector (no `ALL PAGES READ` line), write each page's row count down as you read it (page 1: 10,000; page 2: 10,000; …) and check the sum: every page but the last holds exactly 10,000 rows, so the total is 10,000 × (pages − 1) + the last page's rows. A total that does not match leaves a page out.
- Use `googleAds:search`, not `searchStream`: search answers one page at a time with a row count per page.

Top items by spend (ranked on the item ID alone, so an item whose title changed during the period still counts once; get titles for the top IDs in a second call with `segments.product_title` and `WHERE segments.product_item_id IN (...)`):
```json
{
  "body": {
    "query": "SELECT segments.product_item_id, metrics.cost_micros, metrics.conversions, metrics.conversions_value FROM shopping_performance_view WHERE segments.date BETWEEN '2026-10-01' AND '2026-10-31' AND metrics.cost_micros > 0 ORDER BY metrics.cost_micros DESC LIMIT 20"
  }
}
```

When the user asks for every item and there are thousands: give the exact count and the top items, and say the full list is too long for a chat. Never ask the user to narrow the question because the answer is long.

Which source when: counts and complete lists of items with spend come from this live view. A top-items table or a roll-up to products can use the stored report instead (`v2GadsProducts`, `playbooks/product-optimization.md`), which is complete up to its last sync (its last ~8 days are still not settled, as with any Google Ads read); say which one you used and its date range. Use the live view for days the stored report doesn't have yet.

### List Accessible Customers
```graphql
{ gadsProxy(input: { path: "customers:listAccessibleCustomers", method: "GET" }) { statusCode data } }
```

## GAQL (Google Ads Query Language)

Queries use GAQL syntax in the `body.query` field. Key concepts:
- `cost_micros` = cost in micros (divide by 1,000,000 for actual currency)
- Date ranges: `DURING LAST_7_DAYS`, `DURING LAST_30_DAYS`, `DURING THIS_MONTH`, `DURING LAST_MONTH`
- Custom dates: `WHERE segments.date BETWEEN '2026-03-01' AND '2026-03-31'`

## Notes

- Always pass `body` as a JSON variable
- `cost_micros` needs conversion: divide by 1,000,000 to get the actual amount
- Present ROAS as `conversions_value / (cost_micros / 1000000)`
- `googleAds` null in extMe means Google Ads is not connected, or its sync is failing or running: check whoami's source states (or `v2MarketingSourceStatuses`) before telling the user to connect it in the Analyzify dashboard
