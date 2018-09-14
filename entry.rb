require 'csv'

#UI
# module Sketchup::ArchProto
#   # cmd_create_apt=UI::Command.new("CreateApt"){Prototyping.set_tool}
#   # cmd_create_apt.tooltip = "crt_apt"
#   # cmd_create_apt.status_bar_text = "crt_apt"
#   # cmd_create_apt.menu_text = "crt_apt"
#   #
#   # toolbar1 = toolbar1.add_item cmd_create_apt
#   # toolbar1 = toolbar1.add_item cmd_interact_dlg
#   # toolbar1.show
# end

module ArchProto

  @@data=nil
  @@is_first_time_connect=true

  def self.reload_scripts()

    directory=self.get_file_path('')
    ordered_files = []
    ordered_files << directory + '/constances.rb'
    ordered_files += Dir.glob(directory + '/arch_util*.rb')
    ordered_files << directory + '/observer_manager.rb'
    ordered_files << directory + '/archi.rb'
    ordered_files << directory + '/building_block.rb'
    ordered_files << directory + '/html_dialog_wrapper.rb'
    ordered_files += Dir.glob(directory + '/proto*.rb')
    ordered_files += Dir.glob(directory + '/swit*.rb')
    ordered_files += Dir.glob(directory + '/wd_*.rb')
    ordered_files += Dir.glob(directory + '/bh_*.rb')

    ordered_files.each {|f|
      name=f.split('/')[-1]
      if name!='entry.rb'
        p "loading: #{f}"
        load f
      end
    }
  end

  def self.reload_profiles()
    load_profiles()
    return @@profiles
  end

  @@profiles=nil
  def self.profiles
    if @@profiles==nil
      self.load_profiles
    end
    return @@profiles
  end

  def self.load_profiles()
    directory=self.get_file_path('profiles/')
    # list all profile files in the directory
    files=Dir.glob(directory+'/*.csv')

    @@profiles=Hash.new
    files.each{|f|
      content=[]
      CSV.foreach(f) do |row|
        p "row=#{row} row.class=#{row.class}"
        content<<row
      end
      key=f.split('/')[-1].split('.')[0]
      @@profiles[key]=content
    }
  end

  def self.load_profile(name)
    path=self.get_file_path('profiles/'+name+'.csv')
    content=[]
    CSV.foreach(path) do |row|
      p "row=#{row} row.class=#{row.class}"
      content<<row
    end
    return content
  end


  def self.get_file_path(file="/colorPallet.txt")
    basepath = 'd:/SketchupRuby/Prototype/'
    profile_path = basepath + file
    return profile_path
  end

  def self.get_file_path_bak(file="/colorPallet.txt")
    basepath = File.dirname(__FILE__)
    profile_path = basepath + file
    return profile_path
  end


end


ArchProto.reload_profiles
ArchProto.reload_scripts

ArchProto.open_interaction









