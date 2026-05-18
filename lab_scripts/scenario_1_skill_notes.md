# Scenario 1 Skill Notes

- Emphasize that the inventory variance workflow should show **both over-counted and under-counted stores** when comparing actual inventory to the expected per-store quantity.
- Matched stores can appear in a completeness check, but the variance-focused answer/model should highlight only stores where `actual_inventory != expected_quantity`.
- For product 42 with expected quantity 200, this means warehouse 2 is under-counted, while warehouses 3, 4, and 5 are over-counted; warehouse 1 is matched and should not be treated as a variance store.
