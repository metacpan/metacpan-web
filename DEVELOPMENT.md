# Development Setup Guide

This guide helps you set up a local development environment for MetaCPAN Web.

## Quick Setup

For automated setup, run:

```bash
./bin/setup-dev
```

This script will:
- Check system requirements
- Install system dependencies (libcmark-dev)
- Install Perl development tools (carton, cpm)
- Install all project dependencies
- Build static assets
- Set up git hooks
- Run basic tests

## Manual Setup

If you prefer to set up manually or the automated script doesn't work in your environment:

### Prerequisites

- Perl 5.36+ (tested with 5.38.2)
- Node.js 20+ (tested with 20.19.4)
- npm 10+ (tested with 10.8.2)
- System dependencies: libcmark-dev (on Ubuntu/Debian)

### Install Dependencies

1. **Install system dependencies:**
   ```bash
   # On Ubuntu/Debian
   sudo apt-get install libcmark-dev
   
   # On macOS
   brew install cmark
   ```

2. **Install Perl tools:**
   ```bash
   # Install carton and cpm
   cpan App::carton App::cpm
   ```

3. **Install Node.js dependencies:**
   ```bash
   npm install
   ```

4. **Install Perl dependencies:**
   ```bash
   # Using cpm (faster)
   cpm install --resolver=snapshot
   
   # Or using carton
   carton install
   ```

5. **Build static assets:**
   ```bash
   npm run build
   ```

6. **Set up git hooks:**
   ```bash
   ./git/setup.sh
   ```

## Running the Application

### Development Server

```bash
carton exec plackup -p 5001 -r app.psgi
```

The application will be available at http://localhost:5001

### Alternative Servers

For better performance during development:

```bash
# Using Gazelle
carton exec plackup -p 5001 -s Gazelle -r app.psgi

# Using Starman
carton exec plackup -p 5001 -s Starman app.psgi
```

## Testing

### Run All Tests

```bash
carton exec prove -l -r --jobs 2 t
```

### Run Specific Tests

```bash
# Basic functionality tests (work offline)
carton exec prove -l t/moose.t t/assets.t t/session.t

# Specific controller tests
carton exec prove -l t/controller/about.t
```

### Note on Test Failures

Many tests require network access to `api.metacpan.org` and will fail in isolated environments. This is expected behavior. The core functionality tests (like `t/moose.t`, `t/assets.t`, etc.) should pass.

## Asset Development

### Building Assets

```bash
# One-time build
npm run build

# Minified build (for production)
npm run build:min

# Watch for changes during development
npm run build:watch
```

### Asset Files

- Source files: `root/static/`
- Built files: `root/assets/`
- Build configuration: `build-assets.mjs`

## Code Quality

### Linting

The project uses `precious` to orchestrate various linters:

```bash
# Install precious (if not using Docker)
./bin/install-precious /usr/local/bin

# Lint all files
precious lint --all

# Lint specific files
precious lint path/to/file

# Auto-fix issues
precious tidy --all
```

### Git Hooks

Pre-commit hooks are configured to run `precious` automatically. Set them up with:

```bash
./git/setup.sh
```

## Docker Development

For a completely isolated environment, use Docker:

```bash
# Build development image
docker build --target develop -t metacpan-web:dev .

# Run development container
docker run -it -p 5001:8000 -v $(pwd):/app metacpan-web:dev
```

## Configuration

### Local Configuration

Create a `metacpan_web_local.yaml` file to override settings:

```yaml
api: http://127.0.0.1:5000  # Local API server
debug: 1
```

### Environment Variables

- `PLACK_ENV`: Set to `development` for development mode
- `METACPAN_WEB_HOME`: Path to application root (auto-detected)

## Troubleshooting

### Common Issues

1. **Asset map errors**: Run `npm run build` to generate assets
2. **Permission errors**: Check that `local/` directory is writable
3. **Test failures**: Most network-dependent tests will fail without API access
4. **Module not found**: Ensure `carton exec` is used or local lib is in `PERL5LIB`

### Getting Help

- Check the main [README.md](README.md)
- Review existing [issues](https://github.com/metacpan/metacpan-web/issues)
- Ask in the MetaCPAN IRC channel or discussions