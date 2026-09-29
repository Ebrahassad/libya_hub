import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/directory.dart';
import '../../widgets/dir_item_tile.dart';

/// شاشة قسم من الدليل: مجموعات مرتبة داخل بطاقات، كل عنصر برابطه.
class SectionScreen extends StatelessWidget {
  final DirSection section;
  const SectionScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('sec_${section.id}'.tr()), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final g in section.groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(g.title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: section.color)),
            ),
            for (final item in g.items) DirItemTile(item: item, accent: section.color),
          ],
          const SizedBox(height: 8),
          Text('disclaimer'.tr(),
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
