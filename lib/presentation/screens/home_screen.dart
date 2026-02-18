import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled1/core/theme/app_theme.dart';
import 'package:untitled1/presentation/blocs/now_playing/now_playing_cubit.dart';
import 'package:untitled1/presentation/screens/library_screen.dart';
import 'package:untitled1/presentation/screens/now_playing_screen.dart';
import 'package:untitled1/presentation/widgets/mini_player_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [LibraryScreen(), NowPlayingScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player - only show on Library tab
          if (_currentIndex == 0)
            MiniPlayerWidget(onTap: () => setState(() => _currentIndex = 1)),
          Container(
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF0A0A0A) : Colors.white,
              border: Border(top: BorderSide(color: context.dividerColor)),
              boxShadow: context.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        icon: Icons.library_music_outlined,
                        activeIcon: Icons.library_music_rounded,
                        label: 'Library',
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<NowPlayingCubit, NowPlayingState>(
                        builder: (context, state) {
                          return _buildNavItem(
                            index: 1,
                            icon: Icons.play_circle_outline_rounded,
                            activeIcon: Icons.play_circle_filled_rounded,
                            label: 'Now Playing',
                            hasIndicator: state.currentTrack != null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool hasIndicator = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? context.accent : context.textSecondary,
                size: 26,
              ),
              if (hasIndicator && !isSelected)
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? context.accent : context.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
