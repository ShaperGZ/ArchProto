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
      @name=""
      @alignment= Alignment::SW
      @attributes=Hash.new
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

    def rotation
      return @rotation
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
  end

  class AttrComposit < AttrGeo
    attr_accessor :meshes
    def initialize(meshes=nil)
      super()
      @mesh=Geom::PolygonMesh.new
      add(meshes) if meshes.is_a? Geom::PolygonMesh
      add_range(meshes) if meshes.is_a? Array
    end

    def add_box(pos,size,rot)
      MeshUtil.box(pos,size,rot,@mesh)
    end

    def add_polygon(pts)
      @mesh.add_polygon(pts)
    end

    def add(m)
      for f in m.polygons
        nf=[]
        for i in f
          nf<< m.points[i-1]
        end
        @mesh.add_polygon(nf)
      end
    end

    def clone()
      return AttrComposit.new(mesh())
    end

    def add_range(ms)
      for m in ms
        add m
      end
    end

    def size
      return @meshs.size
    end

    def mesh
      out_mesh=MeshUtil.clone_mesh @mesh
      trans_reflect=ArchUtil.Transformation_scale_3d(@reflection)
      trans_translate=Geom::Transformation.translation(@position)
      trans_rotate=Geom::Transformation.rotation([0,0,0],[0,0,1],@rotation.degrees)
      out_mesh.transform! trans_reflect
      out_mesh.transform! trans_rotate
      out_mesh.transform! trans_translate
      return out_mesh
    end
  end

  class AttrExtrusion < AttrGeo
    attr_accessor :base_pts
    attr_accessor :height
    def initialize(pts,h)
      super()
      @base_pts = pts
      @height = h
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

      m=MeshUtil.extrude_to_mesh_faces(@base_pts,@height,parent)
    end
  end

  class AttrBox < AttrGeo
    def initialize()
      super()
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
    parent=Sketchup.active_model.entities.add_group if parent==nil


    parent.entities.add_faces_from_mesh(mesh,smooth)
    return parent
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

  def MeshUtil.extrude_to_mesh_faces(pts,h,mesh)
    mesh=Geom::PolygonMesh.new if mesh==nil
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
end
