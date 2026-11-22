---
name: align
description: Interview the user until every decision in a plan is settled. Use when starting new work, or when the user asks to align on, pressure-test, or grill an idea.
---

Settle every decision in the plan before any work starts.

## How to ask

- Treat the plan as a tree: each decision opens the ones that depend on it.
- Ask one question at a time whose prerequisites are settled. Hold back anything that depends on an answer you don't have yet.
- Number each question. Give each a short title, the options as a short list, and your recommendation in one sentence.
- Phrase each question so "yes" accepts your recommendation.
- Wait for an answer, then ask the next question.

## Facts vs decisions

- Facts are yours to find. Look them up yourself, using a sub-agent for anything broad. Never ask the user something the code or tools can answer.
- Decisions are the user's. Ask about every one; never assume.

## Finishing

When no open questions remain, or if the user indicates the questioning can end, post a summary in four parts:

- **Decided**: each decision, with its reason
- **Rejected**: options considered and why they lost
- **Out of scope**: what was explicitly excluded
- **Open**: decisions not made yet

Once the user confirms the planning is complete, tell them to run `spec`. Build nothing yourself.
