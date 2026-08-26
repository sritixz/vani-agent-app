import 'package:flutter/material.dart';
import 'package:vani_app/config/theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onSendCallPressed;
  final bool showNotification;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    this.onProfilePressed,
    this.onSendCallPressed,
    this.showNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surfaceCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      shape: const Border(bottom: BorderSide(color: AppTheme.borderGrey)),
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Text(
            'VaniAgent',
            style: TextStyle(
              color: AppTheme.darkGrey,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        if (onSendCallPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: onSendCallPressed,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.darkGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.call, size: 14, color: Colors.white),
              label: const Text(
                'Send Call',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (showNotification)
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.darkGrey,
            ),
            onPressed: () {},
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: onProfilePressed,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.lightGrey,
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppTheme.darkGrey,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
