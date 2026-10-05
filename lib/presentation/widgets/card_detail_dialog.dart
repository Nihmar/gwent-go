import 'package:flutter/material.dart';

import '../../core/models/card.dart';
import '../../l10n/generated/app_localizations.dart';
import '../localization.dart';
import '../theme/gwent_colors.dart';
import 'gwent_card.dart';

/// Shows a large card with its localized name, type and ability text.
Future<void> showCardDetail(
  BuildContext context,
  CardDefinition card, {
  int? strength,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final strings = context.strings;
      return Dialog(
        backgroundColor: GwentColors.surfaceHigh,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GwentCard(definition: card, strength: strength, width: 140),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cardTypeLine(strings, card),
                            style: const TextStyle(
                              color: GwentColors.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in cardTags(strings, card))
                                Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  strings.cardDescription(card),
                  style: const TextStyle(
                    color: GwentColors.onSurface,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(strings.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Type line such as "Close Combat · Hero".
String cardTypeLine(AppLocalizations strings, CardDefinition card) {
  if (card.isLeader) return strings.cardTypeLeader;
  if (card.isWeather) return strings.cardTypeWeather;
  if (card.isSpecial) return strings.cardTypeSpecial;
  final row = card.row == CardRow.agile ? CardRow.close : card.row;
  final hero = card.isHero ? ' · ${strings.tagHero}' : '';
  return '${strings.rowName(row)}$hero';
}

/// Localized category tags shown in the detail dialog.
List<String> cardTags(AppLocalizations strings, CardDefinition card) {
  if (card.isLeader) return [strings.cardTypeLeader];
  if (card.isWeather) return [strings.cardTypeWeather];
  if (card.isSpecial) return [strings.cardTypeSpecial];
  return [strings.rowName(card.row), if (card.isHero) strings.tagHero];
}
