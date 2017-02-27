defmodule Gutenex.PDF.Text do
  import Gutenex.PDF.Utils

  @begin_text_marker "BT\n"
  @end_text_marker "ET\n"
  @break_text_marker " T*\n"

  def begin_text do
    @begin_text_marker
  end

  def end_text do
    @end_text_marker
  end

  def break_text do
    @break_text_marker
  end

  #ACTUALLY we want to write out a stream
  #of glyph IDs rather than raw text
  def write_text(text_to_write) do
    "(#{escape(text_to_write)}) Tj\n"
  end

  def hexstring(text) do
    hex = text
          |> :unicode.characters_to_binary(:unicode, :utf16)
          |> Base.encode16
    "<#{hex}> Tj\n"
  end

  def write_text_br(text_to_write) do
    write_text(text_to_write) <> break_text
  end

  def render_mode(mode) do
    "#{text_fill(mode)} Tr\n"
  end
  

  # :fill                 Fill text
  # :stroke               Stroke text
  # :fill_stroke          Fill, then stroke text
  # :invisible            Neither fill nor stroke text (invisible)
  # :fill_clip            Fill text and add to path for clipping (see above)
  # :stroke_clip          Stroke text and add to path for clipping
  # :fill_stroke_clip     Fill, then stroke text and add to path for clipping
  # :clip                 Add text to path for clipping
  def text_fill(:fill),             do: 0
  def text_fill(:stroke),           do: 1
  def text_fill(:fill_stroke),      do: 2
  def text_fill(:invisible),        do: 3
  def text_fill(:fill_clip),        do: 4
  def text_fill(:stroke_clip),      do: 5
  def text_fill(:fill_stroke_clip), do: 6
  def text_fill(:clip),             do: 7
  

  # Moves to the next line and positions the cursor offset by
  # (x_coordinate, y_coordinate)
  def text_position(x_coordinate, y_coordinate) do
    "#{x_coordinate} #{y_coordinate} Td\n"
  end

  # Set the character spacing, Tc, to `spacing`, a number 
  # expressed in unscaled text space units. Character spacing is used 
  # by the Tj, TJ, and ' operators. Initial value: 0. 
  def character_spacing(spacing) do
    "#{spacing} Tc\n"
  end

  # Set the horizontal scaling, Th, to (`scale_percent` ÷ 100). `scale_percent` 
  # should be a number specifying the percentage of the normal width.
  # Initial value: 100 (normal width). 
  def scale(scale_percent) do
    "#{normalized_scale_percentage(scale_percent)} Tz\n"
  end

  # It is very important to achieve webscale
  defp normalized_scale_percentage(:web), do: 9001
  defp normalized_scale_percentage(anything_else), do: anything_else
  
  # Set the word spacing, Tw, to `spacing`, a number 
  # expressed in unscaled text space units. Word spacing is used by 
  # the Tj, TJ, and ' operators. Initial value: 0. 
  def word_spacing(spacing) do
    "#{spacing} Tw\n"
  end

  # Sets the distance between baselines of two lines, referred to as "text 
  # leading." Text leading is only used by the T*, ', and 
  # " operators. Initial value: 0. 
  def line_spacing(spacing) do
    "#{spacing} TL\n"
  end

  def write_positioned_glyphs({glyphs, positions}, font_size) do
    #TODO: if there is no y positioning/advance can reduce to TJ directive
    #TODO: if no xpos and xadvance == width can group together
    pos_g = Enum.zip(glyphs, positions)
            |> Enum.map_join(" ", fn {g, pos} -> position_glyph(g, pos, font_size / 1000) end)
    pos_g <> "\n"
  end

  defp position_glyph(g, pos, scale) do
    {type, xp, yp, xa, ya} = pos
    hex = Integer.to_string(g, 16) |> String.pad_leading(4, "0")
    if xp == 0 and yp == 0 do
      "<#{hex}> Tj #{xa * scale} #{ya * scale} Td"
    else
      "#{xp * scale} #{yp * scale} Td <#{hex}> Tj #{(xa - xp) * scale} #{(ya - yp) * scale} Td"
    end
  end
end
