require 'sketchup.rb'

module TT::Plugins::RetroUp

  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins')
    retro_menu = menu.add_submenu('Retro Mode')

    id = retro_menu.add_item('Activate') { self.toggle_retro_mode }
    retro_menu.set_validation_proc(id)  { self.validation_proc_retro_mode }

    id = retro_menu.add_item('Debug') { self.toggle_debug_mode }
    retro_menu.set_validation_proc(id)  { self.validation_proc_debug_mode }

    file_loaded(__FILE__)
  end


  def self.toggle_retro_mode
    self.retro_mode = !self.retro_mode?
  end

  def self.retro_mode=(value)
    Sketchup.write_default('TT_RetroUp', 'RetroMode', value)
    @retro_model = value
  end

  def self.retro_mode?
    if @retro_mode.nil?
      @retro_model = Sketchup.read_default('TT_RetroUp', 'RetroMode', true)
    end
    @retro_model
  end

  def self.validation_proc_retro_mode
    self.retro_mode? ? MF_CHECKED : MF_ENABLED
  end


  def self.toggle_debug_mode
    self.debug_mode = !self.debug_mode?
  end

  def self.debug_mode=(value)
    Sketchup.write_default('TT_RetroUp', 'DebugMode', value)
    @debug_mode = value
  end

  def self.debug_mode?
    if @debug_mode.nil?
      @debug_mode = Sketchup.read_default('TT_RetroUp', 'DebugMode', false)
    end
    @debug_mode
  end

  def self.validation_proc_debug_mode
    self.debug_mode? ? MF_CHECKED : MF_ENABLED
  end


  class RetroToolsObserver < Sketchup::ToolsObserver

    def onActiveToolChanged(tools, tool_name, tool_id)
      retro_beep(tool_name)
    end

    def onToolStateChanged(tools, tool_name, tool_id, tool_state)
      retro_beep(tool_name)
    end

    private

    RETRO_BEEP_SOUND_FILE = File.join(__dir__, 'beep.wav')

    def retro_beep(tool_name)
      return unless TT::Plugins::RetroUp.retro_mode?
      debug
      debug(tool_name)
      tool_audio_file = File.join(__dir__, 'audio', "#{tool_name}.wav")
      debug(tool_audio_file)
      tool_audio_file = RETRO_BEEP_SOUND_FILE unless File.exist?(tool_audio_file)
      debug(tool_audio_file)
      UI.play_sound(tool_audio_file)
    end

    def debug(output = nil)
      puts output
    end

  end


  class RetroAppObserver < Sketchup::AppObserver

    def expectsStartupModelNotifications
      return true
    end

    def onActivateModel(model)
      observe_model(model)
    end

    def onNewModel(model)
      observe_model(model)
    end

    def onOpenModel(model)
      observe_model(model)
    end

    private

    def observe_model(model)
      model.tools.add_observer(RetroToolsObserver.new)
    end

  end

  Sketchup.add_observer(RetroAppObserver.new)

end # module
