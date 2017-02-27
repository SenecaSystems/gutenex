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
    current_font: %{},
    current_font_size: 10,
    current_leading: 12,
    current_text_x: 0,
    current_text_y: 0,
    features: [
        "ccmp", "locl", # preprocess (compose/decompose, local forms)
        #"mark", "mkmk", # marks (mark-to-base, mark-to-mark)
        "clig", "liga", "rlig", # ligatures (contextual, standard, required)
        "calt", "rclt", # contextual alts (standard, required)
        "kern", # the "palt" feature will enable automatically if "kern" is on
        #"opbd", "lfbd", "rtbd", # optical bounds -- requires app support to identify bounding glyphs?
        "curs", # cursive (required? for Arabic, useful for cursive latin)
      ],
    media_box: Page.page_size(:letter),
    generation_number: 0)

  def register_font(context, font_alias, font_def) do
    %Gutenex.PDF.Context{
      context |
      fonts: Map.put(context.fonts, font_alias, font_def)
   }
  end
  def set_current_font(context, font_alias) do
    %Gutenex.PDF.Context{
      context |
      current_font: Map.get(context.fonts, font_alias)
   }
  end
  def set_current_font(context, font_alias, font_size) do
    %Gutenex.PDF.Context{
      context |
      current_font: Map.get(context.fonts, font_alias),
      current_font_size: font_size
   }
  end
end
