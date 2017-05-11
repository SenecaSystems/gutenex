defmodule Gutenex.PDF.Filter do

  # returns compressed bytes, updated dictionary
  def flate(stream_content, stream_dict) do


    # the original size can be passed as "DL" 
    # in the stream dictionary
    # original_size = byte_size(stream_content)
    
    # deflate the stream contents
    z = :zlib.open()
    :zlib.deflateInit(z)
    zout = :zlib.deflate(z, stream_content)
    compressed = IO.iodata_to_binary(zout)
    :zlib.close(z)

    new_dict = stream_dict
               |> Map.put("Length", byte_size(compressed))
               |> add_filter("FlateDecode")
    {compressed, new_dict}
  end

  # TODO: also need to correctly handle DecodeParams, if any
  defp add_filter(stream_dict, filter_name) do
    existing = Map.get(stream_dict, "Filter")

    # multiple filters are treated as an array
    # filters are added to the head when encoding
    # so decoder can simply iterate over list of filters
    filter_val = case existing do
      nil -> {:name, filter_name}
      {:name, orig} -> {:array, [{:name, filter_name}, {:name, orig}]}
      {:array, list} -> {:array, [{:name, filter_name} | list]}
    end

    stream_dict
    |> Map.put("Filter", filter_val)
  end
end
