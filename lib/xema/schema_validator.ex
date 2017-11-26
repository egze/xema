defmodule Xema.SchemaValidator do
  @moduledoc false

  import Xema.Validator, only: [is_unique?: 1]

  @xema %Xema{} |> Map.keys() |> MapSet.new()

  @get_keys fn type ->
    type
    |> Map.keys()
    |> MapSet.new()
    |> MapSet.union(@xema)
  end

  @keys [
    any: @get_keys.(%Xema.Any{}),
    boolean: @get_keys.(%Xema.Boolean{}),
    float: @get_keys.(%Xema.Float{}),
    integer: @get_keys.(%Xema.Integer{}),
    list: @get_keys.(%Xema.List{}),
    map: @get_keys.(%Xema.Map{}),
    number: @get_keys.(%Xema.Number{}),
    string: @get_keys.(%Xema.String{})
  ]

  @spec validate(atom, keyword) :: :ok | {:error, String.t()}
  def validate(_, []), do: :ok

  def validate(:any, opts) do
    with :ok <- validate_keywords(:any, opts),
         :ok <- enum(:any, opts[:enum]) do
      :ok
    end
  end

  def validate(:boolean, opts) do
    with :ok <- validate_keywords(:boolean, opts) do
      :ok
    end
  end

  def validate(:list, opts) do
    with :ok <- items(opts[:items]),
         :ok <- additional_items(opts[:additional_items], opts[:items]),
         :ok <- validate_keywords(:list, opts) do
      :ok
    end
  end

  def validate(:map, opts) do
    with :ok <-
           additional_properties(
             opts[:additional_properties],
             opts[:properties],
             opts[:pattern_properties]
           ),
         :ok <- dependencies(opts[:dependencies]),
         :ok <- validate_keywords(:map, opts) do
      :ok
    end
  end

  def validate(type, opts)
      when type == :number or type == :integer or type == :float do
    with :ok <- ex_min_max(type, :exclusive_maximum, opts[:exclusive_maximum], opts[:maximum]),
         :ok <- ex_min_max(type, :exclusive_minimum, opts[:exclusive_minimum], opts[:minimum]),
         :ok <- min_max(type, :maximum, opts[:maximum]),
         :ok <- min_max(type, :minimum, opts[:minimum]),
         :ok <- multiple_of(type, opts[:multiple_of]),
         :ok <- validate_keywords(type, opts),
         :ok <- enum(type, opts[:enum]) do
      :ok
    end
  end

  def validate(:string, opts) do
    with :ok <- validate_keywords(:string, opts),
         :ok <- enum(:string, opts[:enum]) do
      :ok
    end
  end

  # Check for unsupported keywords.

  defp validate_keywords(type, opts) do
    case difference(type, opts) do
      [] ->
        :ok

      keywords ->
        {
          :error,
          "Keywords #{inspect(keywords)} are not supported by #{inspect(type)}."
        }
    end
  end

  defp difference(type, opts),
    do:
      opts
      |> Keyword.keys()
      |> MapSet.new()
      |> MapSet.difference(@keys[type])
      |> MapSet.to_list()

  # Keyword: additional_items
  # The value of `additional_items` must be either a boolean or a schema.

  defp additional_items(nil, _), do: :ok

  defp additional_items(_, nil), do: {:error, "additional_items has no effect if items not set."}

  defp additional_items(_, items)
       when not is_list(items),
       do: {:error, "additional_items has no effect if items is not a list."}

  defp additional_items(_, _), do: :ok

  # Keyword: additional_properties
  # The value of `additional_properties` must be a boolean or a schema.

  defp additional_properties(nil, _, _), do: :ok

  defp additional_properties(_, nil, nil),
    do: {:error, "additional_properties has no effect if properties not set."}

  defp additional_properties(_, properties, nil)
       when not is_map(properties),
       do: {:error, "additional_properties has no effect if properties is not a map."}

  defp additional_properties(_, _, _), do: :ok

  # Keyword: dependencies
  # This keyword's value must be a map. Each property specifies a dependency.
  # Each dependency value must be an array or a valid schema.

  defp dependencies(nil), do: :ok

  defp dependencies(value) when is_map(value), do: :ok

  defp dependencies(_), do: {:error, "dependencies must be a map."}

  # Keyword: enum
  # The value of this keyword must be an array. This array should have at least
  # one element. Elements in the array should be unique.

  defp enum(_, nil), do: :ok

  defp enum(_, []), do: {:error, "enum can not be an empty list."}

  defp enum(type, value) when is_list(value) do
    case is_unique?(value) do
      false -> {:error, "enum must be unique."}
      true -> do_enum(type, value)
    end
  end

  defp enum(_, _), do: {:error, "enum must be a list."}

  defp do_enum(:any, _), do: :ok

  defp do_enum(:number, value) do
    case Enum.all?(value, fn item -> is_number(item) end) do
      true -> :ok
      false -> {:error, "Entries of enum have to be Integers or Floats."}
    end
  end

  defp do_enum(:integer, value) do
    case Enum.all?(value, fn item -> is_integer(item) end) do
      true -> :ok
      false -> {:error, "Entries of enum have to be Integers."}
    end
  end

  defp do_enum(:float, value) do
    case Enum.all?(value, fn item -> is_float(item) end) do
      true -> :ok
      false -> {:error, "Entries of enum have to be Floats."}
    end
  end

  defp do_enum(:string, value) do
    case Enum.all?(value, fn item -> is_binary(item) end) do
      true -> :ok
      false -> {:error, "Entries of enum have to be Strings."}
    end
  end

  # Keyword: exclusive_maximum
  # Draft-06: The value of `exclusive_maximum` must be number, representing an
  # exclusive upper limit for a numeric instance.
  # Draft-04: if `exclusive_maximum` has boolean value true, the instance is
  # valid if it is strictly lower than the value of `maximum`.
  #
  # Keyword: exclusive_minimum
  # Draft-06: The value of `exclusive_minimum` must be number, representing an
  # exclusive lower limit for a numeric instance.
  # Draft-04: if `exclusive_minimum` has boolean value true, the instance is
  # valid if it is strictly higher than the value of `maximum`.

  defp ex_min_max(_, _, nil, _), do: :ok

  defp ex_min_max(:integer, _, value, nil) when is_integer(value), do: :ok

  defp ex_min_max(:float, _, value, nil) when is_number(value), do: :ok

  defp ex_min_max(:number, _, value, nil) when is_number(value), do: :ok

  defp ex_min_max(_, _, value, maximum)
       when is_boolean(value) and is_number(maximum),
       do: :ok

  defp ex_min_max(_, :exclusive_maximum, value, _maximum)
       when is_boolean(value),
       do: {:error, "No maximum value found for exclusive_maximum."}

  defp ex_min_max(_, :exclusive_minimum, value, _maximum)
       when is_boolean(value),
       do: {:error, "No minimum value found for exclusive_minimum."}

  defp ex_min_max(:integer, keyword, value, nil),
    do: {:error, "Expected a integer for #{keyword}, got #{inspect(value)}"}

  defp ex_min_max(_, keyword, value, nil),
    do: {:error, "Expected a number for #{keyword}, got #{inspect(value)}"}

  defp ex_min_max(_, :exclusive_maximum, value, _maximum)
       when is_number(value),
       do: {:error, "The exclusive_maximum overwrites maximum."}

  defp ex_min_max(_, :exclusive_minimum, value, _maximum)
       when is_number(value),
       do: {:error, "The exclusive_minimum overwrites minimum."}

  defp ex_min_max(_, keyword, value, _maximum),
    do: {:error, "Expected a boolean for #{keyword}, got #{inspect(value)}"}

  # Keyword: items
  # The value of `items` MUST be either a valid JSON Schema or an array of
  # valid JSON Schemas.

  defp items(nil), do: :ok

  defp items(value)
       when is_list(value) or is_tuple(value) or is_atom(value) or is_map(value),
       do: :ok

  defp items(value),
    do: {:error, "Expected a schema or a list of schemas, got #{inspect(value)}."}

  # Keyword: maximum
  # The value of `maximum` must be a number, representing an inclusive upper
  # limit for a numeric instance.
  #
  # Keyword: minimum
  # The value of `minimum` must be a number, representing an inclusive upper
  # limit for a numeric instance.

  defp min_max(_, _, nil), do: :ok

  defp min_max(:number, _, value) when is_number(value), do: :ok

  defp min_max(:integer, _, value) when is_integer(value), do: :ok

  defp min_max(:float, _, value) when is_number(value), do: :ok

  defp min_max(:integer, keyword, value),
    do: {:error, "Expected an Integer for #{keyword}, got #{inspect(value)}."}

  defp min_max(_, keyword, value),
    do: {:error, "Expected a number for #{keyword}, got #{inspect(value)}."}

  # Keyword: multiple_of
  # The value of `multipleOf` must be a number, strictly greater than 0.

  defp multiple_of(_, nil), do: :ok

  defp multiple_of(:integer, value)
       when is_integer(value),
       do: do_multiple_of(value)

  defp multiple_of(:float, value)
       when is_number(value),
       do: do_multiple_of(value)

  defp multiple_of(:number, value)
       when is_number(value),
       do: do_multiple_of(value)

  defp multiple_of(:integer, value),
    do:
      {
        :error,
        "Expected an Integer for multiple_of, got #{inspect(value)}."
      }

  defp multiple_of(_, value),
    do:
      {
        :error,
        "Expected a number for multiple_of, got #{inspect(value)}."
      }

  @compile {:inline, do_multiple_of: 1}
  defp do_multiple_of(value) do
    case value > 0 do
      true -> :ok
      false -> {:error, "multiple_of must be strictly greater than 0."}
    end
  end
end
