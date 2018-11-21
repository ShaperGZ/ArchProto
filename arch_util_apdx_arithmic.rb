module ArchUtil

  def ArchUtil.vector_scale(v,f,inplace=false)
    if inplace
      nv=v
    else
      nv=v.clone
    end
    for i in 0..2
      nv[i]*=f
    end
    return nv
  end


  def ArchUtil.vector_scale3d(v,v2,inplace=false)
    if inplace
      nv=v
    else
      nv=v.clone
    end
    for i in 0..2
      nv[i]*=vs[i]
    end
    return nv
  end

  def ArchUtil.to_vector3d(p)
    v=Geom::Vector3d.new()
    for i in 0..2
      v[i]=p[i]
    end
    return v
  end

  def ArchUtil.to_point3d(p)
    v=Geom::Point3d.new()
    for i in 0..2
      v[i]=p[i]
    end
    return v
  end


end


