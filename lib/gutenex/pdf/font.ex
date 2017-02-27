defmodule Gutenex.PDF.Font do
  # Helpful PDF on fonts in PDFs: http://www.ntg.nl/EuroTeX/2001/KacvinskyPDF.pdf

  @default_font_size 12
  @default_font "Helvetica"
  @standard_fonts  %{
    "Times-Roman" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Times-Roman" }},
    "Times-Italic" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Times-Italic" }},
    "Times-Bold" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Times-Bold" }},
    "Times-BoldItalic" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Times-BoldItalic" }},
    "Helvetica" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Helvetica" }},
    "Helvetica-Oblique" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Helvetica-Oblique" }},
    "Helvetica-Bold" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Helvetica-Bold" }},
    "Helvetica-BoldOblique" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Helvetica-BoldOblique" }},
    "Courier" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Courier" }},
    "Courier-Oblique" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Courier-Oblique" }},
    "Courier-Bold" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Courier-Bold" }},
    "Courier-BoldOblique" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Courier-BoldOblique" }},
    "Symbol" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "Symbol" }},
    "ZapfDingbats" => %{
      "Encoding"  => {:name, "MacRomanEncoding"},
      "Type"      => {:name, "Font"},
      "Subtype"   => {:name, "Type1"},
      "BaseFont"  => {:name, "ZapfDingbats" }}
  }

  def standard_fonts do
    @standard_fonts
  end

  def default_font_size do
    @default_font_size
  end
  

  def set_font(%{}=fonts, font_name, font_size \\ @default_font_size) do
    font_name = if Map.has_key?(fonts, font_name) do
      font_name
    else
      @default_font
    end
    "/#{font_name} #{font_size} Tf\n"
  end
end
