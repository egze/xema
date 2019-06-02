defmodule Xema.AnyOfTest do
  use ExUnit.Case, async: true

  import Xema, only: [validate: 2, valid?: 2]

  alias Xema.ValidationError

  describe "keyword any_of:" do
    setup do
      %{
        schema:
          Xema.new({
            :any,
            any_of: [nil, {:integer, minimum: 1}]
          })
      }
    end

    test "type", %{schema: schema} do
      assert schema.schema.type == :any
    end

    test "validate/2 with a valid value", %{schema: schema} do
      assert validate(schema, 1) == :ok
      assert validate(schema, nil) == :ok
    end

    test "validate/2 with an invalid value", %{schema: schema} do
      assert {:error,
              %ValidationError{
                reason: %{
                  any_of: [
                    %{type: nil, value: "foo"},
                    %{type: :integer, value: "foo"}
                  ],
                  value: "foo"
                }
              } = error} = validate(schema, "foo")

      message = """
      No match of any schema.
        Expected nil, got "foo".
        Expected :integer, got "foo".\
      """

      assert Exception.message(error) == message
    end
  end

  describe "keyword any_of (shortcut):" do
    setup do
      %{
        schema: Xema.new(any_of: [nil, {:integer, minimum: 1}])
      }
    end

    test "equal long version", %{schema: schema} do
      assert schema ==
               Xema.new({
                 :any,
                 any_of: [nil, {:integer, minimum: 1}]
               })
    end
  end

  describe "keyword any_of with properties and items" do
    setup do
      %{
        schema:
          Xema.new(
            any_of: [
              {:map, properties: %{foo: :integer}},
              {:list, items: :integer}
            ]
          )
      }
    end

    test "validate/2 with invalid string value", %{schema: schema} do
      assert {:error,
              %Xema.ValidationError{
                reason: %{
                  any_of: [
                    %{type: :map, value: "foo"},
                    %{type: :list, value: "foo"}
                  ],
                  value: "foo"
                }
              } = error} = validate(schema, "foo")

      message = """
      No match of any schema.
        Expected :map, got "foo".
        Expected :list, got "foo".\
      """

      assert Exception.message(error) == message
    end

    test "validate/2 with invalid list value", %{schema: schema} do
      assert {:error,
              %ValidationError{
                reason: %{
                  any_of: [
                    %{type: :map, value: ["foo"]},
                    %{items: [{0, %{type: :integer, value: "foo"}}]}
                  ],
                  value: ["foo"]
                }
              } = error} = validate(schema, ["foo"])

      message = """
      No match of any schema.
        Expected :map, got ["foo"].
        Expected :integer, got "foo", at [0].\
      """

      assert Exception.message(error) == message
    end

    test "validate/2 with invalid property value", %{schema: schema} do
      assert {:error,
              %Xema.ValidationError{
                reason: %{
                  any_of: [
                    %{properties: %{foo: %{type: :integer, value: "foo"}}},
                    %{type: :list, value: %{foo: "foo"}}
                  ],
                  value: %{foo: "foo"}
                }
              } = error} = validate(schema, %{foo: "foo"})

      message = """
      No match of any schema.
        Expected :integer, got "foo", at [:foo].
        Expected :list, got %{foo: "foo"}.\
      """

      assert Exception.message(error) == message
    end
  end

  describe "keyword any_of with properties and items in a map schema" do
    setup do
      %{
        schema:
          Xema.new(
            {:map,
             properties: %{
               foo: [
                 any_of: [
                   {:map, properties: %{bar: :integer}},
                   {:list, items: :integer}
                 ]
               ]
             }}
          )
      }
    end

    test "validate/2 with invalid property value", %{schema: schema} do
      assert {:error,
              %Xema.ValidationError{
                reason: %{
                  properties: %{
                    foo: %{
                      any_of: [
                        %{properties: %{bar: %{type: :integer, value: "foo"}}},
                        %{type: :list, value: %{bar: "foo"}}
                      ],
                      value: %{bar: "foo"}
                    }
                  }
                }
              } = error} = validate(schema, %{foo: %{bar: "foo"}})

      message = """
      No match of any schema, at [:foo].
        Expected :integer, got "foo", at [:foo, :bar].
        Expected :list, got %{bar: "foo"}, at [:foo].\
      """

      assert Exception.message(error) == message
    end
  end

  describe "nesetd any schema" do
    setup do
      %{
        schema:
          Xema.new(
            any_of: [
              [any_of: [:integer, :float]],
              [any_of: [:list, :map]]
            ]
          )
      }
    end

    test "validate/2 with an valid integer", %{schema: schema} do
      assert validate(schema, 5) == :ok
    end

    test "validate/2 with a valid list", %{schema: schema} do
      assert validate(schema, [5]) == :ok
    end

    test "validate/2 with an invalid string", %{schema: schema} do
      assert {:error,
              %Xema.ValidationError{
                reason: %{
                  any_of: [
                    %{
                      any_of: [
                        %{type: :integer, value: "foo"},
                        %{type: :float, value: "foo"}
                      ],
                      value: "foo"
                    },
                    %{
                      any_of: [
                        %{type: :list, value: "foo"},
                        %{type: :map, value: "foo"}
                      ],
                      value: "foo"
                    }
                  ],
                  value: "foo"
                }
              } = error} = validate(schema, "foo")

      message = """
      No match of any schema.
        No match of any schema.
          Expected :integer, got "foo".
          Expected :float, got "foo".
        No match of any schema.
          Expected :list, got "foo".
          Expected :map, got "foo".\
      """

      assert Exception.message(error) == message
    end
  end

  describe "keyword any_of with with multiple types" do
    setup do
      %{
        schema: Xema.new(any_of: [:integer, :string, nil])
      }
    end

    test "validate", %{schema: schema} do
      assert valid?(schema, 5)
      assert valid?(schema, "five")
      assert valid?(schema, nil)
      refute valid?(schema, [6])
    end
  end
end
