require 'sketchup.rb'

module TT::Plugins::RetroUp

  APP = self

  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins')
    retro_menu = menu.add_submenu('Retro Mode')

    id = retro_menu.add_item('Activate All') { self.activate_all }

    id = retro_menu.add_item('Deactivate All') { self.deactivate_all }

    retro_menu.add_separator

    id = retro_menu.add_item('Audio') { self.toggle_retro_mode }
    retro_menu.set_validation_proc(id) { self.validation_proc_retro_mode }

    id = retro_menu.add_item('Style') { self.toggle_retro_style_mode }
    retro_menu.set_validation_proc(id) { self.validation_proc_retro_style_mode }

    retro_menu.add_separator

    id = retro_menu.add_item('Force New Model') { self.new_model_discard_changes }

    retro_menu.add_separator

    id = retro_menu.add_item('Debug') { self.toggle_debug_mode }
    retro_menu.set_validation_proc(id) { self.validation_proc_debug_mode }

    file_loaded(__FILE__)
  end


  def self.new_model_discard_changes
    Sketchup.active_model.close(true)
  end


  def self.activate_all
    self.retro_mode = true
    self.retro_style_mode = true
  end


  def self.deactivate_all
    self.retro_mode = false
    self.retro_style_mode = false
  end


  def self.toggle_retro_mode
    self.retro_mode = !self.retro_mode?
  end

  def self.retro_mode=(value)
    Sketchup.write_default('TT_RetroUp', 'RetroMode', value)
    @retro_mode = value
  end

  def self.retro_mode?
    if @retro_mode.nil?
      @retro_mode = Sketchup.read_default('TT_RetroUp', 'RetroMode', true)
    end
    @retro_mode
  end

  def self.validation_proc_retro_mode
    self.retro_mode? ? MF_CHECKED : MF_ENABLED
  end


  def self.toggle_retro_style_mode
    self.retro_style_mode = !self.retro_style_mode?
  end

  def self.retro_style_mode=(value)
    Sketchup.write_default('TT_RetroUp', 'RetroMode', value)
    @retro_style_mode = value
    if @retro_style_mode
      self.activate_retro_style
    else
      self.restore_style
    end
  end

  def self.retro_style_mode?
    if @retro_style_mode.nil?
      @retro_style_mode = Sketchup.read_default('TT_RetroUp', 'RetroMode', true)
    end
    @retro_style_mode
  end

  def self.validation_proc_retro_style_mode
    self.retro_style_mode? ? MF_CHECKED : MF_ENABLED
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


  RETRO_STYLE_FILE = File.join(__dir__, 'styles', 'RetroUp.style').freeze
  RETRO_STYLE_NAME = 'RetroUp'.freeze

  def self.activate_retro_style
    model = Sketchup.active_model
    styles = model.styles
    unless styles.selected_style.name.include?(RETRO_STYLE_NAME)
      @last_style = styles.selected_style.name
    end
    style = styles[RETRO_STYLE_NAME]
    if style.nil?
      styles.add_style(RETRO_STYLE_FILE, true)
      style = styles[RETRO_STYLE_NAME]
      # HACK: The HorizonColor doesn't appear to be stored with the file.
      # We manually apply it to give a different horizon tint other than the
      # default white-ish one which clash with the dark style.
      model.rendering_options['HorizonColor'] = [64, 0, 0]
      styles.update_selected_style
    else
      styles.selected_style = style
    end
    style
  end

  def self.restore_style
    model = Sketchup.active_model
    styles = model.styles
    last_style = model.styles[@last_style.to_s] || model.styles.find { |style|
      !style.name.include?(RETRO_STYLE_NAME)
    }
    p @last_style
    puts last_style.name
    styles.selected_style = last_style
    # Restore HorizonColor. This makes SU calculate dynamically the color.
    model.rendering_options['HorizonColor'] = [0, 0, 0, 0]
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


  class RetroSelectionObserver < Sketchup::SelectionObserver

    SELECTION_CHANGE_AUDIO = File.join(__dir__, 'audio', 'SelectionTool.wav')

    def onSelectionBulkChange(selection)
      onSelectionChange(selection)
    end

    def onSelectionCleared(selection)
      onSelectionChange(selection)
    end

    private

    def onSelectionChange(selection)
      return unless TT::Plugins::RetroUp.retro_mode?
      UI.play_sound(SELECTION_CHANGE_AUDIO)
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
      model.selection.add_observer(RetroSelectionObserver.new)
      model.tools.add_observer(RetroToolsObserver.new)
      APP.activate_retro_style if APP.retro_style_mode?
    end

  end

  unless file_loaded?('RetroAppObserver')
    Sketchup.add_observer(RetroAppObserver.new)
    file_loaded('RetroAppObserver')
  end

end # module
