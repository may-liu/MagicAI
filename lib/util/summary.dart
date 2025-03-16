import 'dart:convert';
import 'package:blake2/blake2.dart';

String calculateBlake2b(String input) {
  var bytes = utf8.encode(input);
  var blake2b = Blake2b();
  blake2b.update(bytes);
  var digest = blake2b.digest();
  return digest.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}
