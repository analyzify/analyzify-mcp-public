# Changelog

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
