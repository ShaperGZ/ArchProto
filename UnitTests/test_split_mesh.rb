load 'arch_util.rb'
load 'mesh_util.rb'

def test()
  b=MeshUtil.box([0,0,0],[10,10,10])
  n=Geom::Vector3d.new(0,1,0)
  n.length=1

  plane=[[5,5,5],n.to_a]
  l,r,x=MeshUtil.split_mesh(plane,b)

  lm=Geom::PolygonMesh.new
  rm=Geom::PolygonMesh.new

  l.each{|p| lm.add_polygon(p)}
  r.each{|p| rm.add_polygon(p)}


  sel=Sketchup.active_model.selection
  sel.clear
  sel.add MeshUtil.add_model(lm)
  sel.add MeshUtil.add_model(rm)

  result=true
  return false if l.size!=6
  return false if r.size!=6
  return false if x.size!=4

  return true
end

