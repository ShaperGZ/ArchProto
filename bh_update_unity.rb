class BH_UpdateUnity
  attr_accessor :added_objects
  def initialize()
    @added_objects=[]
  end

  def update()
    return if !ArchServer.valid?

    # 1 clear last added_objects
    clear_objects

    # 2 add new objects and record to @added_objects
    composition=@host.get_updator_by_type(BH_Apt_Composition)
    composition.abstract_geometries.each{|g|
      if g.is_a? MeshUtil::AttrBox
        Encriptor.abs_box(b)
        @added_objects<<b
      end
    }
  end

  def clear_objects()
    Encriptor.deleteRange(@added_objects)
    @added_objects=[]
  end

end