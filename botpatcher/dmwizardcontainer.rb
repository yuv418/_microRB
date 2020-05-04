require 'discordrb'
require 'colorize'
require './botpatcher/enhancedeventcontainer'

module DMWizardContainer
  include EnhancedEventContainer

  @wizardData = {}

  def stage(stage:, event:, key:, &block)

    if @wizardData == nil
      @wizardData = {}
    end

    if @wizardData.has_key? key
      if @wizardData[key][:stage] == stage
        yield @wizardData[key], key
        return true
      end
    end

    false

  end

  def stage_create(key, &block)

    if @wizardData == nil
      @wizardData = {}
    end

    if not @wizardData.has_key? key # We check this to make sure we aren't overwriting someone's pre-existing session.
      @wizardData[key] = {:stage => 1}
      yield @wizardData[key] # Users can inject variables

      puts "(DMWizardContainer debug)".colorize(:blue) + " stage created."
      return true
    end
    false

  end

  def advance_stage(key)

    if @wizardData.has_key? key
      @wizardData[key][:stage] += 1
      puts "(DMWizardContainer debug)".colorize(:blue) + " stage advance #{key} #{@wizardData[key][:stage]}"
      return true
    end
    false

  end

  def stage_finish(key)

    if @wizardData.has_key? key
      puts "(DMWizardContainer debug)".colorize(:blue) + " stage finish #{@wizardData[key]}"
      @wizardData.delete key

      return true
    end

    false

  end
end
