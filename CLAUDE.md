# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Allimgtools is a Ruby on Rails 8.1.2 application using Ruby 3.4.1. It follows standard Rails MVC architecture with modern frontend tooling (Tailwind CSS, Stimulus.js, Turbo) via Import Maps (no JavaScript bundler).

## Common Commands

### Development
```bash
bin/setup               # Install dependencies and setup database
bin/dev                 # Start development server (runs Puma + Tailwind CSS watcher)
```

### Testing
```bash
bin/rails test          # Run unit/integration tests
bin/rails test:system   # Run system/browser tests
bin/rails test test/models/user_test.rb           # Run a single test file
bin/rails test test/models/user_test.rb:10        # Run a specific test at line 10
```

### Linting & Security
```bash
bin/rubocop             # Ruby style checker (Rails Omakase preset)
bin/rubocop -a          # Auto-fix correctable offenses
bin/brakeman            # Security vulnerability scanner
bin/bundler-audit       # Gem vulnerability checker
bin/ci                  # Run full CI pipeline (setup, style, security, tests)
```

### Database
```bash
bin/rails db:prepare    # Create and migrate database
bin/rails db:seed       # Seed database
bin/rails dbconsole     # Database console
```

## Architecture

### Technology Stack
- **Backend**: Rails 8.1.2, Puma, SQLite3
- **Frontend**: Tailwind CSS, Stimulus.js, Turbo Rails (via Import Maps)
- **Background Jobs**: Solid Queue (in-process)
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **File Storage**: Active Storage (local disk, configurable for S3/GCS)

### Key Directories
- `app/javascript/controllers/` - Stimulus controllers (auto-loaded via Import Maps)
- `app/assets/stylesheets/` - Tailwind CSS styles
- `config/importmap.rb` - JavaScript module mappings

### Base Classes
- `ApplicationController` - Enforces modern browser support, handles import map caching
- `ApplicationRecord` - Base model with abstract class setup
- `ApplicationJob` - Base for Solid Queue jobs

### Testing
- Parallel test execution enabled
- System tests use Capybara + Selenium
- Failed test screenshots saved as artifacts in CI

## CI/CD

GitHub Actions runs on push to main and PRs:
1. Security scanning (Brakeman, Bundler Audit, Import Map audit)
2. RuboCop linting
3. Full test suite

## Deployment

Uses Kamal for Docker-based deployment. Configuration in `config/deploy.yml`.
