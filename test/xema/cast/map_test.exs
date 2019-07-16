defmodule Xema.Cast.MapTest do
  use ExUnit.Case, async: true

  import AssertBlame
  import Xema, only: [cast: 2, cast!: 2, validate: 2]

  alias Xema.{CastError, ValidationError}

  @set [1, 1.1, [42], {:tuple}, :atom]

  #
  # Xema.cast/2
  #

  describe "cast/2 with a minimal map schema" do
    setup do
      %{
        schema: Xema.new(:map)
      }
    end

    test "from an empty map", %{schema: schema} do
      data = %{}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, data}
    end

    test "from a map with atom keys", %{schema: schema} do
      data = %{bla: "foo"}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, data}
    end

    test "from a map with string keys", %{schema: schema} do
      data = %{"bla" => "foo"}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, data}
    end

    test "from a map with mixed keys", %{schema: schema} do
      data = %{"bla" => "foo", foo: "bla"}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, data}
    end

    test "from a map with the same key as string and atom", %{schema: schema} do
      data = %{"foo" => "bla", foo: "bla"}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, data}
    end

    test "from a keyword list", %{schema: schema} do
      assert cast(schema, foo: 6) == {:ok, %{foo: 6}}
    end

    test "from an invalid type", %{schema: schema} do
      Enum.each(@set, fn data ->
        expected = {:error, CastError.exception(path: [], to: :map, value: data)}
        assert cast(schema, data) == expected
      end)
    end
  end

  describe "cast/2 with a map schema and [keys: :atoms]" do
    setup do
      %{
        schema: Xema.new({:map, keys: :atoms})
      }
    end

    test "from a map with known atom", %{schema: schema} do
      _ = String.to_atom("zzz")
      assert cast(schema, %{"zzz" => "z"}) == {:ok, %{zzz: "z"}}
    end

    test "from a map with unknown atom", %{schema: schema} do
      data = %{"xyz" => "zyx"}
      expected = {:error, CastError.exception(path: [], key: "xyz", to: :map)}

      assert cast(schema, data) == expected
    end

    test "from a keyword list", %{schema: schema} do
      assert cast(schema, foo: 6) == {:ok, %{foo: 6}}
    end

    test "from a map with mixed keys", %{schema: schema} do
      data = %{"bla" => "foo", foo: "bla"}
      assert cast(schema, data) == {:ok, %{:foo => "bla", :bla => "foo"}}
    end

    test "from a map with the same key as string and atom", %{schema: schema} do
      data = %{"foo" => "bar", foo: "baz"}
      assert {:error, error} = cast(schema, data)
      assert Exception.message(error) == "cannot cast foo to :keyword key, the key is ambiguous"
    end
  end

  describe "cast/2 with a map schema and [keys: :strings]" do
    setup do
      %{
        schema: Xema.new({:map, keys: :strings})
      }
    end

    test "from a map with atom keys", %{schema: schema} do
      assert cast(schema, %{abc: 55, zzz: "z"}) ==
               {:ok, %{"abc" => 55, "zzz" => "z"}}
    end

    test "from a map with string keys", %{schema: schema} do
      data = %{"abc" => 55, "zzz" => "z"}
      assert cast(schema, data) == {:ok, data}
    end

    test "from a keyword list", %{schema: schema} do
      assert cast(schema, foo: 6) == {:ok, %{"foo" => 6}}
    end
  end

  describe "cast/2 with a map schema, [keys: :atoms] and properties" do
    setup do
      %{
        schema: Xema.new({:map, keys: :atoms, properties: %{bla: :string}})
      }
    end

    test "from map with string keys and valid property", %{schema: schema} do
      data = %{"bla" => "foo"}

      assert {:error,
              %ValidationError{
                reason: %{keys: :atoms}
              }} = validate(schema, data)

      assert cast(schema, data) == {:ok, %{bla: "foo"}}
    end

    test "from map with string keys and integer property", %{schema: schema} do
      data = %{"bla" => 11}

      assert {:error,
              %ValidationError{
                reason: %{keys: :atoms}
              }} = validate(schema, data)

      assert {:ok, cast} = cast(schema, data)
      assert cast == %{bla: "11"}

      assert validate(schema, cast) == :ok
    end

    test "from map with atom keys and string property", %{schema: schema} do
      data = %{bla: "foo"}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, data}
    end

    test "from map with atom keys and a castable value", %{schema: schema} do
      data = %{bla: 11}

      assert {:error,
              %ValidationError{
                reason: %{properties: %{bla: %{type: :string, value: 11}}}
              }} = validate(schema, data)

      assert {:ok, cast} = cast(schema, data)
      assert cast == %{bla: "11"}

      assert validate(schema, cast) == :ok
    end

    test "from a map with unknown atom", %{schema: schema} do
      data = %{"xyz" => "z"}
      expected = {:error, CastError.exception(path: [], key: "xyz", to: :map)}

      assert cast(schema, data) == expected
    end

    test "from a keyword list", %{schema: schema} do
      assert cast(schema, foo: 6) == {:ok, %{foo: 6}}
    end
  end

  describe "cast/2 with a map schema and additional properties" do
    setup do
      %{
        schema:
          Xema.new({
            :map,
            keys: :atoms,
            properties: %{
              str: :string
            },
            additional_properties: :integer
          })
      }
    end

    test "from a map without an additional property", %{schema: schema} do
      assert cast(schema, %{str: 5}) == {:ok, %{str: "5"}}
    end

    test "from a map with an additional property", %{schema: schema} do
      assert cast(schema, %{str: "foo", a: "5"}) == {:ok, %{str: "foo", a: 5}}
    end

    test "from a keyword list with an additional property", %{schema: schema} do
      assert cast(schema, str: "foo", a: "5") == {:ok, %{str: "foo", a: 5}}
    end

    test "from a map with an invalid additional property", %{schema: schema} do
      assert cast(schema, %{str: "foo", a: "x"}) ==
               {:error, %CastError{key: nil, message: nil, path: [:a], to: :integer, value: "x"}}
    end
  end

  describe "cast/2 with a map schema, [keys: :strings] and properties" do
    setup do
      %{
        schema: Xema.new({:map, keys: :strings, properties: %{"bla" => :string}})
      }
    end

    test "from map with string keys", %{schema: schema} do
      data = %{"bla" => "foo"}
      assert validate(schema, data) == :ok
      assert cast(schema, data) == {:ok, %{"bla" => "foo"}}
    end

    test "from map with string keys and castable value", %{schema: schema} do
      data = %{"bla" => 11}

      assert {:error,
              %ValidationError{
                reason: %{properties: %{"bla" => %{type: :string, value: 11}}}
              }} = validate(schema, data)

      assert cast(schema, data) == {:ok, %{"bla" => "11"}}
    end

    test "from map with atoms keys", %{schema: schema} do
      data = %{bla: "foo"}

      assert {:error,
              %ValidationError{
                reason: %{keys: :strings}
              }} = validate(schema, data)

      assert cast(schema, data) == {:ok, %{"bla" => "foo"}}
    end

    test "from map with atom keys and castable value", %{schema: schema} do
      data = %{bla: 11}

      assert {:error,
              %ValidationError{
                reason: %{keys: :strings}
              }} = validate(schema, data)

      assert cast(schema, data) == {:ok, %{"bla" => "11"}}
    end

    test "from a map with additional property", %{schema: schema} do
      assert cast(schema, %{bla: 42, foo: 11}) == {:ok, %{"bla" => "42", "foo" => 11}}
    end

    test "from a keyword list", %{schema: schema} do
      assert cast(schema, bla: 6, foo: 11) == {:ok, %{"bla" => "6", "foo" => 11}}
    end
  end

  describe "cast/2 with a nested map schema" do
    setup do
      %{
        schema:
          Xema.new(
            {:map,
             keys: :atoms,
             properties: %{
               foo:
                 {:map,
                  keys: :atoms,
                  properties: %{
                    num: {:integer, maximum: 12},
                    bar:
                      {:map,
                       keys: :atoms,
                       properties: %{
                         num: {:integer, maximum: 12}
                       }}
                  }}
             }}
          )
      }
    end

    test "from a valid map", %{schema: schema} do
      data = %{"foo" => %{"num" => 2}}
      expected = {:ok, %{foo: %{num: 2}}}

      assert cast(schema, data) == expected
    end

    test "from a map with unknown key", %{schema: schema} do
      data = %{"foo" => %{"xyz" => 42}}
      expected = {:error, CastError.exception(path: ["foo"], key: "xyz", to: :map)}

      assert cast(schema, data) == expected
    end

    test "from a map with unknown key (deeper)", %{schema: schema} do
      data = %{"foo" => %{"bar" => %{"xyz" => 42}}}
      expected = {:error, CastError.exception(path: ["foo", "bar"], key: "xyz", to: :map)}

      assert cast(schema, data) == expected
    end

    test "from an invalid map", %{schema: schema} do
      data = %{"foo" => %{"num" => "42"}}

      assert cast(schema, data) ==
               {:error,
                %ValidationError{
                  reason: %{
                    properties: %{
                      foo: %{properties: %{num: %{value: 42, maximum: 12}}}
                    }
                  }
                }}
    end

    test "from a keyword list nested in a map", %{schema: schema} do
      data = %{"foo" => [num: 2]}
      expected = {:ok, %{foo: %{num: 2}}}

      assert cast(schema, data) == expected
    end

    test "from nested keyword lists", %{schema: schema} do
      data = [foo: [num: 2]]
      expected = {:ok, %{foo: %{num: 2}}}

      assert cast(schema, data) == expected
    end
  end

  describe "cast/2 with an integer property" do
    setup do
      %{
        schema: Xema.new(properties: %{num: :integer})
      }
    end

    test "with a valid value", %{schema: schema} do
      assert cast(schema, %{num: "77"}) == {:ok, %{num: 77}}
    end

    test "with an invalid value", %{schema: schema} do
      data = %{num: "77."}
      expected = {:error, CastError.exception(path: [:num], to: :integer, value: "77.")}

      assert cast(schema, data) == expected
    end

    test "with an invalid value from a keyword list", %{schema: schema} do
      data = [num: "77."]
      expected = {:error, CastError.exception(path: [:num], to: :integer, value: "77.")}

      assert cast(schema, data) == expected
    end
  end

  #
  # Xema.cast!/2
  #

  describe "cast!/2 with a minimal map schema" do
    setup do
      %{
        schema: Xema.new(:map)
      }
    end

    test "from an empty map", %{schema: schema} do
      data = %{}
      assert cast!(schema, data) == data
    end

    test "from a map with atom keys", %{schema: schema} do
      data = %{bla: "foo"}
      assert cast!(schema, data) == data
    end

    test "from a map with key strings", %{schema: schema} do
      data = %{"bla" => "foo"}
      assert cast!(schema, data) == data
    end

    test "from a keyword list", %{schema: schema} do
      assert cast!(schema, foo: 5) == %{foo: 5}
    end

    test "from an invalid type", %{schema: schema} do
      Enum.each(@set, fn data ->
        msg = "cannot cast #{inspect(data)} to :map"

        assert_blame CastError, msg, fn -> cast!(schema, data) end
      end)
    end
  end

  describe "cast!/2 with a map schema and [keys: :atoms]" do
    setup do
      %{
        schema: Xema.new({:map, keys: :atoms})
      }
    end

    test "from a map with known atom", %{schema: schema} do
      _ = String.to_atom("zzz")
      assert cast!(schema, %{"zzz" => "z"}) == %{zzz: "z"}
    end

    test "from a map with unknown atom", %{schema: schema} do
      data = %{"xyz" => "z"}
      msg = ~s|cannot cast "xyz" to :map key, the atom is unknown|

      assert_blame CastError, msg, fn -> cast!(schema, data) end
    end

    test "from a keyword list", %{schema: schema} do
      assert cast!(schema, foo: 7) == %{foo: 7}
    end
  end

  describe "cast!/2 with a map schema and [keys: :strings]" do
    setup do
      %{
        schema: Xema.new({:map, keys: :strings})
      }
    end

    test "from a map with atom keys", %{schema: schema} do
      assert cast!(schema, %{abc: 55, zzz: "z"}) == %{"abc" => 55, "zzz" => "z"}
    end

    test "from a map with string keys", %{schema: schema} do
      data = %{"abc" => 55, "zzz" => "z"}
      assert cast!(schema, data) == data
    end

    test "from a keyword list", %{schema: schema} do
      assert cast!(schema, foo: 9) == %{"foo" => 9}
    end
  end

  describe "cast!/2 with a map schema, [keys: :atoms] and properties" do
    setup do
      %{
        schema: Xema.new({:map, keys: :atoms, properties: %{bla: :string}})
      }
    end

    test "from map with string keys and valid property", %{schema: schema} do
      data = %{"bla" => "foo"}
      assert cast!(schema, data) == %{bla: "foo"}
    end

    test "from map with string keys and integer property", %{schema: schema} do
      data = %{"bla" => 11}

      assert {:error,
              %ValidationError{
                reason: %{keys: :atoms}
              }} = validate(schema, data)

      assert cast = cast!(schema, data)
      assert cast == %{bla: "11"}

      assert validate(schema, cast) == :ok
    end

    test "from map with atom keys and string property", %{schema: schema} do
      data = %{bla: "foo"}
      assert validate(schema, data) == :ok
      assert cast!(schema, data) == data
    end

    test "from map with atom keys and a castable value", %{schema: schema} do
      data = %{bla: 11}

      assert {:error,
              %ValidationError{
                reason: %{properties: %{bla: %{type: :string, value: 11}}}
              }} = validate(schema, data)

      assert cast = cast!(schema, data)
      assert cast == %{bla: "11"}

      assert validate(schema, cast) == :ok
    end

    test "from a map with unknown atom", %{schema: schema} do
      data = %{"xyz" => "z"}
      msg = ~s|cannot cast "xyz" to :map key, the atom is unknown|

      assert_blame CastError, msg, fn -> cast!(schema, data) end
    end

    test "from a keyword list", %{schema: schema} do
      assert cast!(schema, foo: 77) == %{foo: 77}
    end
  end

  describe "cast!/2 with a map schema, [keys: :strings] and properties" do
    setup do
      %{
        schema: Xema.new({:map, keys: :strings, properties: %{"bla" => :string}})
      }
    end

    test "from map with string keys", %{schema: schema} do
      data = %{"bla" => "foo"}
      assert validate(schema, data) == :ok
      assert cast!(schema, data) == %{"bla" => "foo"}
    end

    test "from map with string keys and castable value", %{schema: schema} do
      data = %{"bla" => 11}

      assert {:error,
              %ValidationError{
                reason: %{properties: %{"bla" => %{type: :string, value: 11}}}
              }} = validate(schema, data)

      assert cast!(schema, data) == %{"bla" => "11"}
    end

    test "from map with atoms keys", %{schema: schema} do
      data = %{bla: "foo", bar: 5}

      assert {:error,
              %ValidationError{
                reason: %{keys: :strings}
              }} = validate(schema, data)

      assert cast!(schema, data) == %{"bla" => "foo", "bar" => 5}
    end

    test "from map with atom keys and castable value", %{schema: schema} do
      data = %{bla: 11}

      assert {:error,
              %ValidationError{
                reason: %{keys: :strings}
              }} = validate(schema, data)

      assert cast!(schema, data) == %{"bla" => "11"}
    end

    test "from a keyword list", %{schema: schema} do
      assert cast!(schema, bla: 11, foo: 7) == %{"bla" => "11", "foo" => 7}
    end
  end

  describe "cast!/2 with a nested map schema" do
    setup do
      %{
        schema:
          Xema.new(
            {:map,
             keys: :atoms,
             properties: %{
               foo:
                 {:map,
                  keys: :atoms,
                  properties: %{
                    num: {:integer, maximum: 12},
                    bar:
                      {:map,
                       keys: :atoms,
                       properties: %{
                         num: {:integer, maximum: 12}
                       }}
                  }}
             }}
          )
      }
    end

    test "from a valid map", %{schema: schema} do
      data = %{"foo" => %{"num" => 2}}
      expected = %{foo: %{num: 2}}

      assert cast!(schema, data) == expected
    end

    test "from a map with unknown key", %{schema: schema} do
      data = %{"foo" => %{"xyz" => 42}}
      msg = ~s|cannot cast "xyz" to :map key at ["foo"], the atom is unknown|

      assert_blame CastError, msg, fn -> cast!(schema, data) end
    end

    test "from a map with unknown key (deeper)", %{schema: schema} do
      data = %{"foo" => %{"bar" => %{"xyz" => 42}}}
      msg = ~s|cannot cast "xyz" to :map key at ["foo", "bar"], the atom is unknown|

      assert_blame CastError, msg, fn -> cast!(schema, data) end
    end

    test "from an invalid map", %{schema: schema} do
      data = %{"foo" => %{"num" => "42"}}

      assert_blame ValidationError,
                   "Value 42 exceeds maximum value of 12, at [:foo, :num].",
                   fn -> cast!(schema, data) end
    end

    test "from a keyword list", %{schema: schema} do
      assert cast!(schema, foo: [num: "5"]) == %{foo: %{num: 5}}
    end
  end

  describe "cast!/2 with an integer property schema" do
    setup do
      %{
        schema: Xema.new(properties: %{num: :integer})
      }
    end

    test "with a valid value", %{schema: schema} do
      assert cast!(schema, %{num: "77"}) == %{num: 77}
    end
  end

  describe "cast/3 with pattern properties" do
    setup do
      %{
        schema:
          Xema.new({
            :map,
            pattern_properties: %{
              ~r/^s_/ => :string,
              ~r/^i_/ => :number
            }
          })
      }
    end

    test "from a map", %{schema: schema} do
      assert cast(schema, %{s_1: 5, i_1: "5"}) == {:ok, %{s_1: "5", i_1: 5}}
    end

    test "from an invalid map", %{schema: schema} do
      assert {:error, error} = cast(schema, %{s_1: 5, i_1: []})

      assert error == %CastError{
               key: nil,
               message: nil,
               path: [:i_1],
               to: :number,
               value: []
             }
    end
  end

  describe "cast/3 with pattern properties and properties" do
    setup do
      %{
        schema:
          Xema.new({
            :map,
            properties: %{
              s_1: :string
            },
            pattern_properties: %{
              ~r/^s_/ => :string,
              ~r/^i_/ => :number
            }
          })
      }
    end

    test "from a map", %{schema: schema} do
      assert cast(schema, %{s_1: 5, i_1: "5"}) == {:ok, %{s_1: "5", i_1: 5}}
    end

    test "from an invalid map", %{schema: schema} do
      assert {:error, error} = cast(schema, %{s_1: 5, i_1: []})

      assert error == %CastError{
               key: nil,
               message: nil,
               path: [:i_1],
               to: :number,
               value: []
             }
    end
  end
end
