---
name: skill-creator
description: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, update or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.
---

# Skill Creator

A skill for creating new skills and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill to do and roughly how it should do it
- Write a draft of the skill
- Create a few test prompts and run claude-with-access-to-the-skill on them
- Help the user evaluate the results both qualitatively and quantitatively
- Rewrite the skill based on feedback from the user's evaluation
- Repeat until you're satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages.

## Communicating with the user

Pay attention to context cues to understand how to phrase your communication. Briefly explain terms if you're in doubt, and feel free to clarify terms with a short definition if you're unsure if the user will get it.

---

## Creating a skill

### Capture Intent
Start by understanding the user's intent.

1. What should this skill enable the agent to do?
2. When should this skill trigger? (what user phrases/contexts)
3. What's the expected output format?
4. Should we set up test cases to verify the skill works?

### Interview and Research
Proactively ask questions about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until you've got this part ironed out.

### Write the SKILL.md
Based on the user interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does. This is the primary triggering mechanism - include both what the skill does AND specific contexts for when to use it.
- **the rest of the skill**

### Skill Writing Guide

#### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic/repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output (templates, icons, fonts)
```

#### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines ideal)
3. **Bundled resources** - As needed (unlimited, scripts can execute without loading)

**Key patterns:**
- Keep SKILL.md under 500 lines; if approaching this limit, add hierarchy with clear pointers
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

#### Writing Patterns

Prefer using the imperative form in instructions.

**Defining output formats:**
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern:**
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style
Explain to the model why things are important. Use theory of mind and try to make the skill general. Start by writing a draft and then look at it with fresh eyes and improve it.

### Test Cases
After writing the skill draft, come up with 2-3 realistic test prompts. Share them with the user. Save test cases to `evals/evals.json`.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

---

## Running and evaluating test cases

This section is one continuous sequence.

### Step 1: Run test cases
For each test case, run the agent with the skill applied, and optionally a baseline run without the skill for comparison.

### Step 2: Draft assertions
While runs are in progress, draft quantitative assertions for each test case. Good assertions are objectively verifiable and have descriptive names.

### Step 3: Capture timing data
When each run completes, save timing data (tokens, duration) to `timing.json`.

### Step 4: Grade, aggregate, and launch the viewer
Once all runs are done:
1. Grade each run against assertions
2. Aggregate results into a benchmark report
3. Present to the user for review

### Step 5: Read the feedback
Read user feedback. Empty feedback means the user thought it was fine. Focus improvements on test cases where the user had specific complaints.

---

## Improving the skill

This is the heart of the loop. You've run the test cases, the user has reviewed results, and now you need to make the skill better based on their feedback.

### How to think about improvements
1. **Generalize from the feedback.** Rather than put in fiddly overfitty changes, try branching out and using different metaphors, or recommending different patterns.

2. **Keep the prompt lean.** Remove things that aren't pulling their weight.

3. **Explain the why.** Try hard to explain the **why** behind everything. Today's LLMs are *smart*. They have good theory of mind and when given a good harness can go beyond rote instructions.

4. **Look for repeated work across test cases.** If all test cases resulted in the agent writing similar helper scripts, that's a signal the skill should bundle that script in `scripts/`.

### The iteration loop
After improving the skill:

1. Apply your improvements to the skill
2. Rerun all test cases into a new iteration directory
3. Present results for review
4. Wait for the user to review
5. Read the new feedback, improve again, repeat

Keep going until:
- The user says they're happy
- The feedback is all empty
- You're not making meaningful progress

---

## Reference files

The skill folder may contain additional directories:
- `agents/` — Instructions for specialized subagents (grader, comparator, analyzer)
- `references/` — JSON schemas and documentation
- `scripts/` — Automation scripts for benchmarking and packaging

---

Core loop summary:
1. Figure out what the skill is about
2. Draft or edit the skill
3. Run the agent with the skill on test prompts
4. Evaluate the outputs with the user
5. Repeat until satisfied
6. Package the final skill
