// Copyright 2021 Google Inc. Use of this source code is governed by an
// MIT-style license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import '../../value.dart';
import '../reflection.dart';

/// The JavaScript `SassBoolean` class.
final JSClass booleanClass = () {
  var jsClass =
      createJSClass('sass.SassBoolean', (Object self, [Object? _]) {});
  getJSClass(sassTrue).injectSuperclass(jsClass);

  return jsClass;
}();
