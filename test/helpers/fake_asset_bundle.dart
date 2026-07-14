import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FakeAssetBundle extends AssetBundle {
  FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final asset = _assets[key];
    if (asset == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return ByteData.sublistView(utf8.encode(asset));
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async {
    return parser(await loadString(key));
  }
}
