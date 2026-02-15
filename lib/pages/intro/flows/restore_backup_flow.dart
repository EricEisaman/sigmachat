import 'package:flutter/material.dart';

import 'package:sigmachat/utils/file_selector.dart';
import 'package:sigmachat/widgets/future_loading_dialog.dart';
import 'package:sigmachat/widgets/matrix.dart';

Future<void> restoreBackupFlow(BuildContext context) async {
  final picked = await selectFiles(context);
  final file = picked.firstOrNull;
  if (file == null) return;

  if (!context.mounted) return;
  await showFutureLoadingDialog(
    context: context,
    future: () async {
      final client = await Matrix.of(context).getLoginClient();
      await client.importDump(String.fromCharCodes(await file.readAsBytes()));
      Matrix.of(context).initMatrix();
    },
  );
}
