require "ostruct"


class BuildingBlock < Arch::Block

  #类静态函数，保证不重复加载监听器
  def self.create_or_invalidate(g,default_param_file=nil)
    # 删除非法reference只在读取新档案时有用，但放在这里保证每次选择都检查并清除非法组
    self.remove_deleted()

    # 如果这个组已经创建过，不能再创建，因为已经有了监听器
    # 所以只更新其属性，然后invalidate
    # 否则就新创建一个 BuuildingBlock, 在构造器里会invalidate
    if @@created_objects.key?(g)
      block=@@created_objects[g]
      block.setAttr4(zone,tower,program,ftfh)

      block.invalidate
      return block
    else
      return if g.name==$genName
      b=BuildingBlock.new(g,default_param_file)
      b.invalidate
      return b
    end
  end


  def self.remove_deleted()
    hs=@@created_objects
    hs.keys.each{|k|
      gp=hs[k].gp
      hs.delete(k) if gp==nil or !gp.valid?
    }
  end

  def self.read_param(gp,file)
    path=ArchProto.get_file_path(file)
    params=CSV.read(path)
    for i in 1..params.size
      l=params[i]
      # p "params[#{i}]=#{params[i]}"
      break if l ==nil
      gp.set_attribute("BuildingBlock",l[1],self.interpret_param_val(l[2]))
      if l.size==6
        gp.set_attribute("BuildingBlock","p_"+l[1],[l[2].to_f,l[3].to_f,l[4].to_f,l[5].to_f])
      end
    end
  end

  def self.interpret_param_val(value)
    if value.include? ','
      trunks=value.split(',')
      vals=[]
      trunks.each{|s|
        vals<<s.to_f
      }
      return vals
    else
      return value.to_f
    end
    return nil
  end

  attr_accessor :abstract_gemetries
  def initialize(gp, default_param_file=nil)
    super(gp)
    if default_param_file!=nil
      BuildingBlock.read_param(@gp,default_param_file)
    end
    abstract_gemetries=[]
    add_updators()
  end


  def add_updators()
    # override
  end

  def get_updator_by_type(type_name)
    @updators.each{|u|
      return u if u.class == type_name
    }
    return nil
  end


  def setAttrByDict(dict)
    dict.each{|kvp|
      k=kvp[0]
      v=kvp[1]
      @gp.set_attribute("BuildingBlock",k,v)
    }
  end

  def attr(key)
    return @gp.get_attribute("BuildingBlock",key)
  end

  def invalidate()
    # @updators.each{|e| e.onClose(@gp)}
    @updators.each{|e| e.invalidate}
  end

  def read_attributes_to_memory()
    attrdict = @gp.attribute_dictionary "BuildingBlock"
    keys=attrdict.keys
    keys.each{|k|
      p "setting @#{k}=#{attrdict[k]}"
      instance_variable_set('@'+k,attrdict[k])
      class << self
        attr_accessor k
      end
    }
    #p "instance_vars= #{instance_variables}"
  end

  def set_ftfhs()
    bd_ftfh=@gp.get_attribute("BuildingBlock","bd_ftfh")
    if bd_ftfh.class == Float
      bd_ftfh=[bd_ftfh]
    end
    ftfhs=[]

    # total height
    tth=@gp.local_bounds.max.z * @gp.transformation.zscale
    tth=tth.to_m
    #p "total h =#{tth}"
    current_H=0
    counter=0
    while current_H < tth
      if counter<bd_ftfh.size
        ftfh=bd_ftfh[counter]
      else
        ftfh = bd_ftfh[-1]
      end
      current_H += ftfh
      ftfhs<<ftfh
      counter+=1
    end
    @gp.set_attribute("BuildingBlock","bd_floors",counter)
    @gp.set_attribute("BuildingBlock","bd_ftfhs",ftfhs)
    return ftfhs
  end

  # determins ftfh from local z value
  def get_ftfh_from_z(zval)
    ftfhs=@gp.get_attribute("BuildingBlock", "bd_ftfhs")
    unscaled_z=zval * @gp.transformation.zscale
    tt=0
    abs_h=0
    ftfh=ftfhs[0]
    for i in 0..ftfhs.size-1
      tt+=ftfhs[i].m
      if tt > unscaled_z
        ftfh=ftfhs[i]
        break
      end
      abs_h=tt
    end
    return ftfh,abs_h
  end


end