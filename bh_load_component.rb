class BH_Load_component< Arch::BlockUpdateBehaviour
  attr_accessor :instances
  attr_accessor :creation_queue
  def initialize(gp,host)
    super(gp,host)
    @instances=[]
    # creation_queue sample:
    # [[abs_geo,definition],...]
    @creation_queue=[]
  end

  def invalidate()
    @creation_queue=[]
    # create concrete geometry if not exist
    # use concrete_geometry[0] as container for instances
    # set transform to unit transform
    init_concrete_geo
    load_def_evac
    update_instances
    un_scale_concrete_geometries
  end

  def init_concrete_geo
    if @concrete_geometries.size==0
      g=@gp.entities.add_group
      @concrete_geometries<<g
    end
    if !@concrete_geometries[0].valid?
      g=@gp.entities.add_group
      @concrete_geometries[0]=g
    end
    @concrete_geometries[0].transformation=Geom::Transformation.new
  end

  def un_scale_concrete_geometries
    gt=@gp.transformation
    xs=gt.xscale
    ys=gt.yscale
    zs=gt.zscale
    # tr=Geom::Transformation.rotation([0,0,0],Geom::Vector3d.new(0,0,1),gt.rotz.degrees)
    # tri=Geom::Transformation.rotation([0,0,0],Geom::Vector3d.new(0,0,1),-gt.rotz.degrees)
    ti = ArchUtil.Transformation_scale_3d([1/xs,1/ys,1/zs])

    g=@concrete_geometries[0]
    g.transformation=Geom::Transformation.new
    g.transform! ti
  end

  def update_instances()
    # 1 match instances size
    p "@instances=#{@instances.class} @creation_queue=#{@creation_queue.class}"
    diff = @instances.size-@creation_queue.size
    # 1.1 remove extra instances
    if diff>0
      g=@instances[-1]
      @instances.delete(g)
      g.erase!
    end
    # 1.2 update or add missing containers
    # here has to incorporate add with update
    # because adding an instance requires a proper definition
    p "========= update isntance ========"
    inst_count=@instances.size
    for i in 0..@creation_queue.size-1
      arr=@creation_queue[i]
      abs=arr[0]
      definition=arr[1]
      # p "definition is #{definition.class}"
      if i>=@instances.size
        ins=@concrete_geometries[0].entities.add_instance(definition,Geom::Transformation.new)
        @instances<<ins
      else
        ins=@instances[i]
        ins.definition=definition if ins.definition!=definition
      end

      trans_offset=Geom::Transformation.translation(abs.position)
      trans_rotate=Geom::Transformation.rotation([0,0,0],[0,0,1],abs.rotation.degrees)
      trans_reflect=ArchUtil.Transformation_scale_3d(abs.reflection)
      ins.transformation=Geom::Transformation.new
      ins.transform! trans_reflect
      ins.transform! trans_rotate
      ins.transform! trans_offset
    end
  end

  def grid_position(position)

    un_width=@host.attr("un_width")
    bh_bays=@host.get_updator_by_type(BH_Bays)
    grid=bh_bays.basic_floor_grid
    closest=un_width.m
    closestpos=nil
    # p "bh_bays=#{bh_bays} grid=#{grid}"
    for cluster in grid.clusters.values
      # p "cluster=#{cluster.name} units count=#{cluster.units.size}"
      for unit in cluster.units
        refpos=unit.geometry.position.clone
        vect=unit.geometry.vects[1].clone
        vect.length=unit.geometry.size[1]
        nrefpos=refpos+vect
        nrefpos[2]=position[2]
        # p "cluster=#{cluster.name} refpos=#{refpos} vect=#{vect} nrefpos=#{nrefpos}"
        # d=nrefpos.distance(position)
        nrefpos=Geom::Point3d.new(*nrefpos)
        d=nrefpos.distance(Geom::Point3d.new(*position))
        # p " >>>>> NOT FOUND d=#{d} position=#{position} return:#{nrefpos}"
        if d<closest
          closest = d
          closestpos=nrefpos.clone
        end
        # if d<(un_width.m)
        #   p " >>>>> FOUND d=#{d} position=#{position} return:#{nrefpos}"
        #   return nrefpos
        # end
      end
    end
    return closestpos if closestpos!=nil
    return position
  end

  def load_def_evac
    bh_evac=@host.get_updator_by_type(BH_Evacuation)
    str_cores=bh_evac.str_cores
    lft_cores=bh_evac.lft_cores
    bd_height=@host.attr("bd_height")
    crd_width=2.m

    # load skp definitions for each cores
    str_def=ArchComponents.get_definition('core_apt_str.skp')
    lft_def=ArchComponents.get_definition('core_apt_lft_L3.skp')

    for c in str_cores
      # p "c.position=#{c.position}"
      vecty=c.vects[1].clone
      vectx=c.vects[0].clone
      vecty.length=crd_width
      # p "pre add pos=#{c.position} post:#{c.position+vecty}"

      minors_length=str_def.bounds.min[0]
      vectx.length=minors_length
      # align with edge not pos
      c.position=grid_position(c.position+vecty-vectx)
      # correct the pos from the edge
      c.position += vectx

      @creation_queue<<[c,str_def]
    end

    for c in lft_cores
      # p "c.position=#{c.position}"
      vecty=c.vects[1].clone
      vectx=c.vects[0].clone
      vecty.length=crd_width
      # p "pre add pos=#{c.position} post:#{c.position+vecty}"

      minors_length=str_def.bounds.min[0]
      vectx.length=minors_length
      # align with edge not pos
      c.position=grid_position(c.position+vecty-vectx)
      # correct the pos from the edge
      c.position += vectx

      @creation_queue<<[c,lft_def]
    end
  end

  def load_def_evac_bak()
    bh_evac=@host.get_updator_by_type(BH_Evacuation)
    str_cores=bh_evac.str_cores
    lft_cores=bh_evac.lft_cores
    bd_height=@host.attr("bd_height")

    # load skp definitions for each cores
    str_def=ArchComponents.get_definition('core_apt_str.skp')
    lft_def=ArchComponents.get_definition('core_apt_lft_L3.skp')

    for c in str_cores
      geos=MeshUtil.create_from_definition(str_def)
      for g in geos
        # p "g is a #{g.class}"
        g.size[2]=(bd_height+3).m
        g.position=c.attributes['true_position']
        g.rotation=c.rotation
      end
      @abstract_geometries+=geos
    end
    for c in lft_cores
      geos=MeshUtil.create_from_definition(lft_def)
      for g in geos
        g.size[2]=(bd_height+3).m
        g.position=c.attributes['true_position']
        g.rotation=c.rotation
      end
      @abstract_geometries+=geos
    end



  end
end