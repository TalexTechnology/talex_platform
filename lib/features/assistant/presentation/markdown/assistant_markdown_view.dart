import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:talex_platform/core/utils/open_url.dart';
import 'package:talex_platform/features/assistant/presentation/assistant_style.dart';
import 'package:talex_platform/features/assistant/presentation/markdown/assistant_markdown.dart';

class AssistantMarkdownView extends StatelessWidget {
  const AssistantMarkdownView({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final blocks = parseAssistantMarkdown(data);
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++)
          _block(context, blocks[index], last: index == blocks.length - 1),
      ],
    );
  }

  Widget _block(BuildContext context, MdBlock block, {required bool last}) {
    final bottom = last ? 0.0 : 12.0;
    return switch (block) {
      MdHeading(:final level, :final spans) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: _rich(
          context,
          spans,
          AssistantStyle.body.copyWith(
            fontSize: level == 1
                ? 20
                : level == 2
                ? 17
                : 15.5,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      MdParagraph(:final spans) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: _rich(context, spans, AssistantStyle.body),
      ),
      MdQuote(:final spans) => Container(
        margin: EdgeInsets.only(bottom: bottom),
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AssistantStyle.green, width: 3),
          ),
        ),
        child: _rich(
          context,
          spans,
          AssistantStyle.body.copyWith(color: AssistantStyle.muted),
        ),
      ),
      MdRule() => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: const Divider(height: 1, color: AssistantStyle.line),
      ),
      MdListBlock(:final ordered, :final items) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        ordered ? '${index + 1}.' : '•',
                        style: AssistantStyle.body.copyWith(
                          color: AssistantStyle.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _rich(context, items[index], AssistantStyle.body),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      MdCodeBlock(:final code, :final language) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: _CodeBlock(code: code, language: language),
      ),
      MdTable(:final header, :final rows) => Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: _TableBlock(header: header, rows: rows),
      ),
    };
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, this.language});

  final String code;
  final String? language;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Consolas', 'Courier New'],
      fontSize: 13,
      height: 1.45,
      color: AssistantStyle.ink,
    );
    final shown = code.isEmpty ? ' ' : code;
    final painter = TextPainter(
      text: TextSpan(text: shown, style: style),
      textDirection: Directionality.of(context),
    )..layout(maxWidth: 1000000);
    final height = painter.height + 20;
    final width = painter.width;
    painter.dispose();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AssistantStyle.codeFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                language!,
                style: AssistantStyle.body.copyWith(
                  fontSize: 11,
                  height: 1.2,
                  color: AssistantStyle.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(
            height: height,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(
                width: width,
                child: SelectableText(shown, style: style),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableBlock extends StatelessWidget {
  const _TableBlock({required this.header, required this.rows});

  final List<List<MdSpan>> header;
  final List<List<List<MdSpan>>> rows;

  @override
  Widget build(BuildContext context) {
    const cellStyle = AssistantStyle.body;
    final width = math.max(header.length, 1);
    final body = [header, for (final row in rows) _pad(row, width)];
    final height = body.fold<double>(0, (sum, row) {
      var rowHeight = 20.0;
      for (final cell in row) {
        final text = cell.map((span) => span.text).join();
        final painter = TextPainter(
          text: TextSpan(text: text.isEmpty ? ' ' : text, style: cellStyle),
          textDirection: Directionality.of(context),
          maxLines: 4,
        )..layout(maxWidth: 220);
        rowHeight = math.max(rowHeight, painter.height + 16);
        painter.dispose();
      }
      return sum + rowHeight;
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Table(
                columnWidths: {
                  for (var column = 0; column < width; column++)
                    column: const IntrinsicColumnWidth(),
                },
                border: const TableBorder(
                  horizontalInside: BorderSide(color: AssistantStyle.line),
                  bottom: BorderSide(color: AssistantStyle.line),
                ),
                children: [
                  for (var rowIndex = 0; rowIndex < body.length; rowIndex++)
                    TableRow(
                      decoration: rowIndex == 0
                          ? const BoxDecoration(color: AssistantStyle.wash)
                          : null,
                      children: [
                        for (final cell in body[rowIndex])
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: _rich(
                                context,
                                cell,
                                cellStyle.copyWith(
                                  fontWeight: rowIndex == 0
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<List<MdSpan>> _pad(List<List<MdSpan>> row, int width) {
    if (row.length >= width) return row.take(width).toList();
    return [
      ...row,
      for (var extra = row.length; extra < width; extra++) const <MdSpan>[],
    ];
  }
}

Widget _rich(BuildContext context, List<MdSpan> spans, TextStyle style) {
  if (spans.isEmpty) {
    return Text(' ', style: style);
  }
  return Text.rich(
    TextSpan(
      style: style,
      children: [for (final span in spans) _span(context, span, style)],
    ),
  );
}

InlineSpan _span(BuildContext context, MdSpan span, TextStyle style) {
  if (span.code) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AssistantStyle.codeFill,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            span.text,
            style: style.copyWith(
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Consolas', 'Courier New'],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
  if (span.href != null) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Semantics(
        link: true,
        button: true,
        label: span.text,
        child: InkWell(
          onTap: () => openExternalUrl(span.href!),
          mouseCursor: SystemMouseCursors.click,
          child: Text(
            span.text,
            style: style.copyWith(
              color: AssistantStyle.blue,
              decoration: TextDecoration.underline,
              decorationColor: AssistantStyle.blue,
              fontWeight: span.bold ? FontWeight.w700 : style.fontWeight,
              fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
  return TextSpan(
    text: span.text,
    style: style.copyWith(
      fontWeight: span.bold ? FontWeight.w700 : style.fontWeight,
      fontStyle: span.italic ? FontStyle.italic : FontStyle.normal,
    ),
  );
}
