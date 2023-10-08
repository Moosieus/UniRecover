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

defmodule UniRecover.Benchmark.Simple_Trunc do
  @moduledoc """
  The above but with cases for valid-but-truncated code points.
  """

  def sub(s) when is_binary(s) do
    do_filter(s, <<>>)
  end

  defp do_filter(<<grapheme::utf8, rest::binary>>, acc) do
    do_filter(rest, <<acc::bits, grapheme::utf8>>)
  end

  # 2/3-byte truncated
  defp do_filter(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    # tcp = truncated code point, must be valid for 3-bytes
    <<tcp::10>> = <<i::4, ii::6>>

    cond do
      tcp >= 32 && tcp <= 863 ->
        # valid truncated code point -> replace with 1x U+UFFD
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      tcp >= 896 && tcp <= 1023 ->
        # valid truncated code point -> replace with 1x U+UFFD
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      true ->
        # invalid truncated code point -> replace with 2x U+UFFD
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "��">>)
    end
  end

  # 2/4-byte truncated
  defp do_filter(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    <<tcp::9>> = <<i::3, ii::6>>

    case tcp >= 16 && tcp <= 271 do
      true ->
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      false ->
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "��">>)
    end
  end

  # 3/4-byte truncated
  defp do_filter(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    <<tcp::15>> = <<i::3, ii::6, iii::6>>

    case tcp >= 1024 && tcp <= 17407 do
      true ->
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      false ->
        do_filter(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "���">>)
    end
  end

  defp do_filter(<<_, rest::binary>>, acc), do: do_filter(rest, <<acc::bits, "�">>)
  defp do_filter(<<>>, acc), do: acc
end

defmodule UniRecover.Benchmark.SimpleII do
  @moduledoc """
  Copied from here: https://github.com/Moosieus/UniRecover/pull/1#issuecomment-1751667871
  """

  @dialyzer :no_improper_lists

  def sub(s) when is_binary(s) do
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

  @dialyzer :no_improper_lists

  def sub(s) when is_binary(s) do
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
    # tcp = truncated code point, must be valid for 3-bytes
    <<tcp::10>> = <<i::4, ii::6>>

    cond do
      tcp >= 32 && tcp <= 863 ->
        # valid truncated code point -> replace with 1x U+UFFD
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "�"])

      tcp >= 896 && tcp <= 1023 ->
        # valid truncated code point -> replace with 1x U+UFFD
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "�"])

      false ->
        # invalid truncated code point -> replace with 2x U+UFFD
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "��"])
    end
  end

  # 2/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    <<tcp::9>> = <<i::3, ii::6>>

    case tcp >= 16 && tcp <= 271 do
      true ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "�"])

      false ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "��"])
    end
  end

  # 3/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    <<tcp::15>> = <<i::3, ii::6, iii::6>>

    case tcp >= 1024 && tcp <= 17407 do
      true ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "�"])

      false ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, [acc | "���"])
    end
  end

  defp sub_invalid(<<_, rest::binary>>, acc), do: sub_invalid(rest, [acc | "�"])

  defp sub_invalid(<<>>, acc), do: acc
end

defmodule UniRecover.Benchmark.SimpleIII_BinAcc do
  @moduledoc """
  Iteration on the above where the accumulator's a binary.
  """

  def sub(s) when is_binary(s), do: sub_valid(s, s)

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
    # tcp = truncated code point, must be valid for 3-bytes
    <<tcp::10>> = <<i::4, ii::6>>

    cond do
      tcp >= 32 && tcp <= 863 ->
        # valid truncated code point -> replace with 1x U+UFFD
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      tcp >= 896 && tcp <= 1023 ->
        # valid truncated code point -> replace with 1x U+UFFD
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      true ->
        # invalid truncated code point -> replace with 2x U+UFFD
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "��">>)
    end
  end

  # 2/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    <<tcp::9>> = <<i::3, ii::6>>

    case tcp >= 16 && tcp <= 271 do
      true ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      false ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "��">>)
    end
  end

  # 3/4-byte truncated
  defp sub_invalid(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::binary>>, acc) when n_lead != 0b10 do
    <<tcp::15>> = <<i::3, ii::6, iii::6>>

    case tcp >= 1024 && tcp <= 17407 do
      true ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "�">>)

      false ->
        sub_invalid(<<n_lead::2, n_rest::6, rest::binary>>, <<acc::bits, "���">>)
    end
  end

  defp sub_invalid(<<_, rest::binary>>, acc), do: sub_invalid(rest, <<acc::bits, "�">>)

  defp sub_invalid(<<>>, acc), do: acc
end

Benchee.run(
  %{
    "Binary" => &UniRecover.Benchmark.Simple.sub/1,
    "BinaryWithTrunc" => &UniRecover.Benchmark.Simple_Trunc.sub/1,
    "BinaryII" => &UniRecover.Benchmark.SimpleII.sub/1,
    "BinaryIII" => &UniRecover.Benchmark.SimpleIII.sub/1,
    "BinaryIII_BinAcc" => &UniRecover.Benchmark.SimpleIII_BinAcc.sub/1,
    "UniRecover" => &UniRecover.sub/1,
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
