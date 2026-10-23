import 'package:flutter/material.dart';

import '../data/currency.dart';
import '../models/product.dart';
import 'filter_sort.dart';

/// Checkout screen built from the supplied Figma frame.
///
/// One product is checked out at a time (there is no cart in this project yet),
/// so the page takes the tapped [Product] directly. Courier and payment
/// selection are local UI state; the total is recalculated from the selected
/// courier.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.product});

  final Product product;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const List<_CourierOption> _couriers = <_CourierOption>[
    _CourierOption(
      name: 'J&T Regular',
      eta: '2-3 days',
      price: 18000,
      icon: Icons.local_shipping_outlined,
    ),
    _CourierOption(
      name: 'GoSend Instant',
      eta: 'Today',
      price: 42000,
      icon: Icons.bolt,
    ),
  ];

  static const List<_PaymentOption> _payments = <_PaymentOption>[
    _PaymentOption(
      name: 'QRIS',
      subtitle: 'Scan with any banking app',
      icon: Icons.qr_code_2,
    ),
    _PaymentOption(
      name: 'E-Wallet',
      subtitle: 'GoPay, OVO, or DANA',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  static const String _addressName = 'Maya Putri · +62 812 3456 7890';
  static const String _addressLine = 'Jl. Kemang Raya 18, South Jakarta, 12730';

  int _courierIndex = 0;
  int _paymentIndex = 0;

  _CourierOption get _courier => _couriers[_courierIndex];
  int get _total => widget.product.price + _courier.price;

  /// "MUJI · 90% GOOD" for percentage conditions, plain for "Like New".
  String get _productMeta {
    final String condition = widget.product.condition;
    final String label = condition.contains('%')
        ? '$condition GOOD'
        : condition;
    return '${widget.product.brand} · $label'.toUpperCase();
  }

  Future<void> _confirmPayment() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Pay ${formatRupiah(_total)} for ${widget.product.title}?',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Pay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Payment successful')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const StatusBarRow(),
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildProductCard(),
                    const _SectionLabel('Shipping Address'),
                    _buildAddressCard(),
                    const _SectionLabel('Delivery Courier'),
                    for (int i = 0; i < _couriers.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 10),
                      _buildCourierCard(i),
                    ],
                    const _SectionLabel('Payment Methods'),
                    for (int i = 0; i < _payments.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 10),
                      _buildPaymentCard(i),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- header ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: <Widget>[
          _CircleIconButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Checkout',
                style: TextStyle(
                  fontSize: AppText.headerTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- product ---

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: widget.product.imageUrl.isEmpty
                  ? const _ProductThumbnailPlaceholder()
                  : Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const _ProductThumbnailPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _productMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(widget.product.price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- address ---

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: AppColors.darkGreen,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _addressName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _addressLine,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- options ---

  Widget _buildCourierCard(int index) {
    final _CourierOption courier = _couriers[index];
    return CheckoutOptionCard(
      key: ValueKey<String>('courier:${courier.name}'),
      icon: courier.icon,
      title: courier.name,
      subtitle: '${courier.eta} • ${formatRupiah(courier.price)}',
      selected: _courierIndex == index,
      onTap: () => setState(() => _courierIndex = index),
    );
  }

  Widget _buildPaymentCard(int index) {
    final _PaymentOption payment = _payments[index];
    return CheckoutOptionCard(
      key: ValueKey<String>('payment:${payment.name}'),
      icon: payment.icon,
      title: payment.name,
      subtitle: payment.subtitle,
      selected: _paymentIndex == index,
      onTap: () => setState(() => _paymentIndex = index),
    );
  }

  // ------------------------------------------------------------ bottom bar ---

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Total Price',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupiah(_total),
                    key: const ValueKey<String>('checkout-total'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                key: const ValueKey<String>('pay-now'),
                onPressed: _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Supporting widgets
/// ---------------------------------------------------------------------------

/// Selectable card used by both the courier and payment lists.
///
/// Public so widget tests can assert the selected state directly.
class CheckoutOptionCard extends StatelessWidget {
  const CheckoutOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.darkGreen : AppColors.lightBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sageFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.darkGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.darkGreen : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.darkGreen : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
              ),
            )
          : null,
    );
  }
}

class _ProductThumbnailPlaceholder extends StatelessWidget {
  const _ProductThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7E4DC),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 24, color: AppColors.textMuted),
      ),
    );
  }
}

/// Section heading with the mockup's vertical rhythm.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppText.sectionLabel,
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Icon(icon, size: 22, color: AppColors.darkText),
      ),
    );
  }
}

class _CourierOption {
  const _CourierOption({
    required this.name,
    required this.eta,
    required this.price,
    required this.icon,
  });

  final String name;
  final String eta;
  final int price;
  final IconData icon;
}

class _PaymentOption {
  const _PaymentOption({
    required this.name,
    required this.subtitle,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final IconData icon;
}
