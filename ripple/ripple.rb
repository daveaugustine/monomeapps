#!/usr/bin/env jruby -wKU

require File.dirname(__FILE__) + '/../../monomer/lib/monomer'

class Ripple < Monomer::Listener
  
  before_start do
    @midi = Monomer::MidiOut.new
    @buttons_on = []
    @origin = nil
    @lights_on = []    
    @max_steps = 8
    @current_step = 0
    @play_debug = true    
  end

  on_start do
     timely_repeat :bpm => 120, :prepare => L{play_notes}, :on_tick => L{@midi.play_prepared_notes!}
  end
  
  on_button_press do |x,y|
    unless @origin.nil? or (@origin[:x] == x && @origin[:y] == y)
      @buttons_on.push({:x => x, :y => y})
    else
      @origin = {:x => x, :y => y}
    end    
  end
  
  def self.play_notes 
      
      unless (@current_step == @max_steps) || @origin.nil?
        monome.clear
        light_origin
        light_others        
        light_square(@current_step)  
        check_for_hit
        @current_step += 1
      else
        @current_step = 0
      end  

  end
  
  def self.check_for_hit
    @buttons_on.each do |button|  
      if @lights_on.include?(button)
        @midi.prepare_note(:duration => 0.4 * (60 / 120.0 / 4), :note => button[:x] * 8 + button[:y])
      end
    end
          
  end
  
  def self.light_origin
    monome.toggle_led( @origin[:x], @origin[:y])    
  end
  
  def self.light_others
    for button in @buttons_on do
      monome.toggle_led( button[:x], button[:y])
    end    
  end
   
  def self.light_square(size)
    @lights_on = []
        
    unless size == 0
      upper_left    = { :x => @origin[:x] - size, :y => @origin[:y] - size  }
      upper_right   = { :x => @origin[:x] + size, :y => @origin[:y] - size  }
      lower_left    = { :x => @origin[:x] - size, :y => @origin[:y] + size  }    
      lower_right   = { :x => @origin[:x] + size, :y => @origin[:y] + size  }    
  
      light_line( upper_left  , upper_right )
      light_line( upper_right , lower_right )
      light_line( lower_left  , lower_right )
      light_line( upper_left  , lower_left  )
    end  
  end

  def self.light_line( starting, ending )
    max_x = ( starting[:x] - ending[:x] ).abs    
    max_y = ( starting[:y] - ending[:y] ).abs

    if (max_x > max_y)
      for x in starting[:x]..ending[:x] do
        monome.led_on( x, ending[:y] )
        @lights_on.push( {:x => x, :y => ending[:y]} )
      end
    else
      for y in starting[:y]..ending[:y] do 
        monome.led_on( starting[:x], y )
        @lights_on.push( {starting[:x], y} )        
      end  
    end 
  end
  
end

Monomer::Monome.create.with_listeners(Ripple).start  if $0 == __FILE__