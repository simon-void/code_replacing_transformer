library code.transform;

import 'dart:async';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';

class ReplacePackageTransformer extends AggregateTransformer {
  ReplacePackageTransformer.asPlugin();

  @override
  String classifyPrimary(AssetId id) => id.toString().endsWith(".dart") ? "dart-files" : null;

  @override
  apply(AggregateTransform transform) {
    //capture the whole execution to allow better stacktraces if an error occurs
    Chain.capture(() async {
      print("create the new file replacement.dart in lib with the same interface as default.dart");
      final newLibFileName = "replacement.dart";
      final newLibAsset = _createReplacementAsset(newLibFileName, transform.package);
      transform.addOutput(newLibAsset);

      print("replace main.dart import of default.dart with replacement.dart");

      Asset mainAsset = await _getFileAsset(transform, "main.dart");
      Asset updatedMainAsset =
          await _replaceDefaultImport(mainAsset, transform.package, "default.dart", newLibFileName);

      //first remove the old version before adding one with the same id (seems to be neccessary)
      transform.consumePrimary(mainAsset.id);
      transform.addOutput(updatedMainAsset);

      //check if the replacement was successfull
      await _printAsset("mainAsset", mainAsset);
      await _printAsset("updatedMainAsset", updatedMainAsset);

      var updatedMainAssetRetrieved = await transform.getInput(updatedMainAsset.id);
      await _printAsset("updatedMainAssetRetrieved", updatedMainAssetRetrieved);
      print("------------------------------ transformer is done");
    });
  }

  Asset _createReplacementAsset(String newLibFileName, String transformPackage) {
    //the only difference to default.dart is that getMsg() returns 'replacement' instead of 'default'
    final replacementCode = """library stringsource;

        String getMsg() => "replacement";
        """;
    AssetId newLibAssetId = new AssetId(transformPackage, path.url.join('lib', newLibFileName));
    Asset newLibAsset = new Asset.fromString(newLibAssetId, replacementCode);
    return newLibAsset;
  }

  Future<Asset> _replaceDefaultImport(Asset dartFileAsset, String packageName, String oldLib, String newLib) async {
    final dartSource = await dartFileAsset.readAsString();
    var updatedSource = dartSource;
    // (probably) update the import in main.dart from default.dart to replacement.dart
    updatedSource = updatedSource.replaceAll("package:$packageName/$oldLib", "package:$packageName/$newLib");
    // (probably) update the sourcecode in main.dart from "msg: ..." to "updated msg: ..."
    updatedSource = updatedSource.replaceAll("msg:", "updated msg:");
    //print to debug
    // print("updated source of ${dartFileAsset.id.path}:\n$updatedSource");
    //new Asset has same id but updated source
    // final AssetId idCopy = new AssetId(dartFileAsset.id.package, dartFileAsset.id.path);
    return new Asset.fromString(dartFileAsset.id, updatedSource);
  }

  Future<Asset> _getFileAsset(AggregateTransform transform, String filename) async {
    List<Asset> dartFiles = await transform.primaryInputs.toList();
    Asset dartAsset = dartFiles.singleWhere((asset) => asset.id.path.contains(filename));
    return dartAsset;
  }

  _printAsset(String varName, Asset asset) async {
    print(">>>>>>>>>>>>>$varName - ${asset.id.toString()}");
    var source = await asset.readAsString();
    print(source);
    print("<<<<<<<<<<<<<");
  }
}
