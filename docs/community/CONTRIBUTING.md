# Contributing to GitHub Runner

Thank you for considering contributing to this project! We welcome contributions of all kinds, including bug fixes, feature enhancements, documentation improvements, and more.

## How to Contribute

1. **Fork the Repository**: Create a fork of this repository on GitHub.
2. **Clone Your Fork**: Clone your fork to your local machine.
   ```bash
   git clone https://github.com/your-username/github-runner.git
   ```
3. **Switch to Develop**: Always start from and work on the `develop` branch.
   ```bash
   git checkout develop
   git pull origin develop
   ```
4. **Create a Branch**: Create a new branch for your changes from `develop`.
   ```bash
   git checkout -b feature/your-feature-name
   # or for hotfixes:
   git checkout -b hotfix/your-fix-name
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
9. **Open a Pull Request**: Open a pull request from your branch to the `develop` branch of this repository.

## Branch Strategy

- **`main`**: Production-ready code only. Protected branch that requires PR approval.
- **`develop`**: Active development branch. All features, hotfixes, and improvements go here.
- **Feature branches**: Create from `develop` for new features (`feature/feature-name`)
- **Hotfix branches**: Create from `develop` for urgent fixes (`hotfix/fix-name`)

**Important**: Never work directly on `main`. All development work should be done on `develop` or feature branches created from `develop`.

## Code Style

Please follow the coding style and conventions used in this repository. Consistent code style helps maintain readability and makes it easier for others to understand your contributions.

## Reporting Issues

If you encounter any issues or have suggestions for improvements, please open an issue in the [GitHub Issues](https://github.com/GrammaTonic/github-runner/issues) section of this repository.

## Code of Conduct

Please note that this project is governed by a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

Thank you for contributing!
