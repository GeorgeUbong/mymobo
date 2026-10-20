import 'package:flutter/material.dart';

import '../model/card_model.dart';
import '../themes/app_themes.dart';

/// The visual credit card. Before auth only the name is shown;
/// with [showDetails] it also shows number, expiry and type.
class DigiCardWidget extends StatelessWidget {
  final CardModel card;
  final bool showDetails;
  final VoidCallback? onTap;

  const DigiCardWidget({
    super.key,
    required this.card,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final on = context.cardTheme.onCard;
    final soft = on.withAlpha(210);
    final text = Theme.of(context).textTheme;
    final hasNumber = card.number.isNotEmpty;

    return AspectRatio(
      aspectRatio: 1.586,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: context.cardTheme
                .gradientFor(card.template, isActive: card.isActive),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            color: on,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!card.isActive) _Badge(label: 'INACTIVE', color: on),
                      if (!showDetails)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.lock_outline_rounded,
                              color: on, size: 20),
                        ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      showDetails && hasNumber
                          ? card.formattedNumber
                          : '•••• •••• •••• ••••',
                      style: text.titleLarge?.copyWith(
                        color: on,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        showDetails
                            ? 'EXPIRES  ${card.expiry.isEmpty ? 'MM/YY' : card.expiry}'
                            : 'Tap to unlock',
                        style: text.bodySmall?.copyWith(color: soft),
                      ),
                      if (showDetails)
                        Text(
                          card.type.label,
                          style: text.titleSmall?.copyWith(
                            color: on,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}