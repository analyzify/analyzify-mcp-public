# Klaviyo (Email and SMS) Reports

Klaviyo campaign, flow and attribution data synced into the Report API. Use `execute_report_graphql`.

Before answering, check that Klaviyo is connected and current: run `v2MarketingSourceStatuses` (see `references/reports.md`) and look at the `klaviyo` entry. If it isn't connected, say so; never answer "Klaviyo made 0".

All queries take `{ "input": { "default": { "spaceId": "...", "startDate": "...", "endDate": "...", "groupByDate": false } } }`, with an optional `"comparison"` period. Campaigns and flows default to email only; add `"sendChannels": ["email", "sms"]` (or `"push-notification"`) next to `default` to include other channels.

**Units:** `openRate`, `clickRate`, `bounceRate` and `cvr` are fractions (0.35 means 35%). `revenue` is the order value Klaviyo attributes within its own attribution window, in the account currency. `rpr` is revenue per recipient (revenue / delivered).

## v2KlaviyoCampaigns — Campaign (one-off send) results

```graphql
query($input: V2KlaviyoCampaignsInput!) {
  v2KlaviyoCampaigns(input: $input) {
    meta { currencyCode coverage { latestAvailableDate partialData staleData } freshness { status lastFailureAt } }
    summary { revenue delivered opensUnique clicksUnique conversions unsubscribed openRate clickRate bounceRate cvr rpr aov }
    rows { campaignName messageName subject sendChannel sendTime delivered openRate clickRate conversions revenue rpr cvr unsubscribed audience }
  }
}
```

Rows are one per campaign message: a campaign sent to several audiences can have several rows. Add them up per `campaignName` (totals first, then rates).

**Use when:** "How did my email campaigns do?", "Best campaign last month?", "Open rate?"

## v2KlaviyoFlows — Flow (automation) results

```graphql
query($input: V2KlaviyoFlowsInput!) {
  v2KlaviyoFlows(input: $input) {
    meta { currencyCode coverage { latestAvailableDate partialData staleData } freshness { status lastFailureAt } }
    summary { revenue delivered opensUnique clicksUnique conversions openRate clickRate cvr rpr }
    rows { flowId flowName activeMessages delivered openRate clickRate conversions revenue rpr cvr }
  }
}
```

**Use when:** "How are my flows doing?", "Abandoned cart flow results?", "Welcome series revenue?"

## v2KlaviyoAttribution — Klaviyo's share of store sales, by day and channel

```graphql
query($input: V2KlaviyoAttributionInput!) {
  v2KlaviyoAttribution(input: $input) {
    summary {
      attributedRevenue totalStoreRevenue
      campaignRevenue campaignConversions flowRevenue flowConversions
      emailRevenue smsRevenue pushRevenue
    }
    rows { dated attributedRevenue totalStoreRevenue campaignRevenue flowRevenue }
  }
}
```

Defaults to all channels (email, SMS, push).

**Use when:** "How much revenue comes from email?", "Campaigns vs flows?", "Is email growing?"

## How to Present

- Show campaigns and flows separately.
- `attributedRevenue / totalStoreRevenue` is a rough share only: `totalStoreRevenue` is gross order value (with tax and shipping), and Klaviyo counts an order that falls within its own attribution window after an email or SMS, even when an ad or a search also led to it. Don't add Klaviyo revenue to ad platforms' revenue: the same order is often claimed by both.
- Say which date range and channels you included.

## Not Here

- Customer-level rows (who received or bought) are not covered by this skill.
- Changing a campaign or flow: Analyzify reads Klaviyo data only.
