class BH_Bays < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
  end

  def invalidate()
    composition=@host.get_updator_by_type(BH_Apt_Composition)
    abs_geo=composition.abstract_geometries
    ocupies=[]

    @abstract_geometries=[]
    for g in abs_geo
      if g.name[0]=='O'
        ocupies<<g
        @abstract_geometries<<gen_bays(g)
        # @abstract_geometries<<dup_geo_to_comp(g)
      end
    end
    p "bay counts = #{@abstract_geometries.size}"
    _add_all_abs_to_one()
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


    # /////////////////////////////////////////////////
    # following is not working, need to add AbsComposit
    # /////////////////////////////////////////////////
    vx=Geom::Vector3d.new(bw,0,0)
    vy=Geom::Vector3d.new(0,bd,0)
    vz=Geom::Vector3d.new(0,0,bh)
    composit=MeshUtil::AttrComposit.new
    composit.size=g.size
    composit.rotation=g.rotation
    # composit.reflection=g.reflection
    composit.position=g.position
    for i in 0..countw-1
      for j in 0..counth-1
        p = org+ Geom::Vector3d.new(i*bw,0,j*bh)
        s = [bw,bd,bh]
        # composit.add_box(p,s,0)
        pts=[]
        pts << p
        pts << p + vx
        pts << pts[1] + vz
        pts << p + vz
        pts.reverse! if flip <0

        composit.add_polygon(pts)
      end
    end
    return composit
  end

end