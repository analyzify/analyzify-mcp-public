# Google Analytics 4

All GA4 queries use `execute_graphql` with the `ga4Proxy` query. The OAuth token is retrieved automatically.

## Query Format

```graphql
query($body: JSON) {
  ga4Proxy(input: { path: "<api_path>", body: $body }) { statusCode data }
}
```

For GET requests (no body):
```graphql
{ ga4Proxy(input: { path: "<api_path>", method: "GET" }) { statusCode data } }
```

For Admin API (account/property management):
```graphql
{ ga4Proxy(input: { path: "<api_path>", method: "GET", apiType: ADMIN }) { statusCode data } }
```

## Path Format

Do NOT include base URL or version prefix. Just the resource path:
- Data API: `properties/{propertyID}:runReport`
- Admin API: `properties/{propertyID}/dataStreams`

Get the `propertyID` from the extMe response (`ga4.propertyID`).

## Common Queries

### Run a Report (sessions, users, pageviews)
Path: `properties/{propertyID}:runReport`

Variables:
```json
{
  "body": {
    "dateRanges": [{ "startDate": "7daysAgo", "endDate": "today" }],
    "metrics": [
      { "name": "sessions" },
      { "name": "totalUsers" },
      { "name": "screenPageViews" }
    ],
    "dimensions": [{ "name": "date" }],
    "orderBys": [{ "dimension": { "dimensionName": "date" } }]
  }
}
```

### Realtime Report
Path: `properties/{propertyID}:runRealtimeReport`

Variables:
```json
{
  "body": {
    "metrics": [{ "name": "activeUsers" }],
    "dimensions": [{ "name": "country" }]
  }
}
```

### Traffic by Source/Medium
Path: `properties/{propertyID}:runReport`

Variables:
```json
{
  "body": {
    "dateRanges": [{ "startDate": "30daysAgo", "endDate": "today" }],
    "metrics": [{ "name": "sessions" }, { "name": "totalUsers" }],
    "dimensions": [{ "name": "sessionSourceMedium" }],
    "orderBys": [{ "metric": { "metricName": "sessions" }, "desc": true }],
    "limit": 10
  }
}
```

### Top Pages
Path: `properties/{propertyID}:runReport`

Variables:
```json
{
  "body": {
    "dateRanges": [{ "startDate": "7daysAgo", "endDate": "today" }],
    "metrics": [{ "name": "screenPageViews" }, { "name": "sessions" }],
    "dimensions": [{ "name": "pagePath" }],
    "orderBys": [{ "metric": { "metricName": "screenPageViews" }, "desc": true }],
    "limit": 10
  }
}
```

### List Data Streams (Admin API)
Path: `properties/{propertyID}/dataStreams`

```graphql
{ ga4Proxy(input: { path: "properties/{propertyID}/dataStreams", method: "GET", apiType: ADMIN }) { statusCode data } }
```

## API Types

| apiType | Base URL | Use for |
|---------|----------|---------|
| `DATA` (default) | analyticsdata.googleapis.com/v1beta | Reports, realtime data |
| `ADMIN` | analyticsadmin.googleapis.com/v1beta | Account/property management, data streams |

## Notes

- Always pass `body` as a JSON variable, not an inline string
- Date formats: `YYYY-MM-DD`, `today`, `yesterday`, `NdaysAgo`
- Check `statusCode` in response — 200 means success
- If GA4 is not connected (null in extMe), tell user to connect it in Analyzify dashboard
