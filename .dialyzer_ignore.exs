[
  # Ignore warnings caused by the following problem:
  # https://github.com/elixir-lang/elixir/issues/7177
  {"lib/xema/schema.ex", :pattern_match, 322},
  {"lib/xema/validator.ex", :pattern_match, 388},

  # due a bug in dialyzer
  ~r/.*Function.Xema.Castable.*.__impl__.1.does.not.exist.*/
]
