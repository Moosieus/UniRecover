defmodule UniRecover.Benchmark.Replace do
  def ii_of_iii(tcp, rep) when tcp >= 32 and tcp <= 863, do: rep
  def ii_of_iii(tcp, rep) when tcp >= 896 and tcp <= 1023, do: rep
  def ii_of_iii(_, rep), do: rep <> rep

  def ii_of_iiii(tcp, rep) when tcp >= 16 and tcp <= 271, do: rep
  def ii_of_iiii(_, rep), do: rep <> rep

  def iii_of__iiii(tcp, rep) when tcp >= 1024 and tcp <= 17407, do: rep
  def iii_of__iiii(_, rep), do: rep <> rep <> rep
end

defmodule UniRecover.Benchmark.Simple do
  @moduledoc """
  The above but with cases for valid-but-truncated code points.
  """

  alias UniRecover.Benchmark.Replace

  def replace_invalid(s) when is_binary(s) do
    do_filter(s, <<>>)
  end

  defp do_filter(<<ascii::8, n_lead::2, n_rest::6, rest::binary>>, acc) when ascii in 0..127 and n_lead != 0b10 do
    do_filter(rest, <<acc::bits, ascii::8, n_lead::2, n_rest::6>>)
  end

  defp do_filter(<<grapheme::utf8, rest::binary>>, acc) do
    do_filter(rest, <<acc::bits, grapheme::utf8>>)
  end

  # 2/3-byte truncated
  defp do_filter(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    do_filter(
      <<n_lead::2, n_rest::6, rest::binary>>,
      <<acc::bits, Replace.ii_of_iii(<<i::4, ii::6>>, "�")>>
    )
  end

  # 2/4-byte truncated
  defp do_filter(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    do_filter(
      <<n_lead::2, n_rest::6, rest::binary>>,
      <<acc::bits, Replace.ii_of_iiii(<<i::4, ii::6>>, "�")>>
    )
  end

  # 3/4-byte truncated
  defp do_filter(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    do_filter(
      <<n_lead::2, n_rest::6, rest::binary>>,
      <<acc::bits, Replace.iii_of__iiii(<<i::3, ii::6, iii::6>>, "�")>>
    )
  end

  defp do_filter(<<_, rest::binary>>, acc), do: do_filter(rest, <<acc::bits, "�">>)
  defp do_filter(<<>>, acc), do: acc
end

defmodule UniRecover.Benchmark.SimpleII do
  @moduledoc """
  Copied from here: https://github.com/Moosieus/UniRecover/pull/1#issuecomment-1751667871
  """

  @dialyzer :no_improper_lists

  def replace_invalid(s) when is_binary(s) do
    IO.iodata_to_binary(sub_valid(s, s))
  end

  defp sub_valid(<<_::utf8, rest::binary>>, original) do
    sub_valid(rest, original)
  end

  defp sub_valid(<<_, rest::binary>>, original) do
    valid = binary_part(original, 0, byte_size(original) - byte_size(rest) - 1)
    [valid | sub_invalid(rest)]
  end

  defp sub_valid(<<>>, original), do: original

  defp sub_invalid(<<_::utf8, rest::binary>> = binary), do: ["�" | sub_valid(rest, binary)]
  defp sub_invalid(<<_, rest::binary>>), do: sub_invalid(rest)
  defp sub_invalid(<<>>), do: "�"
end

defmodule UniRecover.Benchmark.SimpleIII do
  @moduledoc """
  Iteration on the above on to match W3C spec. For details, see notebooks/iterating_on_joses_suggestion.livemd.
  """

  alias UniRecover.Benchmark.Replace

  @dialyzer :no_improper_lists

  def replace_invalid(s) when is_binary(s) do
    IO.iodata_to_binary(sub_valid(s, s))
  end

  defp sub_valid(rest, original, acc \\ [])

  defp sub_valid(<<_::utf8, rest::binary>>, original, acc) do
    sub_valid(rest, original, acc)
  end

  defp sub_valid(<<rest::binary>>, original, acc) do
    valid = binary_part(original, 0, byte_size(original) - byte_size(rest))
    sub_invalid(rest, [acc | valid])
  end

  defp sub_valid(<<>>, original, _), do: original

  defp sub_invalid(<<_::utf8, rest::binary>> = binary, acc), do: sub_valid(rest, binary, acc)

  # 2/3-byte truncated
  defp sub_invalid(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | Replace.ii_of_iii(<<i::4, ii::6>>, "�")])
  end

  # 2/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | Replace.ii_of_iiii(<<i::3, ii::6>>, "�")])
  end

  # 3/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | Replace.iii_of__iiii(<<i::3, ii::6, iii::6>>, "�")])
  end

  defp sub_invalid(<<_, rest::binary>>, acc), do: sub_invalid(rest, [acc | "�"])

  defp sub_invalid(<<>>, acc), do: acc
end

defmodule UniRecover.Benchmark.SimpleIII_BinAcc do
  @moduledoc """
  Iteration on the above where the accumulator's a binary.
  """

  alias UniRecover.Benchmark.Replace

  def replace_invalid(s) when is_binary(s), do: sub_valid(s, s)

  defp sub_valid(rest, original, acc \\ <<>>)

  defp sub_valid(<<_::utf8, rest::binary>>, original, acc) do
    sub_valid(rest, original, acc)
  end

  defp sub_valid(<<rest::binary>>, original, acc) do
    valid = binary_part(original, 0, byte_size(original) - byte_size(rest))
    sub_invalid(rest, <<acc::bits, valid::bits>>)
  end

  defp sub_valid(<<>>, original, _), do: original

  defp sub_invalid(<<_::utf8, rest::binary>> = binary, acc), do: sub_valid(rest, binary, acc)

  # 2/3-byte truncated
  defp sub_invalid(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, Replace.ii_of_iii(<<i::4, ii::6>>, "�")>>)
  end

  # 2/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, Replace.ii_of_iiii(<<i::3, ii::6>>, "�")>>)
  end

  # 3/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, Replace.iii_of__iiii(<<i::3, ii::6, iii::6>>, "�")>>)
  end

  defp sub_invalid(<<_, rest::binary>>, acc), do: sub_invalid(rest, <<acc::bits, "�">>)

  defp sub_invalid(<<>>, acc), do: acc
end

defmodule UniRecover.Benchmark.SimpleIV do
  alias UniRecover.Benchmark.Replace

  def replace_invalid(s) when is_binary(s) do
    IO.iodata_to_binary(sub_valid(s, s))
  end

  defp sub_valid(<<_::utf8, rest::binary>>, original) do
    sub_valid(rest, original)
  end

  defp sub_valid(<<rest::binary>>, original) do
    valid = binary_part(original, 0, byte_size(original) - byte_size(rest))
    [valid | sub_invalid(rest)]
  end

  defp sub_valid(<<>>, original), do: original

  defp sub_invalid(<<_::utf8, rest::binary>> = binary), do: sub_valid(rest, binary)

  # 2/3-byte truncated
  defp sub_invalid(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>) when n_lead != 0b10 do
    [Replace.ii_of_iii(<<i::4, ii::6>>, "�") | sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>)]
  end

  # 2/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>) when n_lead != 0b10 do
    [Replace.ii_of_iiii(<<i::3, ii::6>>, "�") | sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>)]
  end

  # 3/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>) when n_lead != 0b10 do
    [Replace.iii_of__iiii(<<i::3, ii::6, iii::6>>, "�") | sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>)]
  end

  defp sub_invalid(<<_, rest::binary>>), do: ["�" | sub_invalid(rest)]
  defp sub_invalid(<<>>), do: <<>>
end

Benchee.run(
  %{
    "Binary" => &UniRecover.Benchmark.Simple.replace_invalid/1,
    "BinaryII" => &UniRecover.Benchmark.SimpleII.replace_invalid/1,
    "BinaryIII" => &UniRecover.Benchmark.SimpleIII.replace_invalid/1,
    "BinaryIII_BinAcc" => &UniRecover.Benchmark.SimpleIII_BinAcc.replace_invalid/1,
    "BinaryIV" => &UniRecover.Benchmark.SimpleIV.replace_invalid/1,
  },
  inputs: %{
    "207KB JSON Once Invalid" => File.read!("benchmarking/hll_server_list-single_error.json"),
    "200KB Very Often Invalid" => String.duplicate(<<"abc", 233>>, 50_000),
    "200KB Valid ASCII" => String.duplicate("abcd", 50_000),
    "210KB Valid Unicode" => String.duplicate("こんにちは世界", 10_000),
  },
  time: 10,
  memory_time: 2,
  unit_scaling: :smallest
)
