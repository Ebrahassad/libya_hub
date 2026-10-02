import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/directory.dart';
import '../../widgets/dir_item_tile.dart';
import '../../widgets/ad_banner.dart';

String _norm(String s) => s
    .replaceAll(RegExp('[\u064B-\u065F]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .toLowerCase()
    .trim();

/// شاشة قسم من الدليل: مجموعات مرتبة داخل بطاقات، كل عنصر برابطه، مع بحث داخل القسم.
class SectionScreen extends StatefulWidget {
  final DirSection section;
  const SectionScreen({super.key, required this.section});

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final q = _norm(_q);
    return Scaffold(
      appBar: AppBar(title: Text(sectionTitle(section)), centerTitle: true),
      bottomNavigationBar: const AdBanner(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (section.count > 8) ...[
            TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'section_search'.tr(),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
          ],
          for (final g in section.groups) ...[
            Builder(builder: (context) {
              final items = g.items
                  .where((i) => q.isEmpty || _norm(i.title).contains(q) || _norm(i.desc).contains(q))
                  .toList();
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (g.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(g.title,
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: section.color)),
                  ),
                for (final item in items) DirItemTile(item: item, accent: section.color),
              ]);
            }),
          ],
          const SizedBox(height: 8),
          Text('disclaimer'.tr(),
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
