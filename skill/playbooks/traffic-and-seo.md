# Playbook: Traffic, SEO & Search Performance

## Triggers

"Where's my traffic coming from?", "SEO performance?", "Top search queries?", "Organic traffic?", "Landing pages?", "Bounce rate?", "Google Search Console?", "Which pages rank?", "Search impressions?", "Click-through rate?", "404 errors?", "Broken pages?", "Traffic by device?", "Mobile vs desktop?"

## Strategy

**Primary:** Report API for historical/aggregated data
- `ga4Channels` — traffic by channel
- `ga4Scorecards` — sessions, users overview
- `ga4LandingPages` — landing page performance
- `ga4ReferralRevenue` — traffic source attribution
- `ga4DeviceCategory` — device breakdown
- `ga4404Pages` — broken pages
- `scTraffics` — search query performance
- `scAnalytics` — search traffic trend

**Fallback:** `ga4Proxy` for realtime data or custom GA4 reports not available via Report API.

## Queries

### 1. Traffic Overview (GA4 Scorecards)

```graphql
query($input: Ga4ScorecardsInput!) {
  ga4Scorecards(input: $input) {
    scorecards {
      dated metricsAddToCart metricsPurchases metricsSessions
      metricsRevenue metricsUsers metricsTransactions
    }
    metricsSessionsPercentageDiff metricsUsersPercentageDiff
    metricsRevenuePercentageDiff metricsPurchasesPercentageDiff
  }
}
```

The percentage diffs auto-compare against the previous period (same length).

### 2. Traffic by Channel

```graphql
query($input: Ga4ChannelInput!) {
  ga4Channels(input: $input) {
    channels {
      dated channelName currencyCode
      metricsSessions metricsUsers metricsPurchases metricsRevenue
    }
    metricsTotalSessions metricsTotalUsers
    metricsTotalPurchases metricsTotalRevenue
  }
}
```

Use `groupByFields: ["channel_name"]` and `groupByDate: false` for channel summary.

### 3. Traffic by Source/Medium

```graphql
query($input: Ga4ReferralRevenueInput!) {
  ga4ReferralRevenue(input: $input) {
    sessionSource sessionMedium currencyCode
    metricsSessions metricsUsers metricsEcommPurchases metricsRevenue
  }
}
```

### 4. Landing Page Performance

```graphql
query($input: Ga4LandingPageInput!) {
  ga4LandingPages(input: $input) {
    landingPage currencyCode
    metricsActiveUsers metricsNewUsers metricsTotalUsers metricsSessions
    metricsEcommPurchases metricsTotalRevenue metricsBounceRate
  }
}
```

### 5. Device Breakdown

```graphql
query($input: Ga4DeviceCategoryInput!) {
  ga4DeviceCategory(input: $input) {
    deviceName metricsCount
  }
}
```

### 6. Search Console — Top Queries

```graphql
query($input: ScTrafficInput!) {
  scTraffics(input: $input) {
    queried clicks impressions ctr position
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
      "groupByDate": false,
      "groupByFields": ["queried"],
      "orderByFields": ["clicks desc"]
    }
  }
}
```

### 7. Search Console — Top Pages

Same query but with `groupByFields: ["url_id"]`.

### 8. Search Console — Traffic Trend

```graphql
query($input: ScAnalyticInput!) {
  scAnalytics(input: $input) {
    dated clicks impressions ctr position
  }
}
```

With `groupByDate: true`.

### 9. 404 Error Pages

```graphql
query($input: Ga4404PagesInput!) {
  ga4404Pages(input: $input) {
    pages {
      landingPage pagePath sessionSourceMedium
      metricsSessions metricsTotalUsers metricsEventCount
    }
    metricsTotalSessions metricsTotalUsers metricsTotalEventCount
  }
}
```

### 10. Realtime Visitors (Live Proxy Only)

This requires the live GA4 proxy — not available via Report API:

```graphql
query($body: JSON) {
  ga4Proxy(input: {
    path: "properties/{{ga4PropertyID}}:runRealtimeReport",
    body: $body
  }) {
    statusCode data
  }
}
```

```json
{
  "body": {
    "dimensions": [{ "name": "unifiedScreenName" }],
    "metrics": [{ "name": "activeUsers" }]
  }
}
```

## How to Present

### Traffic Summary

| Metric | This Period | vs Previous |
|--------|------------|-------------|
| Sessions | X | +X% |
| Users | X | +X% |
| Purchases | X | +X% |
| Revenue | $X | +X% |

### Channel Breakdown

| Channel | Sessions | Users | Purchases | Revenue | Conv. Rate |
|---------|----------|-------|-----------|---------|------------|
| Organic Search | X | X | X | $X | X% |
| Paid Search | X | X | X | $X | X% |
| Direct | X | X | X | $X | X% |
| Social | X | X | X | $X | X% |
| Referral | X | X | X | $X | X% |

Calculate conversion rate: `purchases / sessions × 100`

### SEO Performance

| Query | Clicks | Impressions | CTR | Avg Position |
|-------|--------|-------------|-----|-------------|
| brand name | X | X | X% | X.X |
| product keyword | X | X | X% | X.X |

Highlight:
- High impression / low CTR queries (title/description improvement opportunity)
- Position 4-10 queries (almost on page 1, opportunity to push up)
- Top revenue-driving organic terms

### Landing Page Performance

| Page | Sessions | Bounce Rate | Purchases | Revenue |
|------|----------|-------------|-----------|---------|
| /collections/summer | X | X% | X | $X |
| /products/best-seller | X | X% | X | $X |

Highlight pages with high bounce rate (>70%) or high traffic but low conversions.

## Common Follow-ups

- "Show me just organic" → filter channels for "Organic Search"
- "Which keywords should I focus on?" → GSC queries with position 4-20, high impressions
- "Any broken pages?" → ga4404Pages query
- "Realtime visitors?" → ga4Proxy with realtime endpoint (live only)
- "Mobile conversion rate?" → combine ga4DeviceCategory with ga4Scorecards
