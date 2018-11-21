

class BH_Bays < Arch::BlockUpdateBehaviour
  attr_accessor :unitClusters
  # keep all units by: floors[]
  #                   each contains clusters[]
  #                   each contains units

  attr_accessor :typical_floors
  attr_accessor :basic_floor_grid
  attr_accessor :floor_instances
  attr_accessor :xaxis
  attr_accessor :yaxis

  def initialize(gp,host)
    #p 'f=initialized constrain face'
    @unitClusters=[]
    @units_oriented=Hash.new()
    @typical_indices=[1]
    super(gp,host)
  end

  def invalidate()
    # 1 generate floor grid
    generate_floor_grid()

    # 2 generate floors
    generate_floors()

    # 3(temp) add_model
    add_model()
  end

  # def invalidate2()
  #   @typical_floors=Hash.new()
  #   @floors=[]
  #   t1=Time.now
  #   composition=@host.get_updator_by_type(BH_Apt_Composition)
  #   abs_geo=composition.abstract_geometries
  #   ocupies=[]
  #   @unitClusters=[]
  #   if @concrete_geometries.size>0
  #     g=@concrete_geometries[0]
  #     if g.is_a? Sketchup::Entity and g.valid?
  #       g.entities.clear!
  #     end
  #   end
  #
  #   @abstract_geometries=[]
  #   for g in abs_geo
  #     if g.name[0]=='O'
  #       ocupies<<g
  #       bay=gen_bays(g)
  #       @abstract_geometries<<bay
  #       @abstract_geometries<<gen_flr_cuts(g)
  #
  #       # @abstract_geometries<<dup_geo_to_comp(g)
  #     end
  #   end
  #   # p "bay counts = #{@abstract_geometries.size}"
  #   expansive_update
  #   t2=Time.now
  #   p "BH_Bays.invalidate took #{t2-t1} seconds"
  # end

  def generate_floor_grid()
    # 1 create planes along X,Y axies
    x_axis,y_axis=create_axies
    @xaxis,@yaxis=x_axis,y_axis
    # p "xaxis:#{x_axis}"
    # p "yaxis:#{y_axis}"

    # 2 get composition abs geos
    occupies=get_composition_geos

    # 3 create unit cluster for each composition geos
    floor = ArchProto::Floor.new()
    for g in occupies
      x_axis_names=['O1','O2','O8','O7']
      y_axis_names=['O3','O4','O5','O6']
      direction='x'
      if x_axis_names.include? g.name
        axis=x_axis.clone
        if ['O8','O7'].include? g.name
          direction='x_inverse'
        end
      else
        axis=y_axis.clone
        if ['O3','O4'].include? g.name
          direction='y_inverse'
        else
          direction='y'
        end
      end
      cluster=create_cluster(g, axis, direction,@host.attr('bd_height'))
      cluster.name=g.name
      floor.add_cluster(cluster)
    end
    @basic_floor_grid=floor
  end

  def generate_floors()
    # this demo has only one typical floor
    t1=@basic_floor_grid.clone
    count=(@host.attr('bd_height')/3).floor.to_i
    levels=[]
    for i in 0..count-1
      levels<<3*i
    end
    t1.levels=levels
    t1.floor_number=1
    @typical_floors=[t1]

  end

  def create_axies()
    # operate in meters
    x_axis=[]
    y_axis=[]

    bd_width=@host.attr('bd_width')
    bd_depth=@host.attr('bd_depth')
    un_width=@host.attr('un_width')

    ttl=0
    while ttl<=bd_width-un_width
      x_axis<<ttl
      ttl+=un_width
    end
    x_axis<<bd_width

    ttl=0
    while ttl<=bd_depth-un_width
      y_axis<<ttl
      ttl+=un_width
    end
    y_axis<<bd_depth
    return x_axis,y_axis
  end

  def get_composition_geos()
    composition=@host.get_updator_by_type(BH_Apt_Composition)
    abs_geo=composition.abstract_geometries
    occupies=[]
    for g in abs_geo
      if g.name[0]=='O'
        occupies<<g
      end
    end
    return occupies
  end

  def create_or_get_definition(name)
    Sketchup.active_model.definitions.each{|d|
      if d.name==name
        return d
      end
    }

    d=Sketchup.active_model.definitions.add(name)
    return d
  end

  def add_model()
    # 1 add definition for each typical floor
    tf_queue=@typical_floors
    for i in 0..tf_queue.size-1
      tf=tf_queue[i]
      # 1.1 create or get ref of definition
      def_name=@gp.guid+"_typical_flr_#{i}"
      definition=create_or_get_definition(def_name)
      tf.definition=definition

      # 1.2 update the definition with given tf (typical floor)
      composit=MeshUtil::AttrComposit.new()
      for cluster in tf.clusters.values
        for unit in cluster.units
          composit.add(unit.geometry.mesh)
        end
      end
      definition.entities.clear!
      mesh=composit.mesh
      definition.entities.add_faces_from_mesh(mesh,0)
    end

    # 2 add instances for each typical floor
    # 2.1 cal the total instance required
    ttl_ins_required=0
    for tf in tf_queue
      ttl_ins_required+= tf.count
    end

    # 2.2 match instance length
    # 2.2.1 create array if not exist
    @floor_instances=[] if @floor_instances==nil

    #       remove all invalid instance
    tbd=[]
    for ins in @floor_instances
      tbd<<ins if ins ==nil or (ins.is_a? Sketchup::ComponentInstance and !ins.valid?)
    end
    for t in tbd
     @floor_instances.delete(t)
    end

    # 2.2.2 remove extra instances
    if @floor_instances.size>ttl_ins_required
      diff = @floor_instances.size - ttl_ins_required
      for i in 1..diff
        ins=@floor_instances[-1]
        ins.erase!
        @floor_instances.delete(ins)
      end
    end

    # 2.2.3 update or add extra instances
    count=0
    # Iterate each typical floor
    for tf in tf_queue
      definition=tf.definition
      # Iterate each floor instance that belongs to the typical floor

      for h in tf.levels
        #create instance if missing
        if count>=@floor_instances.size
          ins=@gp.entities.add_instance(definition,Geom::Transformation.new())
          p "added #{ins}"
          @floor_instances<<ins
        end

        ins=@floor_instances[count]
        p "count:#{count} floor_instances.size:#{@floor_instances.size} ins:#{ins}"
        # transform the new instance vertically
        # instances should ne positioned at (0,0,h)
        tr=Geom::Transformation.translation([0,0,h.m])
        ins.transformation=Geom::Transformation.new
        ins.transform! tr
        _untransform_internal_entity(ins)
        count+=1

      end
    end
  end

  def expansive_update()
    # t1=Time.now
    # # _add_all_abs_to_one
    # _refresh_concrete_geometries
    # t2=Time.now
    # p "BH_Bays.expansive_update took #{t2-t1} seconds"
  end

  def dup_geo_to_comp(geo)
    comp=MeshUtil::AttrComposit.new
    comp.add(geo.mesh)
    return comp
  end

  def create_cluster(g, axis, direction, h=0) # returns a cluster
    axis=axis.clone
    h=h.m
    mw=g.size[0]
    md=g.size[1]
    mh=g.size[2]

    org=Geom::Point3d.new
    unwidth=@host.attr('un_width').m

    countw=axis.size



    if direction.include? 'x'
      w_str=g.position[0].to_m
      vect=Geom::Vector3d.new(1,0,0)
    else
      w_str=g.position[1].to_m
      vect=Geom::Vector3d.new(0,1,0)
    end

    if direction.include? 'inverse'
      inversed = true
      axis.reverse!
      vect.reverse!
      sign=-1
    else
      inversed=false
      sign=1
    end

    un_width=@host.attr('un_width')
    un_depth=@host.attr('un_depth')
    un_height=3
    w_max=(g.size[0].to_m * sign) +w_str

    # ////////////////////////////
    # ////// new iteration ///////
    # ////////////////////////////

    total_offset=0
    creation_queue=[]
    islast=false

    # p "------#{g.name}----------"
    # p "axis=#{axis}"
    # p "str:#{w_str} max:#{w_max} g.size=(#{g.size[0].to_m} x #{g.size[1].to_m})"
    for i in 0..axis.size-1
      knot=axis[i]
      break if islast
      if !inversed
        # 0 1 2 3 4 5 6
        #   1            8
        next if knot<=w_str
        islast = true if knot > w_max
      else
        # 6 5 4 3 2 1 0
        #   5     2.5
        next if knot>=w_str
        islast =true if knot<w_max
      end

      if islast
        w=(w_max-w_str).abs
      else
        w=(knot-w_str).abs
      end

      # next if w<un_width/2
      offset=vect.clone
      offset.length=total_offset.m
      pos=g.position+offset

      size=[w.m,un_depth.m,un_height.m]
      creation_queue<<[pos,size]
      # p "pos:#{pos} size:#{size[0].to_m} islast:#{islast}"
      w_str=knot
      total_offset+=w
    end

    cluster=ArchProto::Cluster.new()
    cluster.parent_geometry=g
    cluster.cal_orientation(@gp)

    for c in creation_queue
      pos=c[0]
      size=c[1]
      unit_geo=MeshUtil::AttrBox.new()
      unit_geo.position=pos
      unit_geo.size=size
      unit_geo.reflection=g.reflection.clone
      unit_geo.rotation=g.rotation
      unit=ArchProto::Unit.new(unit_geo)
      cluster.add_unit(unit)
    end

    return cluster
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