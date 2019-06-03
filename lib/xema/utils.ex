defmodule Xema.Utils do
  @moduledoc """
  Some utilities for Xema.
  """

  @doc """
  Converts the given `string` to an existing atom. Returns `nil` if the
  atom does not exist.

  ## Examples

        iex> import Xema.Utils
        iex> to_existing_atom(:my_atom)
        :my_atom
        iex> to_existing_atom("my_atom")
        :my_atom
        iex> to_existing_atom("not_existing_atom")
        nil
  """
  @spec to_existing_atom(String.t() | atom) :: atom | nil
  def to_existing_atom(atom) when is_atom(atom), do: atom

  def to_existing_atom(string) when is_binary(string) do
    String.to_existing_atom(string)
  rescue
    _ -> nil
  end

  @doc """
  Returns whether the given `key` exists in the given `value`.

  Returns true if
  * `value` is a map and contains `key` as a key.
  * `value` is a keyword and contains `key` as a key.
  * `value` is a list of tuples with `key`as the first element.

  ## Example

        iex> alias Xema.Utils
        iex> Utils.has_key?(%{foo: 5}, :foo)
        true
        iex> Utils.has_key?([foo: 5], :foo)
        true
        iex> Utils.has_key?([{"foo", 5}], "foo")
        true
  """
  @spec has_key?(map | keyword | [{String.t(), any}], any) :: boolean
  def has_key?([], _), do: false

  def has_key?(value, key) when is_map(value), do: Map.has_key?(value, key)

  def has_key?(value, key) when is_list(value) do
    case Keyword.keyword?(value) do
      true -> Keyword.has_key?(value, key)
      false -> Enum.any?(value, fn {k, _} -> k == key end)
    end
  end

  @doc """
  Returns `nil` if `uri_1` and `uri_2` are `nil`.
  Parses a URI when the other URI is `nil`.
  Merges URIs if both are not nil.
  """
  @spec update_uri(URI.t() | String.t() | nil, URI.t() | String.t() | nil) ::
          URI.t() | nil
  def update_uri(nil, nil), do: nil

  def update_uri(uri_1, nil), do: URI.parse(uri_1)

  def update_uri(nil, uri_2), do: URI.parse(uri_2)

  def update_uri(uri_1, uri_2), do: URI.merge(uri_1, uri_2)

  @doc """
  Returns the size of a `list` or `tuple`.
  """
  @spec size(list | tuple) :: integer
  def size(list) when is_list(list), do: length(list)

  def size(tuple) when is_tuple(tuple), do: tuple_size(tuple)
end
