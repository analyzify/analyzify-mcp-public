# Changelog

## Skill 0.1.1 (2026-11-11)

- Take out the naive "losing money" rules: break-even is 1 / (margin × net share), not ROAS 1.0; settled days, two periods, enough volume and a tracking check before any verdict; facts instead of "pause", "cut" or "scale" (new `references/judging-performance.md`)
- Point ad questions at the `v2*` reports (Google Ads, Meta, TikTok), which compute rates from totals; legacy examples no longer read rates that are wrong over multi-day rows
- Answer rules in SKILL.md: rates from totals, empty is not zero, a failed read is not zero, name the source
- Source status check (`v2MarketingSourceStatuses`) before treating empty results as zero
- Google Ads results by product: roll-up recipe from variants (top items by spend, Shopify `nodes` 250 per call, sums per product)
- Klaviyo reference (campaigns, flows, attribution)
- Fix queries that failed: `advertising_channel_type`, `ga4LandingPages` (flat list), a syntax error in channel attribution; replace the removed `ALL` attribution model with `LINEAR`, `U_SHAPED`, `ANY_CLICK`
- Profit: `grossMargin` is a percentage; MER, margin and AOV computed from totals; net profit does not subtract shipping

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
