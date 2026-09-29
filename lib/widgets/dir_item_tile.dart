import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../data/directory.dart';
import '../services/app_state.dart';
import 'open_link.dart';

/// بطاقة عنصر في الدليل: العنوان والوصف وزر الفتح ونجمة المفضلة.
class DirItemTile extends StatelessWidget {
  final DirItem item;
  final Color accent;
  const DirItemTile({super.key, required this.item, required this.accent});

  String get _actionLabel {
    switch (item.kind) {
      case LinkKind.web:
        return 'open_site'.tr();
      case LinkKind.phone:
        return 'call'.tr();
      case LinkKind.app:
        return item.package != null ? 'download_play'.tr() : 'search_play'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final fav = AppState.instance.isFavorite(item.key);
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'nav_favorites'.tr(),
                      icon: Icon(fav ? Icons.star : Icons.star_border,
                          color: fav ? Colors.amber : null),
                      onPressed: () => AppState.instance.toggleFavorite(item.key),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(item.desc,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(foregroundColor: accent),
                    icon: Icon(item.icon, size: 18),
                    label: Text(_actionLabel),
                    onPressed: () => openUri(context, item.uri),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
