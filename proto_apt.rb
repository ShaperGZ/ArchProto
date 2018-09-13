load 'd:/SketchupRuby/Prototype/building_block.rb'


class Proto_Apt < BuildingBlock

  def self.create_or_get(g,param_file=nil,invalidate_created=true)
    self.remove_deleted()
    if @@created_objects.key?(g.guid)
      block=@@created_objects[g.guid]
      block.invalidate() if invalidate_created
      return block
    else
      b=Proto_Apt.new(g,param_file)
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


    @updators << BH_Dimension.new(g,self)
    @updators << BH_ReadAttrToMemory.new(g,self)
    @updators << @g_composition
  end


  def set_gen_composition(behavior)
    index=@updators.index(@g_composition)
    @g_composition=behavior
    @updators[index]=@g_composition;
  end




end