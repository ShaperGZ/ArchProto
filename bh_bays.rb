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
      end
    end
    p "bay counts = #{@abstract_geometries.size}"
    _add_all_abs_to_one()
  end

  def gen_bays(g)
    mw=g.size[0]
    md=g.size[1]
    mh=g.size[2]
    org=g.position
    org=Geom::Point3d.new(org.x,org.y,org.z)

    countw= (mw/3.m).round
    counth= (mh/3.m).round
    bw=mw/countw
    bh=mw/counth
    bd=md

    # /////////////////////////////////////////////////
    # following is not working, need to add AbsComposit
    # /////////////////////////////////////////////////
    vx=Geom::Vector3d.new(bw,0,0)
    vy=Geom::Vector3d.new(0,bd,0)
    vz=Geom::Vector3d.new(0,0,bh)
    composit=MeshUtil::AttrComposit.new
    for i in 0..countw
      for j in 0..counth
        p = org+ Geom::Vector3d.new(i*bw,bd,j*bh)
        s = [bw,bd,bh]
        # composit.add_box(p,s,0)
        pts=[]
        pts << p
        pts << p + vx
        pts << pts[1] + vz
        pts << p + vz

        composit.add_polygon(pts)
      end
    end
    return composit
  end

end