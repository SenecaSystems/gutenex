defmodule Gutenex.PDF.Context do
  alias Gutenex.PDF.Page
  defstruct(
    meta_data: %{
      creator: "Elixir",
      creation_date: :calendar.local_time(),
      producer: "Gutenex",
      author: "",
      title: "",
      subject: "",
      keywords: ""
    },
    images: %{},
    fonts: Gutenex.PDF.Font.standard_fonts(),
    templates: [nil],
    template_aliases: %{},
    pages: [],
    scripts: [],
    convert_mode: "utf8_to_latin2",
    current_page: 1,
    media_box: Page.page_size(:letter),
    generation_number: 0)

  def register_font(context, font_alias, font_def) do
    %Gutenex.PDF.Context{
      context |
      fonts: Map.put(context.fonts, font_alias, font_def)
   }
  end
end
