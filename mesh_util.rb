module MeshUtil


  class AttrGeo
    # attr_accessor :position
    attr_accessor :size
    # attr_accessor :rotation
    # attr_accessor :vects
    attr_accessor :name
    attr_accessor :attributes
    attr_accessor :color
    attr_accessor :alignment
    # attr_accessor :reflection
    attr_accessor :bounds
    attr_accessor :children

    def initialize()
      @position=[0,0,0]
      @size=[1,1,1]
      @rotation=0
      @color="white"
      @bounds=[]
      @reflection=[1,1,1]
      @vects=[
          Geom::Vector3d.new(1,0,0),
          Geom::Vector3d.new(0,1,0),
          Geom::Vector3d.new(0,0,1)
      ]
      @name= ""
      @alignment= Alignment::SW
      @attributes= Hash.new
      @parent=nil
      @children=[]
    end

    def set_pos(pos)
      @position=pos
      return self
    end

    def position
      return @position
    end

    def position=(pos)
      if pos.is_a? Array
        pos=Geom::Point3d.new(pos)
      end
      @position=pos
    end

    def rotation(parent=nil)
      rot=@rotation
      if parent!=nil
        rot+=parent.rotation
      end
      return rot
    end
    def rotation=(rots)
      @rotation=rots
      _set_vects
      #remember to set the vectors
    end

    def reflection
      return @reflection
    end

    def reflection=(reflect)
      # make sure reflection is 1 dimension 3 length array
      # such as [1,1,1]
      if reflect.is_a? Array and reflect.size==2
        reflect<<1
      end
      @reflection=reflect
      _set_vects
    end


    def vects
      out_vects=[]
      out_vects<<@vects[0].clone
      out_vects<<@vects[1].clone
      out_vects<<@vects[2].clone

      return out_vects
    end

    def forward()
      vect=@vects[1].clone
      vect.length*=@reflection[1]
      return vect
    end

    def _set_vects()
      #TODO: vects have reflection
      xvect=Geom::Vector3d.new(1,0,0)
      trans_rotate=Geom::Transformation.rotation([0,0,0],[0,0,1],@rotation.degrees)
      xvect=trans_rotate * xvect
      zvect=Geom::Vector3d.new(0,0,1)
      yvect=zvect.cross xvect
      xvect.length*=@reflection[0]
      yvect.length*=@reflection[1]

      @vects=[xvect,yvect,zvect]
    end

    def set_alignment(alignment)
      @alignment=alignment
      return self
    end

    def set_reflection(reflection)
      @reflection=reflection
      return self
    end

    def mesh(parent=nil)
      return nil
    end

    def parent
      return @parent
    end

    def parent=(parent)
      @parent=parent
      if !parent.children.include? self
        parent.children<<self
      end
    end

    def add(tree)
      children<<tree
      tree.parent=self
    end

    def get_untrans_geo(levels=-1)

    end
    def _untransform(subject,transform)
      # subject: array of [pos,scale,rot]
      # transform: Geom::Transformation
      t = transform
      u_pos=t.origin
      u_scale=[t.xscale,t.yscale,t.zscale]
      u_rot=transform.rotz
      return _untransform_array(subject,[u_pos,u_scale,u_rot])
    end
    def _untransform_array(array,untrans_ref)
      # both inputs are arrays: [ trans, scale, rot]
      output=[[],[],[]]
      # do we need to scale the local position?
      pos = vector_scale3d array[0],untrans_ref[1]
      pos = vector_add pos, untrans_ref[0]
      size = vector_scale3d array[1],reverse_scale(untrans_ref[1])
      rot = array[2] + untrans_ref[2]
      return [pos,size,rot]
    end
    def untransform(abs_geo,untransform_refs)
      # untransform_refs is an array of refs
      # sample untransform_refs:
      # [ cloeset_parent , grand_parent  , third_level_ancestor]
      # [ [pos,scale,rot],[pos,scale,rot],[pos,scale,rot]]
      #
    end

  end

  class AttrComposit < AttrGeo
    attr_accessor :meshes
    attr_accessor :base_vect
    def initialize(meshes=nil)
      super()
      @mesh=Geom::PolygonMesh.new
      # composit takes pure mesh to compose a geometry
      # therefore it doesn't have an orientation
      # will give an orientation manually to calculating bounding box / size
      # default value for this base_vect is (1,0,0)
      @base_vect=Geom::Vector3d.new(1,0,0)
      # set base_rotation= will change the base_vect
      @base_rotation=0

      add(meshes) if meshes.is_a? Geom::PolygonMesh
      add_range(meshes) if meshes.is_a? Array
    end

    def base_vect
      return @base_vect
    end

    def base_rotation
      return @base_rotation
    end

    def base_vect=(val)
      @base_vect=val
    end

    def offet_mesh(param)
      tr=nil
      if param.class == Geom::Vector3d
        tr=Geom::Transformation.translation(vect.to_a)
      elsif param.is_a? Geom::Transformation
        tr=param
      else
        p "offset mesh failed, param must = vector3d or transform"
      end
      @mesh.transform! tr if tr!=nil
    end

    def base_rotation=(val)
      rot=Geom::Transformation.rotation([0,0,0],[0,0,1],val.degrees)
      @base_vect*=rot
    end

    def add_box(pos,size,rot)
      MeshUtil.box(pos,size,rot,@mesh)
    end

    def add_polygon(pts)
      @mesh.add_polygon(pts)
    end

    def add(m,basept=Geom::Point3d.new(0,0,0))
      offset=Geom::Vector3d.new(*basept)
      offset.length*=-1 if offset.length>0
      tr=Geom::Transformation.translation(offset.to_a)
      # m.transform! tr
      for f in m.polygons
        nf=[]
        for i in f
          p= m.points[i-1]
          nf<<tr* p
        end
        @mesh.add_polygon(nf)
      end
    end

    def clone()
      return AttrComposit.new(mesh())
    end

    def add_abs_geometries(geos)
      for g in geos
        add g.mesh
      end
    end

    def add_range(ms)
      for m in ms
        add m
      end
    end

    def size=(val)
      orgsize=size()
      scale=[1,1,1]
      for i in 0..2
        scale[i]=val[i]/orgsize[i]
      end
      m_scale=ArchUtil.scale_3d()

    end

    def vects
      vx=@base_vect.normalize
      vz=Geom::Vector3d.new(0,0,1)
      vy=vz.cross(vx)
      vz=vx.cross(vy)
      return [vx,vy,vz]
    end

    def size
      rot=nil
      if @base_vect.to_a != [1,0,0]
        angle=@base_vect.angle_between(Geom::Vector3d.new(1,0,0))
        rot=Geom::Transformation.rotation([0,0,0],[0,0,1],-angle)
      end

      bbox=Geom::BoundingBox.new
      pts=@mesh.points
      if rot!=nil
        pts=[]
        for p in @mesh.points
          pts<<rot * p
        end
      end
      bbox.add(pts)
      min=bbox.min
      max=bbox.max
      size=[1,1,1]
      for i in 0..2
        size[i]=max[i]-min[i]
      end
      return size
    end

    def mesh
      out_mesh=MeshUtil.clone_mesh @mesh
      trans_reflect=ArchUtil.Transformation_scale_3d(@reflection)
      trans_translate=Geom::Transformation.translation(@position)
      base_rotation=@base_vect.angle_between(Geom::Vector3d.new(1,0,0))
      actual_rotation=@rotation.degrees-base_rotation
      trans_rotate=Geom::Transformation.rotation([0,0,0],[0,0,1],actual_rotation)
      out_mesh.transform! trans_reflect
      out_mesh.transform! trans_rotate
      out_mesh.transform! trans_translate
      return out_mesh
    end
  end

  class AttrExtrusion < AttrGeo
    attr_accessor :base_pts
    attr_accessor :height
    def initialize(pts,h,org=nil)
      super()
      @base_pts = pts
      @height = h
      _offset_pts(org)
      _set_size_from_base()
    end

    def _offset_pts(org)
      org=Geom::Point3d.new() if org==nil
      @offset=org
      @position=Geom::Point3d.new

      # for i in 0..@base_pts.size-1
      #   @base_pts[i]=@base_pts[i]-org
      # end
    end

    def _set_size_from_base()
      pts=@base_pts
      min=pts[0]
      max=pts[0]

      pts.each{|p|
        min.x = p.x if p.x < min.x
        min.y = p.y if p.y < min.y
        max.x = p.x if p.x > max.x
        max.y = p.y if p.y < max.y
      }
      x=max.x-min.x
      y=max.y-min.y
      z=@height
      @size=[x,y,z]
    end

    def clone()
      dup=AttrExtrusion.new(@base_pts,@height)
      dup.position=@position
      dup.vects=@vects
      dup.size=@size
      dup.reflection=@reflection
      dup.rotation=@rotation
      dup.alignment=@alignment
      return dup
    end

    def mesh(parent=nil)
      #reflect, rotate, translate
      #TODO: needs rotation, rotate the base pts first

      flip=(@reflection[0]*@reflection[1]*@reflection[2])<0
      p "flip=#{flip}"
      out_mesh=MeshUtil.extrude_to_mesh_faces(@base_pts,@height,parent,flip)

      trans_reverse_offset=Geom::Transformation.translation(ArchUtil.to_vector3d ArchUtil.vector_scale(@offset,-1))

      trans_reflect=ArchUtil.Transformation_scale_3d(@reflection)
      trans_translate=Geom::Transformation.translation(@position)
      trans_rotate=Geom::Transformation.rotation([0,0,0],[0,0,1],@rotation.degrees)
      out_mesh.transform! trans_reverse_offset
      out_mesh.transform! trans_reflect
      out_mesh.transform! trans_rotate
      out_mesh.transform! trans_translate
      return out_mesh
    end
  end

  class AttrBox < AttrGeo
    def initialize()
      super()
    end

    def area()
      return @size[0]*@size[1]
    end

    def clone()
      dup=AttrBox.new
      dup.position=@position
      dup.vects=@vects
      dup.size=@size
      dup.reflection=@reflection
      dup.rotation=@rotation
      dup.alignment=@alignment
      return dup
    end

    def format(long=false)
      txt=""
      txt+="#{name}: pos=#{@position},size=#{@size},color=#{@color}"
      return txt
    end

    def forward()
      #TODO: calculate forward from rotation and reflection
    end

    def to_extrusion()
      sx=@size[0]
      sy=@size[1]
      sz=@size[2]
      pts=[]
      pts<<@position
      pts<<pts[0] + Geom::Vector3d.new(sx,0,0)
      pts<<pts[0] + Geom::Vector3d.new(sx,sy,0)
      pts<<pts[0] + Geom::Vector3d.new(0,sy,0)
      pts.reverse!
      h=sz

      ext=AttrExtrusion.new(pts,h)
      return ext
    end


    def mesh(parent=nil)
      if @position.is_a? Array
        pos=Geom::Point3d.new(@position)
      else
        pos=@position.clone
      end
      org=pos

      lvects = vects()
      xvect=lvects[0]
      yvect=lvects[1]
      zvect=lvects[2]
      size=@size

      xvect.length=size[0]
      xvecth=xvect.clone()
      xvecth.length=size[0]/2.0

      yvect.length=size[1]
      yvecth=yvect.clone()
      yvecth.length=size[1]/2.0


      case @alignment
      when Alignment::SE
        # SE
        org = pos - xvect
      when Alignment::NE
        # NE
        p "pos:#{pos}, x:#{xvect}, y:#{yvect}"
        p "pos.c:#{pos.class}, x.c:#{xvect.class} y.c:#{yvect.class}"
        org = pos - xvect - yvect
      when Alignment::NW
        # NW
        org = pos - yvect
      when Alignment::E
        # E
        org = pos - xvect - yvecth
      when Alignment::S
        # S
        org = pos - xvecth
      when Alignment::W
        # W
        org = pos - yvecth
      when Alignment::N
        # N
        org = pos - xvecth - yvect
      when Alignment::Center
        org = pos - xvecth - yvecth
      end

      flip=(@reflection[0]*@reflection[1]*@reflection[2])<0
      trans_reflect=ArchUtil.Transformation_scale_3d(@reflection)
      trans_rotate=Geom::Transformation.rotation([0,0,0],[0,0,1],@rotation.degrees)
      trans_translate=Geom::Transformation.translation(pos)

      # m=MeshUtil.box(Geom::Point3d.new,@size,@rotation,parent,flip)
      m=MeshUtil.box(Geom::Point3d.new,@size,0,parent,flip)
      # m=MeshUtil.box(pos,@size,@rotation,parent,flip)

      # m.transform! (trans_reflect * trans_translate)
      m.transform! trans_reflect
      m.transform! trans_rotate
      m.transform! trans_translate
      return m
    end
  end


  def MeshUtil.clone_mesh(m)
    out_mesh=Geom::PolygonMesh.new
    for f in m.polygons
      nf=[]
      for i in f
        nf<< m.points[i-1]
      end
      out_mesh.add_polygon(nf)
    end
    return out_mesh
  end

  def MeshUtil.add_model(mesh,parent=nil,smooth=0)
    if mesh.is_a? Array
      for i in 0..mesh.size-1
        m=mesh[i]
        MeshUtil.add_model(m,parent,smooth)
      end
    end
    mesh=mesh.mesh if mesh.is_a? MeshUtil::AttrGeo
    parent=Sketchup.active_model.entities.add_group if parent==nil
    parent.entities.add_faces_from_mesh(mesh,smooth)
    return parent
  end

  def MeshUtil.add_geos_to_model(geo,parent=nil,smooth=0)
    if geo.is_a? Array
      for g in geo
        MeshUtil.add_geos_to_model(g,parent,smooth)
      end
    else
      g=MeshUtil.add_model(geo.mesh,parent,smooth)
    end
  end

  def MeshUtil.box(pos=nil,size=nil,rot=nil,mesh=nil, flip=false)
    pos=[0,0,0] if pos == nil
    size=[1,1,1] if size == nil

    x=size[0]
    y=size[1]
    z=size[2]

    pts=[]
    if pos.is_a? Array
      pos=Geom::Point3d.new(pos)
    elsif pos.is_a? Geom::Vector3d
      pos=Geom::Point3d.new(pos.x,pos.y,pos.z)
    elsif !pos.is_a? Geom::Point3d
      return nil
    end
    pts<<pos
    pts<<pts[0] + Geom::Vector3d.new(x,0,0)
    pts<<pts[0] + Geom::Vector3d.new(x,y,0)
    pts<<pts[0] + Geom::Vector3d.new(0,y,0)
    pts.reverse! if !flip

    mesh=Geom::PolygonMesh.new if mesh==nil

    if rot!= nil
      tr=Geom::Transformation.rotation(pos,Geom::Vector3d.new(0,0,1),rot.degrees)
      for i in 0..3
        pts[i]=tr*pts[i]
      end
    end

    return MeshUtil.extrude_to_mesh_faces(pts,z,mesh)
    #t2=Geom::Transformation.rotation(rot)
    #mesh.transforma *= t1

  end


  def MeshUtil.add_poly_to_mesh_faces(pts,mesh)
    mesh=Geom::PolygonMesh.new if mesh==nil
    # indices=[]
    # pts.each{|p|
    #   indices<<mesh.add_point(p)
    # }
    # mesh.add_polygon(indices)
    mesh.add_polygon(pts)
    return mesh
  end

  def MeshUtil.extrude_to_mesh_faces(pts,h,mesh,flip=false)
    mesh=Geom::PolygonMesh.new if mesh==nil
    pts.reverse! if flip
    MeshUtil.add_poly_to_mesh_faces(pts,mesh)
    # p mesh.polygons

    for i in 0..pts.size-1
      j=i+1
      j=0 if j>=pts.size
      vpts=[]
      vpts<<(pts[i])
      vpts<<(pts[j])
      vpts<<(pts[j] + Geom::Vector3d.new(0,0,h))
      vpts<<(pts[i] + Geom::Vector3d.new(0,0,h))
      vpts.reverse!
      MeshUtil.add_poly_to_mesh_faces(vpts,mesh)
    end

    #top
    tpts=[]
    pts.each{|p|
      tpts<<p+Geom::Vector3d.new(0,0,h)
    }
    tpts.reverse!
    MeshUtil.add_poly_to_mesh_faces(tpts,mesh)
    return mesh
  end

  def MeshUtil.split_mesh(plane,mesh,cap=true)
    plane[0]=Geom::Point3d.new(*plane[0]) if plane[0].is_a? Array
    normal=Geom::Vector3d.new(*plane[1])
    normal.length=1 if normal.length!=1
    plane[1]=normal
    left=[]
    right=[]
    xedges=[]

    polygons=mesh.polygons
    pts=mesh.points
    for polygon in polygons
      gon_left=[]
      gon_right=[]
      xedge=[]
      reverse=ArchUtil.point_in_plane_front(pts[polygon[0]-1],plane)
      # p "polygon:#{polygon} reverse:#{reverse} plane:#{plane}-------"
      for i in 0..polygon.size-1
        j=i+1
        j=0 if j>=polygon.size
        index1=polygon[i]
        index2=polygon[j]
        # p ["i=#{i}, j=#{j} index1=#{index1} index2=#{index2}"]
        p1=pts[index1-1]
        p2=pts[index2-1]
        onTop=ArchUtil.point_in_plane_front(p1,plane)
        # p "i:#{i} ontop=#{onTop} p1:#{p1} p2:#{p2}"
        if onTop
          gon_right<<p1
        else
          gon_left<<p1
        end
        line=[p1,p2]
        xp=Geom.intersect_line_plane(line,plane)

        if xp !=nil
          ref_len = (p1-p2).length
          d1 = xp - p1
          d2 = xp - p2
          if d1.length > ref_len or d2.length > ref_len
            xp=nil
          end

        end

        if xp!=nil
          # p "xp=#{xp}"
          xedge<<xp
          gon_right<<xp
          gon_left<<xp
        end
      end
      left<<gon_left if gon_left.size>=3
      right<<gon_right if gon_right.size>=3

      xedge.reverse! if reverse
      xedges<<xedge if xedge.size>=2
    end
    begin
      # p "pre sort xedges=#{xedges}"
      cutline=[]
      cutline=MeshUtil.sort_xedges(xedges) if xedges.size>=3
    rescue
      # p "post sort xedges=#{cutline}"
    end

    if cap and cutline.size>=3
      left_cap=cutline.clone.reverse!
      right_cap=cutline.clone
      left<<left_cap
      right<<right_cap
    end

    if left.size==0 or right.size==0 or cutline.size<3
      cutline=nil
    end

    mesh_left=Geom::PolygonMesh.new
    mesh_right=Geom::PolygonMesh.new

    # left mesh
    for f in left
      mesh_left.add_polygon(f) if f.size>=3
    end

    # right mesh
    for f in right
      mesh_right.add_polygon(f) if f.size>=3
    end

    return mesh_left,mesh_right,cutline
  end

  def MeshUtil.sort_xedges(xedges)
    #p "=========== sort_xedges ==========="
    sorted=[xedges[0][0]]
    edge1=xedges[0]
    if xedges.size<3
      return nil
    end
    unsorted=xedges[1..xedges.size-1]
    for i in 0..xedges.size-1
      for m in 0..unsorted.size-1
        edge2=unsorted[m]
        next if edge1==edge2
        if edge1[1]==edge2[0]
          sorted<<edge2[0]
          unsorted.delete(edge2)
          edge1=edge2
          break
        end
      end
    end
    return sorted
  end

  def MeshUtil.split_geometry(plane,geometry)
    left,right,cap=MeshUtil.split_mesh(plane,geometry.mesh,true)
    geo_left=MeshUtil::AttrComposit.new()
    geo_right=MeshUtil::AttrComposit.new()

    geo_left.add left
    geo_left.rotation=geometry.rotation
    geo_left.base_vect=geometry.vects[0]


    geo_right.add right
    geo_right.rotation=geometry.rotation
    geo_left.base_vect=geometry.vects[0]
    return geo_left,geo_right
  end

  def MeshUtil.create_from_definition(definition)
    abs_geos=[]
    ents=definition.entities
    for g in ents
      gents=[]
      if g.is_a? Sketchup::Group
        gents=g.entities
      elsif g.is_a? Sketchup::ComponentInstance
        gents=g.definition.entities
      else
        next
      end
      abs=MeshUtil::AttrComposit.new()
      # abs.position=g.transformation.origin
      # abs.rotation=g.transformation.rotz
      itf=g.transformation
      for e in gents
        if e.is_a? Sketchup::Face
          pts=[]
          e.vertices.each{|v|
            pts<<itf *  v.position
          }
          abs.add_polygon(pts)
        end
      end #end for e in gents
      abs_geos<<abs
    end # end for g in ents
    return abs_geos
  end # end function
end


load 'arch_util_apdx_arithmic.rb'
def temp_test()

  pts=[
      Geom::Point3d.new(0,0,0),
      Geom::Point3d.new(1.m,0,0),
      Geom::Point3d.new(1.m,1.m,0),
      Geom::Point3d.new(0.5.m,1.m,0),
      Geom::Point3d.new(0.5.m,1.5.m,0),
      Geom::Point3d.new(0,1.5.m,0),
  ]
  pts.reverse!

  f=Sketchup.active_model.selection[0]
  verts=f.vertices
  pts=[]
  for v in verts
    pts<<v.position
  end
  ext=MeshUtil::AttrExtrusion.new(pts,10,Geom::Point3d.new(2.45.m,1.67.m))

  # ext.position=Geom::Point3d.new(1.m,0,0)
  MeshUtil.add_model(ext.mesh)

  # ext.position=Geom::Point3d.new(-1.m,0,0)
  ext.reflection=[-1,1,1]
  MeshUtil.add_model(ext.mesh)

  ext.rotation=45
  ext.reflection=[-1,-1,1]
  # ext.position=Geom::Point3d.new(-1.m,-1.m,0)
  MeshUtil.add_model(ext.mesh)

end
