# Playwright tests

Run the Playwright tests locally or on a runner that has Node and Playwright installed.

Install deps:

```bash
cd tests/playwright
npm ci
npx playwright install --with-deps
npm test
```

Note: The repository does not alter runner images automatically—use the provided `docker/Dockerfile.chrome` image which includes Playwright in CI.
