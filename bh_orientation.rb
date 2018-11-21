class BH_Orientation < Arch::BlockUpdateBehaviour
  attr_accessor :unitClusters
  def initialize(gp,host)
    super(gp,host)
  end

  def invalidate()
    bh_bay = @host.get_updator_by_type(BH_Bays)
    typical_floors=bh_bay.typical_floors
    total_units=0
    total_scores=0
    possible_min=0.25

    for tf in typical_floors
      clusters=tf.clusters
      for cluster in clusters.values
        floor_count=tf.levels.size
        cluster_unit_count=cluster.units.size*floor_count
        total_units+=cluster_unit_count
        # south and west factor
        sf=1-cluster.south_factor
        wf=1-cluster.west_factor

        p "#{cluster.name} sf:#{sf} wf:#{wf}"

        # orientation scores
        score=possible_min+sf-(wf/2)
        total_scores += score * cluster_unit_count

      end
    end

    # @unitClusters = bh_bay.unitClusters
    # total_units=0
    # total_scores=0
    # possible_min=0.25
    # for cluster in @unitClusters
    #   total_units+=cluster.units.size
    #
    #   # south and west factor
    #   sf=1-cluster.south_factor
    #   wf=1-cluster.west_factor
    #
    #   # orientation scores
    #   score=possible_min+sf-(wf/2)
    #   total_scores += score * cluster.size
    #   # p "cluster orientation score=#{score} size=#{cluster.size} sf:#{sf} wf:#{wf}"
    # end

    score=total_scores/total_units
    orn_dscr="--"
    # p "orientation score=#{score}, ttlS:#{total_scores}, ttlU:#{total_units}"
    @gp.set_attribute("PrototypeScores","SouthUnit",[score,orn_dscr])
  end
end