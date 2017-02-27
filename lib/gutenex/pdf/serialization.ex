defmodule Gutenex.PDF.Serialization do
  @moduledoc """
  Need to serialize elixir into PDF format? You came to the right place!

  ```
    defmodule Walrus do
      import Gutenex.PDF.Serialization

      def to_pdf(attributes) do
        serialize({:dict, Dict.to_list(attributes)})
      end
    end
  ```
  """
  def serialize(nil) do
    " null "
  end

  def serialize(true) do
    " true "
  end

  def serialize(false) do
    " false "
  end

  def serialize(float) when is_float(float) do
    #Float.to_string(float, [decimals: 2])
    :erlang.float_to_binary(float, [decimals: 2])
  end

  def serialize(integer) when is_integer(integer) do
    Integer.to_string(integer)
  end

  def serialize({:string, str}) do
    " (#{str}) "
  end

  def serialize({:hexstring, str}) do
    " <#{Base.encode16 str}> "
  end

  def serialize({:name, name}) do
    " /#{name} "
  end

  def serialize({:ptr, object_number, generation_number}) do
    " #{object_number} #{generation_number} R "
  end

  def serialize({:date, {{year, month, day}, {hours, minutes, seconds}}}) do
    formatted_date_string =
      Enum.map([month, day, hours, minutes, seconds], &format_date_part(&1)) |>
      Enum.join()

    " (D:#{year}" <> formatted_date_string <> ") "
  end

  def serialize({:date, {_year, _month, _day} = date}) do
    serialize({:date, {date, {0, 0, 0}}})
  end

  def serialize({{:obj, object_number, generation_number}, object}) do
    """
    #{serialize object_number} #{serialize generation_number} obj
    #{serialize object}
    endobj
    """
  end

  def serialize({:array, elements}) when is_list(elements) do
    inner = Enum.map(elements, &serialize/1)
    |> Enum.join(" ")
    " [" <> inner <> "] "
  end

  def serialize({:rect, elements}) do
    inner = Enum.map(elements, &serialize/1)
    |> Enum.join(" ")
    " [" <> inner <> "] "
  end

  def serialize({:dict, map}) when is_map(map) do
    "<< #{serialize_dictionary_pairs(map)} >>"
  end

  def serialize({:stream, {:dict, options}, payload}) when is_binary(payload) do
    {options, payload} = prepare_stream(options, payload)
    serialize({:dict, options}) <> "\n" <>
    Enum.join(["stream", payload, "endstream"], "\n")
  end

  def serialize({:stream, payload}) when is_binary(payload) do
    serialize({:stream, {:dict, %{}}, payload})
  end

  def serialize({:trailer, {:dict, _dict}=trailer}) do
    "trailer\n#{serialize(trailer)}\n"
  end


  def serialize(untyped) when is_binary(untyped) do
    serialize({:string, untyped})
  end

  # Takes in the options and payload:
  #   - Encodes the payload if it knows how (it currently knows nothing)
  #   - Adds the "Length" key to the options
  # Returns the {modified_options, encoded_payload}
  # TODO: Implement filters defined on page PDF 42 of
  # http://partners.adobe.com/public/developer/en/pdf/PDFReference.pdf
  defp prepare_stream(options, payload) do
    options = Map.put(options, "Length", byte_size(payload))
    {options, payload}
  end

  def serialize_dictionary_pairs(map) do
    Enum.reject(map, fn ({_key, value}) -> value == nil end)
    |> Enum.map(&serialize_dictionary_pair/1)
    |> Enum.join()
  end

  def serialize_dictionary_pair({key, value}) do
    serialized_key = String.strip(serialize({:name, key}))
    serialized_value = String.strip(serialize(value))
    serialized_key <> " " <> serialized_value
  end

  defp format_date_part(integer) do
    if integer >= 10 do
      to_string integer
    else
      "0#{to_string integer}"
    end
  end
end
