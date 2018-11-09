class BH_Apt_Vis_Flr < Arch::BlockUpdateBehaviour
    def initialize(gp,host)
      super(gp,host)
    end

    def invalidate()
      _reset_values
      composition=@host.get_updator_by_type(BH_Apt_Composition)
      abs_geo=composition.abstract_geometries

      @abstract_geometries=[]


      for g in abs_geo
        # TODO: cut g with flr planes
        m=cut_z(g,divs)
        @abstract_geometries<<m
      end
    end

    # divs=[3,6,9,12, ....]
    def cut_z(g,divs)
      mesh=Geom::PolygonMesh.new()
      divs.each{|z|
        pln=[[0,0,z],[0,0,1]]
        l,r,c=MeshUtil.split_mesh(pln,g,false);
        mesh.add_polygon(c)
      }
      return mesh;
    end
end