o = <<"foo"::utf16>> <> <<0xD800::16>> <> <<"bar"::utf16>>

i = binary_slice(o, -14..-9)
#   binary_slice(o, -8..-7)
ii = binary_slice(o, -6..-1)

[i, ii]  |> :unicode.characters_to_binary(:utf16) |> IO.inspect
