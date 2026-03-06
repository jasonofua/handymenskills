import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimensions.dart';

class AppSearchBar extends StatefulWidget {
  final String hint;
  final void Function(String) onSearch;
  final VoidCallback? onFilterTap;
  final Duration debounceDuration;

  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    required this.onSearch,
    this.onFilterTap,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.textHint, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onSearch('');
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, color: AppColors.textHint, size: 20),
              ),
            ),
          if (widget.onFilterTap != null)
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.tune, color: AppColors.primary, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}
