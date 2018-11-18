# load 'd:/SketchupRuby/Prototype/building_block.rb'


class Proto_Apt < BuildingBlock

  def self.created_objects
    @@created_objects=Hash.new if @@created_objects == nil
    return @@created_objects
  end

  def self.create_or_get(g,param_file=nil,invalidate_created=false)
    self.remove_deleted()
    if Proto_Apt.created_objects().key?(g.guid)
      block=Proto_Apt.created_objects[g.guid]
      block.invalidate() if invalidate_created
      return block
    else
      p "creating a Proto_Apt instance"
      b=Proto_Apt.new(g,param_file)
      Proto_Apt.created_objects[g.guid]=b

      g.set_attribute("OperableStates","entrance_number",1)
      comp_arr=[["cb_double", false], ["cb_L-shape", true], ["cb_U-shape", false], ["cb_O-shape", false]]
      g.set_attribute("OperableStates","composition",comp_arr)

      b.invalidate()

    end
  end

  def self.create_from_selection(gp=nil)
    if gp==nil
      gp = Sketchup.active_model.selection[0]
    end
    proto=Proto_Apt.create_or_get(gp,'Params.csv',true)
    wd=WD_Interact.singleton
    wd.subjectGP=gp
    wd.subjectBB = proto
    wd.set_web_param(proto)
    return proto
  end

  def initialize(g,param_file)
    p "start creation ------------------"
    super(g,param_file)
    hide_nongroup(g)

    # TODO: set the default g_composition

    @updators << BH_Dimension.new(g,self)
    @updators << @g_composition=BH_Apt_Composition.new(g,self)
    @updators << @g_evacuation=BH_Evacuation.new(g,self)
    @updators << BH_Bays.new(g,self)
    @updators << BH_Orientation.new(g,self)
    @updators << @g_area=BH_Apt_Area.new(g,self)
    @updators << BH_Load_component.new(g,self)
    @updators << BH_Update_WebGL.new(g,self)
    @updators << @g_update_web_scores=BH_Update_Web_Scores.new(g,self)
  end

  def hide_nongroup(g)
    g.entities.each{|e|
      if !(e.is_a? Sketchup::Group or e.is_a? Sketchup::ComponentInstance)
        e.visible=false
      end
    }
  end


  def set_gen_composition(behavior)
    index=@updators.index(@g_composition)
    @g_composition=behavior
    @updators[index]=@g_composition
  end

end