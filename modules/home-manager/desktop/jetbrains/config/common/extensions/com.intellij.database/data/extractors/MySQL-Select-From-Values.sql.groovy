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

SEP = ", "
QUOTE     = "\'"
STRING_PREFIX = DIALECT.getDbms().isMicrosoft() ? "N" : ""
NEWLINE   = System.getProperty("line.separator")

KEYWORDS_LOWERCASE = com.intellij.database.util.DbSqlUtil.areKeywordsLowerCase(PROJECT)
KW_SELECT = KEYWORDS_LOWERCASE ? "select *" : "SELECT *"
KW_FROM_VALUES = KEYWORDS_LOWERCASE ? "from (values" : "FROM (VALUES"
KW_ROW = KEYWORDS_LOWERCASE ? "row" : "ROW"
KW_AS = KEYWORDS_LOWERCASE ? "as" : "AS"
KW_NULL = KEYWORDS_LOWERCASE ? "null" : "NULL"

OUT.append(KW_SELECT).append(NEWLINE)
OUT.append(KW_FROM_VALUES)

def first = true
ROWS.each { dataRow ->
    if (!first) OUT.append(NEWLINE).append(",")
    OUT.append(" ").append(KW_ROW).append(" (")

    COLUMNS.eachWithIndex { column, idx ->
        def value = dataRow.value(column)
        def stringValue = value == null ? KW_NULL : FORMATTER.formatValue(value, column)
        def isStringLiteral = value != null && FORMATTER.isStringLiteral(value, column)
        if (isStringLiteral && DIALECT.getDbms().isMysql()) stringValue = stringValue.replace("\\", "\\\\")
        OUT.append(isStringLiteral ? (STRING_PREFIX + QUOTE) : "")
          .append(isStringLiteral ? stringValue.replace(QUOTE, QUOTE + QUOTE) : stringValue)
          .append(isStringLiteral ? QUOTE : "")
          .append(idx != COLUMNS.size() - 1 ? SEP : "")
    }

    OUT.append(")")
    first = false
}

OUT.append(NEWLINE).append("     ) ").append(KW_AS).append(" ")

if (TABLE == null) OUT.append("t")
else OUT.append(TABLE.getName())

OUT.append(" (")

COLUMNS.eachWithIndex { column, idx ->
    OUT.append(column.name()).append(idx != COLUMNS.size() - 1 ? SEP : "")
}

OUT.append(")").append(NEWLINE)
