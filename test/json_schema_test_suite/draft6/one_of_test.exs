defmodule JsonSchemaTestSuite.Draft6.OneOfTest do
  use ExUnit.Case

  import Xema, only: [valid?: 2]

  describe ~s|oneOf| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [%{"type" => "integer"}, %{"minimum" => 2}]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|first oneOf valid|, %{schema: schema} do
      assert valid?(schema, 1)
    end

    test ~s|second oneOf valid|, %{schema: schema} do
      assert valid?(schema, 2.5)
    end

    test ~s|both oneOf valid|, %{schema: schema} do
      refute valid?(schema, 3)
    end

    test ~s|neither oneOf valid|, %{schema: schema} do
      refute valid?(schema, 1.5)
    end
  end

  describe ~s|oneOf with base schema| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [%{"minLength" => 2}, %{"maxLength" => 4}], "type" => "string"},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|mismatch base schema|, %{schema: schema} do
      refute valid?(schema, 3)
    end

    test ~s|one oneOf valid|, %{schema: schema} do
      assert valid?(schema, "foobar")
    end

    test ~s|both oneOf valid|, %{schema: schema} do
      refute valid?(schema, "foo")
    end
  end

  describe ~s|oneOf with boolean schemas, all true| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [true, true, true]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|any value is invalid|, %{schema: schema} do
      refute valid?(schema, "foo")
    end
  end

  describe ~s|oneOf with boolean schemas, one true| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [true, false, false]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|any value is valid|, %{schema: schema} do
      assert valid?(schema, "foo")
    end
  end

  describe ~s|oneOf with boolean schemas, more than one true| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [true, true, false]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|any value is invalid|, %{schema: schema} do
      refute valid?(schema, "foo")
    end
  end

  describe ~s|oneOf with boolean schemas, all false| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [false, false, false]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|any value is invalid|, %{schema: schema} do
      refute valid?(schema, "foo")
    end
  end

  describe ~s|oneOf complex types| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{
              "oneOf" => [
                %{"properties" => %{"bar" => %{"type" => "integer"}}, "required" => ["bar"]},
                %{"properties" => %{"foo" => %{"type" => "string"}}, "required" => ["foo"]}
              ]
            },
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|first oneOf valid (complex)|, %{schema: schema} do
      assert valid?(schema, %{"bar" => 2})
    end

    test ~s|second oneOf valid (complex)|, %{schema: schema} do
      assert valid?(schema, %{"foo" => "baz"})
    end

    test ~s|both oneOf valid (complex)|, %{schema: schema} do
      refute valid?(schema, %{"bar" => 2, "foo" => "baz"})
    end

    test ~s|neither oneOf valid (complex)|, %{schema: schema} do
      refute valid?(schema, %{"bar" => "quux", "foo" => 2})
    end
  end

  describe ~s|oneOf with empty schema| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [%{"type" => "number"}, %{}]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|one valid - valid|, %{schema: schema} do
      assert valid?(schema, "foo")
    end

    test ~s|both valid - invalid|, %{schema: schema} do
      refute valid?(schema, 123)
    end
  end

  describe ~s|oneOf with required| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{
              "oneOf" => [%{"required" => ["foo", "bar"]}, %{"required" => ["foo", "baz"]}],
              "type" => "object"
            },
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|both invalid - invalid|, %{schema: schema} do
      refute valid?(schema, %{"bar" => 2})
    end

    test ~s|first valid - valid|, %{schema: schema} do
      assert valid?(schema, %{"bar" => 2, "foo" => 1})
    end

    test ~s|second valid - valid|, %{schema: schema} do
      assert valid?(schema, %{"baz" => 3, "foo" => 1})
    end

    test ~s|both valid - invalid|, %{schema: schema} do
      refute valid?(schema, %{"bar" => 2, "baz" => 3, "foo" => 1})
    end
  end

  describe ~s|oneOf with missing optional property| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{
              "oneOf" => [
                %{"properties" => %{"bar" => true, "baz" => true}, "required" => ["bar"]},
                %{"properties" => %{"foo" => true}, "required" => ["foo"]}
              ]
            },
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|first oneOf valid|, %{schema: schema} do
      assert valid?(schema, %{"bar" => 8})
    end

    test ~s|second oneOf valid|, %{schema: schema} do
      assert valid?(schema, %{"foo" => "foo"})
    end

    test ~s|both oneOf valid|, %{schema: schema} do
      refute valid?(schema, %{"bar" => 8, "foo" => "foo"})
    end

    test ~s|neither oneOf valid|, %{schema: schema} do
      refute valid?(schema, %{"baz" => "quux"})
    end
  end

  describe ~s|nested oneOf, to check validation semantics| do
    setup do
      %{
        schema:
          Xema.from_json_schema(
            %{"oneOf" => [%{"oneOf" => [%{"type" => "null"}]}]},
            draft: "draft6",
            atom: :force
          )
      }
    end

    test ~s|null is valid|, %{schema: schema} do
      assert valid?(schema, nil)
    end

    test ~s|anything non-null is invalid|, %{schema: schema} do
      refute valid?(schema, 123)
    end
  end
end
