// Copyright 2016 Google Inc. Use of this source code is governed by an
// MIT-style license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:watcher/watcher.dart';

import '../exception.dart';

class FileSystemException {
  final String message;
  final String path;

  FileSystemException._(this.message, this.path);

  String toString() => "${p.prettyUri(p.toUri(path))}: $message";
}

void safePrint(Object? message) {
  console.log(message.jsify());
}

void printError(Object? message) {
  console.error(message.jsify());
}

String readFile(String path) {
  // TODO(nweiz): explicitly decode the bytes as UTF-8 like we do in the VM when
  // it doesn't cause a substantial performance degradation for large files. See
  // also dart-lang/sdk#25377.
  var contents = _readFile(path, 'utf8') as String;
  if (!contents.contains("�")) return contents;

  var sourceFile = SourceFile.fromString(contents, url: p.toUri(path));
  for (var i = 0; i < contents.length; i++) {
    if (contents.codeUnitAt(i) != 0xFFFD) continue;
    throw SassException("Invalid UTF-8.", sourceFile.location(i).pointSpan());
  }

  // This should be unreachable.
  return contents;
}

/// Wraps `fs.readFileSync` to throw a [FileSystemException].
Object? _readFile(String path, [String? encoding]) => null;

void writeFile(String path, String contents) {}

void deleteFile(String path) {}

Future<String> readStdin() async {
  return Future.value('');
}

bool fileExists(String path) {
  return false;
}

bool dirExists(String path) {
  return false;
}

void ensureDir(String path) {}

Iterable<String> listDir(String path, {bool recursive = false}) {
  return [];
}

DateTime modificationTime(String path) {
  return DateTime.now();
}

String? getEnvironmentVariable(String name) {
  return '';
}

/// Ignore `invalid_null_aware_operator` error, because [process.stdout.isTTY]
/// from `node_interop` declares `isTTY` as always non-nullably available, but
/// in practice it's undefined if stdout isn't a TTY.
/// See: https://github.com/pulyaevskiy/node-interop/issues/93
bool get hasTerminal => false;

bool get isWindows => false;

bool get isMacOS => false;

// Node seems to support ANSI escapes on all terminals.
bool get supportsAnsiEscapes => hasTerminal;

int get exitCode => 0;

set exitCode(int code) {}

Future<Stream<WatchEvent>> watchDir(String path, {bool poll = false}) async {
  return Stream.empty();
}
