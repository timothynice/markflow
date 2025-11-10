import 'package:flutter_test/flutter_test.dart';
import 'package:markflow/features/markdown/services/syntax_highlight_service.dart';

void main() {
  group('SyntaxHighlightService', () {
    late SyntaxHighlightService service;

    setUp(() {
      service = SyntaxHighlightService.instance;
    });

    group('Language Detection', () {
      test('should detect Dart code correctly', () {
        const dartCode = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}''';

        final detectedLanguage = service.detectLanguage(dartCode);
        expect(detectedLanguage, equals('dart'));
      });

      test('should detect JavaScript code correctly', () {
        const jsCode = '''
function hello() {
  console.log('Hello, world!');
  const message = "Hello";
  let count = 0;
}''';

        final detectedLanguage = service.detectLanguage(jsCode);
        expect(detectedLanguage, equals('javascript'));
      });

      test('should detect TypeScript code correctly', () {
        const tsCode = '''
interface User {
  name: string;
  age: number;
}

function greet(user: User): void {
  console.log(\`Hello, \${user.name}\`);
}''';

        final detectedLanguage = service.detectLanguage(tsCode);
        expect(detectedLanguage, equals('typescript'));
      });

      test('should detect Python code correctly', () {
        const pythonCode = '''
def hello_world():
    print("Hello, world!")
    return True

import os
from datetime import datetime''';

        final detectedLanguage = service.detectLanguage(pythonCode);
        expect(detectedLanguage, equals('python'));
      });

      test('should detect HTML code correctly', () {
        const htmlCode = '''
<!DOCTYPE html>
<html>
<head>
  <title>Test Page</title>
</head>
<body>
  <h1>Hello World</h1>
</body>
</html>''';

        final detectedLanguage = service.detectLanguage(htmlCode);
        expect(detectedLanguage, equals('html'));
      });

      test('should detect CSS code correctly', () {
        const cssCode = '''
.container {
  display: flex;
  justify-content: center;
  align-items: center;
}

#header {
  background-color: #333;
}''';

        final detectedLanguage = service.detectLanguage(cssCode);
        expect(detectedLanguage, equals('css'));
      });

      test('should detect JSON code correctly', () {
        const jsonCode = '''
{
  "name": "test",
  "version": "1.0.0",
  "dependencies": {
    "flutter": "^3.0.0"
  }
}''';

        final detectedLanguage = service.detectLanguage(jsonCode);
        expect(detectedLanguage, equals('json'));
      });

      test('should detect YAML code correctly', () {
        const yamlCode = '''
name: my_app
description: A new Flutter project
version: 1.0.0+1

dependencies:
  flutter:
    sdk: flutter''';

        final detectedLanguage = service.detectLanguage(yamlCode);
        expect(detectedLanguage, equals('yaml'));
      });

      test('should detect Java code correctly', () {
        const javaCode = '''
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }

    private void doSomething() {
        // implementation
    }
}''';

        final detectedLanguage = service.detectLanguage(javaCode);
        expect(detectedLanguage, equals('java'));
      });

      test('should detect Kotlin code correctly', () {
        const kotlinCode = '''
fun main() {
    println("Hello, World!")
}

class Person(val name: String, var age: Int)''';

        final detectedLanguage = service.detectLanguage(kotlinCode);
        expect(detectedLanguage, equals('kotlin'));
      });

      test('should detect Go code correctly', () {
        const goCode = '''
package main

import "fmt"

func main() {
    fmt.Println("Hello, World!")
}

func add(a, b int) int {
    return a + b
}''';

        final detectedLanguage = service.detectLanguage(goCode);
        expect(detectedLanguage, equals('go'));
      });

      test('should detect Rust code correctly', () {
        const rustCode = '''
fn main() {
    println!("Hello, world!");
}

struct Person {
    name: String,
    age: u32,
}

impl Person {
    fn new(name: String, age: u32) -> Person {
        Person { name, age }
    }
}''';

        final detectedLanguage = service.detectLanguage(rustCode);
        expect(detectedLanguage, equals('rust'));
      });

      test('should detect Swift code correctly', () {
        const swiftCode = '''
import Foundation

func greet(name: String) {
    print("Hello, \\(name)!")
}

let message: String = "Hello, World!"
var count: Int = 0''';

        final detectedLanguage = service.detectLanguage(swiftCode);
        expect(detectedLanguage, equals('swift'));
      });

      test('should detect SQL code correctly', () {
        const sqlCode = '''
SELECT name, age
FROM users
WHERE age > 18
ORDER BY name;

INSERT INTO products (name, price)
VALUES ('iPhone', 999.99);''';

        final detectedLanguage = service.detectLanguage(sqlCode);
        expect(detectedLanguage, equals('sql'));
      });

      test('should fallback to dart for unknown code', () {
        const unknownCode = '''
This is some random text
that doesn't match any
programming language patterns.''';

        final detectedLanguage = service.detectLanguage(unknownCode);
        expect(detectedLanguage, equals('dart'));
      });

      test('should handle empty code', () {
        const emptyCode = '';
        final detectedLanguage = service.detectLanguage(emptyCode);
        expect(detectedLanguage, equals('dart'));
      });

      test('should handle whitespace-only code', () {
        const whitespaceCode = '   \\n\\t  \\n  ';
        final detectedLanguage = service.detectLanguage(whitespaceCode);
        expect(detectedLanguage, equals('dart'));
      });
    });

    group('Language Aliases', () {
      test('should normalize JavaScript aliases', () {
        expect(service.isLanguageSupported('js'), isTrue);
        expect(service.isLanguageSupported('jsx'), isTrue);
      });

      test('should normalize TypeScript aliases', () {
        expect(service.isLanguageSupported('ts'), isTrue);
        expect(service.isLanguageSupported('tsx'), isTrue);
      });

      test('should normalize Python aliases', () {
        expect(service.isLanguageSupported('py'), isTrue);
        expect(service.isLanguageSupported('python3'), isTrue);
      });

      test('should normalize CSS aliases', () {
        expect(service.isLanguageSupported('scss'), isTrue);
        expect(service.isLanguageSupported('sass'), isTrue);
        expect(service.isLanguageSupported('less'), isTrue);
      });

      test('should normalize HTML aliases', () {
        expect(service.isLanguageSupported('htm'), isTrue);
        expect(service.isLanguageSupported('xml'), isTrue);
      });

      test('should normalize YAML aliases', () {
        expect(service.isLanguageSupported('yml'), isTrue);
      });

      test('should normalize JSON aliases', () {
        expect(service.isLanguageSupported('jsonc'), isTrue);
      });
    });

    group('Language Support', () {
      test('should return true for supported languages', () {
        for (final language in SyntaxHighlightService.supportedLanguages) {
          expect(service.isLanguageSupported(language), isTrue);
        }
      });

      test('should return false for unsupported languages', () {
        expect(service.isLanguageSupported('unsupported'), isFalse);
        expect(service.isLanguageSupported('random'), isFalse);
        expect(service.isLanguageSupported(''), isFalse);
      });

      test('should return available languages', () {
        final languages = service.getAvailableLanguages();
        expect(languages, isNotEmpty);
        expect(languages, containsAll(SyntaxHighlightService.supportedLanguages));
      });
    });

    group('Initialization', () {
      test('should handle initialization gracefully', () async {
        // This test ensures initialization doesn't throw
        await expectLater(
          () => service.initialize(),
          returnsNormally,
        );
      });
    });

    group('Edge Cases', () {
      test('should handle mixed language content', () {
        const mixedCode = '''
<script>
function test() {
  console.log("JavaScript inside HTML");
}
</script>''';

        // Should detect HTML due to the tags
        final detectedLanguage = service.detectLanguage(mixedCode);
        expect(detectedLanguage, equals('html'));
      });

      test('should prefer more specific patterns', () {
        const typeScriptCode = '''
const user: { name: string; age: number } = {
  name: "John",
  age: 30
};''';

        // Should detect TypeScript due to type annotations
        final detectedLanguage = service.detectLanguage(typeScriptCode);
        expect(detectedLanguage, equals('typescript'));
      });

      test('should handle single line code', () {
        const singleLine = 'console.log("Hello, World!");';
        final detectedLanguage = service.detectLanguage(singleLine);
        expect(detectedLanguage, equals('javascript'));
      });

      test('should handle code with only comments', () {
        const commentOnly = '''
// This is a JavaScript comment
/* Multi-line comment
   in JavaScript */''';
        final detectedLanguage = service.detectLanguage(commentOnly);
        // Should fallback to default since no executable code
        expect(detectedLanguage, equals('dart'));
      });
    });

    group('Performance', () {
      test('should handle large code blocks efficiently', () {
        final largeCode = 'console.log("test");\\n' * 1000;

        final stopwatch = Stopwatch()..start();
        final detectedLanguage = service.detectLanguage(largeCode);
        stopwatch.stop();

        expect(detectedLanguage, equals('javascript'));
        // Should complete within reasonable time (less than 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should handle multiple rapid detections', () {
        const codes = [
          'console.log("test");',
          'print("hello")',
          'function test() {}',
          'def test(): pass',
          'public class Test {}',
        ];

        final stopwatch = Stopwatch()..start();
        for (final code in codes) {
          service.detectLanguage(code);
        }
        stopwatch.stop();

        // Should complete all detections quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}