# Agent Guidelines for General Code and Practices

## BE CONCISE (always on)

Be brief. Plain English. No pleasantries. Facts only.

Write so the sentence is understood the first time. Use the ordinary word for
the thing. If that word is not already in the code or the conversation, define
it in the same sentence. Name the subject, say what it is, and say what happens
to it.

Keep the grammar that makes the sentence mean one thing. Cut filler, not
meaning.

State problems directly. Use ordinary words such as “problem” instead of
metaphors such as “leak”. Name the problem and its effect; omit commentary on
how completely the user diagnosed it. Say: “Your old approach had two problems.”

**Dictionary-verb check, before every sentence you send:**

Read each verb as its dictionary meaning. The sentence must still be true. If
the subject cannot do that action, replace the verb with the event that happens.

Use these words only for the physical thing they name. E.g.:

- gate: a door in a fence
- landed: a plane or bird arriving on the ground
- load-bearing: a pillar holding up a building

Do not compare a sentence to a person, story, or object unless the user asked
for that comparison. State the fact.

Use analogies only to teach or clarify how something works. Introduce the
analogy before using it, explain what it represents, and return to the direct
explanation. Do not use an unexplained analogy as decoration or shorthand.

## General version control guidelines

- **Commit Often**: Commit small, incremental changes frequently. Avoid large,
  monolithic commits.
- **Descriptive Commit Messages**: Use clear, descriptive commit messages that
  explain the "why" behind the change, not just the "what." Follow
  [Tim Pope's commit message guidelines](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
- **Branching Strategy**: Use a clearly named branches. If you're in subagent
  mode, use Git Worktrees to avoid polluting the main branch. Avoid long-lived
  branches; merge back to main frequently.
- **Conventional Commits**: Only use conventional commits if you're in a repo
  that has a clearly established convention. Otherwise, use _actual_ commit
  messages as described above.

## Execution discipline

- **Evidence**: Ground conclusions in authoritative state. Inspect the actual
  source, configuration, runtime artifact, path, version, and ownership before
  reporting a result.
- **Scope**: Treat the user’s stated target, naming, rollout order, and
  ownership boundaries as requirements. Preserve unrelated work and state.
- **Context**: Validate changes in their real execution environment: the
  deployed or rebuilt artifact, documented test environment, active shell, and
  exact data root.
- **Safety**: Report repository state and obtain approval before changing
  working-tree history or performing an operation with external or production
  impact. Prefer isolated, reversible validation.
- **Boundaries**: Keep systems, layers, producers, consumers, and authorization
  responsibilities distinct. Change the owning layer only.
- **Observability**: Make important state transitions and failures diagnosable
  through explicit checks, useful logs or traces, and clear recovery steps.

## General principles for all languages

- **Readability**: Prioritize clear, understandable code over clever or complex
  solutions. This includes using descriptive variable and function names - DO
  NOT ABBREVIATE.
- **Composition over Configuration**: Prefer composing small, reusable functions
  over large, monolithic classes or configurations.
- **Simplicity**: Strive for the simplest solution that works. Avoid
  over-engineering. Make every change as simple as possible. Impact minimal
  code.
- **Testing**: Write tests for all new functionality. Use mocks and fixtures to
  isolate external dependencies.
- **Functional Programming**: Favor pure functions and immutability where
  possible. Avoid Object-Oriented Programming unless absolutely necessary.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer
  standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid
  introducing bugs.

## Typescript-specific guidelines

- **ALWAYS** Use TypeScript with strict mode enabled
- **ALWAYS** Make sure `noUncheckedIndexedAccess` is enabled in `tsconfig.json`.
  If it isn't, fix it, and let me know.
- **NEVER** specify return types. You're not smarter than the compiler.
- **NEVER** use OOP. Use functional programming principles.
- **NEVER** use `any`. If you don't know the type, use generics or `unknown`.

## Python-specific guidelines

- Prefer to use Pydantic models and a functional programming approach to all
  designs.
- Do not use Pandas. Use it only when no other library can do the job.
- **NEVER** solve circular imports by using local imports; refactor and
  re-organize modules/folders instead.
- **NEVER** solve circular type imports using `if TYPE_CHECKING` imports;
  refactor and re-organize modules/folders instead.

### General best Python practices:

- Avoid Object Oriented Programming; prefer functional programming with pure
  functions. If you need something not offered by `functools`, use the Toolz
  library for functional utilities.
- DO NOT NEST functions or create closure functions.
- Avoid mutable state; prefer immutable data structures (tuples, frozensets).

## Workflow Orchestration

### 1. Plan Node Default

Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)

- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, run more subagents
- One task per subagent

### 3. Self-Improvement Loop

- After ANY correction from the user: update '.scratch/lessons.md' with the
  pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegant (Balanced)

- For non-trivial changes: pause and ask "Is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant
  solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

- Always use `.scratch/` for agent working files (`todo.md`, `lessons.md`,
  notes, temp plans). Never create repo-root `tasks/` for agent state.

1. _Plan First_: Write plan to '.scratch/todo.md' with checkable items
2. _Verify Plan_: Check in before starting implementation
3. _Track Progress_: Mark items complete as you go
4. _Explain Changes_: High-level summary at each step
5. _Document Results_: Add review section to '.scratch/todo.md'
6. _Capture Lessons_: Update '.scratch/lessons.md' after corrections
