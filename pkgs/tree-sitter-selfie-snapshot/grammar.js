module.exports = grammar({
  name: "selfie_snapshot",

  // Whitespace and newlines are significant, so disable the default `extras`.
  extras: () => [],

  rules: {
    document: ($) => repeat($.block),

    block: ($) => seq($.header, optional($.content)),

    // KEY_START="╔═ " and KEY_END=" ═╗" per the selfie format. The trailing
    // segment after KEY_END carries optional flags (e.g. " base64 length N bytes").
    header: ($) =>
      seq(
        "╔═ ",
        field("filename", choice($.end_marker, $.filename)),
        " ═╗",
        /[^\n]*/,
        optional("\n"),
      ),

    // The key has no leading or trailing spaces and cannot contain the box
    // characters, but may contain interior spaces.
    filename: () => /[^ ═╗\n]([^═╗\n]*[^ ═╗\n])?/,

    end_marker: () => "[end of file]",

    content: () => /[^╔]+/,
  },
});
