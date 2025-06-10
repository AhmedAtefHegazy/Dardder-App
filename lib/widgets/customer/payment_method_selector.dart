import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _PaymentMethodTile(
          title: 'Cash on Delivery',
          subtitle: 'Pay when you receive your order',
          icon: Icons.payments_outlined,
          isSelected: selectedMethod == 'cash',
          onTap: () => onMethodSelected('cash'),
        ),
        const SizedBox(height: 12),
        _PaymentMethodTile(
          title: 'Credit/Debit Card',
          subtitle: 'Coming soon',
          icon: Icons.credit_card_outlined,
          isEnabled: false,
          isSelected: selectedMethod == 'card',
          onTap: () => onMethodSelected('card'),
        ),
        const SizedBox(height: 12),
        _PaymentMethodTile(
          title: 'Digital Wallet',
          subtitle: 'Coming soon',
          icon: Icons.account_balance_wallet_outlined,
          isEnabled: false,
          isSelected: selectedMethod == 'wallet',
          onTap: () => onMethodSelected('wallet'),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.isEnabled = true,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
