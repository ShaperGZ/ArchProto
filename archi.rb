module Arch
  class EntsObs < Sketchup:: EntitiesObserver
    def initialize(host)
      @host=host
    end
    def onElementAdded(entities, entity)
      # model= Sketchup.active_model
      # model.start_operation('onElementAdded')
      @host.onElementAdded(entities,entity) if @host.enableUpdate
      # model.commit_operation
    end
    def onElementModified(entities, entity)
      # model= Sketchup.active_model
      # model.start_operation('onElementModified')
      @host.onElementModified(entities, entity) if @host.enableUpdate
      #model.commit_operation
    end
  end

  # InstanceObserver 不稳定，容易导致死机所以暂时不适用
  class InstObs < Sketchup::InstanceObserver
    def initialize(host)
      @host=host
    end
    def onOpen(instance)
      # model= Sketchup.active_model
      # model.start_operation('onOpen')
      @host.onOpen(instance) if @host.enableUpdate
      # model.commit_operation
    end
    def onClose(instance)
      # model= Sketchup.active_model
      # model.start_operation('onClose')
      @host.onClose(instance) if @host.enableUpdate
      # model.commit_operation

    end
  end

  class EntObs < Sketchup::EntityObserver

    def initialize(host)
      @host=host
      @last_transformation=@host.gp.transformation.clone
    end

    def onEraseEntity(entity)
      # model= Sketchup.active_model
      # model.start_operation('onErase')
      @host.onEraseEntity(entity) if @host.enableUpdate
      # model.commit_operation
    end

    def onChangeEntity(entity)
      return if not @host.gp.valid?
      invalidated=ArchUtil.invalidated_transformation?(@last_transformation, @host.gp.transformation)
      # model= Sketchup.active_model
      # model.start_operation('invalidate')
      sign="---"
      for i in 0..2
        sign[i]= '+' if invalidated[i]
      end
      p "#{sign} [ EntObs.onChangeEntity e:#{entity} ] host.gp:#{@host.gp}"
      @host.onChangeEntity(entity,invalidated) if @host.enableUpdate
      @last_transformation = @host.gp.transformation.clone
      # model.commit_operation

    end
  end

  class BlockUpdateBehaviour
    attr_accessor :gp
    attr_accessor :host
    attr_accessor :abstract_geometries
    attr_accessor :concrete_geometries
    def initialize(gp,host=nil)
      @gp=gp
      @host=host
      @enableUpdate = true
      @abstract_geometries=[]
      @concrete_geometries=[]
    end

    def onOpen(e)
    end

    def onClose(e)
    end

    def onChangeEntity(e, invalidated)
    end

    def onEraseEntity(e)
    end

    def onElementAdded(entities, e)
    end

    def onElementModified(entities, e)
    end

    def invalidate()
    end

    def _add_all_abs_to_one()
      abs=@abstract_geometries
      if @concrete_geometries.size<1
        # g=Sketchup.active_model.entities.add_group
        g=@gp.entities.add_group
        @concrete_geometries<<g
      else
        g=@concrete_geometries[0]
        # g=Sketchup.active_model.entities.add_group if !g.valid?
        g=@gp.entities.add_group if !g.valid?
        @concrete_geometries[0]=g

      end
      gt=@gp.transformation
      xs=gt.xscale
      ys=gt.yscale
      zs=gt.zscale
      ti = ArchUtil.Transformation_scale_3d([1/xs,1/ys,1/zs])
      # ti=@gp.transformation.inverse
      tr=Geom::Transformation.rotation([0,0,0],Geom::Vector3d.new(0,0,1),gt.rotz.degrees)
      tri=Geom::Transformation.rotation([0,0,0],Geom::Vector3d.new(0,0,1),-gt.rotz.degrees)
      p "@g.rotz=#{gt.rotz}"
      g.entities.clear!

      # Push matrix and load unit matrix
      # only recreated scale and rotation because the local origin is [0,0,0]
      g.transformation=Geom::Transformation.new
      g.transform! tri*ti

      #create geometries
      for a in abs
        m=a.mesh()
        g.entities.add_faces_from_mesh(m,0)
      end

      # pop matrix
      g.transform! tr

    end

    def create_geometry(key,position,size,rotation=0,flip=[1,1,1],alignment=Alignment::SW, meter=true, color=nil)
      if position == nil or size == nil
        p "nil input found pos=#{position} size=#{size}"
      end

      # clone useful parameters
      p=position.clone
      # print "name:#{key} | pos:#{p} | scales:#{[xscale,yscale,zscale]}\n"

      s=size.clone
      t=key

      #convert units to meters
      if meter
        for i in 0..2
          p[i]=p[i].m if not p[i].nil?
        end
        for i in 0..s.size-1
          begin
            s[i] = s[i].m
          rescue
            p "Exception i=#{i}, s=#{s} "
            p $!
            throw Exception
          end
        end
      end


      box=MeshUtil::AttrBox.new
      # box.position=p
      box.reflection=flip
      box.set_pos(p)
      box.size=s
      box.rotation=rotation
      box.color=color
      box.name=key.to_s
      @abstract_geometries << box
      # add_space(key,box)
    end
  end

  class Block < BlockUpdateBehaviour
    @@created_objects=Hash.new
    def self.created_objects
      @@created_objects
    end

    def self.create_or_get(g)
      if @@created_objects.key?(g)
        return @@created_objects[g]
      else
        return Block.new(g)
      end
    end

    def initialize (gp)
      super(gp)
      @enableUpdate = true
      @entObs=[]
      @entsObs=[]
      @updators=[]


      #ObserverManager.Add(@gp.entities,EntsObs.new(self))
      #ObserverManager.Add(@gp,EntObs.new(self))
      #ObserverManager.Add(@gp,InstObs.new(self))

      # add_entsObserver(EntsObs.new(self))
      # add_entObserver(EntObs.new(self))
      # add_entObserver(InstObs.new(self))
      @@created_objects[gp]=self
    end
    def add_entObserver(observer)
      obs=@gp.add_observer(observer)
      ObserverManger.Add(@gp, obs)
      @entObs<<observer
    end
    def add_entsObserver(observer)

      obs=@gp.entities.add_observer(observer)
      @entsObs<<observer
    end
    def enableUpdate()
      @enableUpdate
    end
    def enableUpdate=(val)
      @enableUpdate=val
      p "set @enaleUpdate to: #{@enableUpdate}"
    end

    # override the following methods
    def onOpen(e)
      @updators.each{|u| u.onOpen(e)} if enableUpdate and @gp.valid?
    end
    def onClose(e)
      @updators.each{|u| u.onClose(e)} if enableUpdate and @gp.valid?
    end

    def invalidate()
      @updators.each{|u| u.invalidate()} if enableUpdate and @gp.valid?
    end

    # invalidated 是一个长度为三的bool array, 指明那种变化已过期
    # invalidated: [pos,rot,scale]
    def onChangeEntity(e,invalidated)
      # 当删除物件的时候这个e会变成另一个地址，所以检查e组是否还存在要靠@gp.valid?
      if enableUpdate and @gp.valid?
        @updators.each{|u|
          #p "executed u.gp:#{u.gp} u.valid=#{u.gp.valid?}"
          u.onChangeEntity(@gp,invalidated)
        }
      end
    end

    def onEraseEntity(e)
      # 删除时输入的e不等于@gp, 要用@gp来删除
      if enableUpdate
        @updators.each{|u| u.onEraseEntity(@gp)}
        @@created_objects.delete(@gp)
      end
    end

    def onElementAdded(entities, e)
      @updators.each{|u| u.onElementAdded(entities, e)} if enableUpdate and !e.deleted?
    end
    def onElementModified(entities, e)
      #p "enable update=#{enableUpdate}"
      @updators.each{|u| u.onElementModified(entities, e)} if enableUpdate and !e.deleted?
    end
  end
end