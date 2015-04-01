// Copyright (c) 2015, the source_map_transformer project authors. Please see
// the AUTHORS file for details. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Source map transformer.
library cleancss_transformer;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barback/barback.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as ospath;

final _commentRegexp = new RegExp(r'^\s*\/(?:\/|\*)[@#]\s+sourceMappingURL=data:(?:application|text)\/json;(?:charset[:=]\S+;)?base64,(.*)(?:\s*\*\/)$', multiLine: true);

/// Transformer Options:
///
/// * [source_map] Enables source map transforms in release mode. DEFAULT: `false`
class TransformerOptions {
  final bool sourceMap;

  TransformerOptions(this.sourceMap);

  factory TransformerOptions.parse(Map configuration) {
    config(key, defaultValue) {
      var value = configuration[key];
      return value != null ? value : defaultValue;
    }

    return new TransformerOptions(
        config('source_map', false));
  }
}

/// Transforms Source Maps
class SourceMapTransformer extends Transformer implements DeclaringTransformer {
  final BarbackSettings _settings;
  final TransformerOptions _options;

  SourceMapTransformer.asPlugin(BarbackSettings s)
      : _settings = s,
        _options = new TransformerOptions.parse(s.configuration);

  final String allowedExtensions = '.css';

  Future apply(Transform transform) async {
    final asset = transform.primaryInput;
    if (_settings.mode == BarbackMode.RELEASE && !_options.sourceMap) {
      return null;
    }

    final String css = await asset.readAsString();

    final match = _commentRegexp.firstMatch(css);
    if (match != null) {
      final map = UTF8.decode(CryptoUtils.base64StringToBytes(match.group(1).trim()));

      transform.addOutput(new Asset.fromString(asset.id, css.substring(0, match.start) + css.substring(match.end)));
      transform.addOutput(new Asset.fromString(asset.id.addExtension('.map'), map));
    } else {
      transform.addOutput(new Asset.fromString(asset.id, css));
    }
  }

  Future declareOutputs(DeclaringTransform transform) {
    transform.declareOutput(transform.primaryId);
    return new Future.value();
  }
}
