module MeshUtil

  class AttrGeo
    attr_accessor :position
    attr_accessor :size
    attr_accessor :rotation
    attr_accessor :vects
    attr_accessor :name
    attr_accessor :attributes
    attr_accessor :color
    attr_accessor :alignment
    attr_accessor :reflection
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

    def set_rote(rots)
      @rotation=rots
      return self
      #remember to set the vectors
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


    def set_xvect(vect)
      xvect=vect
      zvect=Geom::Vector3d.new(0,0,1)
      yvect=zvect.cross xvect
      @vects=[xvect,yvect,zvect]
      return self
    end

    def mesh(parent=nil)
      if @position.is_a? Array
        pos=Geom::Point3d.new(@position)
      else
        pos=@position.clone
      end
      org=pos

      vects = @vects
      xvect=vects[0]
      yvect=vects[1]
      zvect=vects[2]
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
      trans_translate=Geom::Transformation.translation(pos)
      m=MeshUtil.box(Geom::Point3d.new,@size,@rotation,parent,flip)
      # m=MeshUtil.box(pos,@size,@rotation,parent,flip)

      # m.transform! (trans_reflect * trans_translate)
      m.transform! trans_reflect
      m.transform! trans_translate
      return m
    end
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
