# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "markflow" - a Flutter Markdown editor application built with the shadcn/ui design system. The app started as a shadcn/ui component showcase but has evolved into a full-featured markdown editor with document management capabilities.

**Product Requirements**: See [PRODUCT_REQUIREMENTS.md](./PRODUCT_REQUIREMENTS.md) for detailed feature roadmap, implementation phases, and technical specifications.

## Development Commands

### Basic Commands
```bash
# Install dependencies
flutter pub get

# Run the app (defaults to available device)
flutter run

# Run on specific platforms
flutter run -d chrome    # Web
flutter run -d ios       # iOS Simulator
flutter run -d android   # Android Emulator

# Hot reload is available during development
```

### Code Quality
```bash
# Format code
dart format .

# Analyze code (linting)
flutter analyze

# Run tests
flutter test

# Clean and rebuild
flutter clean && flutter pub get
```

### Production Builds
```bash
# Web deployment
flutter build web --release

# Mobile builds
flutter build appbundle --release  # Android
flutter build ipa --release        # iOS
```

## Architecture Overview

### Core Structure
The application follows a feature-based architecture with clear separation of concerns:

- **Features**: Located in `lib/features/` - self-contained feature modules
- **Screens**: Located in `lib/screens/` - top-level screen widgets
- **Widgets**: Located in `lib/widgets/` - reusable UI components
- **Routes**: Centralized routing configuration using GoRouter

### Key Architectural Components

#### 1. Feature-Based Organization
The main functionality is organized into feature modules in `lib/features/`:
- `markdown/` - Core markdown editing functionality including editor screen, document management, and local storage

#### 2. Theme Management
- `ThemeController` (lib/theme_controller.dart): Singleton pattern for app-wide theme state management
- Supports light/dark/system theme modes using ValueNotifier for reactive updates
- Theme switching persists across app sessions

#### 3. Component Registry System
- `ComponentExampleRegistry` (lib/widgets/component_examples/): Centralized registration system for shadcn/ui components
- Components are organized by category: form, layout, navigation, feedback, media, data
- Provides search, filtering, and categorization capabilities

#### 4. Navigation Architecture
- Uses GoRouter for type-safe navigation (lib/routes/go_router_config.dart)
- Routes: `/` (home/docs), `/markdown/:id` (editor), `/docs` (document list), `/settings`
- NoTransitionPage used for seamless navigation experience

#### 5. Local Data Management
- `MdLocalStore` manages document persistence
- Document model (`MdDocument`) handles markdown content and metadata
- Supports document creation, editing, and deletion with auto-save functionality

### Key Files and Their Purpose
- `main.dart`: App entry point, initializes component registry and theme system
- `lib/features/markdown/editor_screen.dart`: Main markdown editor with dual-pane editing/preview
- `lib/features/markdown/local_store.dart`: Document persistence layer
- `lib/routes/go_router_config.dart`: Navigation configuration and route definitions
- `lib/theme_controller.dart`: App-wide theme management

### Dependencies and Libraries
- **shadcn_ui**: Primary UI component library (v0.28.5)
- **flutter_markdown**: Markdown rendering and parsing
- **go_router**: Type-safe navigation (v16.2.0)
- **provider**: State management (v6.1.5)
- **google_fonts**: Custom typography (Geist font family)
- **shared_preferences**: Persistent settings storage
- **file_saver**: Document export functionality

### Development Notes
- Component registry must be initialized before app startup (see main.dart:14)
- The app uses conditional imports for web/native platform-specific functionality
- Auto-save functionality with debounced updates in the markdown editor
- Responsive design using ShadResponsiveBuilder throughout the UI