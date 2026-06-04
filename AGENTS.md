<!-- dft-dataface:start -->
## Dataface

This project uses [Dataface](https://github.com/fivetran/dataface) (`dft`) for visualizations, dashboards, and reports (YAML in `faces/`).

Learn how to work here — run:

- `dft skills dashboard-build`
- `dft skills dashboard-design`
- `dft skills report-design`
- `dft skills dashboard-review`
- `dft skills dataface-troubleshooting`

| Command | Use for |
|---------|---------|
| `dft schema` → `dft schema SRC` → `dft schema SRC SCH` → `dft schema SRC SCH TBL` → `dft schema SRC SCH TBL COL` | Drill data hierarchy: sources → schemas → tables → columns (each positional arg narrows one level) |
| `dft query` | Run queries |
| `dft serve` | Preview dashboards |
| `dft validate` | Check face YAML |
| `dft render` | Export |

Use `dft schema` for real names — do not invent columns.

More: `dft -h`, `dft docs`, `dft skills`. `dft init mcp` installs skills + wires MCP.
<!-- dft-dataface:end -->
