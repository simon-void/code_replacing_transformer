library codereplacingtransformer.test;

import 'package:code_replacing_transformer/default.dart';

main(List<String> args) {
  final msg = getMsg();
  print("if the message is 'default' instead of 'replacement' than the transformer didn't work");
  print('msg: $msg');
}
