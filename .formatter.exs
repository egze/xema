locals_without_parens = [xema: 2, field: 2, field: 3, required: 1]

[
  inputs: ["mix.exs", ".dialyzer_ignore.exs", "{config,lib,test,bench}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens ++ [assert_blame: 3],
  export: [
    locals_without_parens: locals_without_parens
  ]
]
