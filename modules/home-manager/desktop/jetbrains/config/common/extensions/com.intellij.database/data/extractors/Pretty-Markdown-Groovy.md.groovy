package extensions.data.extractors

/*
 * Available context bindings:
 *   COLUMNS     List<DataColumn>
 *   ROWS        Iterable<DataRow>
 *   OUT         { append() }
 *   FORMATTER   { format(row, col); formatValue(Object, col); getTypeName(Object, col); isStringLiteral(Object, col); }
 *   TRANSPOSED  Boolean
 * plus ALL_COLUMNS, TABLE, DIALECT
 *
 * where:
 *   DataRow     { rowNumber(); first(); last(); data(): List<Object>; value(column): Object }
 *   DataColumn  { columnNumber(), name() }
 */

NEWLINE = System.getProperty("line.separator")
SEPARATOR = "|"
BACKSLASH = "\\"
BACKQUOTE = "`"
LTAG = "<"
RTAG = ">"
ASTERISK = "*"
UNDERSCORE = "_"
LPARENTH = "("
RPARENTH = ")"
LBRACKET = "["
RBRACKET = "]"
TILDE = "~"

def escape = { value ->
  value.toString()
    .replace(BACKSLASH, BACKSLASH + BACKSLASH)
    .replace(SEPARATOR, BACKSLASH + SEPARATOR)
    .replace(BACKQUOTE, BACKSLASH + BACKQUOTE)
    .replace(ASTERISK, BACKSLASH + ASTERISK)
    .replace(UNDERSCORE, BACKSLASH + UNDERSCORE)
    .replace(LPARENTH, BACKSLASH + LPARENTH)
    .replace(RPARENTH, BACKSLASH + RPARENTH)
    .replace(LBRACKET, BACKSLASH + LBRACKET)
    .replace(RBRACKET, BACKSLASH + RBRACKET)
    .replace(TILDE, BACKSLASH + TILDE)
    .replace(LTAG, "&lt;")
    .replace(RTAG, "&gt;")
    .replaceAll("\r\n|\r|\n", "<br/>")
    .replaceAll("\t|\b|\f", "")
}

def printRow = { cells, widths, firstBold = false ->
  cells.eachWithIndex { cell, idx ->
    def content = firstBold && idx == 0 ? "**" + cell + "**" : cell
    OUT.append("| ").append(content.padRight(widths[idx], " ")).append(" ")
  }
  OUT.append("|").append(NEWLINE)
}

def printSeparator = { widths, aligns ->
  widths.eachWithIndex { w, idx ->
    OUT.append("| ").append((aligns[idx]).padRight(w, "-")).append(" ")
  }
  OUT.append("|").append(NEWLINE)
}

if (TRANSPOSED) {
  def rows = COLUMNS.collect { new ArrayList<String>([escape(it.name())]) }
  ROWS.forEach { row ->
    COLUMNS.eachWithIndex { col, i -> rows[i].add(escape(FORMATTER.format(row, col))) }
  }
  def colCount = rows.isEmpty() ? 0 : rows[0].size()
  def widths = new int[colCount]
  rows.each { r ->
    r.eachWithIndex { cell, idx ->
      def len = idx == 0 ? cell.length() + 4 : cell.length()
      widths[idx] = Math.max(widths[idx], len)
    }
  }
  def aligns = new String[colCount]
  for (int i = 0; i < colCount; i++) aligns[i] = ":"
  rows.eachWithIndex { r, idx ->
    printRow(r, widths, true)
    if (idx == 0) printSeparator(widths, aligns)
  }
}
else {
  def header = COLUMNS.collect { escape(it.name()) }
  def dataRows = new ArrayList<List<String>>()
  ROWS.each { row ->
    dataRows.add(COLUMNS.collect { escape(FORMATTER.format(row, it)) })
  }

  def widths = new int[COLUMNS.size()]
  header.eachWithIndex { name, idx -> widths[idx] = name.length() }
  dataRows.each { r ->
    r.eachWithIndex { cell, idx -> widths[idx] = Math.max(widths[idx], cell.length()) }
  }
  // separator needs room for at least ":---"
  for (int i = 0; i < widths.length; i++) widths[i] = Math.max(widths[i], 4)

  def aligns = new String[COLUMNS.size()]
  for (int i = 0; i < aligns.length; i++) aligns[i] = ":"

  printRow(header, widths)
  printSeparator(widths, aligns)
  dataRows.each { r -> printRow(r, widths) }
}
