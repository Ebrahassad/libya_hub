import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../data/directory.dart';
import '../../services/app_state.dart';
import '../../widgets/city_picker.dart';
import '../../widgets/open_link.dart';

/// الطوارئ: أرقام سريعة + أقرب خدمات في المدينة المختارة عبر خرائط جوجل.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const _nearbyIds = ['hospital', 'pharmacy', 'police', 'fuel'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('emergency_title'.tr()), centerTitle: true),
      body: ListenableBuilder(
        listenable: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final medical = sectionById('health');
          final energy = sectionById('energy');
          final links = [
            ...?medical?.groups.first.items,
            ...?energy?.groups.first.items.take(2),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('emergency_note'.tr(),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final n in emergencyNumbers)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          icon: const Icon(Icons.call),
                          label: Text('${n.title}  ${n.phone}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: () => openUri(context, n.uri),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.hasCity
                          ? 'emergency_nearby'.tr(args: [s.city])
                          : 'nearby_pick_city'.tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.location_city),
                    label: Text('choose_city'.tr()),
                    onPressed: () => showCityPicker(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in nearbyKinds.where((k) => _nearbyIds.contains(k.id)))
                    ActionChip(
                      avatar: Icon(k.icon, size: 18, color: k.color),
                      label: Text('near_${k.id}'.tr()),
                      onPressed: () {
                        if (!s.hasCity) {
                          showCityPicker(context);
                          return;
                        }
                        openUri(context, mapsSearchUri(k.query, s.city));
                      },
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text('useful_links'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final item in links)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.desc),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => openUri(context, item.uri),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
