defmodule Gutenex.PDF.Exporter do
  alias Gutenex.PDF.RenderContext
  alias Gutenex.PDF.Serialization
  # Declare the PDF version
  @start_mark "%PDF-1.7\n"
  @end_mark "%%EOF\r\n"

  def export(%RenderContext{}=render_context) do
    serialized_objects =
      Enum.map(RenderContext.objects(render_context), &Serialization.serialize/1)
    @start_mark <>
    Enum.join(serialized_objects) <>
    cross_reference_table(serialized_objects) <>
    Serialization.serialize(RenderContext.trailer(render_context)) <>
    start_cross_reference(serialized_objects) <>
    @end_mark
  end

  def trailer(root_index, generation_number, meta_data_index, objects) do
    Serialization.serialize({:trailer, {:dict,
      %{
        "Size" => length(objects) + 1,
        "Root" => {:ptr, root_index, generation_number},
        "Info" => {:ptr, meta_data_index, generation_number}
      }}})
  end

  def cross_reference_table(serialized_objects) do
    pdf_start_position = byte_size(@start_mark)
    {xrefs, _acc} = :lists.mapfoldl &xref/2, pdf_start_position, serialized_objects
    """
    xref
    0 #{length(serialized_objects) + 1}
    #{xref1(0, "65535 f")}#{xrefs}
    """
  end

  def start_cross_reference(serialized_objects) do
    total_length = Enum.reduce serialized_objects, byte_size(@start_mark), fn (object, total) ->
      byte_size(object) + total
    end

    """
    startxref
    #{total_length}
    """
  end

  def xref(serialized_objects, position) do
    objects_length = byte_size(serialized_objects)
    {xref1(position, "00000 n"), position + objects_length}
  end

  def xref1(position, string) do
    :io_lib.format("~10.10.0w ~s \n", [position, string])
  end

end
