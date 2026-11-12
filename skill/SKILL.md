---
name: analyzify
version: 0.1.2
description: >
  Complete skill for the Analyzify Shopify analytics and tracking app.
  Covers all Analyzify MCP features and workflows.
  Trigger when the user wants to: check store info, view workspace details,
  query Google Analytics 4 data, run GA4 reports, check GA4 traffic,
  query Google Search Console data, view search performance, top queries,
  query Google Ads campaigns and performance, view ad spend and ROAS,
  Meta and TikTok ad results, Klaviyo email and SMS campaigns and flows,
  access Shopify store data via Admin API, list products, collections, orders,
  query historical analytics reports, campaign attribution, traffic trends,
  check connected accounts, view API key capabilities,
  or any Analyzify-related task.
  Example questions: "what is my store", "show my GA4 traffic",
  "top search queries this week", "how are my Google Ads performing",
  "list my products", "show campaign attribution",
  "compare organic vs paid traffic", "daily sessions this month".
---

# Analyzify MCP Skill

Complete workflow guide for the Analyzify Shopify analytics platform. All operations go through MCP tools.

**Two APIs — use the right tool:**

| API | Introspect tool | Execute tool | What it has |
|-----|----------------|--------------|-------------|
| **Analyzify API** | `introspect_schema` | `execute_graphql` | Live data: Shopify proxy, GA4 proxy, GSC proxy, Google Ads proxy, workspace info |
| **Report API** | `introspect_report_schema` | `execute_report_graphql` | Historical data: traffic trends, campaign attribution, aggregated metrics |

## MANDATORY: Session Initialization

At the very start of EVERY conversation, before responding to the user, execute this query via `execute_graphql`:

```graphql
{ extMe { workspaceId shopUrl shopName shopifyShopId shopifyScope shopifyIanaTimezone capabilities keyName reportSpaceId ga4 { propertyID accountName } googleAds { accountID } googleSearchConsole { url } meta { adAccountID adAccountName } tiktok { advertiserID } klaviyo { accountID accountName } } }
```

Store the entire response for the session. This gives you:
- **workspaceId** — the workspace/user ID (this IS the "space ID" if the user asks)
- **shopUrl / shopName** — the Shopify store
- **reportSpaceId** — report space ID for analytics data
- **ga4.propertyID** — GA4 property ID to use in ga4Proxy paths
- **googleAds.accountID** — Google Ads customer ID to use in gadsProxy paths
- **googleSearchConsole.url** — GSC site URL to use in gscProxy paths

Never ask the user for these IDs. A null service means it is not connected, or its sync is failing or running: check `v2MarketingSourceStatuses` before telling the user a source is not connected.

## Playbooks (Business Questions)

Match the user's question to the right playbook. Each playbook has exact queries, variables, presentation formats, and follow-up handling.

| Playbook | Triggers | File |
|----------|----------|------|
| **Diagnose Sales Drop** | "Why are sales down?", "Revenue dropped", "What changed?", "Why did X decline?", "Something broke" | `playbooks/diagnose-sales-drop.md` |
| **Weekly/Monthly Report** | "Weekly report", "Monthly recap", "Business summary", "How did we do?" | `playbooks/weekly-monthly-report.md` |
| **Profit & Revenue** | "What's my profit?", "Revenue?", "MER?", "Costs?", "P&L?", "Margin?" | `playbooks/profit-and-revenue.md` |
| **Sales & Orders** | "Total sales?", "Orders?", "AOV?", "Returns?", "Find order #X?" | `playbooks/sales-and-orders.md` |
| **Product Optimization** | "Best/worst products?", "What should I promote?", "High views low sales?", "Dead stock?" | `playbooks/product-optimization.md` |
| **Ad Performance** | "How are my ads?", "ROAS?", "Campaign performance?", "Best/worst campaigns?" | `playbooks/ad-performance.md` |
| **Budget Allocation** | "Where to spend more?", "Budget optimization?", "Scale ads?", "Cut wasteful spend?", "Losing campaigns?" | `playbooks/budget-allocation.md` |
| **Attribution** | "Where do orders come from?", "First/last touch?", "Channel attribution?" | `playbooks/attribution.md` |
| **Conversion Optimization** | "Improve conversion rate?", "Cart abandonment?", "Funnel?", "Bounce rate?", "Mobile conversion?" | `playbooks/conversion-optimization.md` |
| **Traffic & SEO** | "Traffic sources?", "SEO?", "Top queries?", "Landing pages?", "404s?" | `playbooks/traffic-and-seo.md` |
| **Seasonal / YoY** | "Compare to last year?", "YoY growth?", "Seasonal trends?", "Am I on track?", "BFCM planning?" | `playbooks/seasonal-yoy-comparison.md` |
| **Discount & Promo Impact** | "Are discounts working?", "Promotion results?", "Margin impact?", "Should I run a sale?" | `playbooks/discount-promotion-impact.md` |
| **Conversion Health** | "Is tracking working?", "Last conversion?", "Tags broken?", "PMax not converting?" | `playbooks/conversion-health-tracking.md` |
| **Store Health** | "How's my store?", "Overview?", "Dashboard?", "KPIs?" | `playbooks/store-health.md` |
| **Customer Insights** | "New vs returning?", "Segments?", "CAC?", "Repeat rate?", "LTV?" | `playbooks/customer-insights.md` |
| **Email & SMS (Klaviyo)** | "How are my emails doing?", "Flow revenue?", "Best campaign?", "Open rate?" | `references/klaviyo.md` |

**Priority matching:**
- If the user describes a **problem** ("sales dropped", "why did X change") → use **Diagnose Sales Drop**
- If the user asks for a **report** ("weekly report", "monthly summary") → use **Weekly/Monthly Report**
- If the user asks a **specific question** → match to the relevant playbook above
- If the user is **vague** ("how's my store?", "give me an overview") → use **Store Health**

## API References (Technical)

| Flow | Trigger | Reference |
|------|---------|-----------|
| Workspace & Account Info | User asks about store, space ID, capabilities, connected accounts | `references/workspace.md` |
| Shopify Store Data | User wants products, collections, orders, themes, or any Shopify Admin data | `references/shopify.md` |
| Google Analytics 4 | User wants GA4 traffic, reports, sessions, pageviews, realtime data | `references/ga4.md` |
| Google Search Console | User wants search performance, top queries, impressions, clicks, CTR | `references/gsc.md` |
| Google Ads | User wants ad campaigns, spend, ROAS, conversions, keywords | `references/gads.md` |
| Analytics Reports | Full report query reference with all fields, inputs, and response shapes | `references/reports.md` |
| Klaviyo | Email and SMS campaigns, flows, Klaviyo's share of sales | `references/klaviyo.md` |
| Judging performance | Before calling anything losing money, wasted, a loser or a winner, or suggesting cuts or scaling | `references/judging-performance.md` |

## Query Strategy: Report API First

**The queries in this skill are valid even when `introspect_report_schema` doesn't list them.** The schema search can lag behind the Report API (the `v2*`, Klaviyo and source-status queries may be missing from it). Run the queries as written here; only introspect for something this skill doesn't cover.

**ALWAYS try the Report API first.** It has pre-aggregated historical data that is fast and doesn't hit external rate limits.

1. Match the user's request to a Report API query (see `references/reports.md`)
2. If the Report API has the data → use `execute_report_graphql`
3. Only fall back to live proxies (ga4Proxy, gscProxy, gadsProxy, shopifyProxy) when:
   - The Report API doesn't have the query (e.g., realtime GA4 data)
   - The user needs live/current data that hasn't been synced yet
   - The user needs Shopify Admin data (products, collections, themes) — these are only available via `shopifyProxy`

**Examples:**
- "What's my revenue?" → Report API (`ga4Scorecards` or `profitMerReport`)
- "Show my top campaigns" → Report API (`v2GadsCampaigns`, `v2MetaCampaigns`, `v2TiktokCampaigns`)
- "Realtime visitors right now" → Live proxy (`ga4Proxy` with realtime endpoint)
- "List my products" → Live proxy (`shopifyProxy`)

## How to Use

1. Run the extMe initialization query (MANDATORY)
2. Match the user's request to a Report API query first (check `references/reports.md`)
3. If no Report API query fits, match to a live proxy flow
4. Load the corresponding reference file for exact operations
5. Use `introspect_schema` or `introspect_report_schema` if you need field details
6. Execute and present results cleanly — no technical jargon

## Answer Rules

These keep the same question giving the same, correct answer in every chat:

- **Rates come from totals.** For Google Ads, Meta and TikTok use the `v2*` reports, which compute CTR, CPC, CPA and ROAS from totals. In legacy reports, never read a rate (CTR, CPC, CPM, CPA, ROAS, conversion rate, MER, margin, AOV) from a row covering more than one day: compute it from the totals in that row. When combining rows, add the totals first, then divide.
- **Empty is not zero.** If a report is empty or shows zero spend, check `v2MarketingSourceStatuses` first and say what you found: not connected, sync failing since a date, data only up to a date, or connected with nothing to report.
- **A failed read is not zero.** If a query returns errors, tell the user the data couldn't be read (in plain words, without error codes) and what they can do. Never present it as 0 orders or 0 sales.
- **`profitMerReport` returns one row per day** (it ignores `groupByDate`), or one row per calendar month with `groupByFields: ["month"]`, whose ratios come from the month's totals. For any other period, add up the daily rows, then compute MER, margin, AOV and CPA from the sums. A row with `adSpendComplete: false` may be missing ad spend that has not synced yet: call its profit provisional, and check `v2MarketingSourceStatuses` covers the whole period (`playbooks/profit-and-revenue.md`).
- **Dates are `YYYY-MM-DD`** in report queries. Shopify dates are in the store's time zone (`shopifyIanaTimezone`); GA4 and the ad platforms use their account's time zone (`timezone` in `v2MarketingSourceStatuses`); Klaviyo order data is dated in UTC; Search Console gives no time zone. Say which dates an answer covers.
- **Hidden is not missing.** In live Shopify reads, customer e-mails, phone numbers, first and last names and addresses come back as `[redacted: …]` (e-mails inside text as `[redacted email]`) unless the API key has the `pii` capability. Say they are hidden for this key; never say the customer has none.
- **Read only.** You cannot create, change, delete or sync anything in the store, its reports or its ad accounts. If asked, say so and point the user to the Analyzify app.
- **Say where a number came from:** the stored report (synced daily, up to which date) or a live read, and the date range.
- **Recent days aren't settled.** Ad platforms keep adding conversions after the click: Google Ads and TikTok for about 8 days, Meta for up to 28. Say so when the range includes those days (`references/judging-performance.md`).
- **Long answers come complete or in parts, never "narrow your question".** A long result arrives in parts (fetch the others before you total or rank) or with a next page. For "every product" style questions with thousands of items, give the exact count and the top items, and say the full list is too long for a chat. Per-item Google Ads counts come from the live Shopping performance view (`references/gads.md`), not from stored report row counts; an item is a variant in one country feed, so say "items (variants)" or count distinct products as `references/gads.md` explains.
- **No verdicts from a raw ROAS.** Never call a campaign or product "losing money", "wasted", a loser or a winner, and never tell the user to pause, cut or scale, unless the checks in `references/judging-performance.md` hold. Break-even is not ROAS 1.0.

## Behavior Rules

- NEVER mention GraphQL, APIs, queries, mutations, tool names, schemas, or any technical details to the user
- NEVER show raw JSON, query strings, or error codes (but do say plainly when data couldn't be read)
- If a service is null in extMe and `v2MarketingSourceStatuses` confirms it is not connected: "That service isn't connected to your store yet. You can set it up in your Analyzify dashboard."
- Present data in clean tables, lists, or summaries
- Act like a knowledgeable assistant who just knows things about the store
- If the user asks "what version", "skill version", "check for updates", "is my skill up to date", or "update skill":
  - **Installed skill version:** from this file's frontmatter (`version` field)
  - **Latest skill version:** run `analyzify-mcp skill latest-version` via terminal
  - **MCP server version:** run `analyzify-mcp version` via terminal if available
  - **MCP server update check:** run `analyzify-mcp self-update --check` via terminal
  - Compare installed vs latest. If the installed version is older, tell the user their skill is outdated and suggest updating:
    - `npx skills add analyzify/analyzify-mcp-public` to update the skill
    - `analyzify-mcp self-update` to update the MCP server binary
  - If versions match, tell the user they are up to date

## Quick Reference

**Get workspace info:**
```graphql
{ extMe { workspaceId shopUrl shopName shopifyShopId shopifyIanaTimezone reportSpaceId capabilities keyName ga4 { propertyID accountName } googleAds { accountID } googleSearchConsole { url } meta { adAccountID } tiktok { advertiserID } klaviyo { accountID } } }
```

**List products (via Shopify proxy):**
```graphql
{ shopifyProxy(query: "{ products(first: 10) { edges { node { id title handle status } } } }") { data errors } }
```

**GA4 traffic report (use propertyID from extMe):**
```graphql
query($body: JSON) { ga4Proxy(input: { path: "properties/{propertyID}:runReport", body: $body }) { statusCode data } }
```
