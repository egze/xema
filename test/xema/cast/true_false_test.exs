defmodule Xema.Cast.TrueFalseTest do
  use ExUnit.Case, async: true

  import Xema, only: [cast: 2, cast!: 2]

  alias Xema.ValidationError

  @set [:atom, "str", 1.1, 1, [], %{}, {:tuple}]

  describe "true schema" do
    setup do
      %{
        schema: Xema.new(true)
      }
    end

    test "cast/2", %{schema: schema} do
      Enum.each(@set, fn data ->
        assert cast(schema, data) == {:ok, data}
      end)
    end

    test "cast/2 with an invalid type", %{schema: schema} do
      assert_raise Protocol.UndefinedError, fn -> cast(schema, ~r/.*/) end
    end

    test "cast!/2", %{schema: schema} do
      Enum.each(@set, fn data ->
        assert cast!(schema, data) == data
      end)
    end

    test "cast!/2 with an invalid type", %{schema: schema} do
      assert_raise Protocol.UndefinedError, fn ->
        cast!(schema, ~r/.*/)
      end
    end
  end

  describe "false schema" do
    setup do
      %{
        schema: Xema.new(false)
      }
    end

    test "cast/2", %{schema: schema} do
      Enum.each(@set, fn data ->
        assert cast(schema, data) ==
                 {:error,
                  %ValidationError{
                    reason: %{type: false}
                  }}
      end)
    end

    test "cast/2 with an invalid type", %{schema: schema} do
      assert_raise Protocol.UndefinedError, fn -> cast(schema, ~r/.*/) end
    end

    test "cast!/2", %{schema: schema} do
      Enum.each(@set, fn data ->
        assert_raise ValidationError, fn ->
          cast!(schema, data) == data
        end
      end)
    end

    test "cast!/2 with an invalid type", %{schema: schema} do
      assert_raise Protocol.UndefinedError, fn ->
        cast!(schema, ~r/.*/)
      end
    end
  end
end
