defmodule Xema.SchemaError do
  @moduledoc """
  Raised when a schema can't be build.
  """

  alias Xema.SchemaError

  defexception [:message, :reason]

  @impl true
  def exception(reason) when is_binary(reason),
    do: %SchemaError{message: reason, reason: nil}

  def exception(:missing_type = reason),
    do: %SchemaError{message: "Missing type.", reason: reason}

  def exception({:invalid_type, type} = reason),
    do: %SchemaError{message: "Invalid type #{inspect(type)}.", reason: reason}

  def exception({:invalid_types, types} = reason),
    do: %SchemaError{
      message: "Invalid types #{inspect(types)}.",
      reason: reason
    }

  def exception({:ref_not_found, path} = reason),
    do: %SchemaError{
      message: "Ref #{path} not found.",
      reason: reason
    }

  def exception(%{__struct__: SyntaxError} = error), do: error

  def exception(%{__struct__: CompileError} = error), do: error

  def exception(reason),
    do: %SchemaError{
      message: "Can't build schema! Reason:\n#{reason |> inspect() |> Code.format_string!()}",
      reason: reason
    }
end
