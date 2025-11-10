# Markflow Test Suite

This directory contains the comprehensive test suite for the Markflow Flutter application. The tests are organized into three main categories following Flutter testing best practices.

## Test Structure

```
test/
├── unit/                           # Unit tests for business logic
│   ├── features/
│   │   └── markdown/              # Markdown feature tests
│   │       ├── models_test.dart           # MdDocument and MdVersion model tests
│   │       ├── local_store_test.dart      # Local storage functionality tests
│   │       └── download_test.dart         # Document download/export tests
│   ├── widgets/                   # Widget logic tests
│   │   ├── theme_controller_test.dart     # Theme management tests
│   │   ├── header_component_test.dart     # Header component logic tests
│   │   └── responsive_nav_test.dart       # Navigation logic tests
│   └── utils/                     # Utility function tests
│       ├── constants_test.dart            # App constants validation
│       └── routing_test.dart              # Router configuration tests
├── widget/                        # Widget tests for UI components
│   ├── editor/                    # Editor-related widget tests
│   │   ├── editor_screen_test.dart        # Main editor screen tests
│   │   └── formatting_toolbar_test.dart   # Formatting toolbar tests
│   ├── components/                # Reusable component tests
│   │   ├── header_component_test.dart     # Header UI tests
│   │   ├── responsive_nav_test.dart       # Navigation UI tests
│   │   └── code_viewer_test.dart          # Code syntax highlighting tests
│   └── screens/                   # Screen widget tests
│       ├── home_screen_test.dart          # Home screen UI tests
│       ├── docs_screen_test.dart          # Document list screen tests
│       └── settings_screen_test.dart      # Settings screen tests
└── integration/                   # End-to-end integration tests
    └── user_flows/                # User workflow tests
        ├── document_creation_flow_test.dart    # Document creation workflows
        ├── document_editing_flow_test.dart     # Document editing workflows
        ├── navigation_flow_test.dart           # App navigation workflows
        ├── theme_switching_flow_test.dart      # Theme switching workflows
        └── document_management_flow_test.dart  # Full document lifecycle tests
```

## Test Categories

### Unit Tests (`test/unit/`)
Tests individual functions, classes, and business logic in isolation. These tests:
- Run quickly and don't require Flutter framework
- Test business logic, data models, and utilities
- Mock external dependencies
- Validate edge cases and error handling

### Widget Tests (`test/widget/`)
Tests individual widgets and their rendering behavior. These tests:
- Render widgets in a test environment
- Test user interactions and UI behavior
- Verify widget properties and appearance
- Test responsive behavior and theme integration

### Integration Tests (`test/integration/`)
Tests complete user workflows and app functionality. These tests:
- Run the full application in a test environment
- Test end-to-end user scenarios
- Verify cross-screen functionality
- Test performance and error recovery

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Categories
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests only
flutter test test/integration/
```

### Run Specific Test Files
```bash
# Run specific test file
flutter test test/unit/features/markdown/models_test.dart

# Run tests with coverage
flutter test --coverage
```

### Integration Test Setup
Integration tests require additional setup:
```bash
# For web integration tests
flutter drive --driver=test_driver/integration_test.dart --target=test/integration/user_flows/navigation_flow_test.dart -d chrome

# For mobile integration tests
flutter drive --driver=test_driver/integration_test.dart --target=test/integration/user_flows/navigation_flow_test.dart -d <device_id>
```

## Test Implementation Status

All test files have been created with:
- ✅ Proper Flutter test imports
- ✅ Organized test groups with descriptive names
- ✅ Placeholder test cases with TODO comments
- ✅ Consistent naming conventions
- ✅ Appropriate test structure for each test type

## Next Steps

1. **Implement Test Cases**: Fill in the TODO placeholders with actual test implementations
2. **Add Test Utilities**: Create helper functions for common test setup and mocking
3. **Configure CI/CD**: Set up automated test running in your CI/CD pipeline
4. **Add Coverage Goals**: Establish coverage targets and monitoring
5. **Mock Dependencies**: Implement mocking for external dependencies (shared_preferences, file_saver, etc.)

## Testing Guidelines

### Unit Tests
- Focus on testing business logic and data transformations
- Mock all external dependencies
- Test edge cases and error conditions
- Keep tests fast and isolated

### Widget Tests
- Test widget rendering and user interactions
- Use `testWidgets()` for widget tests
- Mock data providers and external dependencies
- Test responsive behavior across different screen sizes

### Integration Tests
- Test complete user workflows
- Use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
- Test on real devices/browsers when possible
- Include performance and accessibility testing

## Dependencies

The test suite uses these Flutter testing packages:
- `flutter_test`: Core testing framework (included with Flutter)
- `integration_test`: Integration testing support (add to pubspec.yaml dev_dependencies if needed)

## Contributing

When adding new tests:
1. Follow the established directory structure
2. Use descriptive test names that explain what is being tested
3. Group related tests using `group()` blocks
4. Add appropriate setup and teardown logic
5. Include both positive and negative test cases
6. Test accessibility and responsive behavior where applicable