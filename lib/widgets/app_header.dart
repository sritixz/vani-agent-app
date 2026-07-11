import 'package:flutter/material.dart';
import 'package:vani_app/config/theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;
  final bool showNotification;

  const AppHeader({
    super.key,
    this.onMenuPressed,
    this.onProfilePressed,
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
