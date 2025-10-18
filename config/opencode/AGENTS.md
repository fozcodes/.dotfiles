# Agent Guidelines for General Code and Practices

## General principles for all languages

- **Readability**: Prioritize clear, understandable code over clever or complex solutions.
- **Composition over Configuration**: Prefer composing small, reusable functions over large, monolithic classes or configurations.
- **Simplicity**: Strive for the simplest solution that works. Avoid over-engineering.
- **Testing**: Write tests for all new functionality. Use mocks and fixtures to isolate external dependencies.
- **Functional Programming**: Favor pure functions and immutability where possible. Avoid Object-Oriented Programming unless absolutely necessary.

## Typescript-specific guidelines

- **ALWAYS** Use TypeScript with strict mode enabled
- **ALWAYS** Make sure `noUncheckedIndexedAccess` is enabled in `tsconfig.json`. If it isn't, fix it, and let me know.
- Don't specify return types. You're not smarter than the compiler.
- Don't use OOP. Use functional programming principles.

## Python-specific guidelines

- Prefer to use Pydantic models and a functional programming approach to data transformations.
- Avoid Pandas like the plague. Use it only when absolutely necessary - which is pretty much never.
- Don't solve circular imports by using local imports; refactor and re-organize modules/folders instead.
