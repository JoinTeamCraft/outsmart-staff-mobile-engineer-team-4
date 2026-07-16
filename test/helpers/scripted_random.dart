import 'dart:math';

class ScriptedRandom implements Random {
  ScriptedRandom(this._doubles);

  final List<double> _doubles;
  int _index = 0;

  @override
  double nextDouble() => _doubles[_index++];

  @override
  int nextInt(int max) => throw UnsupportedError('nextInt is not scripted');

  @override
  bool nextBool() => throw UnsupportedError('nextBool is not scripted');
}
