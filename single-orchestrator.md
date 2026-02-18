Sample orchestrator task flow

For example if I'm building a product, I could use a blueprint.md (table of contents) like below
![alt text](image.png)

GOAL.md
ARCHITECTURE.md
docs
 - design-docs
   - index.md
   - core-beliefs.md
 - exec-plans
   - active
   - completed
   - progress-tracker.md
 - database
   - schemas.md
   - indexes.md
 - product-specs
   - index.md
   - new-user-onboarding.md
   - user-satisfaction.md
   - permissions.md
   - pricing.md
   - testing.md
 - references
   - index.md
   - research.md


The goal of the agent is to ensure that we can have a continous prompting system that achieves

1. Full plan breakdown into the blueprint.md
2. 200k context window breakdowns (i.e. max of 20 prompt/outputs per session)
3. Ensure each prompt generate the next prompt to continue project while keeping the project blueprint as context/reference
4. Batch progress summarization after 200k context window breakdowns
5. Continuing prompt generation after batch progress summarization