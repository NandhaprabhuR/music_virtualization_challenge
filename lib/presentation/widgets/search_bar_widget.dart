import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/core/theme/app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.bg,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: false,
        style: GoogleFonts.playfairDisplay(color: context.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search tracks, artists...',
          hintStyle: GoogleFonts.playfairDisplay(color: context.textSecondary),
          prefixIcon: Icon(Icons.search, color: context.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                )
              : null,
          filled: true,
          fillColor: context.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
