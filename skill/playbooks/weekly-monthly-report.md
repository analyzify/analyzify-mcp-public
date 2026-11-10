# Playbook: Weekly / Monthly Business Report

## Triggers

"Give me a weekly report", "Monthly recap", "Send me a summary", "Weekly numbers", "Monthly performance report", "How did we do this week/month?", "Executive summary", "Board report", "Business review"

## Strategy

Compose data from multiple queries into a structured business report. Run all queries for the requested period, then present in a standardized format.

**Required queries (run in sequence):**

1. `profitMerReport` — revenue, profit, costs, unit economics (totals)
2. `profitMerReport` — same but with `groupByDate: true` for trend
3. `ga4Scorecards` — traffic + conversion with auto-comparison
4. `ga4Channels` — channel breakdown (groupByDate: false, groupByFields: ["channel_name"])
5. `v2GadsCampaigns` — top campaigns (if Google Ads connected)
6. `v2MetaCampaigns` — top Meta campaigns (if Meta connected)
7. `v2TiktokCampaigns` — top TikTok campaigns (if TikTok connected)
8. `ga4ProductPerformances` — top products (groupByDate: false, groupByFields: ["item_name"])
9. `shopifyCampaignAttributionReport` — attribution summary

**Only query channels that show as connected in extMe.**

## Report Template

Present in this exact structure:

---

### [Store Name] — [Period] Performance Report

**Period:** [Start Date] — [End Date]
**Compared to:** [Previous Period]

---

#### Revenue & Profit

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Gross Revenue | $X | $X | +X% |
| Net Revenue | $X | $X | +X% |
| Net Profit | $X | $X | +X% |
| Gross Margin | X% | X% | +Xpp |
| MER | X.Xx | X.Xx | |

#### Costs

| Cost | Amount | % of Revenue |
|------|--------|-------------|
| COGS | $X | X% |
| Google Ads | $X | X% |
| Meta Ads | $X | X% |
| TikTok Ads | $X | X% |
| Shipping | $X | X% |
| **Total Costs** | **$X** | **X%** |

#### Orders & Customers

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Total Orders | X | X | +X% |
| AOV | $X | $X | +X% |
| New Customers | X | X | +X% |
| New Customer % | X% | X% | |
| CAC | $X | $X | |
| CPA | $X | $X | |

#### Traffic & Conversion

| Metric | This Period | Previous | Change |
|--------|------------|----------|--------|
| Sessions | X | X | +X% |
| Users | X | X | +X% |
| Conversion Rate | X% | X% | +Xpp |

#### Channel Performance

| Channel | Sessions | Revenue | Conv. Rate | ROAS |
|---------|----------|---------|------------|------|
| Organic Search | X | $X | X% | — |
| Paid Search | X | $X | X% | X.Xx |
| Paid Social | X | $X | X% | X.Xx |
| Email/Direct | X | $X | X% | — |
| Other | X | $X | X% | — |

#### Top 5 Campaigns (by Revenue)

| Campaign | Platform | Spend | Revenue | ROAS |
|----------|----------|-------|---------|------|
| Campaign A | Google | $X | $X | X.Xx |
| Campaign B | Meta | $X | $X | X.Xx |
| Campaign C | Google | $X | $X | X.Xx |
| Campaign D | TikTok | $X | — | — |
| Campaign E | Meta | $X | $X | X.Xx |

Revenue and ROAS here are the platform's own numbers (TikTok reports conversions but no value). A recent week isn't settled yet: say so instead of calling a campaign weak.

#### Top 5 Products (by Revenue)

| Product | Units Sold | Revenue | Views | Cart Rate |
|---------|-----------|---------|-------|-----------|
| Product A | X | $X | X | X% |
| Product B | X | $X | X | X% |
| Product C | X | $X | X | X% |
| Product D | X | $X | X | X% |
| Product E | X | $X | X | X% |

#### Key Takeaways

After reviewing all data, provide 3-5 bullet points:

- **Wins:** What improved and why (be specific)
- **Concerns:** What declined and the likely cause
- **Opportunities:** Untapped potential spotted in the data
- **Action Items:** 2-3 specific things to do next week/month

---

## Period Defaults

| Request | Start Date | End Date | Compare To |
|---------|-----------|---------|------------|
| "Weekly report" | Last Monday | Last Sunday | Week before |
| "This week" | This Monday | Today | Same days last week |
| "Monthly report" | 1st of last month | Last day of last month | Month before |
| "This month" | 1st of this month | Today | Same days last month |
| "Quarterly" | Quarter start | Quarter end or today | Previous quarter |

Use the store's timezone (`shopifyIanaTimezone` from extMe) to determine day boundaries.

## Notes

- Always show both absolute values AND percentage changes
- Highlight the most significant changes (>20% swing) positively or negatively
- If a metric is missing (channel not connected), skip that section — don't show zeros
- For weekly reports, use daily grouping for trend context
- For monthly reports, use weekly grouping for trend context
- End with actionable takeaways, not just numbers
