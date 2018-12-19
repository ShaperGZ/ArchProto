var canvasW=260;
var canvasH=150;
var container = document.getElementById("threejs_container")
var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera( 75, canvasW/canvasH, 0.1, 1000 );
var renderer = new THREE.WebGLRenderer();
var sunlight;
var controls;
var saoPass;

var geometries=[]
var object3ds=[]
var invalidated=false
var enableUpdate=true

function init(){
    var geometries=[]
    var object3ds=[]

    // controls = new THREE.TrackballControls( camera );
    // controls = new THREE.OrbitControls( camera, renderer.domElement );
    // controls.enableDamping = true; // an animation loop is required when either damping or auto-rotation are enabled
    // controls.dampingFactor = 1;
    // controls.screenSpacePanning = false;
    // controls.minDistance = 10
    // controls.maxDistance = 500;
    // controls.maxPolarAngle = Math.PI / 2;


    camera.position.set(-20,28,43)
    camera.lookAt(new THREE.Vector3(0,0,0))
    camera.far=10000
    camera.setFocalLength(35)

    renderer.setSize(canvasW,canvasH,false);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFShadowMap;
    container.appendChild(renderer.domElement);

    scene.background = new THREE.Color( 0xffffff );

    // SAO:
    //
    // composer = new THREE.EffectComposer( renderer );
    // renderPass = new THREE.RenderPass( scene, camera );
    // composer.addPass( renderPass );
    // saoPass = new THREE.SAOPass( scene, camera, false, true );
    // saoPass.renderToScreen = true;
    // saoPass.params.saoScale=1.7;
    // saoPass.params.saoBias=0;
    // saoPass.params.saoKernelRadius=100
    // saoPass.params.saoIntensity=0.002
    // // saoPass.params.saoBlurRadius=2
    // // saoPass.params.saoBlurDepthCutoff=0.008
    // composer.addPass( saoPass );



    //lighting
    sunLight=lighting_setup();

    //add_box([0,0,0],[1,1,1]);
    //add_box([0.5,0.3,0],[1,1,1.5]);
    //add_box_m(10);
    //add_box_4();
    add_test_units()
    refresh() ;
    console.log("done");

}

function lighting_setup(){
    // //sky
    // hemiLight = new THREE.HemisphereLight( 0xffffff, 0xffffff, 0.3 );
    // hemiLight.color.setHSL( 0.6, 0.6, 1 );
    // hemiLight.groundColor.setHSL( 0.7, 0.7, 0.7 );
    // hemiLight.position.set( 0, 50, 0 );
    // //scene.add( hemiLight );

    //sun
    dirLight = new THREE.DirectionalLight( 0xffffff, 1 );
    dirLight.color.setHSL( 1, 1, 1 );
    dirLight.position.set( 1,2,0.5 );
    dirLight.position.multiplyScalar( 1 );
    scene.add( dirLight );
    scene.add(dirLight.target);

    dirLight.castShadow = true;
    dirLight.shadow.mapSize.width = 2048;
    dirLight.shadow.mapSize.height = 2048;

    scene.add( new THREE.AmbientLight( 0x404080 ) );

    return dirLight;
}
function sky_ground_setup(){
    // GROUND

    var groundGeo = new THREE.PlaneBufferGeometry( 10000, 10000 );
    var groundMat = new THREE.MeshPhongMaterial( { color: 0xffffff, specular: 0x050505 } );
    groundMat.color.setHSL( 1, 1,1 );

    var ground = new THREE.Mesh( groundGeo, groundMat );
    ground.rotation.x = - Math.PI / 2;
    ground.position.y = - 33;
    scene.add( ground );

    ground.receiveShadow = true;

    // // SKYDOME
    //
    // var vertexShader = document.getElementById( 'vertexShader' ).textContent;
    // var fragmentShader = document.getElementById( 'fragmentShader' ).textContent;
    // var uniforms = {
    //     topColor: { value: new THREE.Color( 0x0077ff ) },
    //     bottomColor: { value: new THREE.Color( 0xffffff ) },
    //     offset: { value: 33 },
    //     exponent: { value: 0.6 }
    // };
    // uniforms.topColor.value.copy( hemiLight.color );
    //
    // scene.fog.color.copy( uniforms.bottomColor.value );
    //
    // var skyGeo = new THREE.SphereBufferGeometry( 4000, 32, 15 );
    // var skyMat = new THREE.ShaderMaterial( { vertexShader: vertexShader, fragmentShader: fragmentShader, uniforms: uniforms, side: THREE.BackSide } );
    //
    // var sky = new THREE.Mesh( skyGeo, skyMat );
    // scene.add( sky );
}

function add_boxes_grouped(params,transform){
    var group=new THREE.Object3D()

    // sample transform
    // transform = [ pos    , size    , rot ]
    // transform = [[0,0,0] , [1,1,1] , 15  ]
    t_pos=transform[0]
    t_scale=transform[1]
    t_rot=transform[2]

    group.position.set(t_pos[0],t_pos[1],t_pos[2]);
    group.scale.set(t_scale[0],t_scale[1],t_scale[2])
    scene.add(group)






}

function add_boxes(params){
    var ttl=params.length
    for (var i =0;i<ttl;i++){
        param=params[i];
        pos=param[0];
        size=param[1];
        rot=param[2];
        color=param[3];
        add_box(pos,size,rot,color)
    }
}


function enable_update(flag=true){
    enableUpdate=flag;
}

function add_box(pos=[0,0,0],size=[1,1,1],rot=0,color=[1,1,1]){
    pos[1]*=-1
    size[1]*=-1

    sx=Math.abs(size[0])
    sy=Math.abs(size[2])
    sz=Math.abs(size[1])
    var geo = new THREE.BoxGeometry(sx,sy,sz);
    px=pos[0];
    py=pos[2];
    pz=pos[1];

    geo.pos=[px,py,pz];
    geo.translate(size[0]/2,size[2]/2,size[1]/2)
    geo.rot=rot / (180/Math.PI);
    geo.color=color;
    geometries.push(geo)
    invalidated=true;
    return geo;
}

function add_test_units(){
    gap=[2.5,8.5,2.5]
    size=[3,9,3]
    for(var i=0;i<10;i++)
    {
        for (var j=0;j<3;j++)
        {
          p=[i*gap[0],0,j*gap[2]]
          add_box(p,size)
        }
    }
}

function add_box_4(){
    // add_box([1,1,0],[1,1,1])
    // add_box([-1,1,0],[-1,1,1.5])
    // add_box([-1,-1,0],[-1,-1,2])
    // add_box([1,-1,0],[1,-1,2.5])

    boxes=[
        [[1,1,0],[1,1,1],0,[1,1,1]],
        [[-1,1,0],[-1,1,0.75],0,[1,1,1]],
        [[-1,-1,0],[-1,-1,0.5],0,[1,1,1]],
        [[1,-1,0],[1,-1,0.3],0,[1,1,1]],
    ]

    add_boxes(boxes)
}

function update_camera(pos,trg=[0,0,0],fov=35){
    pos[1]*=-1
    trg[1]*=-1
    camera.position.set(pos[0],pos[2],pos[1])
    camera.lookAt(new THREE.Vector3(trg[0],trg[2],trg[1]))
}

// function add_box(pos=[0,0,0],size=[1,1,1],rot=0){
//     var geometry = new THREE.BoxGeometry( size[0], size[1], size[2] );
//     // var geometry = new THREE.BoxGeometry(1,1,1);
//     // var material = new THREE.MeshBasicMaterial( { color: 0xffffff } );
//     var mat = new THREE.MeshLambertMaterial({ color:0xffffff});
//     var cube = new THREE.Mesh( geometry, mat );
//     scene.add( cube );
//     cube.position.set(pos[0],pos[1],pos[2]);
//     cube.receiveShadow=true;
//     // cube.position=new THREE.Vector3(pos[0],pos[1],pos[2]);
//     // cube.rotation.z=rot;
//     return cube;
// }

function add_box_m(u=10,v=null){
    var w=1;
    if (v==null) v=u;
    for (var i=0;i<u;i++){
        for (var j=0;j<v;j++){
            var x=i*(w*1.5)
            var y=j*(w*1.5)
            //add_box([x,y,0],[w,w,w],i/u+j*v);
            add_box([x,y,0],[w,w,w]);
        }
    }
}

function clear_scene(){
    geometries=[];
    invalidated=true;
}


function refreshGeometries(){
    if(invalidated==false || enableUpdate==false) return;
    console.log("invalidating");
    var diff =object3ds.length - geometries.length;

    //remove extra
    if (diff>0){
        for (var i=0;i<diff;i++){
            last=object3ds.pop();
            scene.remove(last);
        }
    }
    //add extra
    else if (diff<0){
        var ttl=diff*-1
        for (var i=0;i<ttl;i++){
            m=new THREE.Mesh();
            m.material=new THREE.MeshLambertMaterial({ color:0xffffff});
            object3ds.push(m);
            scene.add(m);
        }
    }
    //set mesh
    for (var i=0;i<object3ds.length;i++){
        m=object3ds[i];
        g=geometries[i];
        //console.log('>> i:'+i+' :'+g.uuid);
        m.geometry=g;
        m.position.set(g.pos[0],g.pos[1],g.pos[2]);
        m.rotation.y=g.rot;
        m.material.color=g.color;
    }
    invalidated=false
}

function refresh(){
    requestAnimationFrame( refresh );

    refreshGeometries();
    // controls.update();
    renderer.render(scene,camera);
    // composer.render();
}

init();
