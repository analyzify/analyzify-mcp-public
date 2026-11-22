# Changelog

## Skill 0.1.18 (2026-11-22)

- The connector's rules (in the `whoami` answer) win where this skill says otherwise; a tool the skill names but the connector lacks means the connector is older (`analyzify-mcp self-update`)
- Session start is `whoami` first, then extMe, as the connector asks
- "Which channels bring the most orders" goes to `channel_breakdown`, whose Orders by channel block gives Analyzify's attributed orders per channel (last non-direct click), never divided by a platform's spend as a ROAS or a cost per order; the attribution playbook's channel query includes orders with no channel, so its totals are the store's orders
- The playbooks call the dedicated tools first: `performance_summary` for a period and its change (weekly and monthly reports, store health, sales drops, year over year, promotions, sales, new customers), `channel_breakdown` for channels, `source_status` before any "drop" or "no spend", `product_performance` for ads per product; the raw reports stay for daily rows, campaigns and single orders
- Settled days follow the connector: Google Ads for its conversion window (30 days by default), Meta and TikTok about 7 days; judge from 8 days back
- The `never_synced` state; `metric_definitions` for "what does X mean"; the version notes for older connectors are gone, except where an answer line may be missing
- No figure divides one source by another: the budget and attribution tables show each platform's spend and ROAS beside Analyzify's attributed orders, never attributed order totals over spend or spend over attributed orders or new customers; the weekly report compares with the period the request names (the week or month before), not only the days just before
- Shipping in the profit report is shipping charged to the customer, not a cost: the cost tables no longer list it; total ad spend is the report's figure; shares of paid and organic are by orders, or by the attribution report's own total sales, never over net sales

## Skill 0.1.17 (2026-11-22)

- The attribution reports carry no ad-platform figures (cost, clicks, impressions, CTR, CPC, CPM, ROAS, CPA, sessions, campaign type): the queries no longer ask for them, and the presentation tables drop the ROAS and CPA columns. Spend, ROAS and cost per conversion come from `channel_breakdown` or the `v2*` ad reports, shown as the platform's figures
- A Google Ads cost per purchase always comes with the share of its primary conversions that were purchases (the rest are non-purchase actions)
- A platform's cost is compared with an order figure only as a cost per purchase against the store's gross profit per order, never a Google Ads or TikTok cost per conversion against average order value

## Skill 0.1.16 (2026-11-22)

- "Sales" names one of four figures: net sales; the order report's total sales (after returns); the attribution reports' total sales (before returns); or a live order's total (before returns). The old line called every order total "before returns"
- CPA is a platform's cost per conversion (Meta's stored `cpa` is spend / purchases); the profit report's `cpa` is total ad spend / Shopify orders, a cost per order, and is no longer called a cost per acquisition

## Skill 0.1.12 (2026-11-19)

- "How is my store doing", a period against the one before or the year before, and sales, profit or MER up or down go to the `performance_summary` tool first (Analyzify MCP 0.4.12 or later): Shopify's sales and the profit report's figures for both periods, with each change or why it is not computed
- A change the tool does not compute (a comparison period only partly stored, an ad platform starting or stopping inside it, unsynced days) is never estimated, and a missing source is never a drop; no product costs is never a 100% margin, in the tool or in a raw profit report read

## Skill 0.1.10 (2026-11-18)

- "Is my data OK", "is X connected", "why is X missing" and "when did X last sync" go to the `source_status` tool first (Analyzify MCP 0.4.10 or later): every stored source's state, the day its data reaches, the last successful sync, why it fails and the account's currency next to the shop's, in one call
- A lag within the normal 1 to 4 days is not a failure; "no data", "never synced" and "not connected" are never zero

## Skill 0.1.9 (2026-11-18)

- MER, profit, margin and cost per order go to the profit report (`profitMerReport`), one computation for every answer; `channel_breakdown` is for comparing channels, and from Analyzify MCP 0.4.9 its blended line is the profit report's figure
- The platforms' conversions overlap: never add them together, compare their total with Shopify's orders, or say they exceed or fall short of Shopify's orders
- A period's MER, CPA, NCAC, CAC and CVR from daily profit rows leave out the days whose ad spend is not synced (`adSpendComplete: false`), the monthly rows' own rule, so a direct answer and `channel_breakdown` agree

## Skill 0.1.8 (2026-11-18)

- Channels compared: "how are my channels doing", ROAS or spend by channel go to the `channel_breakdown` tool first (Analyzify MCP 0.4.8 or later): Google Ads, Meta and TikTok against Shopify's orders and net sales in one call, with each channel's state and data date, and a blended MER only when every currency matches the shop's
- A currency mismatch never gets an estimated converted figure (no rough or converted MER range)
- Google Ads conversions in its answer are never called purchases or orders; a failed or missing channel is never 0; a lagging channel is not a weak one

## Skill 0.1.7 (2026-11-18)

- Google Ads conversions are not orders: purchases come from a live read split by `segments.conversion_action_category`; otherwise the count mixes calls, leads and other actions
- Units (micros, fractions vs percent) and one definition per metric (net revenue, orders, ROAS, MER, sales), each answer naming its definition, source, dates, time zone and currency
- A currency mismatch names each mismatched source's own currency, read from `v2MarketingSourceStatuses` or its `v2*` report (`currencyCode`), never asked of the user, never labelled in the shop's currency
- Shopify's own analytics changes (sessions and bot filtering 21–23 Sep 2026, Performance by marketing channel in Sep, channel and medium values from 18 Oct, three deprecated attribution reports) are not tracking failures in Shopify's own numbers

## Skill 0.1.6 (2026-11-18)

- Profit answers: a `profitMerReport` row with `currencyMismatch: true` mixes currencies in `totalAdSpend`, `netProfit`, `mer`, `cpa`, `ncac` and `cac`; name the sources in `currencyMismatchAdSources`, give revenue and each source's spend in its own currency, and never add such rows into a total (stored reports since 17 Nov; Analyzify MCP 0.4.6 for the fields)
- STATUS lines: the last successful sync, not the last attempt; `failing` also covers a source Analyzify keeps retrying while nothing newer is stored (Analyzify MCP 0.4.6 or later)

## Skill 0.1.5 (2026-11-13)

- Google Ads counts over several pages: read every page, and give the total from the connector's `ALL PAGES READ` line (Analyzify MCP 0.4.5 or later), never your own sum; with an older connector, check the sum against 10,000 rows on every page but the last
- Break-even ROAS: always written as 1 / (margin × net share) with the net share named, even when it is 1, never shortened to 1 / margin; a worked example for when the margin is not known yet

## Skill 0.1.4 (2026-11-13)

- STATUS lines name each stored source's state in the connector's words from 0.4.4 (`fresh`, `behind_by_design`, `behind`, `stale`, `failing`, `syncing`, `no_data`, `not_connected`, `unknown`), with the newest stored day and how many days behind it is
- A source whose data stops more than a week back is stale: say the day it stops and suggest checking the connection; never call it current or "syncing normally". 1 to 4 days behind is normal
- Older connectors' words (`ok`, `sync_failing`) are still explained
- Klaviyo's newest day is its last send: a quiet week is normal
- Stored reports refresh about every second day (was "daily")

## Skill 0.1.2 (2026-11-12)

- Per-item Google Ads questions (how many items had spend, every item) use the live Shopping performance view: one row per item, summed over the period, counted page by page; items are variants per country feed, and a product count uses distinct product IDs; top items with ORDER BY and LIMIT, rows of one item added together
- `googleAds:search` (10,000 rows a page) over `searchStream` for long lists
- Stored product report: row counts without grouping are item × campaign rows; with grouping they include items without spend
- Answer rule: long answers come complete or in parts, never "narrow your question"; thousands of items get the exact count and the top items

## Skill 0.1.1 (2026-11-11)

- Take out the naive "losing money" rules: break-even is 1 / (margin × net share), not ROAS 1.0; settled days, two periods, enough volume and a tracking check before any verdict; facts instead of "pause", "cut" or "scale" (new `references/judging-performance.md`)
- Point ad questions at the `v2*` reports (Google Ads, Meta, TikTok), which compute rates from totals; legacy examples no longer read rates that are wrong over multi-day rows
- Answer rules in SKILL.md: rates from totals, empty is not zero, a failed read is not zero, name the source
- Source status check (`v2MarketingSourceStatuses`) before treating empty results as zero
- Google Ads results by product: roll-up recipe from variants (top items by spend, Shopify `nodes` 250 per call, sums per product)
- Klaviyo reference (campaigns, flows, attribution)
- Conversion, discount and sales-drop playbooks compare the store with its own history instead of generic benchmarks, and state findings instead of prescribing actions
- Fix queries that failed: `advertising_channel_type`, `ga4LandingPages` (flat list), a syntax error in channel attribution; replace the removed `ALL` attribution model with `LINEAR`, `U_SHAPED`, `ANY_CLICK`
- Profit: `grossMargin` is a percentage; MER, margin and AOV computed from totals; net profit does not subtract shipping; monthly rows are one per calendar month with ratios from the month's totals; customer and ad-click totals for CAC and CVR; days whose ad spend has not synced yet are called provisional
- Read only: Shopify reads take queries only, customer personal data is hidden unless the key has the `pii` capability, and the report access token is handled by the tools
- Session start reads which Meta, TikTok and Klaviyo report sources are connected

## 0.2.0 (2026-04-04, MCP server binary and skill files)

- Add 15 business playbooks (profit, diagnostics, weekly reports, ads, attribution, products, CRO, budget, traffic, SEO, customers, seasonal/YoY, discounts, conversion health)
- Expand reports.md with complete query reference for all report types (GA4, Google Ads, Meta, TikTok, Shopify, Search Console, Profit MER, Segments)
- Add "Report API first" strategy and playbook priority matching to SKILL.md
- Add skills.sh install support
- Add version tracking

## 0.1.0 (2026-03-30)

- Initial release with skill files and install script
- Core references: workspace, shopify, ga4, gsc, gads, reports
- MCP server binary distribution via GitHub Releases
