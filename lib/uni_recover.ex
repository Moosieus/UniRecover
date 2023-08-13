defmodule UniRecover do
  @moduledoc """
  See `UniRecover.sub/3` for documentation.
  """

  @doc """
  Substitutes all illegal sequences in the provided data with the Unicode [replacement character](https://en.wikipedia.org/wiki/Specials_(Unicode_block)#Replacement_character).
  """
  @spec sub(binary, (:utf8 | :utf16 | :utf16be | :utf16le | :utf32 | :utf32be | :utf32le), String.t) :: binary
  def sub(bytes, encoding \\ :utf8, replacement \\ "�")

  def sub(bytes, :utf8, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF8.sub(bytes, rep)
  end

  def sub(bytes, :utf16, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF16.sub(bytes, :be, rep)
  end

  def sub(bytes, :utf16be, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF16.sub(bytes, :be, rep)
  end

  def sub(bytes, :utf16le, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF16.sub(bytes, :le, rep)
  end

  def sub(bytes, :utf32, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF16.sub(bytes, :be, rep)
  end

  def sub(bytes, :utf32be, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF16.sub(bytes, :be, rep)
  end

  def sub(bytes, :utf32le, rep) when is_binary(bytes) and is_binary(rep) do
    UniRecover.UTF16.sub(bytes, :le, rep)
  end
end
