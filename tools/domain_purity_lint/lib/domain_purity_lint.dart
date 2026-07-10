import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Entry point required by custom_lint.
PluginBase createPlugin() => _DomainPurityPlugin();

class _DomainPurityPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const DomainNoFlutterImport(),
      ];
}

/// Lint rule: domain layer files must not import package:flutter/.
class DomainNoFlutterImport extends DartLintRule {
  /// Creates the rule.
  const DomainNoFlutterImport() : super(code: _code);

  static const _code = LintCode(
    name: 'domain_no_flutter_import',
    problemMessage:
        'domain 層不得 import flutter(純 Dart 規則)',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // Only run on files inside lib/domain/
    final path = resolver.path.replaceAll(r'\', '/');
    if (!path.contains('/lib/domain/')) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.startsWith('package:flutter/')) {
        reporter.atNode(node, _code);
      }
    });
  }
}
