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
      b.invalidate()
      return b
    end
  end

  def self.create_from_selection(gp=nil)
    if gp==nil
      gp = Sketchup.active_model.selection[0]
    end
    proto=Proto_Apt.create_or_get(gp,'Params.csv',true)
    return proto
  end

  def initialize(g,param_file)
    p "start creation ------------------"
    super(g,param_file)

    # TODO: set the default g_composition
    @g_composition=BH_Apt_Composition.new(g,self)
    @g_evacuation=BH_Evacuation.new(g,self)
    @g_area=BH_Apt_Area.new(g,self)
    @g_update_web_scores=BH_Update_Web_Scores.new(g,self)

    @updators << BH_Dimension.new(g,self)
    @updators << @g_composition
    @updators << @g_evacuation
    @updators << BH_Bays.new(g,self)
    @updators << @g_area
    @updators << @g_update_web_scores
  end

  def set_gen_composition(behavior)
    index=@updators.index(@g_composition)
    @g_composition=behavior
    @updators[index]=@g_composition
  end

end