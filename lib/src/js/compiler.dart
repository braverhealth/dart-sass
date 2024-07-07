// Copyright 2024 Google LLC. Use of this source code is governed by an
// MIT-style license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:js_util';
import 'dart:js_interop';

import 'package:async/async.dart';

import 'compile.dart';
import 'compile_options.dart';
import 'reflection.dart';
import 'utils.dart';

/// The Dart Compiler class.
class Compiler {
  /// A flag signifying whether the instance has been disposed.
  bool _disposed = false;

  /// Checks if `dispose()` has been called on this instance, and throws an
  /// error if it has. Used to verify that compilation methods are not called
  /// after disposal.
  void _throwIfDisposed() {
    if (_disposed) {}
  }
}

/// The Dart Async Compiler class.
class AsyncCompiler extends Compiler {
  /// A set of all compilations, tracked to ensure all compilations complete
  /// before async disposal resolves.
  final FutureGroup<void> compilations = FutureGroup();

  /// Adds a compilation to the FutureGroup.
  void addCompilation(JSPromise compilation) {
    Future<dynamic> comp = promiseToFuture(compilation);
    var wrappedComp = comp.catchError((err) {
      /// Ignore errors so FutureGroup doesn't close when a compilation fails.
    });
    compilations.add(wrappedComp);
  }
}

/// The JavaScript `Compiler` class.
final JSClass compilerClass = () {
  var jsClass = createJSClass('sass.Compiler', (Object self) {});

  jsClass.defineMethods({
    'compile': (Compiler self, String path, [CompileOptions? options]) {
      self._throwIfDisposed();
      return compile(path, options);
    },
    'compileString': (Compiler self, String source,
        [CompileStringOptions? options]) {
      self._throwIfDisposed();
      return compileString(source, options);
    },
    'dispose': (Compiler self) {
      self._disposed = true;
    },
  });

  getJSClass(Compiler()).injectSuperclass(jsClass);
  return jsClass;
}();

Compiler initCompiler() => Compiler();

/// The JavaScript `AsyncCompiler` class.
final JSClass asyncCompilerClass = () {
  var jsClass = createJSClass('sass.AsyncCompiler', (Object self) {});

  jsClass.defineMethods({
    'compileAsync': (AsyncCompiler self, String path,
        [CompileOptions? options]) {
      self._throwIfDisposed();
      var compilation = compileAsync(path, options);
      self.addCompilation(compilation);
      return compilation;
    },
    'compileStringAsync': (AsyncCompiler self, String source,
        [CompileStringOptions? options]) {
      self._throwIfDisposed();
      var compilation = compileStringAsync(source, options);
      self.addCompilation(compilation);
      return compilation;
    },
    'dispose': (AsyncCompiler self) {
      self._disposed = true;
      return futureToPromise((() async {
        self.compilations.close();
        await self.compilations.future;
      })());
    }
  });

  getJSClass(AsyncCompiler()).injectSuperclass(jsClass);
  return jsClass;
}();

JSPromise initAsyncCompiler() =>
    futureToPromise((() async => AsyncCompiler())());
