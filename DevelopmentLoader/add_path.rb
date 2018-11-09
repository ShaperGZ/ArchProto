paths=[]
paths[0]='g:/sketchupruby/archproto'
paths[1]='d:/sketchupruby/archproto'

for p in paths
  if !($LOAD_PATH.include? p)
    $LOAD_PATH<<p
  end
end

SKETCHUP_CONSOLE.show
p $LOAD_PATH