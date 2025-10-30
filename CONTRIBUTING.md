# Contributing to Linode GPU Kubeflow Deployment

Thank you for your interest in contributing! This project provides infrastructure-as-code for deploying GPU-enabled Kubernetes clusters on Linode for machine learning workloads.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/akamai-linode-kubeflow-deployment.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

### Prerequisites
- OpenTofu/Terraform
- linode-cli configured with valid API token
- kubectl
- Basic understanding of Kubernetes and infrastructure-as-code

### Local Testing
```bash
# Check prerequisites
./setup.sh

# Validate OpenTofu configuration
cd tofu
tofu init
tofu validate
tofu fmt -check -recursive

# Test deployment (in a test account/region)
cd ..
./deploy.sh plan
```

## Contribution Guidelines

### Code Style

**OpenTofu/Terraform:**
- Use consistent formatting: `tofu fmt -recursive`
- Follow [HashiCorp style guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use meaningful variable names
- Add comments for complex logic
- Use locals for computed values

**Bash Scripts:**
- Use shellcheck for linting
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Add comments for non-obvious operations
- Use functions for reusable code
- Handle errors gracefully

**Documentation:**
- Use clear, concise language
- Include examples where helpful
- Keep README.md updated
- Document all configuration variables
- Update architecture diagrams when needed

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat(tofu): add support for multiple node pools

docs(readme): update installation instructions

fix(deploy): resolve API token loading issue
```

### Pull Request Process

1. **Update Documentation**: Ensure all docs reflect your changes
2. **Test Thoroughly**: Verify your changes work as expected
3. **Update CHANGELOG**: Add entry for your changes
4. **Follow Code Style**: Run formatters and linters
5. **Write Clear PR Description**: Explain what and why

PR Template:
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Infrastructure improvement

## Testing
- [ ] Tested locally
- [ ] Updated tests (if applicable)
- [ ] Documentation updated

## Checklist
- [ ] Code follows project style
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] No breaking changes (or documented)
```

## Areas for Contribution

### High Priority
- [ ] Kubeflow deployment automation (Phase 2)
- [ ] Multi-region support
- [ ] Cost optimization strategies
- [ ] Monitoring and alerting setup
- [ ] Backup and disaster recovery

### Features
- [ ] Custom GPU node types
- [ ] Multi-node pool support
- [ ] Advanced networking configurations
- [ ] CI/CD pipeline examples
- [ ] Example ML workloads

### Documentation
- [ ] Video tutorials
- [ ] More troubleshooting guides
- [ ] Best practices guide
- [ ] Performance tuning guide
- [ ] Cost optimization tips

### Testing
- [ ] Automated integration tests
- [ ] GPU validation test suite
- [ ] Performance benchmarks
- [ ] Security scanning

## Reporting Issues

### Bug Reports
Use the issue template and include:
- Clear description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, tool versions)
- Relevant logs or error messages

### Feature Requests
Describe:
- Use case and motivation
- Proposed solution
- Alternative solutions considered
- Additional context

## Code Review Process

1. Maintainers will review PRs within 1-2 weeks
2. Address review feedback promptly
3. Keep PRs focused and reasonably sized
4. Be open to suggestions and improvements

## Community

- Be respectful and inclusive
- Help others when possible
- Share knowledge and experiences
- Follow standard open source etiquette

## Questions?

- Open an issue for questions
- Check existing issues and discussions
- Review documentation first

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
