import 'package:flutter/material.dart';

import '../../models/departure.dart';
import '../../services/departure_service.dart';
import '../../utils/event_time_format.dart';
import 'dashboard_card_frame.dart';

class DeparturesCard extends StatelessWidget {
  const DeparturesCard({
    required this.departures,
    required this.error,
    required this.filtered,
    required this.onRetry,
    super.key,
  });

  static const _maxRows = 5;

  final List<Departure>? departures;
  final String? error;

  final bool filtered;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCardFrame(
      icon: Icons.directions_bus_outlined,
      title: 'Busabfahrten',
      subtitle: DepartureService.campusStationName,
      trailing: filtered
          ? Tooltip(
              message: 'Gefiltert – siehe Einstellungen',
              child: Icon(
                Icons.filter_alt_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final list = departures;

    if (list == null && error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (list == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error!,
              style: TextStyle(fontSize: 13, color: colorScheme.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Erneut')),
        ],
      );
    }

    if (list.isEmpty) {
      return Text(
        filtered
            ? 'Keine passenden Abfahrten in den nächsten 90 Minuten'
            : 'Keine Abfahrten in den nächsten 90 Minuten',
        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
      );
    }

    final rows = list.take(_maxRows).toList();
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _DepartureRow(departure: rows[i]),
        ],
      ],
    );
  }
}

class _DepartureRow extends StatelessWidget {
  const _DepartureRow({required this.departure});

  final Departure departure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final d = departure;
    final otherStop =
        d.stopName != null &&
        !d.stopName!.contains(DepartureService.campusStationName);

    return Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: d.cancelled
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            d.line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: d.cancelled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.direction,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  decoration: d.cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (otherStop || d.platform != null)
                Text(
                  [
                    if (otherStop) 'ab ${d.stopName}',
                    if (d.platform != null) 'Steig ${d.platform}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _TimeColumn(departure: d),
      ],
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.departure});

  final Departure departure;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final d = departure;

    if (d.cancelled) {
      return Text(
        'Entfällt',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: colorScheme.error,
        ),
      );
    }

    final minutes = d.expectedTime.difference(DateTime.now()).inMinutes;
    final primary = minutes <= 0
        ? 'jetzt'
        : minutes < 60
        ? 'in $minutes min'
        : EventTimeFormat.time(d.expectedTime);

    final delay = d.delayMinutes;
    final Color statusColor;
    final String status;
    if (!d.hasRealtime) {
      statusColor = colorScheme.onSurfaceVariant;
      status = '${EventTimeFormat.time(d.plannedTime)} lt. Plan';
    } else if (delay <= 0) {
      statusColor = Colors.green.shade600;
      status = EventTimeFormat.time(d.plannedTime);
    } else {
      statusColor = delay >= 5 ? colorScheme.error : Colors.orange.shade700;
      status = '${EventTimeFormat.time(d.plannedTime)} +$delay';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          primary,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        Text(status, style: TextStyle(fontSize: 11, color: statusColor)),
      ],
    );
  }
}
