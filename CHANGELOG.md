# Changelog

## 0.13.2 - 2020/10/06

+ Fixing docs for `Xema.Builder.strux/1`.
+ Updating deps.
+ Fixing tests.

## 0.13.1 - 2020/09/09

+ Fixing minor issues.

## 0.13.0 - 2020/09/07

+ Adding option `:fail` to `Xema.validate/3`. See also
  ["Validate with option `:fail`"](examples.html#validate-with-option-fail)

## 0.12.0 - 2020/08/26

+ Refactoring of the properties validation.

### Breaking changes

+ The error data structure for `list` `items` has changed from a `list` of
  `tuple`s to a `map`. This change allows you to convert `reason` directly to
  JSON.

since 0.12.0:
```elixir
iex> schema = Xema.new({:list, items: :integer})
iex> Xema.validate(schema, [1, "foo", 2, :bar])
{:error,
 %Xema.ValidationError{
   message: nil,
   reason: %{
     items: %{
       1 => %{type: :integer, value: "foo"},
       3 => %{type: :integer, value: :bar}
     }
   }
 }}
```
before 0.12.0:
```elixir
iex> schema = Xema.new({:list, items: :integer})
iex> Xema.validate(schema, [1, "foo", 2, :bar])
{:error,
 %Xema.ValidationError{
   message: nil,
   reason: %{
     items: [
       {1, %{type: :integer, value: "foo"}},
       {3, %{type: :integer, value: :bar}}
     ]
   }
 }}
```

## 0.11.4 - 2020/08/19

+ Fix an issue with circular references.

## 0.11.3 - 2020/08/18

+ Fix an issue with circular references.

## 0.11.2 - 2020/07/31

+ Fix a bug when `unique_items` is explicit set to `false`.

## 0.11.1 - 2020/07/17

+ Fix hostname format validation. Thanks to @romul.

## 0.11.0 - 2019/10/19

+ Add `Xema.from_json_schema`.

## 0.10.0 - 2019/09/8

+ Refactor `Xema.cast` with an improvement of the error messages.
+ Add macro `field` and `required` for struct schemas.

## 0.9.3 - 2019/08/25

+ Fix specs.

## 0.9.2 - 2019/08/21

+ Update specs.

## 0.9.1 - 2019/06/16

+ Silence warnings for `Decimal`.

## 0.9.0 - 2019/06/16

### New features

+ Add `Xema.cast/2`.

### Breaking changes

+ Add option `multi` to use multiple schema modules: `use Xema, multi: true`.
+ Remove `xema/2` macro.
+ Add `xema/0` and `xema/1` macro.
+ Change return value of `Xema.validate/2` to `{:error, Exception.t}` in case
  of error.
+ Update `Xema.ValidationError`.
  + `ValidationError.reason` contains the error map of the previous versions
    with some changes.
  + `ValidationError.message` contains an error message.

### Bugfixes

+ Fixes in `Xema.Validator`. In some cases the validators `any_of`, `one_of`,
`all_of`, `enum`, `not`, `const`, and `if-then-else` was be ignored.

## O.8.1 - 2019/06/02

+ Fix email format checker.

## 0.8.0 - 2019/03/10

+ Inline references in schemas by default. Increased performance of reference
  handling by 30%.
+ Rename `defxema` to `xema` and refactor macros.
+ Add custom `validator`.
+ Add examples page.
+ Add `@default true`.

## 0.7.0 - 2019/02/10

+ Increase `ref` performance.
+ Fix option `:resolver` in `Xema.new/2`.
+ Refactor `ref` handling,
+ Rename `resolver` to `loader`.
+ Remove deprecated function `Xema.is_valid/2`.
+ Reduce public API docs.
+ Add `Xema.Builder` and `use Xema`.

## 0.6.3 - 2019/01/15

+ Ignore unknown formatters.

## 0.6.2 - 2019/01/13

+ Change regex for email validation (~7x faster).
+ Add `:resolver` option to `Xema.new`.
+ Speed up string validator.

## 0.6.1 - 2019/01/06

Update docs.

## 0.6.0 - 2018/12/29

+ Fixed and updated some specs.
+ Remote check for references is moved to the `behaviour`.
+ Key types in the schema are now matters for validation. See
  [Usage - Key types](https://hexdocs.pm/xema/usage.html#key_types)

## 0.5.0 - 2018/12/25

+ The function `Xema.is_valid?/2` is deprecated. Use `Xema.valid?/2` instead.
+ Add keyword `const`.
+ Add keywords `if`, `then`, `else`.
+ Add handling for none-keyword data.
+ Add annotation keywords
  + `examples`
  + `comment`
  + `contentEncoding`
  + `contentMediaType`contentMediaType
+ Add new `format` checks.
+ Add validatiors for `atom`, `keyword`, `tuple` and `struct`
+ Add schema validator to validate data give to `Xema.new/1`.
+ `Xema.new/2` becomes `Xema.new/1`.
  Migrate to 0.5.0:
  ```elixir
  # < 0.5.0
  Xema.new(:integer, minimum: 0)
  # >= 0.5.0
  Xema.new({:integer, minimum: 0})
  ```
+ Add Xema.validate!/2
