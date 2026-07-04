import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../task/providers/search_providers.dart';

/// Search input used on Home + Category details screens. Reads + writes
/// [searchQueryProvider]; subscribes to it so external mutations (e.g.
/// the suffix "clear" button via the provider) propagate back into the
/// field. No `setState` here — every visual change is a Riverpod state
/// change.
class SearchField extends ConsumerStatefulWidget {
  const SearchField({
    super.key,
    this.hintText = 'Search notes…',
    this.fillColor,
    this.accentColor,
  });

  final String hintText;
  final Color? fillColor;
  final Color? accentColor;

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));

    // Bridge external provider changes back into the TextField. e.g. if
    // a clear-button somewhere calls
    // `searchQueryProvider.notifier.state = ''`, the field needs to
    // reflect that.
    ref.listenManual<String>(
      searchQueryProvider,
      (prev, next) {
        if (_controller.text == next) return;
        if (next.isEmpty) {
          _controller.clear();
        } else {
          _controller.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    ref.read(searchQueryProvider.notifier).set(v);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = ref.watch(
      searchQueryProvider.select((s) => s.isNotEmpty),
    );
    final fill = widget.fillColor ?? Colors.grey.shade50;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade600,
            size: 22,
          ),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.grey.shade600,
                  onPressed: _clear,
                )
              : null,
          filled: true,
          fillColor: fill,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E1E),
        ),
      ),
    );
  }
}