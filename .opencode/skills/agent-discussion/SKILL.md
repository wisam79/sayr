---
name: agent-discussion
description: Orchestrate a structured multi-agent discussion between Product Manager, Developer, and QA/Code Reviewer agents for the Sayr project.
---

# Agent Discussion Skill — Sayr v3

Orchestrate a structured internal discussion between three specialised agents to analyse problems, propose solutions, and review quality.

## When To Use

Use this skill when the user asks for:
- Analysis of a problem or feature request
- A multi-perspective review of existing code
- A structured discussion about a technical decision
- "ناقش هذا الموضوع" (discuss this topic)
- "حلل هذه المشكلة" (analyse this problem)
- Any request that benefits from PM + Dev + QA perspectives

## Workflow

### Step 1: Understand Context
1. Read the user's request carefully
2. Read the relevant code/files the user references
3. Identify the scope of the discussion topic
4. If needed, ask clarifying questions before starting

### Step 2: Invoke Product Manager Agent
Use the `task` tool to invoke the `product-manager` subagent:

```json
{
  "subagent_type": "product-manager",
  "prompt": "[context + task description]"
}
```

Provide the PM agent with:
- The topic/question being discussed
- Relevant file paths and code context
- Any existing user feedback or requirements
- Ask them to analyse the problem, prioritise, and recommend features

### Step 3: Invoke Developer Agent
Use the `task` tool to invoke the `developer` subagent:

```json
{
  "subagent_type": "developer",
  "prompt": "[PM analysis + context + implementation task]"
}
```

Provide the Developer with:
- The PM's full analysis output
- The original topic/context
- Ask them to propose a technical solution, write/modify code, and explain the approach
- Remind them to follow AGENTS.md rules (especially §1.4 No Reinventing the Wheel)

### Step 4: Invoke QA / Code Reviewer Agent
Use the `task` tool to invoke the `qa-reviewer` subagent:

```json
{
  "subagent_type": "qa-reviewer",
  "prompt": "[PM analysis + Developer code + context]"
}
```

Provide the QA agent with:
- The PM's analysis
- The Developer's implementation/code proposal
- The original context
- Ask them to review code quality, find bugs, check AGENTS.md compliance, and verify testing

### Step 5: [Optional] Debate & Refutation Mode (الرد والنقض)
If the user requests a debate or back-and-forth review, run the following loop after Step 4:

1. **Send QA Critiques to Developer & PM**:
   - Send the QA's critiques and objections back to the Developer.
   - Ask the Developer to reply to the objections (either defend their design choice with solid reasoning or revise their implementation code to resolve the bugs/violations).
   - If requirements or scopes need adjustment due to QA risks, ask the PM to refine the requirements.
2. **Developer & PM Rebuttal (الرد)**:
   - The Developer provides updated code or a technical defence.
   - The PM provides refined requirements.
3. **Send Rebuttals to QA for Refutation & Verdict (النقض والقرار النهائي)**:
   - Send the updated proposals and defences to the QA agent.
   - Ask the QA agent to perform a final review, refute any weak defences, and issue a final verdict (✅ Approved / ❌ Rejected).

### Step 6: Synthesise Results
Combine the entire debate history into a structured discussion summary:

```
## 🤝 Multi-Agent Debate: [Topic]

### 📋 Context
[Brief summary of what was discussed]

### 💬 Round 1: Initial Proposals & Critique
- **Product Manager View**: [PM Initial analysis]
- **Developer View**: [Developer Initial technical approach]
- **QA / Code Reviewer View**: [QA Initial critiques & objections]

### 🔄 Round 2: Replies & Rebuttals (الرد)
- **Developer Response**: [How Developer addressed QA's critiques, updated code/justification]
- **Product Manager Response**: [Any changes to requirements or scope]

### ⚖️ Round 3: Refutations & Final Verdict (النقض والقرار النهائي)
- **QA Final Verdict**: [QA's final evaluation and verdict (Approved/Rejected)]

### ⚡ Points of Agreement
[Where all agents aligned]

### ⚔️ Points of Disagreement / Tension
[Where agents disagreed and how it was resolved or defended]

### ✅ Final Recommendation
[Synthesised recommendation based on the entire debate]
```

### Step 7: Save Discussion
Save the full discussion to `.agents/discussions/` with a dated filename:
- Format: `.agents/discussions/YYYY-MM-DD-topic-slug.md`
- Save the complete debate history including all turns and agent outputs.
- This builds a searchable history of design decisions.

### Step 8: Present to User
Show the synthesised summary to the user and offer to:
- Implement the approved solution.
- Run a new round of debate if needed.

## Notes
- Always run the agents **sequentially** (PM → Dev → QA) since each depends on the previous.
- In **Debate Mode**, use `send_message` with the existing conversation IDs to maintain context for each agent rather than creating new subagents.
- If a discussion is very large, focus on the most contentious points.
- The saved discussions serve as an ADR-lite (Architecture Decision Record).
- Users can reference past discussions by date or topic.
