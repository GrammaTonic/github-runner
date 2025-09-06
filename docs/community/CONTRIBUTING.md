# Contributing to GitHub Runner

Thank you for considering contributing to this project! We welcome contributions of all kinds, including bug fixes, feature enhancements, documentation improvements, and more.

## How to Contribute

1. **Fork the Repository**: Create a fork of this repository on GitHub.
2. **Clone Your Fork**: Clone your fork to your local machine.
   ```bash
   git clone https://github.com/your-username/github-runner.git
   ```
3. **Start from Develop**: This repository uses an integration branch workflow. Create feature branches from `develop` and open pull requests to `develop`.
   ```bash
   git checkout develop
   git pull origin develop
   ```
4. **Create a Branch**: Create a new branch for your changes from `develop`.
   ```bash
   git checkout -b feature/your-feature-name
   # For urgent production hotfixes, branch from main instead:
   # git checkout -b hotfix/your-fix-name main
   ```
5. **Make Changes**: Make your changes in the new branch.
6. **Test Your Changes**: Ensure your changes work as expected and do not break existing functionality.
7. **Commit Your Changes**: Commit your changes with a clear and concise commit message.
   ```bash
   git commit -m "Description of your changes"
   ```
8. **Push Your Changes**: Push your changes to your fork.
   ```bash
   git push origin feature/your-feature-name
   ```
9. **Open a Pull Request**: Open a pull request from your feature branch to the `develop` branch of this repository.

10. **Release / Promote**: After your change is merged into `develop`, the integration branch is promoted to `main` via a pull request from `develop` → `main`. The release flow is:

- feature/\* → PR → develop
- develop → PR → main

To create the feature PR:

```bash
gh pr create --base develop --title "feat: ..." --body "..."
```

To promote develop to main (maintainers):

```bash
# After tests and approvals on develop
gh pr create --base main --head develop --title "chore: promote develop -> main" --body "Promote integration branch to main"
```

## Branch Strategy

**Important**: Never work directly on `main`. All regular development work should be done on feature branches created from `develop` and merged into `develop` via pull requests. For emergency hotfixes, branch from `main`, open a PR to `main`, and then merge `main` back to `develop` to keep integration in sync.

## Code Style

Please follow the coding style and conventions used in this repository. Consistent code style helps maintain readability and makes it easier for others to understand your contributions.

## Reporting Issues

If you encounter any issues or have suggestions for improvements, please open an issue in the [GitHub Issues](https://github.com/GrammaTonic/github-runner/issues) section of this repository.

## Code of Conduct

Please note that this project is governed by a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

Thank you for contributing!
