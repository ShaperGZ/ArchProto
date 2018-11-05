
class BH_Representations < Arch::BlockUpdateBehaviour
  attr_accessor :current_mode
  def initialize(gp,host)
    super(gp,host)
    @view_modes=[
        'Norm',
        'Ornt',
        'Unit'
    ]
    scale_colors=[
        [200,80,80],
        [255,255,80],
        [80,255,80]
    ]
    @color_scale=ArchUtil::ColorScale.new(scale_colors,[0,1])
    @current_mode='Ornt'
  end

  def set_view_mode(modestr)
    current_mode=modestr
  end

  def invalidate()
    @abstract_geometries=[]

    if @current_mode=='Norm'
      normal_mode()
    elsif current_mode=='Ornt'
      orientation_mode()
    elsif current_mode=='Unit'
      unit_mode()
    end
    _refresh_concrete_geometries()
  end

  def normal_mode()

  end

  def orientation_mode()
    bh_bay=@host.get_updator_by_type(BH_Bays)
    clusters=bh_bay.unitClusters
    for cluster in clusters
      units=cluster.units

      geo=MeshUtil::AttrComposit.new
      for unit in units
        p1=unit.position
        p2=[p1.x+1.m,p1.y,p1.z]
        p3=[p1.x+0.5.m,p1.y-1.m,p1.z]
        geo.add_polygon([p1,p2,p3])
      end
      @abstract_geometries<<geo
    end

  end

  def unit_mode()

  end
end