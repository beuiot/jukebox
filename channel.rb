#!/usr/bin/env ruby

require 'rev'
require 'time'

load 'display.rb'

class ChannelsCron < Rev::TimerWatcher
  def initialize()
    super(0.2, true);
    @channels = [];
  end

  def register(ch)
    @channels.push(ch);
    log("Cron register channel #{ch.name()} [#{@channels.size()}]");
  end

  def unregister(ch)
    @channels.delete(ch);
    log("Cron unregister channel #{ch.name()} [#{@channels.size()}]");
  end

  private 
  def on_timer
    @channels.each { |c|
      c.cron();
    }
  end
end

$channelsCron = ChannelsCron.new();
$channelsCron.attach(Rev::Loop.default)

class Channel
  attr_reader :name
  attr_reader :pos
  attr_reader :timestamp
  attr_accessor :plugin_name

  def initialize(name, library)
    @name         = name;
    @library      = library;
    @connections  = [];
    @history      = [];
    @cur          = nil;
    @pos          = 0;
    @currentEntry = nil;
    @timestamp    = 0;
    @time         = 0;
    @nb_songs	  = 0;

    log("Creating new channel #{name}");
    set_default_plugin()
    set_nb_songs();
    fetchData();
  end

  def meta()
    @currentEntry;
  end

  def cron()
    frames = sync();
    frames.each { |t|
      @connections.each { |s|
        s.write(t.to_s());
      }
    }
  end

  def register(s)
    $channelsCron.register(self) if(@connections.size() == 0);
    @connections.push(s);
    log("Registering channel #{@name} [#{@connections.size()} user(s) connected]");
    if(@currentEntry)
      tag = Id3.new();
      tag.title  = @currentEntry[3];
      tag.artist = @currentEntry[4];
      tag.album  = @currentEntry[5];
      s.write(tag.to_s());
    end
  end

  def unregister(s)
    @connections.delete(s);
    if(@connections.size() == 0)
      $channelsCron.unregister(self);
      @time = 0;
    end
    log("Unregistering channel #{@name} [#{@connections.size()} user(s) connected]");
  end

  def next()
    log("Next on channel #{@name}");
    @pos += 1;    
    fetchData();
    send(@plugin_name + "_next_callback")
  end

  def previous()
    log("Previous on channel #{@name}");
    @pos -=1 if(@pos > 0);
    fetchData();
    send(@plugin_name + "_previous_callback")
  end

  def mids()
    return @history;
  end

  def getConnected()
    return @connections.size();
  end
 
  def playlist_add(pos, mid)
    @history.insert(@pos+pos+1, mid)
    send(@plugin_name + "_add_callback") 
  end

  def playlist_rem(pos)
    @history.delete_at(@pos+pos+1)
    send(@plugin_name + "_rem_callback") 
  end

  def playlist_move(old_index, new_index)
    mid = @history[@pos+old_index+1]
    if(old_index > new_index) # meaning the song is going up
      playlist_add(new_index, mid)
      playlist_rem(old_index+1)
    else # going down
      playlist_add(new_index+1, mid)
      playlist_rem(old_index)
    end
    send(@plugin_name + "_move_callback") 
  end

  def set_default_plugin()
    @plugin_name = "default"
    load "plugins/default.rb"
    extend Plugin
    log("Loading default plugin for songs selection")
  end
 
  def set_nb_songs()
    @nb_songs = @library.get_nb_songs;
  end
 
  private
  def fetchData()
    begin
      send(@plugin_name)
      # move to the next entry
      mid = @history[@pos];
      @currentEntry = @library.get_file(mid);
      file = @currentEntry[2];
      log("Fetching on channel #{@name}: #{file}");
      @cur = Mp3File.new(file);
      tag = Id3.new();
      tag.title  = @currentEntry[3];
      tag.artist = @currentEntry[4];
      tag.album  = @currentEntry[5];
      @tag = tag.to_s();
      @timestamp = Time.now().to_i();
    rescue => e
      @pos += 1 if(@history[@pos]);
      error("Can't load mid=#{mid}: #{e.to_s()}", true, $error_file);
      retry;
    end
  end

  def sync()
    frames = [];

    now = Time.now();
    if(@time == 0)
      delta = 0.2;
      @time = now - delta;
    end

    if(@tag)
      frames << @tag;
      @tag = nil;
    end

    begin
      delta = now - @time;
      new_frames, delta = @cur.play(delta);
      frames += new_frames;
      @time  += delta;
      self.next() if(@time < now);
    end while(@time < now)

    frames;
  end
end
