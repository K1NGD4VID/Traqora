```markdown
# Traqora Development Patterns

> Auto-generated skill from repository analysis

## Overview
This skill documents the core development patterns, coding conventions, and workflows for the Traqora TypeScript codebase. Traqora is a TypeScript project without a specific framework, following conventional commit messages and a consistent code style. Testing is handled with Jest, and the repository emphasizes clarity and maintainability through its conventions.

## Coding Conventions

### File Naming
- Use **camelCase** for file names.
  - Example: `userProfile.ts`, `orderManager.test.ts`

### Import Style
- Mixed import styles are used, both default and named imports.
  - Example:
    ```typescript
    import { fetchUser } from './userService';
    import config from './config';
    ```

### Export Style
- Prefer **named exports**.
  - Example:
    ```typescript
    // Good
    export function calculateTotal() { ... }
    export const TAX_RATE = 0.07;

    // Avoid
    // export default function calculateTotal() { ... }
    ```

### Commit Messages
- Use **conventional commits** with the `feat` prefix for new features.
  - Example:
    ```
    feat: add user authentication middleware
    ```

## Workflows

### Feature Development
**Trigger:** When adding a new feature  
**Command:** `/feature-development`

1. Create a new branch for your feature.
2. Implement the feature using camelCase file naming and named exports.
3. Write or update relevant Jest tests in `*.test.ts` files.
4. Commit changes using the `feat:` prefix and a concise description.
5. Open a pull request for review.

### Testing
**Trigger:** Before merging or releasing code  
**Command:** `/run-tests`

1. Ensure all test files are named with the `.test.ts` suffix.
2. Run Jest to execute all tests:
    ```bash
    npx jest
    ```
3. Fix any failing tests before proceeding.

## Testing Patterns

- All tests are written using **Jest**.
- Test files follow the pattern: `*.test.ts`.
- Place test files alongside the code they test or in a dedicated `__tests__` directory.
- Example test:
    ```typescript
    // userService.test.ts
    import { fetchUser } from './userService';

    test('fetchUser returns user data', async () => {
      const user = await fetchUser(1);
      expect(user.id).toBe(1);
    });
    ```

## Commands
| Command              | Purpose                                  |
|----------------------|------------------------------------------|
| /feature-development | Start a new feature with conventions     |
| /run-tests           | Run all Jest tests before merging        |
```
