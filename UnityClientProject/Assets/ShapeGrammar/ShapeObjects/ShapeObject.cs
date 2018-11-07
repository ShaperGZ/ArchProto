using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SGGeometry;
//using SGCore;

public class ShapeObject : MonoBehaviour {
    public static bool drawScope = true;
    public virtual Vector3 Size
    {
        get
        {
            return transform.localScale;
        }
        set
        {
            for (int i = 0; i < 3; i++)
                if (value[i] == 0) value[i] = 1;
            transform.localScale = value;
        }
    }
    public Vector3[] Vects
    {
        get
        {
            Vector3 z = transform.forward;
            Vector3 y = transform.up;
            Vector3 x = Vector3.Cross(y,z);
            return new Vector3[] { x, y, z };
        }
    }
    public virtual Vector3 Position
    {
        get { return transform.position; }
        set {
            transform.position = value;
            stale = true;
            Invalidate();
        }
    }

    public System.Guid guid;
    public string sguid;
    public Meshable meshable;
    //public Rule parentRule;
    //public Grammar grammar;
    public int step;
    public bool alwaysActive = false;

    public Dictionary<int, Material> materialsByMode;
    public Material matDefault;
    public Material matRuleMode;
    public Material matNameMode;
    public Material matVisualMode;
    public Material matProgramMode;
    public bool isGraphics = false;

    public static Material DefaultMat
    {
        get
        {
            if(_defaultMat == null)
            {
                //_defaultMat = MaterialManager.GB.Default;
                //_defaultMat = Resources.Load("Mat0") as Material;
            }
            return _defaultMat;
        }
    }

    public bool highlightScope = false;
    protected static Material _defaultMat;
    protected MeshFilter meshFilter;
    protected MeshRenderer meshRenderer;
    protected BoxCollider boxCollider;
    public bool stale = false;
    public void SetVisible(bool flag)
    {
        meshRenderer = GetComponent<MeshRenderer>();
        if(meshRenderer != null)
        {
            meshRenderer.enabled = flag;
        }
    }
    public virtual void Clear()
    {

    }
    private void Awake()
    {
        //guid = System.Guid.NewGuid();
        //sguid = ShortGuid();
    }
    public void Translate(Vector3 offset)
    {
        Debug.Log("translate:" + offset);
        meshable.Translate(offset);
        transform.position += offset;
    }
    // Use this for initialization
    protected void Start () {
        materialsByMode = new Dictionary<int, Material>();
        meshFilter = GetComponent<MeshFilter>();
        meshRenderer = GetComponent<MeshRenderer>();
        SetDefaultMaterials();
        boxCollider = GetComponent<BoxCollider>();
        guid = System.Guid.NewGuid();
        sguid = ShortGuid();
        //SceneManager.CreateShape(this);
    }
	//public void SetGrammar(Grammar g, bool execute=false)
 //   {
 //       if(grammar != null)
 //       {
 //           grammar.Clear();
 //       }
 //       if (g == null) return;

 //       grammar = g;
 //       g.assignedObjects.Clear();
 //       g.assignedObjects.Add(this);

 //       //g.inputs.shapes = new List<ShapeObject>();
 //       //g.inputs.shapes.Add(this);
 //       if (execute)
 //       {
 //           g.Execute();
 //       }
 //   }
    
    public virtual void SetDefaultMaterials()
    {
        //materialsByMode[DisplayMode.NORMAL]= MaterialManager.GB.Default;
        //materialsByMode[DisplayMode.NAMES] = MaterialManager.GB.NameDifferentiate;
        //materialsByMode[DisplayMode.RULE] = MaterialManager.GB.RuleEditing;
        //materialsByMode[DisplayMode.VISUAL] = MaterialManager.GB.Wall0;
        //if(meshRenderer!=null)
        //    meshRenderer.material = materialsByMode[DisplayMode.NORMAL];
    }
    public void SetMaterial(int mode)
    {
        if (meshRenderer == null || isGraphics == false || meshRenderer.material == null || mode == null) return;
        meshRenderer.material = materialsByMode[mode];
    }
    public void SetMaterial(Material m)
    {
        if (meshRenderer != null && isGraphics == false)
            meshRenderer.material = m;
        //else Debug.Log("MeshRender is Null in " + Format());
    }
	// Update is called once per frame
	void Update () {
		
	}
    
    public string Format()
    {
        string txt = "";
        //string draw = "-";
        //try
        //{
        //    if (gameObject.activeSelf) draw = "+";
        //    string ruleName;
        //    if (parentRule == null) ruleName = "unnamedRule";
        //    else ruleName = parentRule.name;
        //    txt += draw + name + "_(" + ruleName + "_step" + step + ")";
        //}
        //catch { }
        

        return txt;
    }
    public string ShortGuid()
    {
        string l = guid.ToString();
        int[] indices = new int[] { 0, 1, 2, 3, 10, 11, 12, 13 };
        string s="";
        s += l.Substring(0, 4) + l.Substring(10, 4);
        return s;


    }
    public void Show(bool flag)
    {
        //if(grammar==null)
        if (!alwaysActive)
            gameObject.SetActive(flag);
        else
            gameObject.SetActive(true);
        if (flag)
            Invalidate();
    }
    public void SetDisplayMode(int mode)
    {
        //switch (mode)
        //{
        //    case DisplayMode.NORMAL:
        //        meshRenderer.material = matNameMode;
        //        break;
        //    case DisplayMode.RULE:
        //        meshRenderer.material = matRuleMode;
        //        break;
        //    case DisplayMode.VISUAL:
        //        meshRenderer.material = matVisualMode;
        //        break;
        //    default:
        //        Debug.LogWarning("the given mode is not implimented, mode=" + mode);
        //        break;
        //}
    }
    private void OnRenderObject()
    {
        //GLDrawScope(Color.black);
        if(ShapeObject.drawScope)
        //if (drawScope && meshRenderer.enabled && isGraphics==false )
        {
            Color c = Color.black;
            //if (highlightScope)
            //    c = Color.red;

            GLDrawScope(c);
            try
            {
                foreach (Meshable m in ((CompositMeshable)meshable).components)
                {
                    if (m.displayLines != null && m.displayLines.Count > 0)
                    {
                        foreach (Polyline pl in m.displayLines)
                        {
                            SGGeometry.GLRender.Polyline(pl.vertices, false, null, Color.black);
                        }
                    }
                }
            }

            catch { }
        }
    }



    Vector3[] makeBoxPoints()
    {
        Vector3[] opts = new Vector3[8];
        Vector3[] vects = Vects;
        for (int i = 0; i < 3; i++)
            vects[i] *= Size[i];
        Vector3 size = Size;

        //opts[0] = new Vector3(-0.5f,-0.5f,-0.5f);
        opts[0] = transform.position;
        opts[1] = opts[0] + (vects[0]);
        opts[2] = opts[1] + (vects[2]);
        opts[3] = opts[0]+ (vects[2]);
        for( int i = 0; i < 4; i++)
        {
            opts[i + 4] = opts[i] + vects[1];
        }
        return opts;

    }
    protected void GLDrawScope(Color color)
    {
        //Color color = Color.black;
        //Material mat = SceneManager.LineMat;
        //mat.SetPass(0);
        //Vector3[] pts = makeBoxPoints();
        //GL.Begin(GL.LINES);
        

        //GL.Color(color);
        //GL.Vertex(pts[1]);
        //GL.Vertex(pts[2]);
        //GL.Vertex(pts[2]);
        //GL.Vertex(pts[3]);
        //GL.Vertex(pts[3]);
        //GL.Vertex(pts[0]);

        //GL.Vertex(pts[4]);
        //GL.Vertex(pts[5]);
        //GL.Vertex(pts[5]);
        //GL.Vertex(pts[6]);
        //GL.Vertex(pts[6]);
        //GL.Vertex(pts[7]);
        //GL.Vertex(pts[7]);
        //GL.Vertex(pts[4]);

        //for(int i =0;i<4;i++)
        //{
        //    GL.Vertex(pts[i]);
        //    GL.Vertex(pts[i+4]);
        //}
        //GL.Color(Color.red);
        //GL.Vertex(pts[0]);
        //GL.Vertex(pts[1]);
        //GL.Color(Color.blue);
        //GL.Vertex(pts[0]);
        //GL.Vertex(pts[3]);
        //GL.Color(Color.green);
        //GL.Vertex(pts[0]);
        //GL.Vertex(pts[4]);
        //GL.End();
    }
    public void RefreshOnMeshableUpdate(Vector3? direction = null)
    {
        if (direction.HasValue)
        {
            SetMeshable(meshable,direction);
        }
        else
        {
            GetComponent<MeshFilter>().mesh = meshable.GetMeshForm();
        }
    } 
    public void SetMeshable(Meshable imeshable, Vector3? direction=null)
    {
        meshable = imeshable;
        Vector3 vectu;
        BoundingBox bbox=null;
        if (direction.HasValue)
        {
            vectu = direction.Value;
            bbox = meshable.GetBoundingBox(vectu);
            meshable.bbox = bbox;
        }
        else if (meshable.bbox == null)
        {
            //Debug.Log("bounding box not found !!!");
            vectu = new Vector3(1, 0, 0);
            bbox = meshable.GetBoundingBox(vectu);
            meshable.bbox = bbox;
        }
        else
        {
            //Debug.Log("assigning existing bounding box");
            bbox = meshable.bbox;
        }
        ConformToBBox(bbox);
        stale = true;
    }
    
    public void SetMeshable(Meshable imeshable, BoundingBox refBbox)
    {
        meshable = imeshable;
        Vector3 vectu;
        BoundingBox bbox = meshable.GetBoundingBox(refBbox);
        
        ConformToBBox(bbox);
        stale = true;
    }
    private void ConformToBBox(BoundingBox bbox)
    {
        //transform.position = bbox.position;
        transform.localPosition = bbox.vertices[0];
        if (bbox.vects[2].magnitude > 0)
            //transform.LookAt(bbox.vertices[3]);
            transform.LookAt(bbox.vertices[0]+bbox.vects[2]);
        else
        {
            Vector3 n = Vector3.Cross(bbox.vects[0].normalized, bbox.vects[1].normalized);
            transform.LookAt(bbox.vertices[0] + n);
        }
        Vector3 signedSize= bbox.GetSignedSize();
        for (int i = 0; i < 3; i++)
        {
            if (signedSize[i] == 0) signedSize[i] = 1;
        }
        transform.localScale = signedSize;
        
        Mesh mesh = meshable.GetNormalizedMesh(bbox);
        meshable.bbox = bbox;
        GetComponent<MeshFilter>().mesh = mesh;
    }
    public void ConformToBBoxTransform(BoundingBox bbox)
    {
        //transform.position = bbox.position;
        transform.localPosition = bbox.vertices[0];
        if (bbox.vects[2].magnitude > 0)
            //transform.LookAt(bbox.vertices[3]);
            transform.LookAt(bbox.vertices[0] + bbox.vects[2]);
        else
        {
            Vector3 n = Vector3.Cross(bbox.vects[0].normalized, bbox.vects[1].normalized);
            transform.LookAt(bbox.vertices[0] + n);
        }
        transform.localScale = bbox.GetSignedSize();
    }
    public void Invalidate()
    {
        //if (!stale) return;
        //if (grammar != null)
        //{
        //    //Show(false);
        //    grammar.Execute();
        //}
        stale = false;
    }
    private void OnDestroy()
    {
        //SceneManager.DestroyShape(guid);
        //if (grammar != null)
        //{
        //    grammar.Clear(true);
        //}
        ////Debug.LogWarning("SHAPE OBJECT DESTROY WARNING:" + Format());
    }
    public static ShapeObject CreateBasic()
    {
        GameObject o = new GameObject();
        ShapeObject so = o.AddComponent<ShapeObject>();
        so.meshFilter = o.AddComponent<MeshFilter>();
        so.meshRenderer = o.AddComponent<MeshRenderer>();
        BoxCollider bc= o.AddComponent<BoxCollider>();
        bc.center = new Vector3(0.5f, 0.5f, 0.5f);
        //o.AddComponent<HighlightMouseOver>();
        //so.meshRenderer.material = DefaultMat;
        return so;
    }
    public static ShapeObject CreateBasic(GameObject prefab,bool isGraphics=false)
    {
        GameObject o = Instantiate(prefab);
        ShapeObject so = o.AddComponent<ShapeObject>();
        BoxCollider bc = o.AddComponent<BoxCollider>();
        bc.center = new Vector3(0.5f, 0.5f, 0.5f);
        //o.AddComponent<HighlightMouseOver>();
        so.isGraphics = isGraphics;
        //so.meshRenderer.material = DefaultMat;
        return so;
    }
    public static ShapeObject CreateBox(Vector3 pos, Vector3 size, Vector3[] vects)
    {
        Vector3[] pts = new Vector3[4];
        Vector3 mv1 = vects[0] * size[0];
        Vector3 mv2 = vects[1] * size[1];
        Vector3 mv3 = vects[2] * size[2];
        pts[0] = pos;
        pts[1] = pts[0] + mv1;
        pts[2] = pts[1] + mv3;
        pts[3] = pts[0] + mv3;

        return CreateExtrusion(pts, mv2.magnitude);
    }
    public static ShapeObject CreateBox(Vector3 size)
    {
        Vector3[] pts = new Vector3[4];
        pts[0] = new Vector3(0, 0, 0);
        pts[1] = new Vector3(size[0], 0, 0);
        pts[2] = new Vector3(size[0], 0, size[2]);
        pts[3] = new Vector3(0, 0, size[2]);

        return CreateExtrusion(pts,size[1]);
    }
    public static ShapeObject CreatePolygon(Vector3[] pts)
    {
        Polygon pg = new Polygon(pts);
        ShapeObject so = ShapeObject.CreateBasic();
        Vector3? ld = PointsBase.LongestDirection(pts);
        so.SetMeshable(pg, ld);
        return so;

    }
    public static ShapeObject CreateExtrusionForm(Vector3[] pts, float d)
    {
        Vector3 magUp = new Vector3(0, d, 0);
        Polygon pg = new Polygon(pts);
        Form ext = pg.ExtrudeToForm(magUp);

        ShapeObject so = ShapeObject.CreateBasic();
        Vector3? ld = PointsBase.LongestDirection(pts);
        so.SetMeshable(ext, ld);
        return so;
    }
    public static ShapeObject CreateExtrusion(Vector3[] pts, float d)
    {
        Vector3 magUp = new Vector3(0, d, 0);
        Polygon pg = new Polygon(pts);
        Extrusion ext = pg.Extrude(magUp);

        ShapeObject so = ShapeObject.CreateBasic();
        Vector3? ld = PointsBase.LongestDirection(pts);
        so.SetMeshable(ext, ld);
        return so;
    }
    public static ShapeObject CreateMeshable(Meshable mb, Vector3? direction=null)
    {
        ShapeObject so = ShapeObject.CreateBasic();
        //Debug.Log("direction=" + direction.Value);
        so.SetMeshable(mb,direction);
        
        return so;
    }
    public static ShapeObject CreateComponent(GameObject prefab = null)
    {
        GameObject o;
        if (prefab == null)
        {
            o = GameObject.CreatePrimitive(PrimitiveType.Cube);
        }
        else
        {
            o = GameObject.Instantiate(prefab);
        }
        ShapeObject so = o.AddComponent<ShapeObject>();
        return so;
    }
    public void PivotTurn(int num=1)
    {
        if (num <= 0) return;

        Vector3 size = Size;
        Vector3[] vects = Vects;
        Vector3 offset;
        Vector3 uOffset;
        float euler;
        num = Mathf.Clamp(num, -3, 3);
        
        if (num > 0)//clock wise
        {
            euler = 90;
            offset = vects[2] * size[2];
            uOffset = new Vector3(1, 0, 0);
        }
        else//counter clck wise
        {
            euler = -90;
            offset = vects[2] * size[2] * -1;
            uOffset = new Vector3(-1, 0, 0);
        }
        offset = vects[2] * size[2];
        Matrix4x4 mt = Matrix4x4.Translate(uOffset);
        Matrix4x4 mr = Matrix4x4.Rotate(Quaternion.Euler(new Vector3(0, -euler, 0)));

        Mesh m = GetComponent<MeshFilter>().mesh;
        Vector3[] opts = m.vertices.Clone() as Vector3[];
        for (int i = 0; i < opts.Length; i++)
        {
            opts[i] = mr.MultiplyPoint3x4(opts[i]);
            opts[i] = mt.MultiplyPoint3x4(opts[i]);
        }
        m.vertices = opts;
        m.RecalculateBounds();
        m.RecalculateNormals();

        transform.Rotate(new Vector3(0, euler, 0));
        Vector3 scale = transform.localScale;
        scale[0] = transform.localScale[2];
        scale[2] = transform.localScale[0];
        transform.localScale = scale;
        transform.position += offset;

        PivotTurn(num - 1);

    }
    public void PivotMirror(int axis)
    {
        //print("Meshable.Type=" + meshable.GetType().FullName);
        meshable.bbox = BoundingBox.Reflect(meshable.bbox,axis);
        //meshable.ReverseSide();
        //Debug.Log("---pre Reverse----");
        //foreach (Vector3 item in ((Extrusion)meshable).polygon.vertices)
        //{
        //    Debug.Log(item);
        //}
        
        //((Extrusion)meshable).Reverse();
        //Debug.Log("---post Reverse-----");
        //foreach (Vector3 item in ((Extrusion)meshable).polygon.vertices)
        //{
        //    Debug.Log(item);
        //}
        SetMeshable(meshable);
    }
    
    public virtual ShapeObject Clone( bool geometryOnly = true)
    {
        ShapeObject so = ShapeObject.CreateBasic();
        CloneTo(so);
        return so;
    }
    public void CloneTo(ShapeObject so, bool geometryOnly=true)
    {
        so.transform.position = transform.position;
        so.transform.up = transform.up;
        so.transform.localScale = transform.localScale;
        so.transform.localRotation = transform.localRotation;
        so.meshable = (Meshable)(meshable.Clone());
        so.GetComponent<MeshFilter>().mesh = GetComponent<MeshFilter>().mesh;
        if (!geometryOnly)
        {
            so.name = name;
            so.step = step;
            //so.parentRule = parentRule;
        }
    }
}
