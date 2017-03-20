require 'sketchup.rb'

module TT::Plugins::RetroUp

  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins')
    id = menu.add_item('Retro Mode') { self.toggle_retro_mode }
    menu.set_validation_proc(id)  { self.validation_proc_retro_mode }
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


  class RetroToolsObserver < Sketchup::ToolsObserver

    def onActiveToolChanged(tools, tool_name, tool_id)
      retro_beep
    end

    def onToolStateChanged(tools, tool_name, tool_id, tool_state)
      retro_beep
    end

    private

    RETRO_BEEP_SOUND_FILE = File.join(__dir__, 'beep.wav')

    def retro_beep
      return unless TT::Plugins::RetroUp.retro_mode?
      UI.play_sound(RETRO_BEEP_SOUND_FILE)
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
