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
    param=[]

    for tf in bays.typical_floors
      for cluster in tf.clusters.values
        # pivot=cluster.parent_geometry.position
        # pivot = Geom::Point3d.new(pivot[0],pivot[1],pivot[2])
        # angle=cluster.parentAttrGeo.rotation
        # tr=Geom::Transformation.rotation(pivot,Geom::Vector3d.new(0,0,1),angle.degrees)
        # pivot = Geom::Vector3d.new(pivot[0],pivot[1],pivot[2])

        # get unit color base on orientation
        # # south and west factor
        sf=1-cluster.south_factor
        wf=1-cluster.west_factor

        # orientation scores
        possible_min=0.25
        score=possible_min+sf-(wf/2)
        color=ArchUtil.colorScale([[1,0.3,0.2],[1,1,0.2],[0.3,1,0.2]],[0,1],score)

        units=cluster.units
        for unit in units
          # pos=Geom::Vector3d.new(unit.position[0],unit.position[1],unit.position[2])
          # pos=(tr*pos) + pivot
          # pos = vector_add pos, @gp.bounds.min
          pos=unit.geometry.position
          size=unit.geometry.size

          pos=vector_to_m pos
          size = vector_to_m unit.size, cluster.parent_geometry.reflection
          for i in 0..2
            size[i]-=0.5
          end
          # rot=angle
          rot=unit.geometry.rotation
          param<<[pos,size,rot,color]
        end
      end
    end
    msg="add_boxes(#{param.to_s})"
    wd.execute_script(msg)
  end

  def vector_add(v1,v2)
    v=[0,0,0]
    for i in 0..2
      v[i]=v1[i]+v2[i]
    end
    return v
  end
  def vector_scale3d(v1,v2)
    v=[0,0,0]
    for i in 0..2
      v[i]=v1[i]*v2[i]
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
  def reverse_scale(v1)
    v=[1,1,1]
    for i in 0..2
      v[i]=1/v1[i]
    end
    return v;
  end


end