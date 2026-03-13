## 2025-11-17 - [Entrypoint Script Input Validation]
**Vulnerability:** Unvalidated environment variables in Docker entrypoint scripts could lead to path traversal or arbitrary file overwrites.
**Learning:** Container entrypoint scripts often trust environment variables passed at runtime (e.g., via docker-compose or Kubernetes), creating a vector for path traversal if those variables are used in file operations (like `touch` or `mv`).
**Prevention:** Implement strict validation for all environment variables in entrypoint scripts. For paths, enforce allowed directories (e.g., `/tmp`), specific file extensions, and block path traversal sequences (`..`). For numeric values (ports, intervals), enforce digit-only patterns.
