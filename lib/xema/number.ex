defmodule Xema.Number do
  @moduledoc """
  TODO
  """

  alias Xema.Helper

  @behaviour Xema

  defstruct minimum: nil,
            maximum: nil,
            exclusive_maximum: nil,
            exclusive_minimum: nil,
            multiple_of: nil

  @spec properties(list) :: nil
  def properties(properties), do: struct(%Xema.Number{}, properties)

  @spec is_valid?(nil, any) :: boolean
  def is_valid?(properties, number), do: validate(properties, number) == :ok

  @spec validate(nil, any) :: :ok | {:error, any}
  def validate(properties, number) do
    with :ok <- type?(number),
         :ok <- minimum?(properties, number),
         :ok <- maximum?(properties, number),
         :ok <- multiple_of?(properties, number),
      do: :ok
  end

  defp type?(number)
    when is_integer(number) or is_float(number),
    do: :ok
  defp type?(_number), do: {:error, %{type: :number}}

  defp minimum?(%Xema.Number{minimum: nil}, _number), do: :ok
  defp minimum?(
    %Xema.Number{minimum: minimum, exclusive_minimum: exclusive_minimum},
    number
  ), do: Helper.Number.minimum?(minimum, exclusive_minimum, number)

  defp maximum?(%Xema.Number{maximum: nil}, _number), do: :ok
  defp maximum?(
    %Xema.Number{maximum: maximum, exclusive_maximum: exclusive_maximum},
    number
  ), do: Helper.Number.maximum?(maximum, exclusive_maximum, number)

  defp multiple_of?(%Xema.Number{multiple_of: nil}, number), do: :ok
  defp multiple_of?(%Xema.Number{multiple_of: multiple_of}, number),
    do: Helper.Number.multiple_of?(multiple_of, number)
end
