#!/usr/bin/env jruby -wKU

require File.dirname(__FILE__) + '/../../lib/monomer'

class Ripple < Monomer::Listener
  
  before_start do
    @midi = Monomer::MidiOut.new
    @buttons_on = []
    @lights_on = []    
    @max_steps = 8
    @current_step = 0
    @play_debug = false    
  end

  on_start do
     timely_repeat :bpm => 120, :prepare => L{play_notes}, :on_tick => L{@midi.play_prepared_notes!}
  end
  
  on_button_press do |x,y|
    @buttons_on.push({:x => x, :y => y})
  end
  
  def self.play_notes 
      
      if @play_debug
        print "Playing note at #{button[:x]}, #{button[:y]}\n"
        puts test
      end
      
      unless @current_step == @max_steps 
        light_rectangle(@current_step)  
        @current_step += 1
      else
        @current_step = 0
      end  

  end

  def self.light_rectangle(size)
    monome.clear
    @lights_on = []
    
    @buttons_on.each do |button|
      monome.toggle_led(button[:x], button[:y])
      
      upper_left    = { :x => button[:x] - size, :y => button[:y] - size  }
      upper_right   = { :x => button[:x] + size, :y => button[:y] - size  }
      lower_left    = { :x => button[:x] - size, :y => button[:y] + size  }    
      lower_right   = { :x => button[:x] + size, :y => button[:y] + size  }    
    
      light_line( upper_left  , upper_right )
      light_line( upper_right , lower_right )
      light_line( lower_left  , lower_right )
      light_line( upper_left  , lower_left  )
      
      if @lights_on.include?(button)
        @midi.prepare_note(:duration => 0.4 * (60 / 120.0 / 4), :note => button[:x] * 8 + button[:y])
      end
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
      end  
    end 
  end
  
end

Monomer::Monome.create.with_listeners(Ripple).start  if $0 == __FILE__