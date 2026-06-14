import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/store.dart';

/// List tile showing a store's name, address, distance and today's hours.
///
/// Shared by the store-selection and settings screens. Provide [onTap] to make
/// the tile selectable.
class StoreTile extends StatelessWidget {
  const StoreTile({
    super.key,
    required this.store,
    this.userPosition,
    this.onTap,
  });

  final Store store;
  final Position? userPosition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          store.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 200,
                  child: Text(
                    store.address,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  userPosition != null
                      ? "${store.getDistance(userPosition!.latitude, userPosition!.longitude).toStringAsFixed(2)} km"
                      : "Distance not available",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            Text(
              store.openingHoursForToday(),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF412a2b),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.storefront, color: Colors.white),
        ),
      ),
    );

    if (onTap == null) return tile;
    return GestureDetector(onTap: onTap, child: tile);
  }
}
