#!/usr/bin/env jruby -wKU

require File.dirname(__FILE__) + '/../../monomer/lib/monomer'

class Ripple < Monomer::Listener
  
  before_start do
    @midi = Monomer::MidiOut.new
    @buttons_on = []
    @origin = nil
    @lights_on = []    
    @max_steps = 8
    @radius = 0
    @play_debug = true    
  end

  on_start do
     timely_repeat :bpm => 120, :prepare => L{play_notes}, :on_tick => L{@midi.play_prepared_notes!}
  end
  
  on_button_press do |x,y|
    button = {:x => x, :y => y}
    if @origin.nil?
      @origin = button
      if @buttons_on.include? button
        @buttons_on.delete(button)
      end
    elsif @origin == button
      extinguish_origin
      monome.clear
      light_others
    elsif @buttons_on.include?(button)
      @buttons_on.delete(button)
    else  
      @buttons_on.push(button)
    end    
  end
  
  def self.play_notes 
      unless (@radius == @max_steps) || @origin.nil?
        monome.clear
        light_origin
        light_others        
        #light_square(@radius)  
        light_circle @radius
        check_for_hit
        @radius += 1
      else
        @radius = 0
      end  
  end
  
  def self.check_for_hit
    @buttons_on.each do |button|
      if distance(@origin, button) == @radius
        @midi.prepare_note(:duration => 0.5, :note => ((button[:x] + 1) * (button[:y] + 1)) + 40)  
      end
      # if @lights_on.include?(button)
      #         @midi.prepare_note(:duration => 0.5, :note => ((button[:x] + 1) * (button[:y] + 1)) + 40)
      #       end
    end
  end
  
  def self.distance(p1, p2)
    Math.sqrt( ((p2[:x] - p1[:x])**2)  + ((p2[:y] - p1[:y])**2) ).floor
  end   
  
  def self.light_origin
    monome.led_on( @origin[:x], @origin[:y])    
  end

  def self.extinguish_origin
    @origin = nil        
  end  
  
  def self.toggle_origin
    monome.toggle_led( @origin[:x], @origin[:y])    
  end
  
  def self.light_others
    for button in @buttons_on do
      monome.led_on( button[:x], button[:y])
    end    
  end
  
  def self.light_circle(radius)
    unless radius == 0
      circle @origin, radius
    end
  end
  
  def self.light_square(size)
    @lights_on = []
        
    unless size == 0
      upper_left    = { :x => @origin[:x] - size, :y => @origin[:y] - size  }
      upper_right   = { :x => @origin[:x] + size, :y => @origin[:y] - size  }
      lower_left    = { :x => @origin[:x] - size, :y => @origin[:y] + size  }    
      lower_right   = { :x => @origin[:x] + size, :y => @origin[:y] + size  }    
  
      line( upper_left  , upper_right )
      line( upper_right , lower_right )
      line( lower_left  , lower_right )
      line( upper_left  , lower_left  )
    end  
  end
  
  
  def self.circle(p1, radius)    
    r2 = radius * radius
    x = -radius
    while x <= radius
      y = (Math.sqrt(r2 - x*x) + 0.5).floor
      monome.led_on(p1[:x] + x, p1[:y] + y)      
      monome.led_on(p1[:x] + x, p1[:y] - y)      
      x += 1
    end
  end

  def self.line(p1, p2)
    x = p1[:x]
    y = p1[:y]
    delta_x = (p2[:x] - p1[:x])    
    delta_y = p2[:y] - p1[:y]
    d = (2 * delta_y) - delta_x
    
    for j in p1[:x]..p2[:x] do
      monome.led_on(x, y)
      if d < 0
        d = d + (2 * delta_y)
      else 
        d = d + 2 * (delta_y - delta_x)
        y = y + 1
      end
      x = x + 1
    end
  end
  
  def self.light_line( starting, ending )
    max_x = ( starting[:x] - ending[:x] ).abs    
    max_y = ( starting[:y] - ending[:y] ).abs

    if (max_x > max_y)
      for x in starting[:x]..ending[:x] do
        monome.led_on( x, ending[:y] )
      end
    else
      for y in starting[:y]..ending[:y] do 
        monome.led_on( starting[:x], y )
      end  
    end 
  end
  
end

Monomer::Monome.create.with_listeners(Ripple).start  if $0 == __FILE__