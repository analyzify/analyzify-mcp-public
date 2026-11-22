# Analyzify MCP

A Model Context Protocol (MCP) server for [Analyzify](https://analyzify.com/) — the Shopify analytics and tracking app ([Shopify App Store](https://apps.shopify.com/analyzify)).

Connects AI assistants to your Shopify store data, Google Analytics 4, Google Search Console, Google Ads, and historical analytics reports through natural conversation.

## Install MCP Server

### macOS / Linux

```bash
curl -sL https://raw.githubusercontent.com/analyzify/analyzify-mcp-public/main/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/analyzify/analyzify-mcp-public/main/install.ps1 | iex
```

### Manual install

Download from the [Releases](https://github.com/analyzify/analyzify-mcp-public/releases) page, extract, and place in your `PATH`.

### Verify

```bash
analyzify-mcp version
```

## Setup

The easiest way to configure Claude Desktop is with the setup command:

```bash
analyzify-mcp setup
```

This will ask for your API key and automatically update your Claude Desktop config. You can also pass the key directly:

```bash
analyzify-mcp setup --api-key azfy_your-api-key
```

Then restart Claude Desktop to activate.

For Claude Code:

```bash
analyzify-mcp setup --claude-code --api-key azfy_your-api-key
```

Setup checks the key and names the connector `analyzify-<store>`, so each store's key gets its own connector.

## Recipes and rules: built in

There is no skill to install. Since v0.4.26 the MCP server carries Analyzify's answer rules and recipes itself
(the `recipe` tool, and one prompt per playbook in clients that show MCP prompts). If you installed the Analyzify
skill earlier, you can remove it. Keep the server up to date with `analyzify-mcp self-update` (on Windows, run the
install command again), then restart Claude Desktop.

The `skill/` folder in this repo is a copy of the server's recipe source, synced at each release: changes go to the
server's source, never here.

## Manual Configuration

If you prefer to configure manually instead of using `analyzify-mcp setup` (one entry per store key, each with its own
name, such as `analyzify-<store>`):

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "analyzify-mystore": {
      "command": "analyzify-mcp",
      "args": ["serve"],
      "env": {
        "ANALYZIFY_API_KEY": "azfy_your-api-key"
      }
    }
  }
}
```

**Cursor / VS Code** (MCP settings):

```json
{
  "analyzify-mystore": {
    "command": "analyzify-mcp",
    "args": ["serve"],
    "env": {
      "ANALYZIFY_API_KEY": "azfy_your-api-key"
    }
  }
}
```

> Without the API key, only the schema tools work; every read answers that the connector has no API key.

## What You Can Ask

**Profit & Revenue:** "What's my profit?", "MER?", "P&L breakdown?"

**Diagnostics:** "Why are my sales down?", "What changed since last month?"

**Reports:** "Give me a weekly report", "Monthly business summary"

**Ads & ROAS:** "How are my Google Ads performing?", "Best/worst campaigns?"

**Attribution:** "Where do my orders come from?", "Channel attribution?"

**Products:** "Best selling products?", "Which products should I promote?"

**Traffic & SEO:** "Top search queries?", "Organic vs paid traffic?"

**Conversion:** "How do I improve my conversion rate?", "Cart abandonment?"

**Customers:** "New vs returning customers?", "Customer acquisition cost?"

**Seasonal:** "Compare to last year?", "Am I on track for my annual target?"

**Promotions:** "Did my sale help?", "Are discounts cutting into margin?"

**Tracking:** "Is my conversion tracking working?", "Last Google Ads conversion?"

## CLI Commands

```bash
analyzify-mcp setup                              # Configure Claude Desktop automatically
analyzify-mcp serve                              # Start MCP server (stdio)
analyzify-mcp serve --transport sse --addr :8080  # Start MCP server (SSE HTTP)
analyzify-mcp version                             # Print version
analyzify-mcp self-update                         # Update to latest version
analyzify-mcp self-update --check                 # Check for updates
analyzify-mcp search proxy                        # Search schema
analyzify-mcp query '{ extMe { shopName } }'      # Execute a query
```

## MCP Tools

The answers first; the raw reads are there for anything they don't cover.

| Tool | What it answers |
|------|-----------------|
| `whoami` | The store, the key's rights, the connector version, every source's state, and the answer rules |
| `performance_summary` | The store over a date range against a comparison period: orders, sales, profit, ad spend, MER |
| `channel_breakdown` | Google Ads, Meta and TikTok side by side (spend, each platform's own conversions, ROAS) against Shopify's orders, plus Analyzify's attributed orders per channel |
| `product_performance` | Google Ads spend and return per product |
| `source_status` | Each data source's state: how fresh it is, the last successful sync, and why one fails |
| `metric_definitions` | What each metric means, its unit and how it is computed |
| `recipe` | Analyzify's recipes, such as the weekly report and channel comparisons |
| `execute_graphql` | A read-only query against the live API (Shopify, Google Analytics, Search Console, Google Ads) |
| `execute_report_graphql` | A read-only query against Analyzify's stored reports |
| `introspect_schema`, `graphql_schema_full` | The live API's schema |
| `introspect_report_schema`, `report_schema_full` | The stored reports' schema |
| `fetch_more_results` | The other parts of a long result |

## Links

- [Analyzify Website](https://analyzify.com/)
- [Analyzify on Shopify App Store](https://apps.shopify.com/analyzify)

## Uninstall

**macOS / Linux:**
```bash
sudo rm /usr/local/bin/analyzify-mcp
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:LOCALAPPDATA\analyzify-mcp" -Recurse -Force
```
