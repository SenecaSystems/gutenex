defmodule Gutenex do
  use GenServer
  alias Gutenex.PDF
  alias Gutenex.PDF.Context
  alias Gutenex.PDF.Text
  alias Gutenex.PDF.OpenTypeFont
  alias Gutenex.PDF.Font

  alias Gutenex.Geometry

  #######################
  ##       Setup       ##
  #######################

  @doc """
  Starts the PDF generation server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Returns the default context and stream (empty binary)
  """
  def init(:ok) do
    {:ok, [%Context{}, <<>>]}
  end

  #######################
  ##    Client API     ##
  #######################

  @doc """
  Stop the server process
  """
  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  @doc """
  Returns the current context
  """
  def context(pid) do
    GenServer.call(pid, :context)
  end

  @doc """
  Sets the current context
  """
  def context(pid, new_context) do
    GenServer.cast(pid, {:context, new_context})
    pid
  end

  @doc """
  Sets the current page
  """
  def set_page(pid, page) when is_integer(page) do
    GenServer.cast(pid, {:context, :put, {:current_page, page}})
    pid
  end

  @doc """
  Begin a text block
  """
  def begin_text(pid) do
    GenServer.cast(pid, {:text, :begin})
    pid
  end

  @doc """
  Set the text position
  """
  def text_position(pid, x_coordinate, y_coordinate) do
    GenServer.cast(pid, {:text, :position, {x_coordinate, y_coordinate}})
    pid
  end

  @doc """
  Set the text render mode
  """
  def text_render_mode(pid, render_mode) do
    GenServer.cast(pid, {:text, :render_mode, render_mode})
    pid
  end

  @doc """
  Write text to the stream
  """
  def write_text(pid, text_to_write) do
    GenServer.cast(pid, {:text, :write, text_to_write})
    pid
  end

  @doc """
  Write text more break line to the stream
  """
  def write_text_br(pid, text_to_write) do
    GenServer.cast(pid, {:text, :write_br, text_to_write})
    pid
  end

  @doc """
  Activate an OpenType feature
  """
  def activate_feature(pid, tag) do
    GenServer.cast(pid, {:text, :add_feature, tag})
    pid
  end

  @doc """
  Deactivate an OpenType feature
  """
  def deactivate_feature(pid, tag) do
    GenServer.cast(pid, {:text, :remove_feature, tag})
    pid
  end

  @doc """
  Set line space
  """
  def text_leading(pid, size) do
    GenServer.cast(pid, {:text, :line_spacing, size})
    pid
  end

  @doc """
  End a text block
  """
  def end_text(pid) do
    GenServer.cast(pid, {:text, :end})
    pid
  end

  #####################################
  #               Fonts               #
  #####################################

  @doc """
  Set the font
  """
  def set_font(pid, font_name) do
    GenServer.cast(pid, {:font, :set, font_name})
    pid
  end

  @doc """
  Set the font and font size
  """
  def set_font(pid, font_name, font_size) do
    GenServer.cast(pid, {:font, :set, {font_name, font_size}})
    pid
  end

  @doc """
  Register a font for embedding
  """
  def register_font(pid, font_name, font_data) do
    GenServer.cast(pid, {:font, :register, {font_name, font_data}})
    pid
  end

  @doc """
  Gets the current stream
  """
  def stream(pid) do
    GenServer.call(pid, :stream)
  end

  @doc """
  Append to the current stream
  """
  def append_to_stream(pid, content) do
    GenServer.cast(pid, {:stream, :append, content})
    pid
  end

  @doc """
  Export the PDF document to a binary
  """
  def export(pid) do
    GenServer.call(pid, :export)
  end

  def export(pid, file_name) do
    File.write file_name, export(pid)
    pid
  end


  #####################################
  #              Images               #
  #####################################


  def add_image(pid, image_alias, %Imagineer.Image.PNG{}=image) do
    GenServer.cast(pid, {:image, :add, {image_alias, image}})
    pid
  end

  @doc """
  Add an image by alias
  """
  def draw_image(pid, image_alias) do
    draw_image(pid, image_alias, %{})
  end

  def draw_image(pid, image_alias, options) do
    GenServer.cast(pid, {:image, :write, {image_alias, options}})
    pid
  end

  #####################################
  #            Templates              #
  #####################################

  def add_template(pid, template_alias, template_contents) do
    GenServer.cast(pid, {:templates, :add, {template_alias, template_contents}})
    pid
  end

  def set_template(pid, template_alias) do
    GenServer.cast(pid, {:template, :set, {template_alias}})
    pid
  end

  #######################
  ##      Geometry     ##
  #######################

  def move_to(pid, point_x, point_y) when is_integer(point_x) and is_integer(point_y) do
    move_to(pid, {point_x, point_y})
  end

  def move_to(pid, {point_x, point_y}=point) when is_integer(point_x) and is_integer(point_y) do
    GenServer.cast(pid, {:geometry, :move_to, point})
    pid
  end

  def line(pid, {point_start, point_finish}) do
    GenServer.cast(pid, {:geometry, :line, {point_start, point_finish}})
    pid
  end

  def line_width(pid, width) do
    GenServer.cast(pid, {:geometry, :line_width, width})
    pid
  end

  #######################
  ##   Call handlers   ##
  #######################

  @doc """
  Handles stopping the server process
  """
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @doc """
  Returns the current context
  """
  def handle_call(:context, _from, [context, stream]) do
    {:reply, context, [context, stream]}
  end

  @doc """
  Returns the stream
  """
  def handle_call(:stream, _from, [context, stream]) do
    {:reply, stream, [context, stream]}
  end

  @doc """
  Export the PDF to binary format
  """

  def handle_call(:export, _from, [context, stream]) do
    {:reply, PDF.export(context, stream), [context, stream]}
  end

  #######################
  ##   Cast handlers   ##
  #######################

  @doc """
  Sets the current context
  """
  def handle_cast({:context, new_context}, [_context, stream]) do
    {:noreply, [new_context, stream]}
  end

  @doc """
  Appends to the stream
  """
  def handle_cast({:stream, :append, str}, [context, stream]) do
    new_stream = stream <> str
    {:noreply, [context, new_stream]}
  end

  @doc """
  Sets the current page
  """
  def handle_cast({:context, :put, {key, value}}, [context, stream]) do
    new_context = Map.put context, key, value
    {:noreply, [new_context, stream]}
  end

  @doc """
    Begin a section of text
  """
  def handle_cast({:text, :begin}, [context, stream]) do
    stream = stream <> Text.begin_text
    {:noreply, [context, stream]}
  end

  @doc """
    End a section of text
  """
  def handle_cast({:text, :end}, [context, stream]) do
    stream = stream <> Text.end_text
    {:noreply, [context, stream]}
  end

  @doc """
    Write some text!
  """
  def handle_cast({:text, :write, text_to_write}, [context, stream]) do
    stream = if is_pid(context.current_font) do
      output = OpenTypeFont.layout(context.current_font, text_to_write, context.features)
               |>Text.write_positioned_glyphs(context.current_font_size)
      stream <> output
    else
      stream <> Text.write_text(text_to_write)
    end

    {:noreply, [context, stream]}
  end

  @doc """
    Write some text more break line!
  """
  def handle_cast({:text, :write_br, text_to_write}, [context, stream]) do
    new_y = context.current_text_y - context.current_leading
    stream = if is_pid(context.current_font) do
      output = OpenTypeFont.layout(context.current_font, text_to_write, context.features)
               |>Text.write_positioned_glyphs(context.current_font_size)
      stream <> output <> " 1 0 0 1 #{context.current_text_x} #{new_y} Tm\n"
    else
      stream <> Text.write_text_br(text_to_write)
    end
    context = %Context{context | current_text_y: new_y}
    {:noreply, [context, stream]}
  end


  @doc """
    Set line space
  """
  def handle_cast({:text, :line_spacing, size}, [context, stream]) do
    stream = stream <> Text.line_spacing(size)
    context = %Context {context | current_leading: size}
    {:noreply, [context, stream]}
  end

  @doc """
    Set the text position
  """
  def handle_cast({:text, :position, {x_coordinate, y_coordinate}}, [context, stream]) do
    stream = stream <> Text.text_position(x_coordinate, y_coordinate)
    context = %Context{context | current_text_x: x_coordinate, current_text_y: y_coordinate}
    {:noreply, [context, stream]}
  end

  @doc """
    Set the text render mode
  """
  def handle_cast({:text, :render_mode, render_mode}, [context, stream]) do
    stream = stream <> Text.render_mode(render_mode)
    {:noreply, [context, stream]}
  end

  #####################################
  #            Templates              #
  #####################################

  def handle_cast({:templates, :add, {template_alias, template_contents}}, [context, stream]) do
    template_aliases =  Map.put context.template_aliases, template_alias, template_contents
    {:noreply, [%Context{template_aliases: template_aliases}, stream]}
  end

  def handle_cast({:template, :set, {template_alias}}, [context, stream]) do
    templates = List.replace_at(context.templates, context.current_page - 1, template_alias)
    {:noreply, [%Context{context | templates: templates}, stream]}
  end

  #####################################
  #              Images               #
  #####################################

  def handle_cast({:image, :add, {image_alias, image}}, [context, stream]) do
    images =  Map.put context.images, image_alias, image
    {:noreply, [%Context{context | images: images}, stream]}
  end

  def handle_cast({:image, :write, {image_alias, options}}, [context, stream]) do
    image = Map.get context.images, image_alias
    stream = stream <> Gutenex.PDF.Images.set_image(image_alias, image, options)
    {:noreply, [context, stream]}
  end

  #####################################
  #               Fonts               #
  #####################################

  @doc """
    Set the font and size
  """
  def handle_cast({:font, :set, {font_name, font_size}}, [context, stream]) do
    stream = stream <> Font.set_font(context.fonts, font_name, font_size)
    new_context = Context.set_current_font(context, font_name, font_size)
    {:noreply, [new_context, stream]}
  end

  @doc """
    Set the font
  """
  def handle_cast({:font, :set, font_name}, [context, stream]) do
    stream = stream <> Font.set_font(context.fonts, font_name)
    new_context = Context.set_current_font(context, font_name)
    {:noreply, [new_context, stream]}
  end

  @doc """
    Register a font for usage
  """
  def handle_cast({:font, :register, {font_name, font_data}}, [context, stream]) do
    new_context = Gutenex.PDF.Context.register_font(context, font_name, font_data)
    {:noreply, [new_context, stream]}
  end

  def handle_cast({:text, :add_feature, tag}, [context, stream]) do
    new_context = %Context {context | features: [tag | context.features]}
    {:noreply, [new_context, stream]}
  end

  def handle_cast({:text, :remove_feature, tag}, [context, stream]) do
    features = context.features |> Enum.filter(fn t -> t != tag end)
    new_context = %Context {context | features: features}
    {:noreply, [new_context, stream]}
  end


  #####################################
  #             Geometry              #
  #####################################

  def handle_cast({:geometry, :move_to, {point_x, point_y}}, [context, stream]) do
    stream = stream <> Geometry.move_to({point_x, point_y})
    {:noreply, [context, stream]}
  end

  def handle_cast({:geometry, :line, {point_start, point_finish}}, [context, stream]) do
    stream = stream <> Geometry.Line.line({point_start, point_finish})
    {:noreply, [context, stream]}
  end

  def handle_cast({:geometry, :line_width, width}, [context, stream]) do
    stream = stream <> Geometry.Line.line_width(width)
    {:noreply, [context, stream]}
  end
end
