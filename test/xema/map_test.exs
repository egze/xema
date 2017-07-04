defmodule Xema.MapTest do

  use ExUnit.Case, async: true

  import Xema, only: [is_valid?: 2, validate: 2]

  alias Xema.Map

  setup do
    %{
      map: Xema.create(:map),
      object: Xema.create(:map, as: :object),
      min: Xema.create(:map, min_properties: 2),
      max: Xema.create(:map, max_properties: 3),
      min_max: Xema.create(:map, min_properties: 2, max_properties: 3),
      props: Xema.create(
        :map,
        properties: %{
          foo: Xema.create(:number),
          bar: Xema.create(:string)
        })
    }
  end

  test "type and keywords", schemas do
    assert schemas.map.type == :map
    assert schemas.map.keywords == %Map{}

    assert schemas.object.type == :map
    assert schemas.object.keywords.as == :object
  end

  describe "validate/2" do
    test "with an empty map", %{map: schema},
      do: assert validate(schema, %{}) == :ok

    test "map with a string", %{map: schema} do
      expected = {:error, :wrong_type, %{type: :map}}
      assert validate(schema, "foo") == expected
    end

    test "object with a string", %{object: schema} do
      expected = {:error, :wrong_type, %{type: :object}}
      assert validate(schema, "foo") == expected
    end

    test "properties with valid values", %{props: schema},
      do: assert validate(schema, %{foo: 2, bar: "bar"}) == :ok

    test "properties with invalid values", %{props: schema} do
      expected = {
        :error,
        :invalid_property,
        %{
          property: :foo,
          error: {:error, :wrong_type, %{type: :number}}
        }
      }
      assert validate(schema, %{foo: "foo", bar: "bar"}) == expected
    end

    test "min_properties with too less properties", %{min: schema} do
      expected = {:error, :too_less_properties, %{min_properties: 2}}
      assert validate(schema, %{a: 1}) == expected
    end

    test "min_properties with propper properties", %{min: schema},
      do: assert validate(schema, %{a: 1, b: 2}) == :ok

    test "max_properties with propper properties", %{max: schema},
      do: assert validate(schema, %{a: 1, b: 2, c: 3}) == :ok

    test "max_properties with too many properties", %{max: schema} do
      expected = {:error, :too_many_properties, %{max_properties: 3}}
      assert validate(schema, %{a: 1, b: 2, c: 3, d: 4}) == expected
    end

    test "min/max_properties with too less properties", %{min_max: schema} do
      expected = {:error, :too_less_properties, %{min_properties: 2}}
      assert validate(schema, %{a: 1}) == expected
    end

    test "min/max_properties propper properties", %{min_max: schema} do
      assert validate(schema, %{a: 1, b: 2}) == :ok
      assert validate(schema, %{a: 1, b: 2, c: 3}) == :ok
    end

    test "min/max_properties with too many properties", %{min_max: schema} do
      expected = {:error, :too_many_properties, %{max_properties: 3}}
      assert validate(schema, %{a: 1, b: 2, c: 3, d: 4}) == expected
    end
  end

  describe "is_valid/2" do
    test "with an empty map", %{map: schema},
      do: assert is_valid?(schema, %{})

    test "map with a string", %{map: schema},
      do: refute is_valid?(schema, "foo")
  end
end
