class BH_Units < BH_Bays
  attr_accessor :grid

  def initialize(gp,host)
    #p 'f=initialized constrain face'

    @unitClusters=[]
    @units_oriented=Hash.new()
    @typical_indices=[1]
    super(gp,host)

    @grid=@host.get_updator_by_type(BH_Bays)
    @xaxis=@grid.xaxis
    @yaxis=@grid.yaxis

  end

  def invalidate()
    merge_floors()
    add_model()
  end

  def merge_floors
    min_width=3.m
    typical_floors=@grid.typical_floors

    for tf in typical_floors
      for cluster in tf.clusters.values
        tbd=[]
        for i in 0..cluster.units.size-1
          unit=cluster.units[i]
          if unit.geometry.size[0]<min_width
            if i==0
              previous=cluster.units[i+1]
              previous.geometry.size[0]+=unit.geometry.size[0]
              vect=previous.geometry.vects[0].clone
              vect.length=unit.geometry.size[0]
              previous.geometry.position-=vect
            else
              previous=cluster.units[i-1]
              previous.geometry.size[0]+=unit.geometry.size[0]
            end
            tbd<<unit
          end
        end
        for u in tbd
          cluster.units.delete(u)
        end
      end
    end

    @typical_floors=typical_floors

  end

end