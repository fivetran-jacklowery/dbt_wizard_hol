# Skill Behavior Improvement Notes

- Skills should be **scenario-specific accelerators**, not end-to-end autopilots. A skill should speed up inference by narrowing the domain, expected data shape, and safe next action, but it should not cause the agent to run an entire scenario workflow without explicit user direction.
- Do **not** run a scenario end to end just because a request matches the scenario. Execute only the specific step the user asked for, then stop at the next natural checkpoint.
- Add more specific trigger phrases for each scenario so the agent can reliably choose the correct skill without over-broad matching. Triggers should distinguish inventory allocation, product quality/returns, support-ticket enrichment, customer segmentation, and source schema drift.
- Once a scenario skill is triggered, keep referencing that same skill for follow-up turns until the user mentions a different skill trigger or clearly changes domains.
- In meta-discussion contexts where the user is evaluating or improving a skill, do not execute the skill workflow or edit dbt files unless the user explicitly says to implement the scenario now.
- If a user asks something that resembles a scenario prompt immediately after discussing skill behavior, clarify whether they want execution or only analysis/notes before making project changes.
- Have each scenario step end with: "What should we do next?"
- When a user provides a prompt matching a specific scenario step, execute only that step. For edit steps, include the minimal safety checks required by the engineering workflow, but do not advance to the next scripted scenario step unless the user explicitly asks.
- Do not mention the scenario name/number in responses to the user. The scenarios are not secret; they are simply implementation context that is not relevant to the attendee's task.
- Expect the lab to proceed linearly in this default order: New User Onboarding -> Scenario 1 -> Scenario 2 -> Scenario 3, where the new Scenario 3 is the broken product/source-schema-change use case. Scenario 4 is the optional Marketing targeted-campaign use case. The instructor may skip one or more scenarios entirely, and that is valid. Skills should handle skipped scenarios without trying to backfill missed steps.
- Keep responses optimized for a time-sensitive lab. These skills exist to reduce inference and execution time, so responses should stay focused on the current requested step and the next actionable checkpoint.
