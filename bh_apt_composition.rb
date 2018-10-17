class BH_Apt_Composition < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    #p 'f=initialized constrain face'
    super(gp,host)
    @ent_mod_counter=0
    @availables=[]
    @checked=[]
    #@composition is a list of abstract geometries
    @composition='Unkown'
    @spaces=Hash.new()
    @switcher=SW_Composition.new()
  end

  # def onChangeEntity(e, invalidated)
  #   return if not invalidated[2]
  #   @host.enableUpdate = false
  #   invalidate()
  #   @host.enableUpdate = true
  #   p "availables=#{@availables}"
  # end
  def composition()
    return @composition
  end

  def invalidate()
    comps=["double","L-shape","U-shape","O-shape"]
    # 要用switche因为switcher通过大小判断可以有的composition
    @availables = @switcher.get(@gp)
    @compositions = Hash.new()

    checked_compositions_arr=@gp.get_attribute("OperableStates","composition")
    checked_compositions = Hash.new()
    checked_compositions_arr.each{|i|
      checked_compositions[i[0]]=i[1]
    }

    comps.each{|comp|
      key='cb_'+comp
      state=checked_compositions[key]
      # state=WD_Interact.singleton().checkbox_value(key)
      if @availables.include? comp and state=="true"
        flag=true
      else
        flag=false
      end
      @compositions[comp]=flag
    }
    # p "@compositions=#{@compositions}"

    @gp.set_attribute("ProtoApt","available_compositions", @availables.to_a)
    @abstract_geometries=[]

    t1=Time.now
    gen_composition
    _add_all_abs_to_one
    t2=Time.now
    p "Bh_Apt_Composition.invalidate took #{t2-t1} seconds"


    #versions < 2017 may not have html UI
    begin
      web_sync
    rescue
      p $!
    end

  end


  def gen_composition
    # clear_generated
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
    if @compositions['O-shape']
      @composition='O-shape'
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
      create_geometry("O4",p6,s6,90,[-1,1,1])

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
      create_geometry("O6",p9,s9,-90,[-1,1,1])

      p10 = Geom::Point3d.new(bd_width,bd_depth,0)
      s10 = [bd_width, un_depth, bd_height]
      create_geometry("O7",p10,s10,180)

      p11 = p10 - Geom::Vector3d.new(0,un_depth,0)
      s11 =[bd_width,circulation_w,bd_height]
      create_geometry("C4",p11,s11,180)

      p12 = p11 - Geom::Vector3d.new(un_depth+circulation_w,un_depth+circulation_w,0)
      s12 = s7
      create_geometry("O8",p12,s12,0,[-1,1,1])

    elsif @compositions['U-shape']
      @composition='U-shape'
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
      create_geometry("O4",p6,s6,90,[-1,1,1])

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
      create_geometry("O6",p9,s9,-90,[-1,1,1])


    elsif @compositions['L-shape']
      @composition='L-shape'
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
      create_geometry("O4",p6,s6,90,[-1,1,1])

      #   3. flank occupy
      w = bd_width-offd
      d = un_depth
      p7 = p2+Geom::Vector3d.new(un_depth+circulation_w,un_depth+circulation_w,0)
      s7 = [w,d,bd_height]
      create_geometry("O2",p7,s7,0,[1,-1,1])
    else
      if @compositions['double']
        @composition='double'
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


  def web_sync
    #sync title
    dlg=WD_Interact.singleton
    id=ArchUtil.short_id(@gp)
    size=Op_Dimension.get_size(@gp)
    msg="'#{id} #{size}'"
    dlg.set_web_param('title',msg)

    # available types

    keys=['double','L-shape','U-shape','O-shape']
    for k in keys
      webkey='sp_'+k
      if(@availables.include? k )
        msg='unfade_element("'+webkey+'")'
      else
        msg='fade_element("'+webkey+'")'
      end
      dlg.execute_script(msg)
    end
  end
end