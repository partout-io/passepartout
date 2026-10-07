// SPDX-License-Identifier: GPL-3.0
// Copyright 2026 SigmaDev

// Upstream `theme.listSection` / `EditableListSection`: one row per item,
// swipe or minus to remove, an "Add" row that stays disabled while the last
// item is still empty. Items carry stable ids, so removing a row never moves
// another row's text into the wrong field.

import 'package:flutter/material.dart';

import '../../../l10n/strings.g.dart';
import '../../kit.dart';
import 'module_builder_cache.dart';

class EditableListSection<T> extends StatelessWidget {
  const EditableListSection({
    super.key,
    required this.header,
    required this.addTitle,
    required this.items,
    required this.onChanged,
    required this.emptyValue,
    required this.isEmptyValue,
    required this.itemBuilder,
    this.footer,
  });

  final String? header;
  final String? footer;
  final String addTitle;
  final List<ListItem<T>> items;
  final ValueChanged<List<ListItem<T>>> onChanged;
  final T Function() emptyValue;
  final bool Function(T) isEmptyValue;

  /// The row content for [item]; call the setter to replace its value.
  final Widget Function(BuildContext context, ListItem<T> item, ValueChanged<T> setValue) itemBuilder;

  bool get _canAdd => items.isEmpty || !isEmptyValue(items.last.value);

  void _remove(ListItem<T> item) => onChanged(<ListItem<T>>[...items]..removeWhere((other) => other.id == item.id));

  void _set(ListItem<T> item, T value) =>
      onChanged(<ListItem<T>>[for (final other in items) other.id == item.id ? other.copyWith(value) : other]);

  @override
  Widget build(BuildContext context) => PSSection(
        header: header,
        footer: footer,
        children: <Widget>[
          for (final item in items)
            Dismissible(
              key: ValueKey<String>('${header ?? ''}/item/${item.id}'),
              direction: .endToStart,
              background: Container(
                color: PSColors.error,
                alignment: .centerRight,
                padding: const .only(right: 16),
                child: Text(tr(Strings.globalActionsDelete), style: const TextStyle(color: Colors.white)),
              ),
              onDismissed: (_) => _remove(item),
              child: Row(children: <Widget>[
                IconButton(
                  tooltip: tr(Strings.globalActionsDelete),
                  icon: const Icon(Icons.remove_circle, color: PSColors.error),
                  onPressed: () => _remove(item),
                ),
                Expanded(child: itemBuilder(context, item, (value) => _set(item, value))),
                const SizedBox(width: 16),
              ]),
            ),
          PSRow(
            title: addTitle,
            leading: Icon(Icons.add_circle, color: _canAdd ? PSColors.active : Theme.of(context).disabledColor),
            onTap: _canAdd ? () => onChanged(<ListItem<T>>[...items, ListItem<T>(emptyValue())]) : null,
          ),
        ],
      );
}

/// A borderless text field for one list row, kept in sync with [value]
/// (`ThemeTextField("", text:, placeholder:)` with hidden label).
class ListItemTextField extends StatefulWidget {
  const ListItemTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.keyboardType,
    this.semanticLabel,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? placeholder;
  final TextInputType? keyboardType;
  final String? semanticLabel;

  @override
  State<ListItemTextField> createState() => _ListItemTextFieldState();
}

class _ListItemTextFieldState extends State<ListItemTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(ListItemTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        autofocus: widget.value.isEmpty,
        autocorrect: false,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.placeholder,
          semanticCounterText: widget.semanticLabel,
        ),
        onChanged: widget.onChanged,
      );
}
