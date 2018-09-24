class BH_Apt_Composition < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
    @ent_mod_counter=0
    @availables=[]
    #@composition is a list of abstract geometriestag
    @composition=[]
    @spaces=Hash.new()
    @switcher=SW_Composition.new()
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2]
    @host.enableUpdate = false
    invalidate()
    @host.enableUpdate = true
    p "availables=#{@availables}"
  end


  def invalidate()
    @availables = @switcher.get(@gp)
    @gp.set_attribute("ProtoApt","available_compositions",@availables)
    gen_composition
    web_sync

  end

  def check_composition(checks)
    @gp.set_attribute("ProtoApt","checked_compositions",checks)
  end

  def gen_composition
    clear_generated
    #p "instance var=#{instance_variables} "

    # 1. get size
    yscale=host.gp.transformation.yscale
    xscale=host.gp.transformation.xscale

    local_bounds=Op_Dimension.local_bound(host.gp)
    circulation_w = host.attr('crd_width')
    bd_width = host.attr('bd_width')
    bd_depth = host.attr('bd_depth')
    bd_height = host.attr('bd_height')

    un_width = host.attr('un_width')
    un_depth = host.attr('un_depth')

    # 2. generate spaces
    if @availables.include? 'O-shape'
    elsif @availables.include? 'U-shape'
      # Straight double loaded
      #   1. occupy
      rw = un_depth
      p1 = local_bounds.min
      s1 = [bd_width, un_depth, bd_height]
      create_geometry("occupy",p1,s1)

      #   2.corridor
      p2 = p1 + Geom::Vector3d.new(0,rw/yscale,0)
      s2 = [bd_width, circulation_w, bd_height]
      create_geometry("corridor",p2,s2)

      #   3. flank occupy AFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      p4 = p2 + Geom::Vector3d.new(0,circulation_w/yscale,0)
      s4 = [w,d,bd_height]
      create_geometry("occupy",p4,s4,90,[1,-1,1])

      #   3. flank circulation A
      w = bd_depth-rw-circulation_w
      d = circulation_w
      p5 = p2 + Geom::Vector3d.new(un_depth/xscale,circulation_w/yscale,0)
      s5 = [w,d,bd_height]
      create_geometry("corridor",p5,s5,90,[1,-1,1])

      #   3. flank occupy ABk
      w = bd_depth-rw-circulation_w
      d = un_depth
      offd=(un_depth*2)+circulation_w
      p6 = p2 + Geom::Vector3d.new(offd/xscale,circulation_w/yscale,0)
      s6 = [w,d,bd_height]
      create_geometry("occupy",p6,s6,90)

      #   3. flank occupy
      w = bd_width-(offd*2)
      d = un_depth
      p7 = p6.clone
      s7 = [w,d,bd_height]
      create_geometry("occupy",p7,s7)

      #-------------------------------------------
      #   3. flank occupy CFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      py=(un_depth)+circulation_w
      p8 = Geom::Vector3d.new(bd_width/xscale, py/yscale,0)
      s8 = [w,d,bd_height]
      create_geometry("occupy",p8,s8,90)

      w = w
      d = circulation_w
      px=bd_width-un_depth
      py=(un_depth)+circulation_w
      p9 = Geom::Vector3d.new(px/xscale, py/yscale,0)
      s9 = [w,d,bd_height]
      create_geometry("corridor",p9,s9,90)

      w = w
      d = un_depth
      px=bd_width-un_depth-circulation_w
      py=(un_depth)+circulation_w
      p9 = Geom::Vector3d.new(px/xscale, py/yscale,0)
      s9 = [w,d,bd_height]
      create_geometry("occupy",p9,s9,90)


    elsif @availables.include? 'L-shape'
      # Straight double loaded
      #   1. occupy
      rw = un_depth
      p1 = local_bounds.min
      s1 = [bd_width, un_depth, bd_height]
      create_geometry("occupy",p1,s1)

      #   2.corridor
      p2 = p1 + Geom::Vector3d.new(0,rw/yscale,0)
      s2 = [bd_width, circulation_w, bd_height]
      create_geometry("corridor",p2,s2)

      #   3. flank occupy AFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      p4 = p2 + Geom::Vector3d.new(0,circulation_w/yscale,0)
      s4 = [w,d,bd_height]
      create_geometry("occupy",p4,s4,90,[1,-1,1])

      #   3. flank circulation A
      w = bd_depth-rw-circulation_w
      d = circulation_w
      p5 = p2 + Geom::Vector3d.new(un_depth/xscale,circulation_w/yscale,0)
      s5 = [w,d,bd_height]
      create_geometry("corridor",p5,s5,90,[1,-1,1])

      #   3. flank occupy ABk
      w = bd_depth-rw-circulation_w
      d = un_depth
      offd=(un_depth*2)+circulation_w
      p6 = p2 + Geom::Vector3d.new(offd/xscale,circulation_w/yscale,0)
      s6 = [w,d,bd_height]
      create_geometry("occupy",p6,s6,90)

      #   3. flank occupy
      w = bd_width-offd
      d = un_depth
      p7 = p6.clone
      s7 = [w,d,bd_height]
      create_geometry("occupy",p7,s7)
    else
      if @availables.include? 'double'
        # Straight double loaded
        #   1. occupy
        rw = un_depth
        p1 = local_bounds.min
        s1 = [bd_width, un_depth, bd_height]
        #p "print from nh_apt_composition.rb line[169], s=#{s} "
        create_geometry("occupy",p1,s1)

        #   2.corridor
        p2 = p1 + Geom::Vector3d.new(0,rw/yscale,0)
        s2 = [bd_width, circulation_w, bd_height]
        create_geometry("corridor",p2,s2)

        #   3. occupy
        p3 = p2 + Geom::Vector3d.new(0,circulation_w/yscale,0)
        s3 = [bd_width, un_depth, bd_height]
        # create_geometry("occupy",p3,s3)
      else
        # Straight single loaded
        #   1. occupy
        rw = un_depth-circulation_w
        p1 = local_bounds.min
        s1 = [bd_width, un_depth, bd_height]
        create_geometry("occupy",p1,s1)

        # 2.corridor
        p2 = p1 + Geom::Vector3d.new(0,rw/yscale,0)
        s2 = [bd_width, circulation_w, bd_height]
        create_geometry("corridor",p2,s2)
      end
    end


  end

  def create_abs_geometries(key,position,size,rotation=0,flip=[1,1,1],alignment=Alignment::SW, meter=true)

  end

  def create_geometry(key,position,size,rotation=0,flip=[1,1,1],alignment=Alignment::SW, meter=true, color=nil)
    if position == nil or size == nil
      p "nil input found pos=#{position} size=#{size}"
    end

    #p @availables
    p=position.clone
    s=size.clone
    t=key

    if meter
      for i in 0..2
        p[i]=p[i].m if not p[i].nil?
      end
      for i in 0..s.size-1
        begin
          s[i] = s[i].m
        rescue
          p "Exception i=#{i}, s=#{s} "
          throw Exception
        end
      end
    end

    zero=Geom::Point3d.new(0,0,0)
    offset=Geom::Transformation.translation(p)
    comp=ArchUtil.add_box(zero,s,true,@gp,true, alignment)
    comp.transformation *= offset
    comp.set_attribute("BuildingComponent","type",t)
    comp.name=key
    if color !=nil
      comp.material=color
    end
    add_space(key,comp)
    if rotation!=0
      org=comp.transformation.origin
      # p "rotating around #{[org.x.to_m,org.y.to_m,org.z.to_m]}"
      vup=Geom::Vector3d.new(0,0,1)
      comp.transform! Geom::Transformation.rotation(org,vup,rotation.degrees)
      xscale=@gp.transformation.xscale
      yscale=@gp.transformation.yscale
      ArchUtil.scale_3d(comp,[xscale/yscale,yscale/xscale,1])
    end
    ArchUtil.scale_3d(comp,flip)
    return comp
  end

  def add_space(key,space)
    if ! @spaces.keys.include? key
      @spaces[key]=[]
    end
    @spaces[key]<<space
  end
  def clear_generated()
    p "clear generated"
    keys=@spaces.keys
    keys.each{|k|
      dgp=@spaces[k]
      dgp.each{|g|
        g.erase! if g.class==Sketchup::Group and g.valid?
      }
    }
    @spaces=Hash.new
  end

  def web_sync
    #sync title
    dlg=WD_Interact.singleton
    id=ArchUtil.short_id(@gp)
    size=Op_Dimension.get_size(@gp)
    msg="'#{id} #{size}'"
    p msg
    dlg.set_web_param('title',msg)

    # available types
    if @availables.include? 'double'
      dlg.set_web_param( 'cb_double','true')
    else
      dlg.set_web_param( 'cb_double','false')
    end
    if @availables.include? 'L-shape'
      dlg.set_web_param( 'cb_L-shape','true')
    else
      dlg.set_web_param( 'cb_L-shape','false')
    end
    if @availables.include? 'U-shape'
      dlg.set_web_param( 'cb_U-shape','true')
    else
      dlg.set_web_param( 'cb_U-shape','false')
    end
    if @availables.include? 'O-shape'
      dlg.set_web_param( 'cb_O-shape','true')
    else
      dlg.set_web_param( 'cb_O-shape','false')
    end
  end
end