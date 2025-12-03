import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShadTheme {
  static ThemeData dark() {
    const surface = Color(0xFF0E0E0E);
    const border = Color(0xFF2A2A2A);
    const foreground = Colors.white;
    const muted = Color(0xFF9F9F9F);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(color: foreground),
          bodyMedium: TextStyle(color: foreground),
        ),
      ).apply(bodyColor: foreground, displayColor: foreground),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        foregroundColor: foreground,
      ),
      // فقط این بخش عوض شد 👇
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF161616),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}

class ShadCard extends StatelessWidget {
  const ShadCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class ShadButton extends StatelessWidget {
  const ShadButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.play_arrow_rounded, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class ShadGhostButton extends StatelessWidget {
  const ShadGhostButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2A2A2A)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class ShadSwitch extends StatelessWidget {
  const ShadSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.black,
          activeTrackColor: Colors.white,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFF2A2A2A),
        ),
        if (label != null)
          Text(
            label!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

class ShadPill extends StatelessWidget {
  const ShadPill({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16, color: Colors.white),
          if (icon != null) const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
