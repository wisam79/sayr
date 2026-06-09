# Contributing to Sayr

## Setup

```bash
# Clone the repository
git clone https://github.com/your-org/sayr.git
cd sayr

# Install melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run code generation
melos run build:runner
```

## Development

```bash
# Run all tests
melos run test

# Run tests with coverage
melos run test:coverage

# Format and analyze
melos run format
melos run analyze:strict
```

## Architecture

- **Clean Architecture**: domain → data → presentation
- **State Management**: flutter_bloc
- **DI**: get_it + injectable
- **Routing**: go_router
- **Backend**: Supabase (PostgreSQL + Edge Functions)

## PR Requirements

- ✅ All tests pass (`melos run test`)
- ✅ `flutter analyze` zero warnings
- ✅ `melos run format:check` passes
- ✅ Coverage ≥80%
- ✅ Conventional commits (`feat:`, `fix:`, `refactor:`)
