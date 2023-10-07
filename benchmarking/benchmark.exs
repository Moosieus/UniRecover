defmodule UniRecover.Benchmark.Simple do
  @dialyzer :no_improper_lists

  @doc """
  Replaces illegal sequences by building a new string, sans the bad sequences.
  Naive but does not compute the minimal sequence and is slower.
  """
  def sub(s) when is_binary(s) do
    do_filter(s, <<>>)
  end

  defp do_filter(<<grapheme::utf8, rest::binary>>, acc) do
    do_filter(rest, <<acc::bits, grapheme::utf8>>)
  end

  defp do_filter(<<_, rest::binary>>, acc), do: do_filter(rest, <<acc::bits, "�">>)
  defp do_filter(<<>>, acc), do: acc
end

Benchee.run(
  %{
    "Binary" => &UniRecover.Benchmark.Simple.sub/1,
    "UniRecover" => &UniRecover.sub/1
  },
  inputs: %{
    "207KB JSON Once Invalid" => File.read!("benchmarking/hll_server_list-single_error.json"),
    "200KB Very Often Invalid" => String.duplicate(<<"abc", 233>>, 50_000),
    "200KB Valid ASCII" => String.duplicate("abcd", 50_000),
    "210KB Valid Unicode" => String.duplicate("こんにちは世界", 10_000)
  },
  time: 10,
  memory_time: 2,
  unit_scaling: :smallest
)
