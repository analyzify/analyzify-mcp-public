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

For Claude Code:

```bash
analyzify-mcp setup --claude-code --api-key azfy_your-api-key
```

After setup, restart Claude Desktop to activate.

## Install Skill

The Analyzify skill teaches your AI assistant how to use the MCP server effectively — what queries to run, how to present data, and how to handle different analytics questions.

### Claude Desktop

1. Download the latest `analyzify-skill-v*.zip` from [Releases](https://github.com/analyzify/analyzify-mcp-public/releases)
2. Open Claude Desktop and go to **Settings > Customize > Skills**
3. Click **+** then **Create skill** then **Upload a skill**
4. Upload the zip file (no need to extract it)

See [Claude's skill documentation](https://support.claude.com/en/articles/12512180-use-skills-in-claude) for more details.

### ChatGPT

1. Download the latest `analyzify-skill-v*.zip` from [Releases](https://github.com/analyzify/analyzify-mcp-public/releases)
2. Extract the zip
3. Upload the skill files to your project's custom instructions or knowledge

### Claude Code

```bash
npx skills add analyzify/analyzify-mcp-public
```

## Manual Configuration

If you prefer to configure manually instead of using `analyzify-mcp setup`:

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "analyzify": {
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
  "analyzify": {
    "command": "analyzify-mcp",
    "args": ["serve"],
    "env": {
      "ANALYZIFY_API_KEY": "azfy_your-api-key"
    }
  }
}
```

> Without the API key, the server works in schema-only mode.

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
analyzify-mcp skill latest-version                # Check latest skill version
analyzify-mcp search proxy                        # Search schema
analyzify-mcp query '{ extMe { shopName } }'      # Execute a query
```

## MCP Tools

| Tool | Description |
|------|-------------|
| `introspect_schema` | Search the schema for types, queries, and mutations |
| `graphql_schema_full` | Returns the complete schema in SDL format |
| `execute_graphql` | Execute a GraphQL query against the live API |
| `introspect_report_schema` | Search the report schema for available report queries |
| `report_schema_full` | Returns the complete report schema in SDL format |
| `execute_report_graphql` | Execute a query against the Report API |

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
