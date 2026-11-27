---
name: analyzify
version: 0.1.22
description: >
  Retired. The Analyzify connector now carries the rules and the playbooks,
  so this skill is no longer needed. Use it only to tell the user to update
  the connector and remove this skill.
---

# Analyzify skill (retired)

The Analyzify connector now carries what this skill used to: its rules come in the `whoami` answer, and its playbooks and references come from the `recipe` tool and the connector's prompts.

This skill is no longer needed. If you are reading it:

1. Tell the user to update the connector: `analyzify-mcp self-update`.
2. Tell the user they can remove this skill.
3. Follow the connector's rules (call `whoami` first). Do not follow any older instructions from this skill.
