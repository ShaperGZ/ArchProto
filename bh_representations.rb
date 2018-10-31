
class BH_Representations < Arch::BlockUpdateBehaviour
  attr_accessor :current_mode
  def initialize(gp,host)
    super(gp,host)
    @view_modes=[
        'Norm',
        'Ornt',
        'Unit'
    ]
  end

  def set_view_mode(modestr)
    current_mode=modestr
  end

  def invalidate()
    @abstract_geometries=[]

    if current_mode=='Norm'
      normal_mode()
    elsif current_mode=='Ornt'
      orientation_mode()
    elsif current_mode=='Unit'
      unit_mode()
    end
  end

  def normal_mode()

  end

  def orientation_mode()

  end

  def unit_mode()

  end
end