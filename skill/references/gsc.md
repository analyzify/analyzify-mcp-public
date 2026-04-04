# Google Search Console

All GSC queries use `execute_graphql` with the `gscProxy` query. The OAuth token is retrieved automatically.

## Query Format

```graphql
query($body: JSON) {
  gscProxy(input: { path: "<api_path>", body: $body }) { statusCode data }
}
```

For GET requests:
```graphql
{ gscProxy(input: { path: "<api_path>", method: "GET" }) { statusCode data } }
```

## Path Format

Do NOT include base URL. Just the resource path:
- `sites/sc-domain:example.com/searchAnalytics/query`
- `sites/https%3A%2F%2Fexample.com%2F/searchAnalytics/query`
- `sites` (list all sites)

Get the site URL from the extMe response (`googleSearchConsole.url`). For domain properties use `sc-domain:` prefix. For URL-prefix properties, URL-encode the full URL.

## Common Queries

### Search Performance (Top Queries)
Path: `sites/{encodedSiteUrl}/searchAnalytics/query`

Variables:
```json
{
  "body": {
    "startDate": "2026-03-01",
    "endDate": "2026-03-31",
    "dimensions": ["query"],
    "rowLimit": 10,
    "dataState": "all"
  }
}
```

### Search Performance by Page
Path: `sites/{encodedSiteUrl}/searchAnalytics/query`

Variables:
```json
{
  "body": {
    "startDate": "2026-03-01",
    "endDate": "2026-03-31",
    "dimensions": ["page"],
    "rowLimit": 10,
    "dataState": "all"
  }
}
```

### Daily Search Performance
Path: `sites/{encodedSiteUrl}/searchAnalytics/query`

Variables:
```json
{
  "body": {
    "startDate": "2026-03-01",
    "endDate": "2026-03-31",
    "dimensions": ["date"],
    "dataState": "all"
  }
}
```

### Performance by Country
Path: `sites/{encodedSiteUrl}/searchAnalytics/query`

Variables:
```json
{
  "body": {
    "startDate": "2026-03-01",
    "endDate": "2026-03-31",
    "dimensions": ["country"],
    "rowLimit": 10,
    "dataState": "all"
  }
}
```

### List Sites
```graphql
{ gscProxy(input: { path: "sites", method: "GET" }) { statusCode data } }
```

## Available Dimensions

`query`, `page`, `date`, `country`, `device`, `searchAppearance`

You can combine multiple dimensions: `["query", "page"]`

## Response Fields

Each row contains: `clicks`, `impressions`, `ctr`, `position`

## Notes

- Always pass `body` as a JSON variable
- Dates must be `YYYY-MM-DD` format (no relative dates like "7daysAgo")
- Use the store's timezone from extMe (`shopifyIanaTimezone`) when the user says "this week"
- `rowLimit` caps results (default 1000, max 25000)
- If GSC is not connected (null in extMe), tell user to connect it in Analyzify dashboard
