# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [
    FreedomFormatter,
  ],
  trailing_comma: true,
  migrate_call_parens_on_pipe: true,
]
