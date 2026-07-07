module.exports = grammar({
  name: "selfie_snapshot",

  rules: {
    document: ($) => repeat($.block),

    block: ($) => seq($.header, optional($.content)),

    header: ($) =>
      seq("╔═", field("filename", choice($.end_marker, $.filename)), "═╗"),

    filename: ($) => /\S([^═╗\n]*\S)?/,

    end_marker: ($) => "[end of file]",

    content: ($) => /[^╔]+/,
  },
});
