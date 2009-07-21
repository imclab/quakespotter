$LOAD_PATH << 'vendor/hpricot/lib'

require 'open-uri'
require 'vendor/hpricot/lib/hpricot'
require 'lib/globe'
require 'lib/dot_gov'
require 'lib/location'

class WorldWide < Processing::App

  load_library 'opengl'
  
  attr_reader :globe, :locations, :selected
        
  def setup
    size(750, 750, OPENGL)
    
    @mouse_sensitivity = 0.03
    @push_back = 0
    @rot_x, @rot_y = 25, 270 # Center on the ol' US of A.
    @vel_x, @vel_y = 0, 0
    @globe = Globe.new
    @source = DotGov.new
    @locations = @source.earthquakes
    @buffer = create_graphics(width, height, P3D)
    
    no_stroke
    texture_mode IMAGE
    ellipse_mode CENTER
    image_mode   CENTER
    text_font    load_font('fonts/AkzidenzGrotesk-Bold-14.vlw')
  end
  
  def draw
    hint(ENABLE_DEPTH_TEST)
    background 0
    lights
    push_matrix
    translate width/2, height/2, @push_back
    rotate_x radians(-@rot_x)
    rotate_y radians(270 - @rot_y)
    @globe.check_visibility if position_changed?
    @globe.draw
    hint(DISABLE_DEPTH_TEST)
    @locations.each_with_index {|loc, i| loc.draw unless i == @selected }
    selected_quake.draw(true) if selected_quake
    pop_matrix
    fill 200
    text("#{frame_rate.to_i} FPS", 14, height-34, 0)
    text(selected_quake.text, 14, height-14, 0) if selected_quake
    update_position
  end
  
  def selected_quake
    @selected && @locations[@selected]
  end
  
  def position_changed?
    @rot_x.to_i != @p_rot_x.to_i || @rot_y.to_i != @p_rot_y.to_i
  end
  
  def mouse_pressed
    @buffer.begin_draw
    @buffer.background 255
    @buffer.no_stroke
    @buffer.translate width/2, height/2, @push_back
    @buffer.rotate_x radians(-@rot_x)
    @buffer.rotate_y radians(270 - @rot_y)
    @locations.each_with_index {|l, i| l.draw_for_picking(i, @buffer) unless l.hidden? }
    result = red(@buffer.get(mouse_x, mouse_y)).to_i
    @selected = result if @locations[result]
    @buffer.end_draw
  end
  
  def key_pressed
    handle_zoom
    handle_selection
  end
  
  def handle_zoom
    @push_back += 3 if key == '='
    @push_back -= 3 if key == '-'
  end
  
  def handle_selection
    return unless [37, 39].include? key_code
    if key_code == 37 # left
      @selected -= 1 if @selected
      @selected = @locations.length - 1 if !selected_quake
    end
    if key_code == 39 # right
      @selected += 1 if @selected
      @selected = 0 if !selected_quake
    end
    @rot_x = selected_quake.latitude
    @rot_y = selected_quake.longitude
  end
  
  def update_position
    @p_rot_x, @p_rot_y = @rot_x, @rot_y
    @rot_x += @vel_x
    @rot_y += @vel_y
    @vel_x *= 0.9
    @vel_y *= 0.9
    if mouse_pressed?
      @vel_x += (mouse_y - pmouse_y) * @mouse_sensitivity
      @vel_y -= (mouse_x - pmouse_x) * @mouse_sensitivity
    end
  end
  
end

WorldWide.new