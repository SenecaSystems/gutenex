defmodule GutenexFontTest do
  use ExUnit.Case
  alias Gutenex.PDF.TrueType, as: TrueType
  alias Gutenex.PDF.OpenTypeFont

  test "parse Truetype font metrics" do
    ttf = TrueType.new
          |> TrueType.parse("./test/support/fonts/NotoSansCJKjp-Bold.otf")
    assert 733 == ttf.capHeight
    assert -120 == ttf.descent
    assert 880 == ttf.ascent
    assert [-1013.0, -1046.0, 2926.0, 1806.0] == ttf.bbox
    assert 0 == ttf.italicAngle
    assert 1000 == ttf.unitsPerEm
    assert 1000 == ttf.defaultWidth
    assert 700 == ttf.usWeightClass
  end

  test "register parsed font" do
    {:ok, pid} = Gutenex.start_link
    ttf = TrueType.new
          |> TrueType.parse("./test/support/fonts/NotoSansCJKjp-Bold.otf")

    # sanity check that we do not have font before registration
    ctx = Gutenex.context(pid)
    assert not Map.has_key?(ctx.fonts, ttf.name)

    Gutenex.register_font(pid, ttf.name, ttf)

    # now font exists
    ctx = Gutenex.context(pid)
    assert Map.has_key?(ctx.fonts, ttf.name)
  end

  test "Basic CMAP support" do
    ttf = TrueType.new
          |> TrueType.parse("./test/support/fonts/NotoSans-Bold.ttf")
    {glyphs, _} = TrueType.layout_text(ttf, "ABC")
    assert glyphs == [36, 37, 38]
  end

  test "Apply OpenType substitutions (GSUB 4) - exercise ligature" do
    ttf = TrueType.new
          |> TrueType.parse("./test/support/fonts/NotoSans-Bold.ttf")
    {glyphs, _} = TrueType.layout_text(ttf, "ffl", ["liga"])
    assert glyphs == [603]
  end

  test "Apply OpenType substitutions (GSUB 6) - exercise chained" do
    ttf = TrueType.new
          |> TrueType.parse("./test/support/fonts/SourceSansPro-Regular.otf")
    {glyphs, _} = TrueType.layout_text(ttf, "1/2", ["liga", "frac"])
    assert glyphs == [1617, 1726, 1604]
  end

  test "Apply mark-to-base positioning" do
    ttf = TrueType.new
          |> TrueType.parse("./test/support/fonts/NotoSans-Bold.ttf")
    {glyphs, pos} = TrueType.layout_text(ttf, "bi\u0300g", ["ccmp", "mark"])
    # ccmp will replace i with dotless variant
    assert glyphs == [69, 243, 608, 74]

    # mark will position accent over the i
    xpos = pos |> Enum.map(fn {_,x,_,_,_} -> x end)
    xadv = pos |> Enum.map(fn {_,_,_,x,_} -> x end)
    # mark has an xOffset
    assert xpos == [0, 0, 636.82421875, 0]
    # mark has zero width
    assert xadv == [632.8125, 305.17578125, 0, 632.8125]
  end

  # turn OpenType features on and off in an integration test
  @tag :integration
  test "Turn OpenType features on and off" do
    File.rm("./tmp/zero.pdf")
    {:ok, ssp} = OpenTypeFont.start_link
    OpenTypeFont.parse(ssp, "./test/support/fonts/SourceSansPro-Regular.otf")
    {:ok, pid} = Gutenex.start_link
    Gutenex.register_font(pid, "SourceSansPro", ssp)
      |> Gutenex.begin_text
      |> Gutenex.text_leading(32)
      |> Gutenex.text_position(40, 180)
      |> Gutenex.text_render_mode(:fill)
      |> Gutenex.set_font("SourceSansPro", 32)
      |> Gutenex.write_text_br("Default zero: 0")
      |> Gutenex.activate_feature("zero")
      |> Gutenex.write_text_br("OpenType zero on: 0")
      |> Gutenex.deactivate_feature("zero")
      |> Gutenex.write_text_br("OpenType zero off: 0")
      |> Gutenex.activate_feature("onum")
      |> Gutenex.write_text_br("OpenType onum: 0123456789")
      |> Gutenex.deactivate_feature("onum")
      |> Gutenex.activate_feature("pnum")
      |> Gutenex.write_text_br("OpenType pnum: 0123456789")
      |> Gutenex.deactivate_feature("pnum")
      |> Gutenex.activate_feature("tnum")
      |> Gutenex.activate_feature("smcp")
      |> Gutenex.write_text_br("OpenType tnum: 0123456789")
      |> Gutenex.end_text
      |> Gutenex.export("./tmp/zero.pdf")
  end

  @tag :integration
  test "basic marks (combining diacratics)" do
    File.rm("./tmp/diacratics.pdf")
    {:ok, ttf} = OpenTypeFont.start_link
    OpenTypeFont.parse(ttf, "./test/support/fonts/NotoSans-Bold.ttf")
    {:ok, ssp} = OpenTypeFont.start_link
    OpenTypeFont.parse(ssp, "./test/support/fonts/SourceSansPro-Regular.otf")

    {:ok, pid} = Gutenex.start_link
    Gutenex.register_font(pid, "NotoSans", ttf)
      |> Gutenex.register_font("SourceSansPro", ssp)
      |> Gutenex.begin_text
      |> Gutenex.text_leading(40)
      |> Gutenex.text_position(40, 180)
      |> Gutenex.set_font("NotoSans", 32)
      |> Gutenex.text_render_mode(:fill)
      |> Gutenex.write_text_br("a\u0300e\u0301i\u0302o\u0303u\u0304")
      |> Gutenex.write_text_br("a\u0300e\u0300i\u0300o\u0300u\u0300")
      |> Gutenex.write_text_br("aeiou")
#|> Gutenex.set_font("SourceSansPro", 32)
#|> Gutenex.write_text_br("f\u0300g\u0306\u0301u\u0302\u0307")
      |> Gutenex.end_text
      |> Gutenex.export("./tmp/diacratics.pdf")
  end

  @tag :integration
  test "embed font" do
    File.rm("./tmp/embed.pdf")
    {:ok, ttf} = OpenTypeFont.start_link
    OpenTypeFont.parse(ttf, "./test/support/fonts/NotoSans-Italic.ttf")
    {:ok, ssp} = OpenTypeFont.start_link
    OpenTypeFont.parse(ssp, "./test/support/fonts/SourceSansPro-Regular.otf")
    {:ok, notojp} = OpenTypeFont.start_link
    OpenTypeFont.parse(notojp, "./test/support/fonts/NotoSansCJKjp-Bold.otf")


    {:ok, pid} = Gutenex.start_link
    Gutenex.register_font(pid, "NotoSans", ttf)
      |> Gutenex.register_font("SourceSansPro", ssp)
      |> Gutenex.register_font("NotoJP", notojp)
      |> Gutenex.begin_text
      |> Gutenex.text_leading(48)
      |> Gutenex.set_font("Helvetica", 48)
      |> Gutenex.text_position(40, 180)
      |> Gutenex.text_render_mode(:fill)
      |> Gutenex.write_text_br("ABC")
      |> Gutenex.set_font("NotoSans", 32)
      |> Gutenex.text_render_mode(:fill)
      |> Gutenex.write_text_br("Noto Sans")
      |> Gutenex.set_font("SourceSansPro", 32)
      |> Gutenex.activate_feature("frac")
      |> Gutenex.write_text_br("kern AWAY difficult waffle 1/2")
      |> Gutenex.deactivate_feature("frac")
      |> Gutenex.set_font("NotoJP", 32)
      |> Gutenex.write_text_br("Japanese \u713C")
      |> Gutenex.end_text
      |> Gutenex.export("./tmp/embed.pdf")
  end
end
