/// A small Markdown reader for assistant replies.
///
/// It accepts the incomplete markup that appears while a reply is revealed:
/// an open code fence, an unclosed emphasis marker, or a link that has not
/// finished yet. It does not interpret HTML.
library;

final _heading = RegExp(r'^(#{1,6})\s+(\S.*)$');
final _ordered = RegExp(r'^(\d+)\.\s+(\S.*)$');
final _bullet = RegExp(r'^[-*]\s+(\S.*)$');
final _rule = RegExp(r'^(\*{3,}|-{3,}|_{3,})$');
final _url = RegExp(r'^(https?|mailto):', caseSensitive: false);

sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.spans);
  final int level;
  final List<MdSpan> spans;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.spans);
  final List<MdSpan> spans;
}

class MdListBlock extends MdBlock {
  const MdListBlock({required this.ordered, required this.items});
  final bool ordered;
  final List<List<MdSpan>> items;
}

class MdCodeBlock extends MdBlock {
  const MdCodeBlock({required this.code, this.language});
  final String? language;
  final String code;
}

class MdQuote extends MdBlock {
  const MdQuote(this.spans);
  final List<MdSpan> spans;
}

class MdTable extends MdBlock {
  const MdTable({required this.header, required this.rows});
  final List<List<MdSpan>> header;
  final List<List<List<MdSpan>>> rows;
}

class MdRule extends MdBlock {
  const MdRule();
}

class MdSpan {
  const MdSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.href,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final String? href;

  MdSpan decorate({bool bold = false, bool italic = false}) => MdSpan(
    text,
    bold: this.bold || bold,
    italic: this.italic || italic,
    code: code,
    href: href,
  );
}

List<MdBlock> parseAssistantMarkdown(String source) {
  final lines = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final blocks = <MdBlock>[];
  var index = 0;
  while (index < lines.length) {
    final line = lines[index];
    if (line.trim().isEmpty) {
      index++;
      continue;
    }
    if (line.trimLeft().startsWith('```')) {
      final language = line.trimLeft().substring(3).trim();
      final body = <String>[];
      index++;
      while (index < lines.length &&
          !lines[index].trimLeft().startsWith('```')) {
        body.add(lines[index]);
        index++;
      }
      if (index < lines.length) index++;
      blocks.add(
        MdCodeBlock(
          language: language.isEmpty ? null : language,
          code: body.join('\n'),
        ),
      );
      continue;
    }
    if (_isTableStart(lines, index)) {
      final table = _readTable(lines, index);
      blocks.add(table.block);
      index = table.next;
      continue;
    }
    final heading = _heading.firstMatch(line.trim());
    if (heading != null) {
      final level = heading.group(1)!.length.clamp(1, 3);
      blocks.add(MdHeading(level, parseAssistantInline(heading.group(2)!)));
      index++;
      continue;
    }
    if (_rule.hasMatch(line.trim())) {
      blocks.add(const MdRule());
      index++;
      continue;
    }
    if (line.trimLeft().startsWith('>')) {
      final quote = <String>[];
      while (index < lines.length && lines[index].trimLeft().startsWith('>')) {
        quote.add(lines[index].trimLeft().replaceFirst(RegExp(r'^>\s?'), ''));
        index++;
      }
      blocks.add(MdQuote(parseAssistantInline(quote.join(' '))));
      continue;
    }
    final listKind = _listKind(line);
    if (listKind != null) {
      final items = <List<MdSpan>>[];
      while (index < lines.length && _listKind(lines[index]) == listKind) {
        items.add(parseAssistantInline(_listBody(lines[index])));
        index++;
        while (index < lines.length &&
            lines[index].startsWith('  ') &&
            lines[index].trim().isNotEmpty &&
            _listKind(lines[index]) == null) {
          items[items.length - 1] = [
            ...items.last,
            const MdSpan(' '),
            ...parseAssistantInline(lines[index].trim()),
          ];
          index++;
        }
      }
      blocks.add(MdListBlock(ordered: listKind, items: items));
      continue;
    }
    final paragraph = <String>[];
    while (index < lines.length &&
        lines[index].trim().isNotEmpty &&
        !_opensBlock(lines, index)) {
      paragraph.add(lines[index].trim());
      index++;
    }
    if (paragraph.isNotEmpty) {
      blocks.add(MdParagraph(parseAssistantInline(paragraph.join(' '))));
    } else {
      index++;
    }
  }
  return blocks;
}

List<MdSpan> parseAssistantInline(String input) {
  final spans = <MdSpan>[];
  final buffer = StringBuffer();
  void flush() {
    if (buffer.isEmpty) return;
    spans.add(MdSpan(buffer.toString()));
    buffer.clear();
  }

  var index = 0;
  while (index < input.length) {
    if (input.startsWith('`', index)) {
      final close = input.indexOf('`', index + 1);
      flush();
      if (close == -1) {
        spans.add(MdSpan(input.substring(index + 1), code: true));
        break;
      }
      spans.add(MdSpan(input.substring(index + 1, close), code: true));
      index = close + 1;
      continue;
    }
    if (input.startsWith('**', index)) {
      final close = input.indexOf('**', index + 2);
      flush();
      if (close == -1) {
        spans.addAll(
          parseAssistantInline(
            input.substring(index + 2),
          ).map((span) => span.decorate(bold: true)),
        );
        break;
      }
      spans.addAll(
        parseAssistantInline(
          input.substring(index + 2, close),
        ).map((span) => span.decorate(bold: true)),
      );
      index = close + 2;
      continue;
    }
    if (input.startsWith('*', index)) {
      final close = input.indexOf('*', index + 1);
      if (close <= index + 1) {
        buffer.write('*');
        index++;
        continue;
      }
      flush();
      spans.addAll(
        parseAssistantInline(
          input.substring(index + 1, close),
        ).map((span) => span.decorate(italic: true)),
      );
      index = close + 1;
      continue;
    }
    if (input.startsWith('[', index)) {
      final labelEnd = input.indexOf(']', index + 1);
      final hasTarget =
          labelEnd != -1 &&
          labelEnd + 1 < input.length &&
          input[labelEnd + 1] == '(';
      if (hasTarget) {
        final urlEnd = _closingParen(input, labelEnd + 1);
        if (urlEnd != null) {
          final label = input.substring(index + 1, labelEnd);
          final url = input.substring(labelEnd + 2, urlEnd).trim();
          flush();
          spans.add(MdSpan(label, href: _safeUrl(url) ? url : null));
          index = urlEnd + 1;
          continue;
        }
      }
      if (labelEnd == -1) {
        buffer.write(input.substring(index + 1));
        break;
      }
    }
    buffer.write(input[index]);
    index++;
  }
  flush();
  return spans
      .where((span) => span.text.isNotEmpty || span.href != null)
      .toList();
}

int? _closingParen(String input, int open) {
  var depth = 0;
  for (var index = open; index < input.length; index++) {
    final char = input[index];
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) return index;
    }
  }
  return null;
}

bool _safeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  return _url.hasMatch(url);
}

bool? _listKind(String line) {
  if (_ordered.hasMatch(line.trim())) return true;
  if (_bullet.hasMatch(line.trim())) return false;
  return null;
}

String _listBody(String line) {
  final trimmed = line.trim();
  final ordered = _ordered.firstMatch(trimmed);
  if (ordered != null) return ordered.group(2)!;
  return _bullet.firstMatch(trimmed)!.group(1)!;
}

bool _opensBlock(List<String> lines, int index) {
  final line = lines[index];
  final trimmed = line.trim();
  if (trimmed.isEmpty) return true;
  if (line.trimLeft().startsWith('```')) return true;
  if (_heading.hasMatch(trimmed) || _rule.hasMatch(trimmed)) return true;
  if (line.trimLeft().startsWith('>')) return true;
  if (_listKind(line) != null) return true;
  if (_isTableStart(lines, index)) return true;
  return false;
}

bool _isTableStart(List<String> lines, int index) {
  if (index + 1 >= lines.length) return false;
  return lines[index].trimLeft().startsWith('|') &&
      _isSeparator(lines[index + 1]);
}

bool _isSeparator(String line) {
  if (!line.trimLeft().startsWith('|')) return false;
  final cells = _cells(line);
  if (cells.isEmpty) return false;
  return cells.every((cell) => RegExp(r'^:?-{3,}:?$').hasMatch(cell));
}

List<String> _cells(String line) {
  var trimmed = line.trim();
  if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
  if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);
  return trimmed.split('|').map((cell) => cell.trim()).toList();
}

({MdTable block, int next}) _readTable(List<String> lines, int index) {
  final header = _cells(lines[index]).map(parseAssistantInline).toList();
  var cursor = index + 2;
  final rows = <List<List<MdSpan>>>[];
  while (cursor < lines.length && lines[cursor].trimLeft().startsWith('|')) {
    if (_isSeparator(lines[cursor])) {
      cursor++;
      continue;
    }
    final cells = _cells(lines[cursor]).map(parseAssistantInline).toList();
    rows.add(_fit(cells, header.length));
    cursor++;
  }
  return (block: MdTable(header: header, rows: rows), next: cursor);
}

List<List<MdSpan>> _fit(List<List<MdSpan>> cells, int width) {
  if (cells.length == width) return cells;
  if (cells.length > width) return cells.sublist(0, width);
  return [
    ...cells,
    for (var extra = cells.length; extra < width; extra++) const <MdSpan>[],
  ];
}
