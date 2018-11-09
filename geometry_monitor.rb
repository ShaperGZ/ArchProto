
# $note=Sketchup.active_model.add_note("note",0.05,0.05) if !$note or !$note.valid?



module Geometry_Monitor
  @@l_sel=[]
  @@last_states={}

  def Geometry_Monitor.reset_timer()
    $note=Sketchup.active_model.add_note("note",0.05,0.05) if !$note or !$note.valid?
    begin
      UI.stop_timer($timer)
      p "$timer stopped:#{$timer}"
    rescue
      p "no existing $timer, start new $timer"
    end

    $timer=UI.start_timer(0.1,true){
      begin
        self.default_action
      rescue
        p $!.message
        p $!.backtrace
        UI.stop_timer($timer)
      end
    }
  end

  def Geometry_Monitor.default_action
    sel=Sketchup.active_model.selection
    sel=self.filter_group(sel)
    if sel.size<1
      $note.text=""
      return
    end

    #if selection changed
    if @@l_sel!=sel
      @@l_sel=sel.clone
      self.on_select()
    #normal state
    else
      self.normal_update()
    end
  end

  def Geometry_Monitor.filter_group(ents)
    output=[]
    ents.each{|e|
      output<<e if e.is_a? Sketchup::Group
    }
    return output
  end

  def Geometry_Monitor.on_select()
    p "selected #{@@l_sel.size} geometries"
    @@last_states={}
    for g in @@l_sel
      @@last_states[g]=self.getParams(g)
    end

    wd=WD_Interact.singleton
    wd.onSelectionBulkChange(@@l_sel)

  end

  def Geometry_Monitor.normal_update()
    notetxt=""
    for g in @@l_sel
      states=self.getParams(g)
      signs=['-']*3
      for i in 0..2
        if states[i] != @@last_states[g][i]
          signs[i]='+'
        end
      end
      @@last_states[g]=states
      txt="#{ArchUtil.short_id(g)}[#{signs[0]},#{signs[1]},#{signs[2]}]"
      notetxt+=txt+' | '
      # if signs.include? '+'
      #   p notetxt
      # end

      if signs[0]=='+' or signs[1]=='+'
        self.invalidate_building(g)
      end
    end
    $note.text=notetxt
  end

  def Geometry_Monitor.invalidate_building(g)
    bb=Proto_Apt.created_objects[g]
    bb.invalidate() if (bb)
  end

  def Geometry_Monitor.getParams(g)
    gt=g.transformation
    scl=[gt.xscale,gt.yscale,gt.zscale]
    rot=[gt.rotx,gt.roty,gt.rotz]
    loc=gt.origin.to_a
    return scl,rot,loc
  end

end

$m=Geometry_Monitor