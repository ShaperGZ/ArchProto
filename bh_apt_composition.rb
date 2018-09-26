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
    p "///////////////// invalidate /////////////"
    @availables = @switcher.get(@gp)
    @gp.set_attribute("ProtoApt","available_compositions",@availables)

    @abstract_geometries=[]

    t1=Time.now
    gen_composition
    t2=Time.now
    p "invalidation took #{t2-t1} seconds"

    _add_all_abs_to_one

    #versions < 2017 may not have html UI
    begin
      web_sync
    rescue
      p $!
    end

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
      # Straight double loaded
      #   1. occupy
      rw = un_depth
      p1 = local_bounds.min
      s1 = [bd_width, un_depth, bd_height]
      create_geometry("O1",p1,s1)

      #   2.corridor
      p2 = p1 + Geom::Vector3d.new(0,rw,0)
      s2 = [bd_width, circulation_w, bd_height]
      create_geometry("C1",p2,s2)

      #   3. flank occupy AFt
      w = bd_depth-(un_depth+circulation_w)*2
      d = un_depth
      p4=Geom::Point3d.new(0,bd_depth-un_depth-circulation_w,0)
      s4 = [w,d,bd_height]
      create_geometry("O3",p4,s4,-90)

      #   3. flank circulation A
      w = bd_depth-(un_depth+circulation_w)*2
      d = circulation_w
      # p5 = p2 + Geom::Vector3d.new(un_depth,circulation_w,0)
      p5 = p4 + Geom::Vector3d.new(un_depth,0,0)
      s5 = [w,d,bd_height]
      create_geometry("C2",p5,s5,-90)

      #   3. flank occupy ABk
      w = bd_depth-(circulation_w+un_depth*2)*2
      d = un_depth
      offd=un_depth+circulation_w
      p6 = p5 + Geom::Vector3d.new(offd,-un_depth,0)
      s6 = [w,d,bd_height]
      create_geometry("O4",p6,s6,-90,[-1,1,1])

      #   3. flank occupy
      w = bd_width-offd*2
      d = un_depth
      p7 = p2+Geom::Vector3d.new(un_depth+circulation_w,un_depth+circulation_w,0)
      s7 = [w,d,bd_height]
      create_geometry("O2",p7,s7,0,[1,-1,1])

      #   3. flank occupy CFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      py=(un_depth)+circulation_w
      p8 = Geom::Vector3d.new(bd_width, py,0)
      s8 = s4
      create_geometry("O5",p8,s8,90)

      w = w
      d = circulation_w
      px=bd_width-un_depth
      py=(un_depth)+circulation_w
      p9 = Geom::Vector3d.new(px, py,0)
      s9 = s5
      create_geometry("C3",p9,s9,90)

      w = w - un_depth
      d = un_depth
      px=bd_width-(un_depth*2)-circulation_w
      py=(un_depth*2)+circulation_w
      p9 = Geom::Vector3d.new(px, py,0)
      s9 = s6
      create_geometry("O6",p9,s9,90,[-1,1,1])

      p10 = Geom::Point3d.new(bd_width,bd_depth,0)
      s10 = [bd_width, un_depth, bd_height]
      create_geometry("O7",p10,s10,180)

      p11 = p10 - Geom::Vector3d.new(0,un_depth,0)
      s11 =[bd_width,circulation_w,bd_height]
      create_geometry("C4",p11,s11,180)

      p12 = p10 - Geom::Vector3d.new(un_depth+circulation_w,un_depth+circulation_w,0)
      s12 = s7
      create_geometry("O8",p12,s12,0,[-1,-1,1])

    elsif @availables.include? 'U-shape'
      # Straight double loaded
      #   1. occupy
      rw = un_depth
      p1 = local_bounds.min
      s1 = [bd_width, un_depth, bd_height]
      create_geometry("O1",p1,s1)

      #   2.corridor
      p2 = p1 + Geom::Vector3d.new(0,rw,0)
      s2 = [bd_width, circulation_w, bd_height]
      create_geometry("C1",p2,s2)

      #   3. flank occupy AFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      p4=Geom::Point3d.new(0,bd_depth,0)
      s4 = [w,d,bd_height]
      create_geometry("O3",p4,s4,-90)

      #   3. flank circulation A
      w = bd_depth-rw-circulation_w
      d = circulation_w
      # p5 = p2 + Geom::Vector3d.new(un_depth,circulation_w,0)
      p5 = p4 + Geom::Vector3d.new(un_depth,0,0)
      s5 = [w,d,bd_height]
      create_geometry("C2",p5,s5,-90)

      #   3. flank occupy ABk
      w = bd_depth-rw-circulation_w-un_depth
      d = un_depth
      offd=un_depth+circulation_w
      p6 = p5 + Geom::Vector3d.new(offd,0,0)
      s6 = [w,d,bd_height]
      create_geometry("O4",p6,s6,-90,[-1,1,1])

      #   3. flank occupy
      w = bd_width-offd*2
      d = un_depth
      p7 = p2+Geom::Vector3d.new(un_depth+circulation_w,un_depth+circulation_w,0)
      s7 = [w,d,bd_height]
      create_geometry("O2",p7,s7,0,[1,-1,1])

      #   3. flank occupy CFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      py=(un_depth)+circulation_w
      p8 = Geom::Vector3d.new(bd_width, py,0)
      s8 = [w,d,bd_height]
      create_geometry("O5",p8,s8,90)

      w = w
      d = circulation_w
      px=bd_width-un_depth
      py=(un_depth)+circulation_w
      p9 = Geom::Vector3d.new(px, py,0)
      s9 = [w,d,bd_height]
      create_geometry("C3",p9,s9,90)

      w = w - un_depth
      d = un_depth
      px=bd_width-(un_depth*2)-circulation_w
      py=(un_depth*2)+circulation_w
      p9 = Geom::Vector3d.new(px, py,0)
      s9 = [w,d,bd_height]
      create_geometry("O6",p9,s9,90,[-1,1,1])


    elsif @availables.include? 'L-shape'
      # Straight double loaded
      #   1. occupy
      rw = un_depth
      p1 = local_bounds.min
      s1 = [bd_width, un_depth, bd_height]
      create_geometry("O1",p1,s1)

      #   2.corridor
      p2 = p1 + Geom::Vector3d.new(0,rw,0)
      s2 = [bd_width, circulation_w, bd_height]
      create_geometry("C1",p2,s2)

      #   3. flank occupy AFt
      w = bd_depth-rw-circulation_w
      d = un_depth
      p4=Geom::Point3d.new(0,bd_depth,0)
      s4 = [w,d,bd_height]
      create_geometry("O3",p4,s4,-90)

      #   3. flank circulation A
      w = bd_depth-rw-circulation_w
      d = circulation_w
      # p5 = p2 + Geom::Vector3d.new(un_depth,circulation_w,0)
      p5 = p4 + Geom::Vector3d.new(un_depth,0,0)
      s5 = [w,d,bd_height]
      create_geometry("C2",p5,s5,-90)

      #   3. flank occupy ABk
      w = bd_depth-rw-circulation_w-un_depth
      d = un_depth
      offd=un_depth+circulation_w
      p6 = p5 + Geom::Vector3d.new(offd,0,0)
      s6 = [w,d,bd_height]
      create_geometry("O4",p6,s6,-90,[-1,1,1])

      #   3. flank occupy
      w = bd_width-offd
      d = un_depth
      p7 = p2+Geom::Vector3d.new(un_depth+circulation_w,un_depth+circulation_w,0)
      s7 = [w,d,bd_height]
      create_geometry("O2",p7,s7,0,[1,-1,1])
    else
      if @availables.include? 'double'
        # Straight double loaded
        #   1. occupy
        p "double"
        rw = un_depth
        p1 = local_bounds.min
        s1 = [bd_width, un_depth, bd_height]
        #p "print from nh_apt_composition.rb line[169], s=#{s} "
        create_geometry("O1",p1,s1)

        #   2.corridor
        p2 = p1 + Geom::Vector3d.new(0,rw,0)
        s2 = [bd_width, circulation_w, bd_height]
        create_geometry("C1",p2,s2)

        #   3. occupy
        p3 = p2 + Geom::Vector3d.new(0,circulation_w+un_depth,0)
        s3 = [bd_width, un_depth, bd_height]
        create_geometry("O2",p3,s3,0,[1,-1,1])
      else
        # Straight single loaded
        #   1. occupy
        p "single"
        rw = un_depth-circulation_w
        p1 = local_bounds.min
        s1 = [bd_width, un_depth, bd_height]
        create_geometry("O1",p1,s1)

        # 2.corridor
        p2 = p1 + Geom::Vector3d.new(0,rw,0)
        s2 = [bd_width, circulation_w, bd_height]
        create_geometry("C1",p2,s2)
      end
    end
  end


  def _create_geometry(key,position,size,rotation=0,flip=[1,1,1],alignment=Alignment::SW, meter=true, color=nil)
    if position == nil or size == nil
      p "nil input found pos=#{position} size=#{size}"
    end

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