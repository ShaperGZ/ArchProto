$timers=[] if $timers == nil

class ArchToolsObserver <Sketchup::ToolsObserver
  def initialize()
    @last_state=0
    @timer=nil
    @shadow=nil
    @action_callbacks=[]
    @subjects=nil
  end

  def self.create()
    mod=Sketchup.active_model
    tools=mod.tools
    state=tools.remove_observer($toolsObserver) if $toolsObserver!=nil
    # p "remove observer :#{state}"
    $toolsObserver=ArchToolsObserver.new
    tools.add_observer($toolsObserver)
  end

  def onToolStateChanged(tools, tool_name, tool_id, tool_state)
    
    puts "onToolStateChanged: #{tool_name}:#{tool_state}"
    rotz=Sketchup.active_model.selection[0].transformation.rotz
    $note = Sketchup.active_model.add_note("",0.05,0.05) if !$note or !$note.valid?
    $note.text="rot:#{rotz}"

    listen=[
        "ScaleTool",
        "RotateTool"
    ]

    if listen.include?(tool_name)
      if tool_state == 1
        @subjects = Sketchup.active_model.selection.to_a if @last_state ==0
        $timer=UI.start_timer(0.1,true){
          for obj in @subjects
            begin
              default_action obj
            rescue
              p $!.message
              p $!.backtrace
              UI.stop_timer($timer)
            end
          end
        }
        $timers<<$timer
      else
        if tool_state == 0 and @last_state ==1
          Sketchup.active_model.start_operation("end tool",true)
          for obj in @subjects
            begin
              default_action obj
              tool_end obj
            rescue
              p $!.message
              p $!.backtrace
            end
          end
          Sketchup.active_model.commit_operation
        end # tool_state == 0
        UI.stop_timer($timer) if $timer!=nil
      end
    end
    @last_state=tool_state
  end

  def tool_end(obj=nil)
    return if obj==nil
    apt=Proto_Apt.created_objects[obj]
    if apt !=nil
      apt.expansive_update()
    end
  end

  def default_action(obj=nil)
    return if obj==nil
    dict=obj.attribute_dictionary("BuildingBlock")
    if dict!=nil
      # p "action on prototype object"
      apt=Proto_Apt.created_objects[obj]
      if apt!=nil
        apt.invalidate()
      end
    end
  end
end
