import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:untitled1/core/theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.accent),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
