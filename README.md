# UniRecover
A library for substituting illegal bytes in Unicode encoded data, following W3C spec as suggested by the [Unicode Standard](https://www.unicode.org/versions/Unicode15.0.0/UnicodeStandard-15.0.pdf#page=153).

This library leverages Erlang [Sub Binaries](https://www.erlang.org/doc/efficiency_guide/binaryhandling#sub-binaries) to scale well with large amounts of data. This should suffice for most use-cases, short of those that may necessitate NIF-based solutions.

## Installation
Add `:uni_recover` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:uni_recover, "~> 0.1.0"}
  ]
end
```

Documentation is available on [HexDocs](https://hexdocs.pm/uni_recover/readme.html) and may also be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

## Usage
```elixir
# 0b11111111 = an illegal utf-8 code sequence
UniRecover.sub(<<"foo", 0b11111111, "bar">>)
# "foo�bar"

# 216, 0 = an illegal utf-16 code sequence
(UniRecover.sub(<<"foo"::utf16, 216, 0, "bar"::utf16>>, :utf16)
|> :unicode.characters_to_binary(:utf16))
# "foo�bar"
```
