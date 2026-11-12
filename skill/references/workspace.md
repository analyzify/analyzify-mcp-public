# Workspace & Account Info

Start with the `whoami` tool (Analyzify MCP 0.4.0 or later): it answers "which store is this", "what can you see" and "what is connected" in one call, with every stored source's state and whether customer-level data is available. The extMe query below gives the IDs other queries need; it runs via `execute_graphql`.

## Get Full Workspace Info

```graphql
{ extMe { workspaceId shopUrl shopName shopifyShopId shopifyScope shopifyIanaTimezone capabilities keyName reportSpaceId ga4 { propertyID accountName } googleAds { accountID } googleSearchConsole { url } meta { adAccountID adAccountName } tiktok { advertiserID } klaviyo { accountID accountName } } }
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
| `ga4` | Connected GA4 property — `propertyID` + `accountName` (null if not connected, or its sync is failing or running) |
| `googleAds` | Connected Google Ads — `accountID` (null if not connected, or its sync is failing or running) |
| `googleSearchConsole` | Connected GSC — `url` (null if not connected, or its sync is failing or running) |
| `meta` | Meta Ads report source — `adAccountID` + `adAccountName` (null if not connected, or its sync is failing or running) |
| `tiktok` | TikTok Ads report source — `advertiserID` (same null rule) |
| `klaviyo` | Klaviyo report source — `accountID` + `accountName` (same null rule) |

## Common User Questions

- "What is my space ID?" → `workspaceId`
- "What is my store?" → `shopName` + `shopUrl`
- "What accounts are connected?" → whoami: each live source, and each stored source with its state (ok, syncing, sync failing, not connected) and the dates its data covers. Without whoami (an older connector): check `ga4`, `googleAds`, `googleSearchConsole`, `meta`, `tiktok` and `klaviyo` in extMe. Non-null means connected and enabled (as of the last status copy, up to 30 minutes old). Null means not connected, or its sync is failing or running, so confirm with `v2MarketingSourceStatuses` before saying a source is not connected. Meta, TikTok and Klaviyo data come only from the stored reports
- "What's my GA4 property?" → `ga4.propertyID` + `ga4.accountName`
- "What timezone is my store in?" → `shopifyIanaTimezone`
- "What can this API key do?" → whoami (or `capabilities` in extMe). Customer contact details and segment customers need the `pii` capability

## Report access

The report tools get their own access token; you never need one. They need the `mcp` or `reports` capability on the key. If `reportSpaceId` is null, Analyzify has no stored reports for this store yet: say so, and use the live reads instead. A non-null `reportSpaceId` does not prove there is data: check whoami's source states (or `v2MarketingSourceStatuses`).
