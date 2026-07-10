import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';

class ExpandableSynopsis extends StatefulWidget {
  final String synopsis;

  const ExpandableSynopsis({super.key, required this.synopsis});

  @override
  State<ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<ExpandableSynopsis> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppColors.textSecondary,
      height: 1.65,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),

          firstChild: Text(
            widget.synopsis,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),

          secondChild: Text(widget.synopsis, style: textStyle),

          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),

        if (widget.synopsis.length > 260) ...[
          const SizedBox(height: 12),

          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),

            onPressed: () {
              setState(() {
                expanded = !expanded;
              });
            },

            icon: Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),

            label: Text(expanded ? "Show Less" : "Read More"),
          ),
        ],
      ],
    );
  }
}
