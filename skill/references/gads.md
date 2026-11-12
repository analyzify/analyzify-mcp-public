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

Questions like "how many products had ad spend last month", "list every product with spend" or "top products by spend" need one row per item. The Shopping performance view gives exactly that, summed over the period:

Count of items with spend (path `customers/{accountID}/googleAds:search`):
```json
{
  "body": {
    "query": "SELECT segments.product_item_id, metrics.cost_micros FROM shopping_performance_view WHERE segments.date BETWEEN '2026-10-01' AND '2026-10-31' AND metrics.cost_micros > 0"
  }
}
```
- Each page holds up to 10,000 items. A long page comes back in parts: part 1 already says how many rows the page has (`_rowsInThisAnswer`, with Analyzify MCP 0.4.0 or later), so you don't need the other parts to count.
- If the answer has a `nextPageToken`, send it as `"pageToken"` in the same body for the next page, and add up the row counts of all pages.

Top items by spend:
```json
{
  "body": {
    "query": "SELECT segments.product_item_id, segments.product_title, metrics.cost_micros, metrics.conversions, metrics.conversions_value FROM shopping_performance_view WHERE segments.date BETWEEN '2026-10-01' AND '2026-10-31' AND metrics.cost_micros > 0 ORDER BY metrics.cost_micros DESC LIMIT 20"
  }
}
```

When the user asks for every item and there are thousands: give the exact count and the top items, and say the full list is too long for a chat. Never ask the user to narrow the question because the answer is long.

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
- `googleAds` null in extMe means Google Ads is not connected, or its sync is failing or running: check `v2MarketingSourceStatuses` before telling the user to connect it in the Analyzify dashboard
