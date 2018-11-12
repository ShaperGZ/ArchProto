class Unit
  attr_accessor :area
  attr_accessor :attrGeo
  attr_accessor :cluster
end

class UnitCluster
  attr_accessor :south_factor
  attr_accessor :west_factor
  attr_accessor :parentAttrGeo
  attr_accessor :units

  def initialize
    @units=[]
  end

  def size
    if @units.is_a? Array
      return @units.size
    end
    return 0
  end

  def cal_orientation(container)
    r=parentAttrGeo.rotation
    if parentAttrGeo.reflection[1]==-1
      r+=180
      r=360-r if r>180
    end

    p "cluster.r=#{r}"
    r+=container.transformation.rotz
    sr = r
    wr = r + 90
    wr=360-wr if wr>180
    @south_factor=sr.abs/180.0
    @west_factor=wr.abs/180.0
    p "    --- r=#{r} sr.abs=#{sr.abs} south_factor=#{@south_factor} west_factor=#{@west_factor}"
  end
end

class BH_Bays < Arch::BlockUpdateBehaviour
  attr_accessor :unitClusters
  def initialize(gp,host)
    #p 'f=initialized constrain face'
    @unitClusters=[]
    @units_oriented=Hash.new()
    super(gp,host)
  end

  def invalidate()
    t1=Time.now
    composition=@host.get_updator_by_type(BH_Apt_Composition)
    abs_geo=composition.abstract_geometries
    ocupies=[]
    @unitClusters=[]
    if @concrete_geometries.size>0
      g=@concrete_geometries[0]
      if g.is_a? Sketchup::Entity and g.valid?
        g.entities.clear!
      end
    end

    @abstract_geometries=[]
    for g in abs_geo
      if g.name[0]=='O'
        ocupies<<g
        bay=gen_bays(g)
        @abstract_geometries<<bay
        @abstract_geometries<<gen_flr_cuts(g)

        # @abstract_geometries<<dup_geo_to_comp(g)
      end
    end
    # p "bay counts = #{@abstract_geometries.size}"
    expansive_update
    t2=Time.now
    p "BH_Bays.invalidate took #{t2-t1} seconds"
  end

  def expansive_update()
    t1=Time.now
    # _add_all_abs_to_one
    _refresh_concrete_geometries
    t2=Time.now
    p "BH_Bays.expansive_update took #{t2-t1} seconds"
  end

  def orient_units()

  end

  def dup_geo_to_comp(geo)
    comp=MeshUtil::AttrComposit.new
    comp.add(geo.mesh)
    return comp
  end

  def gen_bays(g)
    mw=g.size[0]
    md=g.size[1]
    mh=g.size[2]

    # org=g.position
    # org=Geom::Point3d.new(org.x,org.y,org.z)
    org=Geom::Point3d.new

    countw= (mw/3.0.m).round
    counth= (mh/3.0.m).round
    bw=mw/countw
    bh=mh/counth
    # p "bw:#{bw.to_m} bh:#{bh.to_m}"
    bd=md
    flip=g.reflection[0] * g.reflection[1] * g.reflection[2]

    cluster=UnitCluster.new()
    cluster.parentAttrGeo=g
    cluster.cal_orientation(@gp)
    cluster.units=[]

    r=g.rotation
    r+=@gp.transformation.rotz
    p "cluster rot:#{r}"

    vx=Geom::Vector3d.new(bw,0,0)
    vy=Geom::Vector3d.new(0,bd,0)
    vz=Geom::Vector3d.new(0,0,bh)
    composit=MeshUtil::AttrComposit.new
    composit.size=g.size
    composit.rotation=g.rotation
    p "g.rotation=#{g.rotation}"
    composit.reflection=g.reflection
    composit.position=g.position



    for i in 0..countw-1
      for j in 0..counth-1
        # this p is orthogontal, transformation will be applied to the master geometry
        p = org+ Geom::Vector3d.new(i*bw,0,j*bh)
        s = [bw,bd,bh]

        # attr geo for unit
        unit=MeshUtil::AttrBox.new
        unit.size=s.clone

        unit.position=p
        unit.rotation=0
        unit.reflection=[1,1,1]
        cluster.units<<unit

        # composit.add_box(p,s,0)
        pts=[]
        pts << p
        pts << p + vx
        pts << pts[1] + vz
        pts << p + vz
        pts.reverse! if flip <0

        # composit.add_polygon(pts)
        if j==counth-1
          top=[]
          top<<p + vz
          top<<top[0] + vx
          top<<top[1] + vy
          top<<top[2] - vx
          top.reverse! if flip <0
          composit.add_polygon(top)
        end
      end
    end

    @unitClusters<<cluster

    return composit
  end

  # temporary gen flr cuts to show floors
  def gen_flr_cuts(g)
    cuts=MeshUtil::AttrComposit.new
    # cuts.rotation=g.rotation
    # cuts.reflection=g.reflection
    # cuts.position=g.position
    height=g.size[2]
    counts=height/3.m
    for i in 0..counts-1
      z=i*3.m
      pln=[[0,0,z],[0,0,-1]]
      # p "g.mesh is a #{g.mesh.class}"
      l,r,c=MeshUtil.split_mesh(pln,g.mesh)
      cuts.add_polygon(c)
    end
    return cuts

  end

end