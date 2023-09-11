twohundred_kilobyte_example = File.read!("benchmarking/hll_server_list-single_error.json")

defmodule UniRecover.Benchmark.Naive do

  @doc """
  Idiomatic solution utilizing the standard library.
  """
  def sub(s) when is_binary(s) do
    s
    |> String.graphemes()
    |> Enum.filter(&String.valid?/1)
    |> IO.iodata_to_binary()
  end
end

defmodule UniRecover.Benchmark.Simple do
  @dialyzer(:no_improper_lists)

  @doc """
  Replaces illegal sequences by building a new string, sans the bad sequences.
  This solution works better but still uses an outsized amount of memory and
  compute relative to its input.
  """
  def sub(s) when is_binary(s) do
    do_filter(s)
  end

  defp do_filter(bin, acc \\ [])

  defp do_filter(<<grapheme::utf8, rest::binary>>, acc) do
    do_filter(rest, [acc | <<grapheme::utf8>>])
  end

  defp do_filter(<<_::binary-size(1), rest::binary>>, acc), do: do_filter(rest, [acc | "�"])

  defp do_filter(<<>>, acc), do: IO.iodata_to_binary(acc)
end

IO.inspect(byte_size(twohundred_kilobyte_example), label: "Exact size of input")

Benchee.run(
  %{
    "Naive 3-liner, 207KB Input" => fn -> UniRecover.Benchmark.Naive.sub(twohundred_kilobyte_example) end,
    "Simple Rebuild, 207KB Input" => fn -> UniRecover.Benchmark.Simple.sub(twohundred_kilobyte_example) end,
    "UniRecover, 207KB Input" => fn -> UniRecover.sub(twohundred_kilobyte_example) end,
  },
  time: 10,
  memory_time: 2,
  unit_scaling: :smallest
)
