# Agent Guidelines for General Code and Practices

## BE CONCISE

Be extremely concise. Sacrifice grammar for the sake of concision at all times.

## General principles for all languages

- **Readability**: Prioritize clear, understandable code over clever or complex solutions.
- **Composition over Configuration**: Prefer composing small, reusable functions over large, monolithic classes or configurations.
- **Simplicity**: Strive for the simplest solution that works. Avoid over-engineering. Make every change as simple as possible. Impact minimal code.
- **Testing**: Write tests for all new functionality. Use mocks and fixtures to isolate external dependencies.
- **Functional Programming**: Favor pure functions and immutability where possible. Avoid Object-Oriented Programming unless absolutely necessary.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimat Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Typescript-specific guidelines

- **ALWAYS** Use TypeScript with strict mode enabled
- **ALWAYS** Make sure `noUncheckedIndexedAccess` is enabled in `tsconfig.json`. If it isn't, fix it, and let me know.
- Don't specify return types. You're not smarter than the compiler.
- Don't use OOP. Use functional programming principles.
- **NEVER** use `any`. If you don't know the type, use generics or `unknown`.

## Python-specific guidelines

- Prefer to use Pydantic models and a functional programming approach to all designs.
- Avoid Pandas like the plague. Use it only when absolutely necessary - which is pretty much never.
- **NEVER** solve circular imports by using local imports; refactor and re-organize modules/folders instead.
- **NEVER** solve circular type imports using `if TYPE_CHECKING` imports; refactor and re-organize modules/folders instead.

### General best Python practices:

- Avoid Object Oriented Programming; prefer functional programming with pure
  functions. Use the Toolz library for functional utilities.
- DO NOT NEST functions or create closure functions.
- Avoid mutable state; prefer immutable data structures (tuples, frozensets).
- Don't solve circular imports by using local imports; refactor and re-organize modules/folders instead

## Workflow Orchestration

### 1. Plan Node Default

Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)

- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop

- After ANY correction from the user: update '.scratch/lessons.md' with the pattern
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
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

- Always use `.scratch/` for agent working files (`todo.md`, `lessons.md`, notes, temp plans). Never create repo-root `tasks/` for agent state.

1. _Plan First_: Write plan to '.scratch/todo.md' with checkable items
2. _Verify Plan_: Check in before starting implementation
3. _Track Progress_: Mark items complete as you go
4. _Explain Changes_: High-level summary at each step
5. _Document Results_: Add review section to '.scratch/todo.md'
6. _Capture Lessons_: Update '.scratch/lessons.md' after corrections
