defmodule Gutenex.PDF.SerializationTest do
  use ExUnit.Case, async: true
  alias Gutenex.PDF.Serialization

  test "#serialize nil" do
    assert Serialization.serialize(nil) == " null "
  end

  test "#serialize booleans" do
    assert Serialization.serialize(true) == " true "
    assert Serialization.serialize(false) == " false "
  end

  test "#serialize with a integer" do
    assert Serialization.serialize(112392093810293) == "112392093810293"
  end

  test "#serialize with a float should format it" do
    assert Serialization.serialize(23_456.329) == "23456.33"
  end

  test "#serialize a :string" do
    assert Serialization.serialize({:string, "Bubbbles!"}) == " (Bubbbles!) "
  end

  test "#serialize with an :obj" do
    assert Serialization.serialize({{:obj, 1, 0}, true}) == "1 0 obj\n true \nendobj\n"
  end

  test "#serialize with a :date" do
    assert Serialization.serialize({:date, {{2014, 1, 31},{15, 15, 00}}}) ==
           " (D:20140131151500) "
    assert Serialization.serialize({:date, {1776, 7, 4}}) ==
           " (D:17760704000000) "
  end

  test "#serialize with a :name" do
    assert Serialization.serialize({:name, "Harold"}) == " /Harold "
  end

  test "#serialize with an :array" do
    assert Serialization.serialize({:array, [1, {:string, "Two"}, 3.0, {:date, {1776, 7, 4}}]}) ==
           " [1  (Two)  3.00  (D:17760704000000) ] "
  end

  test "#serialize with a :dict using a map" do
    assert Serialization.serialize({:dict, %{"Key" => "Value", "Numbers" => {:array, [1, 2, 3]}, "Nope" => nil}}) ==
    "<< /Key (Value)/Numbers [1 2 3] >>"
  end

  test "#serialize with a :ptr" do
    assert Serialization.serialize({:ptr, 12, 0}) == " 12 0 R "
  end

  test "#serialize with a :rect" do
    assert Serialization.serialize({:rect, [1, 2, 3, 4]}) ==
           " [1 2 3 4] "
  end

  test "#serialize with a :hexstring" do
    assert Serialization.serialize({:hexstring, "Yay Bubbles!"}) ==
           " <59617920427562626C657321> "
  end

  test "#serialize with a :stream with no options" do
    assert Serialization.serialize({:stream, "AHHHHHHHHHHHHHHHHHH"}) ==
           String.rstrip("""
           << /Length 19 >>
           stream
           AHHHHHHHHHHHHHHHHHH
           endstream
           """)
  end

  test "#serialize the :trailer" do
    assert Serialization.serialize({:trailer, {:dict, %{
      "Size" => 200,
      "Root" => {:ptr, 200, 0},
      "Info" => {:ptr, 5, 1}
    }}}) == """
    trailer
    << /Info 5 1 R/Root 200 0 R/Size 200 >>
    """
  end
end
