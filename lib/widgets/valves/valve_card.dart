import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../common/app_card.dart';
import '../common/status_chip.dart';

class ValveCard extends StatelessWidget {
  final String title;
  final bool active;
  final String nodeName;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const ValveCard({
    super.key,
    required this.title,
    required this.active,
    required this.nodeName,
    required this.onOpen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatusChip(
                label: active ? 'ACTIVA' : 'CERRADA',
                color: active ? AppColors.success : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            nodeName,
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
