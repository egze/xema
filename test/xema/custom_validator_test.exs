defmodule Xema.CustomValidatorTest do
  use ExUnit.Case, async: true

  defmodule Palindrome do
    def validate(str) do
      case str == String.reverse(str) do
        true -> :ok
        false -> {:error, :no_palindrome}
      end
    end
  end

  defmodule Schemas do
    alias Xema
    import Xema.Builder

    xema :strings,
         map(
           properties: %{
             short: string(max_length: 3),
             long: string(min_length: 5),
             palindrome: string(validator: {Palindrome, :validate})
           }
         )

    xema :timespan,
         map(
           properties: %{
             from: strux(NaiveDateTime),
             to: strux(NaiveDateTime)
           },
           validator: &Schemas.timespan_validator/1
         )

    def timespan_validator(%{from: from, to: to}) do
      case NaiveDateTime.diff(from, to) < 0 do
        true -> :ok
        false -> {:error, :to_before_form}
      end
    end
  end

  describe "strings schema" do
    test "with valid data" do
      assert Schemas.valid?(:strings, %{
               short: "foo",
               long: "foobar",
               palindrome: "rats live on no evil star"
             })
    end

    test "with invalid data" do
      assert Schemas.validate(:strings, %{
               short: "foobar",
               long: "foo",
               palindrome: "cats live on no evil star"
             }) ==
               {:error,
                %{
                  properties: %{
                    long: %{min_length: 5, value: "foo"},
                    palindrome: %{
                      validator: :no_palindrome,
                      value: "cats live on no evil star"
                    },
                    short: %{max_length: 3, value: "foobar"}
                  }
                }}
    end
  end

  describe "timespan schema" do
    test "with valid data" do
      from = ~N[2019-01-03 12:05:42]
      to = ~N[2019-03-03 12:05:42]

      assert Schemas.validate(:timespan, %{from: from, to: to}) == :ok
    end

    test "with to before from" do
      from = ~N[2019-01-03 12:05:42]
      to = ~N[2019-01-01 12:05:42]

      assert Schemas.validate(:timespan, %{from: from, to: to}) ==
               {:error,
                %{
                  validator: :to_before_form,
                  value: %{
                    from: ~N[2019-01-03 12:05:42],
                    to: ~N[2019-01-01 12:05:42]
                  }
                }}
    end

    test "with invalid data" do
      from = ~N[2019-03-03 12:05:42.328849]
      {:ok, to, 0} = DateTime.from_iso8601("2015-01-23T23:50:07Z")

      assert Schemas.validate(:timespan, %{from: from, to: to}) ==
               {:error, %{properties: %{to: %{value: to, module: NaiveDateTime}}}}
    end
  end
end
