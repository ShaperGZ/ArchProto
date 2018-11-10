class BH_Update_WebGL < Arch::BlockUpdateBehaviour

  def initialize(gp,host)
    super(gp,host)
  end

  def invalidate()

    wd=WD_Interact.singleton
    wd.gl_enable_update(false)
    wd.gl_clear_all()

    # update_composition(wd)
    update_units(wd)
    wd.gl_enable_update(true)
  end

  def update_composition(wd)
    composition= @host.get_updator_by_type(BH_Apt_Composition)

    geos=composition.abstract_geometries
    occupies=[]
    corridors=[]
    for g in geos
      if g.name.include? 'O'
        occupies<<g
      elsif g.name.include? 'C'
        corridors<<g
      end
    end
    wd.gl_add_boxes(occupies,[0.2,1,1])
    wd.gl_add_boxes(corridors,[1,0.7,0])

  end

  def update_units(wd)
    bays=@host.get_updator_by_type(BH_Bays)
    clusters=bays.unitClusters
    boxes=[]
    param=[]
    color1=[1,1,1]
    for cluster in clusters
      units=cluster.units
      for unit in units
        pos=vector_add unit.position,cluster.parentAttrGeo.position
        pos=vector_to_m pos
        size = vector_to_m unit.size, cluster.parentAttrGeo.reflection
        for i in 0..1
          size[i]-=0.5
        end
        rot=unit.rotation+cluster.parentAttrGeo.rotation

        param<<[pos,size,rot,color1]
      end
    end
    msg="add_boxes(#{param.to_s})"
    # p msg
    wd.execute_script(msg)
  end

  def vector_add(v1,v2)
    v=[0,0,0]
    for i in 0..2
      v[i]=v1[i]+v2[i]
    end
    return v
  end
  def vector_to_m(v,reflect=[1,1,1])
    outVect=[1,1,1]
    for i in 0..2
      outVect[i] = v[i].to_m * reflect[i]
    end
    return outVect
  end
end