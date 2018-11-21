
module ArchProto

  class Unit
    attr_accessor :floor
    attr_accessor :cluster
    attr_accessor :name
    attr_accessor :geometry
    attr_accessor :size
    attr_accessor :area
    attr_accessor :levels

    def initialize(absgeo=nil)
      @name=''
      @cluster=nil
      @floor=nil
      @area=nil
      set_geometry absgeo
    end

    def set_geometry absgeo
      @geometry=absgeo if absgeo!=nil and absgeo.is_a? MeshUtil::AttrGeo
      @size=@geometry.size.clone
    end

    def set_size(size)
      @size=size.clone
    end

    def area
      return @geometry.size[0]*@geometry,size[1] if @area == nil
      return @area
    end
  end

  class Cluster
    attr_accessor :south_factor
    attr_accessor :west_factor
    attr_accessor :units
    attr_accessor :name
    attr_accessor :parent_geometry
    def initialize(absgeo=nil)
      @units=[]
      @name=''
      @parent_geometry=nil
      if absgeo.is_a? MeshUtil::AttrGeo
        parent_geometry= absgeo
      end
    end

    def add_unit(unit)
      @units<<unit
    end

    def parent_geometry=(geo)
      @name=geo.name
      @parent_geometry=geo
    end

    def cal_orientation(container)
      r=parent_geometry.rotation
      if parent_geometry.reflection[1]==-1
        r+=180
        r=360-r if r>180
      end

      # p "cluster.r=#{r}"
      r+=container.transformation.rotz
      sr = r
      wr = r + 90
      wr=360-wr if wr>180
      @south_factor=sr.abs/180.0
      @west_factor=wr.abs/180.0
      # p "    --- r=#{r} sr.abs=#{sr.abs} south_factor=#{@south_factor} west_factor=#{@west_factor}"
    end
  end

  class Floor
    attr_accessor :name
    attr_accessor :levels
    attr_accessor :clusters
    attr_accessor :fire_zones
    attr_accessor :definition
    attr_accessor :height
    attr_accessor :floor_number

    def initialize(clusters=nil)
      # definition is use to create
      @definition=nil
      @clusters=Hash.new()
      if clusters.is_a? Array and clusters[0].is_a? ArchProto::Cluster
        for c in clusters
          @clusters[c.name]=c
        end
      end
      @name=''
      # @levels is an array containing the floor number which is an instance of this typical floor
      # sample: [2,3,4,5,6,7,8,9] floor 2-9 are instances of this typical floor
      # in this case, floorInstance.count = 9
      @levels=[]
      @fire_zones=[]
      @height=0
      @floor_number=1
      @definition=nil
    end

    def clone()
      f=Floor.new()
      f.name=@name
      f.levels=@levels.clone
      f.clusters=@clusters.clone
      f.fire_zones=@fire_zones.clone
      f.definition=@definition
      f.height=@height
      f.floor_number=@floor_number
      return f
    end

    def create_definition(name)
      @definition=Sketchup.active_model.definitions.add(name)
      ents=@definition.entities

    end

    def count
      return @levels.size
    end

    def add_cluster(cluster)
      p "cluster.name=#{cluster.name}"
      @clusters[cluster.name]=cluster
    end

    def units(cluster_name=nil)
      # cluster_name will be such as O1, O2...
      # if cluster_name is provided, than get units from that cluster
      # otherwise get all units
      out_units=[]
      if cluster_name!=nil
        if @clusters.key? cluster_name
          cluster=@cluters[cluster_name]
          clusters=[cluster]
        else
          p "cluster_name not found in keys; from Floor.units(cluster_name=nil)"
          return nil
        end
      else
        clusters=@clusters.clone
      end

      for c in clusters
        out_units+=c.units
      end

    end

  end
end