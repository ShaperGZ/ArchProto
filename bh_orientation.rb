class BH_Orientation < Arch::BlockUpdateBehaviour
  attr_accessor :unitClusters
  def initialize(gp,host)
    super(gp,host)
  end

  def invalidate()
    bh_bay=@host.get_updator_by_type(BH_Bays)
    @unitClusters=bh_bay.unitClusters
    total_units=0
    total_scores=0
    possible_min=0.25
    for cluster in @unitClusters
      total_units+=cluster.size

      # south and west factor
      sf=1-cluster.south_factor
      wf=1-cluster.west_factor

      # orientation scores
      score=possible_min+sf-(wf/2)
      total_scores += score * cluster.size
      # p "cluster orientation score=#{score} size=#{cluster.size} sf:#{sf} wf:#{wf}"
    end

    score=total_scores/total_units
    orn_dscr="--"
    # p "orientation score=#{score}, ttlS:#{total_scores}, ttlU:#{total_units}"
    @gp.set_attribute("PrototypeScores","SouthUnit",[score,orn_dscr])
  end
end