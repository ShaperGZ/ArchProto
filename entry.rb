require 'csv'
# $basepath='g:/SketchupRuby/ArchProto/' if $basepath==nil
$basepath='d:/SketchupRuby/ArchProto/' if $basepath==nil

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
    ordered_files << directory + 'geometry_monitor.rb'
    ordered_files << directory + 'arch_components.rb'
    # ordered_files << directory + 'arch_tools_observer.rb'
    ordered_files << directory + 'constances.rb'
    ordered_files += Dir.glob(directory + 'arch_util*.rb')
    ordered_files << directory + 'mesh_util.rb'
    ordered_files << directory + 'html_dialog_wrapper.rb'
    ordered_files << directory + 'observer_manager.rb'
    ordered_files << directory + 'archi.rb'
    ordered_files << directory + 'building_block.rb'

    ordered_files += Dir.glob(directory + 'proto*.rb')
    ordered_files += Dir.glob(directory + 'swit*.rb')
    ordered_files += Dir.glob(directory + 'op_*.rb')
    ordered_files += Dir.glob(directory + 'wd_*.rb')
    ordered_files += Dir.glob(directory + 'bh_*.rb')

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
    profile_path = $basepath + file
    return profile_path
  end

end

def startArchTest (path=nil)
  $basepath = path if path!=nil
  if !$LOAD_PATH.include? $basepath
    $LOAD_PATH << $basepath
  end
  # ArchToolsObserver.create
  Geometry_Monitor.reset_timer
  Proto_Apt.create_from_selection
end

def _get_attr(table,key)
  g=Sketchup.active_model.selection[0]
  a=g.get_attribute(table,key)
  return a
end
def _get_bb()
  g=Sketchup.active_model.selection[0]
  bb=Proto_Apt.created_objects[g]
  return bb
end
def _get_updator(classname)
  bb=_get_bb
  ud=bb.get_updator_by_type(classname)
  return ud
end

def _reload()
  WD_Interact.singleton.dlg.close
  load 'entry.rb'
  g=Sketchup.active_model.selection[0]
  startArchTest
end

ArchProto.reload_profiles
ArchProto.reload_scripts if $entry_loaded_once != nil or $entry_loaded_once !=true
$entry_loaded_once=true
ArchProto.open_interaction true









