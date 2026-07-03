import 'package:flutter/material.dart';

/// The signature iOS-style rounded-square back button used across screens.
class RoundedBackButton extends StatelessWidget {
  const RoundedBackButton({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Center(
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF1E1E1E), size: 16),
            onPressed: onTap ?? () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }
}

/// Standard transparent app bar used by every list/detail screen in the app.
class NotelyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NotelyAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
    this.centerTitle = true,
    this.backgroundColor = const Color(0xFFF2F2F7),
  });

  final String title;
  final List<Widget> actions;
  final Widget? leading;
  final bool centerTitle;
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      leading: leading ?? const RoundedBackButton(),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.2,
        ),
      ),
      actions: actions,
    );
  }
}