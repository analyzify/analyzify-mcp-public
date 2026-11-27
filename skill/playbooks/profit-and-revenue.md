# Playbook: Profit & Revenue Analysis

## Triggers

"What's my profit?", "Am I making money?", "Revenue this month?", "Show me P&L", "Net profit?", "Gross margin?", "How much am I spending on ads?", "MER?", "Marketing efficiency?", "Break down my costs", "COGS?", "Shipping costs?", "Ad spend breakdown"

## Strategy

**For a period's totals and its change against another period:** the `performance_summary` tool first; it reads the same profit report.

**"Shipping costs?":** the store's own shipping costs (what it pays carriers) are not in Analyzify's data: say so. The profit report's `shippingCost` is shipping charged to customers, which is income, not a cost; give it only under that name.

**For figures by day or by month:** `profitMerReport` via Report API — this single query combines Shopify orders + Google Ads + Meta + TikTok into one unified profit view. First call the `source_status` tool: if a connected ad source's data stops before the end of the period, its spend may be missing from those days (or the account had no delivery), so name it and call the profit for those days provisional.

**If profitMerReport returns empty:** check `source_status` first (not synced is not zero), then give Shopify's sales from `shopifyOrderAgg` and each platform's spend from `channel_breakdown`, each with its own source; never compute a profit from them.

## Queries

### 1. Full Profit Report (daily trend)

```graphql
query($input: ProfitMerInput!) {
  profitMerReport(input: $input) {
    dated year month week day
    netRevenue netProfit currency
    googleAdsSpend metaAdsSpend tiktokAdsSpend totalAdSpend
    costOfGoodsSold shippingCost
    mer grossProfit grossMargin
    orders aov
    newCustomers newCustomerPercentage totalCustomers
    cpa ncac cac cvr adClicks
    adSpendComplete incompleteAdSources
    currencyMismatch currencyMismatchAdSources
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
      "groupByDate": true
    }
  }
}
```

### 2. Monthly Summary (for period comparison)

Same query with `groupByFields: ["month"]`: one row per calendar month (`year` and `month`), and every ratio on it (MER, margin, AOV, cost per order `cpa`, NCAC, CAC, CVR) is computed from the month's totals. A month that is not fully inside the date range covers only the days in the range.

### 3. Period Totals

There is no single "totals" row: `groupByDate` is ignored and rows are one per day (or one per month, above). For a period, add up the rows (`netRevenue`, `grossProfit`, `costOfGoodsSold`, `shippingCost`, `totalAdSpend` and each platform's spend, `orders`, `newCustomers`, `totalCustomers`, `adClicks`, `netProfit`).

**Compute ratios from those sums:** MER = `netRevenue / totalAdSpend`, cost per order (`cpa`) = `totalAdSpend / orders`, NCAC = `totalAdSpend / newCustomers`, CAC = `totalAdSpend / totalCustomers` and CVR = `orders / adClicks × 100` **over the days with `adSpendComplete: true` only** (every sum in them from those days), the rule the monthly rows and `channel_breakdown`'s blended line use, so every answer gives one figure for one period; say how many days were left out. Gross margin = `grossProfit / netRevenue` and AOV = `netRevenue / orders` from all rows. Never average the daily `mer`, `grossMargin` or `aov`. `totalCustomers` counts customers per day, so summed over days a customer who ordered on two days counts twice. `grossMargin` is a percentage (40 means 40%).

**Ad spend not synced yet:** a row with `adSpendComplete: false` (today and up to two days before it, in UTC) may be missing the spend of the sources in `incompleteAdSources` (or the account simply had no delivery), so its net profit may be too high and its ad spend too low. Leave them out of MER and cost per order (above), say those days are provisional, or end the period before them. Older days are never flagged: a source whose data stops early (check `v2MarketingSourceStatuses`) counts as no spend there, so say its MER may be too high. On a monthly row, `mer`, `cpa`, `ncac`, `cac` and `cvr` leave those days out while `netProfit` and `totalAdSpend` include them: for the current month, end the period before the flagged days and add up the daily rows. A monthly ratio of 0 with `adSpendComplete: false` means "not known yet", not zero.

**Ad spend in another currency:** `currency` is the currency of the store's orders (the shop's currency on a store that sells in one currency; a store that sells in several can mix currencies in its revenue too), and each source's spend is its ad account's own amount, never converted. A row with `currencyMismatch: true` has spend from the sources in `currencyMismatchAdSources` (for example a Canadian-dollar Google Ads account on a US-dollar shop) in their own currency, so that row's `totalAdSpend`, `netProfit`, `mer`, `cpa`, `ncac` and `cac` add or divide amounts in different currencies. Don't report them, and don't add such rows into a period's total. Say which sources bill in another currency, give revenue and orders and each source's spend in its own currency, and say a combined profit or MER needs the spend converted first. Read each of those sources' own billing currency from `v2MarketingSourceStatuses` (`currencyCode`, one call for every source) or from its own `v2*` report's `meta.currencyCode`, and name it: never ask the user for it, and never label that source's amounts in the shop's currency. If it is empty, say that source's currency is not known. With several accounts of one source, it is the newest account's currency. Never estimate a converted figure yourself: no rough, approximate or converted MER, profit or ROAS range across currencies. If one day of the period has the flag, the period's sums mix currencies too. Only the source's most recently stored account is checked, so with several accounts of one source in different currencies, the others are not: `currencyMismatch: false` means no mismatch was found, not proof of none.

**Older gaps are not flagged:** `adSpendComplete: true` does not prove the spend is complete. A sync that has been failing for weeks is not flagged on older days. Before reporting profit, check `v2MarketingSourceStatuses` covers the whole period for every connected ad source, and name any source whose data stops early (a paused account also has no rows, so say spend may be missing, not that it is).

**Days without orders:** only days with Shopify orders or refunds are in the report. Ad spend on a day with neither is not counted, so `totalAdSpend` can be a little lower than the ad platforms show.

**Missing product costs:** a product without a cost in Shopify counts as zero COGS, so gross profit, margin and net profit come out too high. If `costOfGoodsSold` is under 30% of `netRevenue` over the same rows (0 included), say so and ask the merchant for their usual margin before a break-even.

## How to Present

### Quick Summary (when user asks "how's my profit?")

Present a clean summary table:

| Metric | Value |
|--------|-------|
| Net Revenue | $X |
| Ad Spend | $X (Google: $X, Meta: $X, TikTok: $X) |
| COGS | $X |
| Shipping charged to customers (income, not a cost) | $X |
| **Net Profit** | **$X** |
| Gross Margin | X% |
| MER | X.Xx |

### Trend (when user asks "revenue trend")

For "this month vs last", use `performance_summary` with the month before as `compare_start_date` / `compare_end_date`, and take its changes as given. For a trend, run the daily query and present as a time series. Highlight:
- Best and worst days
- Overall trend direction
- Any significant spikes or drops

### Cost Breakdown (when user asks "where is my money going?")

| Cost Category | Amount | % of Revenue |
|---------------|--------|-------------|
| COGS | $X | X% |
| Google Ads | $X | X% |
| Meta Ads | $X | X% |
| TikTok Ads | $X | X% |
| **Total ad spend** (`totalAdSpend`, not a sum you make) | **$X** | **X%** |
| **Net Profit** (`netProfit`) | **$X** | **X%** |

`shippingCost` is shipping charged to the customer, not a cost: never list it among the costs.

### Unit Economics (when user asks about CAC, cost per order, AOV)

The report's `cpa` is a cost per order, not a platform's cost per conversion: call it cost per order. For a platform's CPA (spend / its own conversions), use `playbooks/ad-performance.md`.

| Metric | Value | What It Means |
|--------|-------|---------------|
| AOV | $X | Average order value |
| Cost per order (`cpa`) | $X | Total ad spend per Shopify order |
| CAC | $X | Cost to acquire one customer |
| NCAC | $X | Cost to acquire one NEW customer |
| MER | X.Xx | $X revenue per $1 ad spend |
| CVR | X% | Orders per 100 ad clicks |

## Key Calculations

- **MER** = Net Revenue / Total Ad Spend (higher is better; whether it is "good" depends on the margin: compare with break-even, `references/judging-performance.md`)
- **Gross Margin** = (Revenue - COGS) / Revenue × 100
- **Net Profit** = Net Revenue - COGS - Ad Spend (as the report computes it; shipping costs, fees and other costs are not subtracted, so say "profit after product cost and ads")
- **Cost per order** (`cpa`) = Total Ad Spend / Total Orders
- **CAC** = Total Ad Spend / Total Customers
- **NCAC** = Total Ad Spend / New Customers Only
- **CVR** = Orders / Total Clicks × 100

## Common Follow-ups

- "Break it down by day/week/month" → daily rows as returned; for weeks, add up the days yourself; for months, `groupByFields: ["month"]`
- "Compare to last month" → `performance_summary` with the calendar month before as `compare_start_date` / `compare_end_date`
- "Which ads are most profitable?" → pivot to `playbooks/ad-performance.md` (`v2GadsCampaigns` + `v2MetaCampaigns`); judge profit against break-even ROAS, not 1.0 (`references/judging-performance.md`)
- "What's my best selling product?" → Analyzify has no report that adds up sales per product: say so, then read Shopify's sales live (both reads are in `playbooks/sales-and-orders.md`). Where the store granted Analyzify `read_reports` (not granted by default; `currentAppInstallation { accessScopes { handle } }` lists it), Shopify's own net sales by product is one read (`shopifyqlQuery`: `FROM sales SHOW net_sales GROUP BY product_title`, with `SINCE` and `UNTIL` for the asked dates, `ORDER BY net_sales DESC`). Without it, add up the order line items' `discountedTotal` per product for the period (`shopifyOrders` → `orderLineItems`; many pages on a large store), never `quantity × variantPrice`. `ga4ProductPerformances` is GA4's own item revenue: name it as GA4's, not Shopify's sales. `shopifyOrderAgg` does not group by product. Never answer it with an ad platform's numbers per product (`product_performance` is ad spend and attributed revenue per product).
