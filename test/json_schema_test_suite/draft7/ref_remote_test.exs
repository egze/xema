defmodule JsonSchemaTestSuite.Draft7.RefRemote do
  use ExUnit.Case

  import Xema, only: [valid?: 2]

  describe "remote ref" do
    setup do
      %{schema: Xema.from_json_schema(%{"$ref" => "http://localhost:1234/integer.json"})}
    end

    test "remote ref valid", %{schema: schema} do
      assert valid?(schema, 1)
    end

    test "remote ref invalid", %{schema: schema} do
      refute valid?(schema, "a")
    end
  end

  describe "fragment within remote ref" do
    setup do
      %{
        schema:
          Xema.from_json_schema(%{"$ref" => "http://localhost:1234/subSchemas.json#/integer"})
      }
    end

    test "remote fragment valid", %{schema: schema} do
      assert valid?(schema, 1)
    end

    test "remote fragment invalid", %{schema: schema} do
      refute valid?(schema, "a")
    end
  end

  describe "ref within remote ref" do
    setup do
      %{
        schema:
          Xema.from_json_schema(%{"$ref" => "http://localhost:1234/subSchemas.json#/refToInteger"})
      }
    end

    test "ref within ref valid", %{schema: schema} do
      assert valid?(schema, 1)
    end

    test "ref within ref invalid", %{schema: schema} do
      refute valid?(schema, "a")
    end
  end

  describe "base URI change" do
    setup do
      %{
        schema:
          Xema.from_json_schema(%{
            "$id" => "http://localhost:1234/",
            "items" => %{"$id" => "folder/", "items" => %{"$ref" => "folderInteger.json"}}
          })
      }
    end

    test "base URI change ref valid", %{schema: schema} do
      assert valid?(schema, [[1]])
    end

    test "base URI change ref invalid", %{schema: schema} do
      refute valid?(schema, [["a"]])
    end
  end

  describe "base URI change - change folder" do
    setup do
      %{
        schema:
          Xema.from_json_schema(%{
            "$id" => "http://localhost:1234/scope_change_defs1.json",
            "definitions" => %{
              "baz" => %{
                "$id" => "folder/",
                "items" => %{"$ref" => "folderInteger.json"},
                "type" => "array"
              }
            },
            "properties" => %{"list" => %{"$ref" => "#/definitions/baz"}},
            "type" => "object"
          })
      }
    end

    test "number is valid", %{schema: schema} do
      assert valid?(schema, %{"list" => [1]})
    end

    test "string is invalid", %{schema: schema} do
      refute valid?(schema, %{"list" => ["a"]})
    end
  end

  describe "base URI change - change folder in subschema" do
    setup do
      %{
        schema:
          Xema.from_json_schema(%{
            "$id" => "http://localhost:1234/scope_change_defs2.json",
            "definitions" => %{
              "baz" => %{
                "$id" => "folder/",
                "definitions" => %{
                  "bar" => %{"items" => %{"$ref" => "folderInteger.json"}, "type" => "array"}
                }
              }
            },
            "properties" => %{"list" => %{"$ref" => "#/definitions/baz/definitions/bar"}},
            "type" => "object"
          })
      }
    end

    test "number is valid", %{schema: schema} do
      assert valid?(schema, %{"list" => [1]})
    end

    test "string is invalid", %{schema: schema} do
      refute valid?(schema, %{"list" => ["a"]})
    end
  end

  describe "root ref in remote ref" do
    setup do
      %{
        schema:
          Xema.from_json_schema(%{
            "$id" => "http://localhost:1234/object",
            "properties" => %{"name" => %{"$ref" => "name.json#/definitions/orNull"}},
            "type" => "object"
          })
      }
    end

    test "string is valid", %{schema: schema} do
      assert valid?(schema, %{"name" => "foo"})
    end

    test "null is valid", %{schema: schema} do
      assert valid?(schema, %{"name" => nil})
    end

    test "object is invalid", %{schema: schema} do
      refute valid?(schema, %{"name" => %{"name" => nil}})
    end
  end
end
