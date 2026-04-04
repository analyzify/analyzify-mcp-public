# Workspace & Account Info

All workspace queries use `execute_graphql`.

## Get Full Workspace Info

```graphql
{ extMe { workspaceId shopUrl shopName shopifyShopId shopifyScope shopifyIanaTimezone capabilities keyName reportSpaceId ga4 { propertyID accountName } googleAds { accountID } googleSearchConsole { url } } }
```

## What Each Field Means

| Field | Description |
|-------|-------------|
| `workspaceId` | The workspace/user ID — this is the "space ID" |
| `shopUrl` | Shopify store URL (e.g. `mystore.myshopify.com`) |
| `shopName` | Store display name |
| `shopifyShopId` | Numeric Shopify shop ID |
| `shopifyIanaTimezone` | Store timezone (e.g. `America/New_York`) |
| `capabilities` | API key permissions (e.g. `["mcp", "reports"]`) |
| `keyName` | Name of the API key being used |
| `reportSpaceId` | Report space ID for analytics queries (null if not created) |
| `ga4` | Connected GA4 property — `propertyID` + `accountName` (null if not connected) |
| `googleAds` | Connected Google Ads — `accountID` (null if not connected) |
| `googleSearchConsole` | Connected GSC — `url` (null if not connected) |

## Common User Questions

- "What is my space ID?" → `workspaceId`
- "What is my store?" → `shopName` + `shopUrl`
- "What accounts are connected?" → Check `ga4`, `googleAds`, `googleSearchConsole` for non-null values
- "What's my GA4 property?" → `ga4.propertyID` + `ga4.accountName`
- "What timezone is my store in?" → `shopifyIanaTimezone`
- "What can this API key do?" → `capabilities`

## Create Report Space Token

If you need a report token (e.g., for manual Report API access):

```graphql
mutation { reportSpaceToken }
```

Returns a short-lived JWT token (30 min expiry).
