# Blast Radius Prompt Template

Use this template when a user asks for every reference to a source or contract column before making a schema-drift fix.

```text
Show me every model, source definition, test, and YAML file in this project that references the column <column_name>. I need a complete blast-radius list before changing anything.

Please list the results grouped as:
1. Broken source-side references
2. Source definitions or YAML documentation
3. Downstream models using the public dbt contract column
4. Tests that directly reference the column
5. Any other relevant files

For each result, include:
- file path
- line number if available
- short explanation of why it matters

Also distinguish between:
- references that must be fixed
- downstream contract references that should be preserved
- documentation-only references
```

For Scenario 3, use this concrete prompt:

```text
Show me every model, source definition, test, and YAML file in this project that references the product column brand. I need a complete blast-radius list before changing anything.

Please list the results grouped as:
1. Broken source-side references
2. Source definitions or YAML documentation
3. Downstream models using the public dbt contract column
4. Tests that directly reference the column
5. Any other relevant files

For each result, include the file path, line number if available, and why it matters. Also tell me which references need to change versus which downstream references should stay unchanged because the staging model should preserve the public column name.
```

Expected grouping for the standard lab setup:

- Broken source-side references: `models/staging/stg_products.sql` selecting `brand` from `RET_PRODUCTS`.
- Source definitions or YAML documentation: `models/staging/_staging__sources.yml` source description mentioning product brand.
- Downstream models using the public contract: product intermediates and marts that select `brand` from `stg_products` or derived product models.
- Tests directly referencing the column: usually none in the standard lab setup.
- Other files: exclude lab setup scripts and generated artifacts unless the user explicitly asks for non-dbt assets.
