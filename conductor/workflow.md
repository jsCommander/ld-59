# Development Workflow

## Git Policy

- **Never commit automatically.** All commits are made by the user, not by the agent
- **Never push, rebase, or reset** without explicit user approval
- **No Co-Authored-By** headers in commits

## Task Execution

1. Read the task from the plan
2. Understand what needs to be done — explain the plan before acting
3. Implement the change
4. Verify it works (run the scene if applicable, check for errors)
5. Move to the next task

## Code Quality

- Follow GDScript style guide (see `conductor/code_styleguides/gdscript.md`)
- Follow CLAUDE.md principles (composition, groups, signals, typed everything)
- No over-engineering — minimum complexity for the current task
- No extra features, no "improvements" beyond what was asked

## Phase Completion

At the end of each phase:
- Summarize what was done
- List any issues or decisions that need user input
- Wait for user to confirm before moving to next phase
