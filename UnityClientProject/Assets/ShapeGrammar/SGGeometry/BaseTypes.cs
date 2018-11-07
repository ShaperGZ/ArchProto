using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using System;

namespace SGGeometry
{
    //Base classes for geometries
    public class GLRender
    {
        public static Material lineMat;
        public static Material confirmMat(Material m)
        {
            if (m == null)
            {
                if (GLRender.lineMat == null)
                {
                    GLRender.lineMat = GetLineMaterial();
                }
                m = GLRender.lineMat;
            }
            return m;
        }
        public static Material GetLineMaterial()
        {
            if (lineMat != null)
            {
                return lineMat;
            }

            Material lineMaterial;
            // Unity has a built-in shader that is useful for drawing
            // simple colored things.
            Shader shader = Shader.Find("Hidden/Internal-Colored");
            lineMaterial = new Material(shader);
            lineMaterial.hideFlags = HideFlags.HideAndDontSave;
            // Turn on alpha blending
            lineMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            lineMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            // Turn backface culling off
            lineMaterial.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
            // Turn off depth writes
            lineMaterial.SetInt("_ZWrite", 0);
            lineMat = lineMaterial;
            return lineMaterial;
        }
        public static void Polyline(Vector3[] pts, bool closed, Material mat, Color color, Transform transform = null)
        {
            mat = confirmMat(mat);
            mat.SetPass(0);

            GL.PushMatrix();
            if (transform != null)
            {
                GL.MultMatrix(transform.localToWorldMatrix);
            }
            GL.Begin(GL.LINE_STRIP);
            GL.Color(color);
            foreach (Vector3 v in pts)
            {
                GL.Vertex(v);
            }
            if (closed)
            {
                GL.Vertex(pts[0]);
            }
            GL.End();
            GL.PopMatrix();
            //Debug.Log("on render object");
        }
        public static void Lines(Vector3[] pts, Color color, Transform transform = null)
        {
            Material mat = GetLineMaterial();
            mat.SetPass(0);

            GL.PushMatrix();
            if (transform != null)
            {
                GL.MultMatrix(transform.localToWorldMatrix);
            }
            GL.Begin(GL.LINES);
            GL.Color(color);
            foreach (Vector3 v in pts)
            {
                GL.Vertex(v);
            }
            GL.End();
            GL.PopMatrix();
            //Debug.Log("on render object");
        }
        public static void GridPlane(Vector3 position, Vector3 normal, Vector3 vectU, Vector3 vectV, float gridSize = 0.1f, int gridCount = 10)
        {
            //make points

            Vector3[] pu = new Vector3[gridCount];
            Vector3[] pv = new Vector3[gridCount];
            float w = gridCount * gridCount;
            float max = w / 2;
            float min = -max;

            Vector3 left = position - vectU * max;
            Vector3 bot = position - vectV * max;

            for (int i = 0; i < gridCount; i++)
            {
                pu[i] = left + (vectU * gridSize * i);
                pv[i] = bot + (vectV * gridSize * i);
            }

            Material mat = GetLineMaterial();
            mat.SetPass(0);
            GL.PushMatrix();
            //if (transform != null)
            //{
            //    GL.MultMatrix(transform.localToWorldMatrix);
            //}
            GL.Begin(GL.LINE_STRIP);
            GL.Color(Color.grey);
            foreach (Vector3 v in pu)
            {
                GL.Vertex(v);
                GL.Vertex(v + vectV * w);
            }
            foreach (Vector3 v in pv)
            {
                GL.Vertex(v);
                GL.Vertex(v + vectU * w);
            }
            GL.Color(Color.red);
            GL.Vertex(position);
            GL.Vertex(position + vectU * max);
            GL.Color(Color.green);
            GL.Vertex(position);
            GL.Vertex(position + vectV * max);
            GL.Color(Color.blue);
            GL.Vertex(position);
            GL.Vertex(position + normal * max / 2);


            GL.End();
            GL.PopMatrix();
        }
    }
    public class BoundingBox
    {
        public Vector3 position;
        public Vector3[] vects;
        public Vector3 size;
        public Vector3[] vertices;
        public BoundingBox()
        {
        }
        public Vector3 GetSignedSize()
        {
            Vector3 s = size;
            if (Vector3.Cross(vects[0], vects[2]).y > 0)
                s[0] *= -1;
            return s;
        }
        public BoundingBox Clone()
        {
            BoundingBox bbox = new BoundingBox();
            bbox.position = position * 1;
            bbox.vects = vects.ToArray<Vector3>();
            bbox.size = size * 1;
            bbox.vertices = vertices.ToArray();
            return bbox;
        }
        public virtual Vector3 GetOriginFromAlignment(Alignment? alignment)
        {
            if(alignment.HasValue)
            {
                switch (alignment.Value)
                {
                    case Alignment.Center:
                        return (vertices[0] + vertices[2]) / 2;
                    case Alignment.Center3D:
                        return (vertices[0] + vertices[6]) / 2;
                    case Alignment.E:
                        return (vertices[2] + vertices[1]) / 2;
                    case Alignment.W:
                        return (vertices[0] + vertices[3]) / 2;
                    case Alignment.S:
                        return (vertices[0] + vertices[1]) / 2;
                    case Alignment.N:
                        return (vertices[2] + vertices[3]) / 2;
                    case Alignment.SE:
                        return vertices[1];
                    case Alignment.SW:
                        return vertices[0];
                    case Alignment.NE:
                        return vertices[2];
                    case Alignment.NW:
                        return vertices[3];
                    default:
                        return vertices[0];
                }
            }
            return vertices[0];
        }
        public string Format()
        {
            string t = "";
            t = string.Format("pos:{0} vect0:{1} size:{2}", position, vects[0], size);
            t += string.Format("signed scale={0}", GetSignedSize());
            return t;
        }
        public static BoundingBox Reflect(BoundingBox bbox, int axis)
        {
            Vector3[] pts = new Vector3[8];
            switch (axis){
                case 0:
                    pts[0] = bbox.vertices[1];
                    pts[1] = bbox.vertices[0];
                    pts[2] = bbox.vertices[3];
                    pts[3] = bbox.vertices[2];
                    pts[4] = bbox.vertices[5];
                    pts[5] = bbox.vertices[4];
                    pts[6] = bbox.vertices[7];
                    pts[7] = bbox.vertices[6];
                    break;
                default:
                    pts[0] = bbox.vertices[3];
                    pts[1] = bbox.vertices[2];
                    pts[2] = bbox.vertices[1];
                    pts[3] = bbox.vertices[0];
                    pts[4] = bbox.vertices[7];
                    pts[5] = bbox.vertices[6];
                    pts[6] = bbox.vertices[5];
                    pts[7] = bbox.vertices[4];
                    break;
            }

            BoundingBox nbbox = new BoundingBox();
            nbbox.vertices = pts;
            nbbox.SetVectsAndSizeFromVertices();
            return nbbox;
        }
        public static BoundingBox Reflect_OLD(BoundingBox bbox, int axis)
        {
            //Debug.Log(counter + " run Reflect");
            //DebugSpheres(bbox,Color.blue, 10f);
            Debug.Log("bbox=" + bbox);
            Vector3[] pts = bbox.vertices.Clone() as Vector3[];
            Vector3 reflection = new Vector3(1, 1, 1);
            reflection[axis] *= -1;
            Vector3 from = bbox.vects[0];
            Matrix4x4 mr1 = Matrix4x4.Rotate(Quaternion.FromToRotation(from, new Vector3(1, 0, 0)));
            Matrix4x4 mMrr = Matrix4x4.Scale(reflection);
            Matrix4x4 mr2 = Matrix4x4.Rotate(Quaternion.FromToRotation(new Vector3(1, 0, 0), from));

            for (int i = 0; i < pts.Length; i++)
            {
                pts[i] -= bbox.position;
                pts[i] = mr1.MultiplyPoint3x4(pts[i]);
                pts[i] = mMrr.MultiplyPoint3x4(pts[i]);
                pts[i] = mr2.MultiplyPoint3x4(pts[i]);
                pts[i] += bbox.position;
                pts[i] += bbox.vects[axis] * bbox.size[axis];
            }
            BoundingBox outbox = new BoundingBox();
            outbox.vertices = pts;
            outbox.SetVectsAndSizeFromVertices();
            //DebugSpheres(outbox, Color.red, 10f);
            return outbox;
        }
        public static void DebugSpheres(BoundingBox bbox, Color c, float d)
        {
            GameObject og;
            og = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            og.GetComponent<MeshRenderer>().material.color = c;
            og.transform.localScale = new Vector3(d * 2, d * 2, d * 2);
            og.transform.position = bbox.vertices[0];

            foreach (Vector3 v in bbox.vertices)
            {
                GameObject o;
                o = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                o.GetComponent<MeshRenderer>().material.color = c;
                o.transform.localScale = new Vector3(d, d, d);
                o.transform.position = v;
                o.transform.parent = og.transform;
            }

        }
        public void SetVectsAndSizeFromVertices()
        {
            position = vertices[0];
            vects = new Vector3[3]
            {
                (vertices[1]-vertices[0]).normalized,
                (vertices[4]-vertices[0]).normalized,
                (vertices[3]-vertices[0]).normalized
            };
            size = new Vector3
            (
                Vector3.Distance(vertices[0], vertices[1]),
                Vector3.Distance(vertices[0], vertices[4]),
                Vector3.Distance(vertices[0], vertices[3])
            );
        }
        public static BoundingBox CreateFromBox(Vector3 pos, Vector3[] vects, Vector3 size)
        {
            Vector3[] pts = new Vector3[8];
            Vector3[] magVs = new Vector3[3];

            //Vector3 reflection = new Vector3(1, 1, 1);


            for (int i = 0; i < 3; i++)
            {
                magVs[i] = vects[i] * size[i];
            }
            pts[0] = pos;
            pts[1] = pos + magVs[0];
            pts[2] = pts[1] + magVs[2];
            pts[3] = pos + magVs[2];

            for (int i = 0; i < 4; i++)
            {
                pts[i] += magVs[1];
            }

            BoundingBox bbox = new BoundingBox();
            bbox.position = pos;
            bbox.vects = vects;
            bbox.size = size;
            return bbox;
        }
        public static BoundingBox CreateFromPoints(Vector3[] pts, Vector3[] vects, Vector3 reflection)
        {
            BoundingBox bbox = new BoundingBox();
            reflection.Normalize();

            Plane[] plnMins = new Plane[3];
            Plane[] plnMaxs = new Plane[3];
            Vector3[] ptMins = new Vector3[3];
            Vector3[] ptMaxs = new Vector3[3];

            for (int i = 0; i < 3; i++)
            {
                plnMins[i] = new Plane(-vects[i], pts[0]);
                plnMaxs[i] = new Plane(vects[i], pts[0]);
                ptMins[i] = pts[0];
                ptMaxs[i] = pts[0];
            }
            for (int i = 0; i < pts.Length; i++)
            {
                for (int j = 0; j < 3; j++)
                {
                    if (plnMins[j].GetSide(pts[i]))
                    {
                        plnMins[j] = new Plane(-vects[j], pts[i]);
                        ptMins[j] = pts[i];
                    }
                    if (plnMaxs[j].GetSide(pts[i]))
                    {
                        plnMaxs[j] = new Plane(vects[j], pts[i]);
                        ptMaxs[j] = pts[i];
                    }

                }
            }

            Vector3[] horPts = new Vector3[4];
            horPts[0] = plnMins[2].ClosestPointOnPlane(ptMins[0]);
            horPts[1] = plnMins[2].ClosestPointOnPlane(ptMaxs[0]);
            horPts[3] = plnMaxs[2].ClosestPointOnPlane(ptMins[0]);
            horPts[2] = plnMaxs[2].ClosestPointOnPlane(ptMaxs[0]);

            Vector3[] outPts = new Vector3[8];
            for (int i = 0; i < 4; i++)
            {
                outPts[i] = plnMins[1].ClosestPointOnPlane(horPts[i]);
                outPts[i + 4] = plnMaxs[1].ClosestPointOnPlane(horPts[i]);
            }

            bbox.position = outPts[0];
            bbox.vects = vects;
            bbox.size = new Vector3(
                Vector3.Distance(outPts[0], outPts[1]),
                Vector3.Distance(outPts[0], outPts[4]),
                Vector3.Distance(outPts[0], outPts[3])
                );
            //bbox.size = new Vector3(
            //    Vector3.Distance(outPts[0], outPts[1]) * reflection[0],
            //    Vector3.Distance(outPts[0], outPts[4]) * reflection[1],
            //    Vector3.Distance(outPts[0], outPts[3]) * reflection[2]
            //    );
            bbox.vertices = outPts;
            return bbox;
        }
        public static BoundingBox CreateFromPoints(Vector3[] pts, BoundingBox refBbox)
        {
            Vector3[] vects = refBbox.vects;
            return CreateFromPoints(pts, vects, refBbox.size);
        }
        public static BoundingBox CreateFromPoints(Vector3[] pts, Vector3? direction = null)
        {
            Vector3 vu;
            if (direction.HasValue) vu = direction.Value;
            else vu = new Vector3(1, 0, 0);
            BoundingBox bbox = new BoundingBox();
            Vector3[] vects = new Vector3[3];

            vects[0] = vu.normalized;
            vects[1] = Vector3.up;
            vects[2] = Vector3.Cross(vects[0], vects[1]);

            Plane[] plnMins = new Plane[3];
            Plane[] plnMaxs = new Plane[3];
            Vector3[] ptMins = new Vector3[3];
            Vector3[] ptMaxs = new Vector3[3];

            for (int i = 0; i < 3; i++)
            {
                if (pts == null) throw new System.Exception("pts is null");
                if (pts[0] == null) throw new System.Exception("pts[0] is null");
                if (vects == null) throw new System.Exception("vects is null");
                if (vects[i] == null) throw new System.Exception("vects[i] is null");
                Vector3 vtest = vects[i];
                //Debug.Log(pts.Length);
                Vector3 ptest = pts[0];

                plnMins[i] = new Plane(-vects[i], pts[0]);
                plnMaxs[i] = new Plane(vects[i], pts[0]);
                ptMins[i] = pts[0];
                ptMaxs[i] = pts[0];
            }
            for (int i = 0; i < pts.Length; i++)
            {
                for (int j = 0; j < 3; j++)
                {
                    if (plnMins[j].GetSide(pts[i]))
                    {
                        plnMins[j] = new Plane(-vects[j], pts[i]);
                        ptMins[j] = pts[i];
                    }
                    if (plnMaxs[j].GetSide(pts[i]))
                    {
                        plnMaxs[j] = new Plane(vects[j], pts[i]);
                        ptMaxs[j] = pts[i];
                    }

                }
            }

            Vector3[] horPts = new Vector3[4];
            horPts[0] = plnMins[2].ClosestPointOnPlane(ptMins[0]);
            horPts[1] = plnMins[2].ClosestPointOnPlane(ptMaxs[0]);
            horPts[3] = plnMaxs[2].ClosestPointOnPlane(ptMins[0]);
            horPts[2] = plnMaxs[2].ClosestPointOnPlane(ptMaxs[0]);

            Vector3[] outPts = new Vector3[8];
            for (int i = 0; i < 4; i++)
            {
                outPts[i] = plnMins[1].ClosestPointOnPlane(horPts[i]);
                outPts[i + 4] = plnMaxs[1].ClosestPointOnPlane(horPts[i]);
            }

            bbox.position = outPts[0];
            bbox.vects = vects;
            bbox.size = new Vector3(
                Vector3.Distance(outPts[0], outPts[1]),
                Vector3.Distance(outPts[0], outPts[4]),
                Vector3.Distance(outPts[0], outPts[3])
                );
            bbox.vertices = outPts;
            return bbox;
        }

    }
    public enum Alignment
    {
        Center,Center3D,S,N,W,E,SE,SW,NE,NW
    }
    public class GeometryBase
    {
        public Material _lineMatDefault;
        public Color color = Color.white;
        public string name = "unnamedGeometry";
        public Material lineMatDefault
        {
            get
            {
                if (_lineMatDefault == null)
                    _lineMatDefault = CreateLineMaterial();
                return _lineMatDefault;
            }
            set
            {
                _lineMatDefault = value;
            }
        }

        public GeometryBase() { }
        public static Material CreateLineMaterial()
        {
            Material lineMaterial;
            // Unity has a built-in shader that is useful for drawing
            // simple colored things.
            Shader shader = Shader.Find("Hidden/Internal-Colored");
            lineMaterial = new Material(shader);
            lineMaterial.hideFlags = HideFlags.HideAndDontSave;
            // Turn on alpha blending
            lineMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            lineMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            // Turn backface culling off
            lineMaterial.SetInt("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
            // Turn off depth writes
            lineMaterial.SetInt("_ZWrite", 0);
            return lineMaterial;
        }
        public virtual void update() { }
        //do regular OpenGL drawings
        public virtual void OnRenderObject() { }
        //post rendering GL drawings
        public virtual void OnPostRender() { }

    }
    public class PointsBase : GeometryBase
    {
        public BoundingBox bbox;
        public Vector3[] vertices;
        public PointsBase()
        {
            vertices = new Vector3[0];
        }
        public PointsBase(Vector3[] pts)
        {
            vertices = pts;
        }
        public Vector3 LongestDirection(bool normalized = true)
        {
            Vector3? ld = PointsBase.LongestDirection(vertices, normalized);
            return ld.Value;
        }
        public virtual void Translate(Vector3 translation)
        {
            for (int i = 0; i < vertices.Length; i++)
            {
                vertices[i] += translation;
            }
        } 


        public virtual PointsBase Clone()
        {
            PointsBase pb = new PointsBase();
            if (bbox != null)
                pb.bbox = bbox.Clone();
            pb.vertices = vertices.Clone() as Vector3[];
            return pb;
        }
        public static Vector3[] transform(Vector3[] ipts, Matrix4x4 matrix)
        {
            Vector3[] pts = ipts.Clone() as Vector3[];
            for (int i = 0; i < pts.Length; i++)
            {
                pts[i] = matrix * pts[i];
            }
            return pts;
        }
        public static Vector3? LongestDirection(Vector3[] pts, bool normalized = true)
        {
            if (pts.Length < 2) return null;
            Vector3 ld = pts[1] - pts[0];
            for (int i = 0; i < pts.Length; i++)
            {
                int j = i + 1;
                if (j >= pts.Length) j = 0;
                Vector3 direct = pts[j] - pts[i];
                if (direct.magnitude > ld.magnitude)
                {
                    ld = direct;
                }
            }
            return ld;
        }
        public static Vector3[] MultiplyMatrix(Vector3[] pts, Matrix4x4 matrix)
        {
            for (int i = 0; i < pts.Length; i++)
            {
                pts[i] = matrix * pts[i];
            }
            return pts;
        }
        public static Vector3[] Translate(Vector3[] pts, Vector3 vect)
        {
            for (int i = 0; i < pts.Length; i++)
            {
                pts[i] += vect;
            }
            return pts;
        }
        public static Vector3[] Rotate(Vector3[] pts, Vector3 degrees)
        {
            Quaternion q = Quaternion.EulerRotation(degrees);
            Matrix4x4 matrix = Matrix4x4.Rotate(q);
            for (int i = 0; i < pts.Length; i++)
            {
                pts[i] = matrix * pts[i];
            }
            return pts;
        }
        public static Vector3[] offset(Vector3[] pts, float d)
        {
            List<Vector3> rawOffsetPts = new List<Vector3>();
            Vector3[] outpts = new Vector3[pts.Length];
            Vector3[] vns = new Vector3[pts.Length];
            Ray[] rays = new Ray[pts.Length];
            if (pts.Length > 2)
            {
                Vector3 fn = Vector3.Cross((pts[2] - pts[1]).normalized, (pts[0] - pts[1]).normalized);
                Debug.Log(fn);
                //get all the offseted rays
                for (int i = 0; i < pts.Length; i++)
                {
                    int j = i + 1;
                    if (j >= pts.Length) j = 0;
                    Vector3 vect = (pts[i] - pts[j]).normalized;
                    Vector3 vn = Vector3.Cross(vect, fn);
                    vn = vn * d;
                    Debug.Log(i + ":" + vn);
                    vns[i] = vn;
                    Ray r = new Ray(pts[i] + vn, vect);
                    rays[i] = r;
                    rawOffsetPts.Add(pts[i] + vn);
                    rawOffsetPts.Add(pts[j] + vn);
                }
                //get offset points
                for (int i = 0; i < rays.Length; i++)
                {
                    int j = i - 1;
                    if (j < 0) j = rays.Length - 1;
                    Plane pln = new Plane(vns[i], rays[i].origin);
                    float t;
                    pln.Raycast(rays[j], out t);
                    Vector3 xp = rays[j].GetPoint(t);
                    outpts[i] = (xp);
                }
                return outpts;
                //return rawOffsetPts.ToArray();
            }
            return null;
        }
        public static Vector3[] Scale(Vector3[] pts, Vector3 scale)
        {
            for (int i = 0; i < pts.Length; i++)
            {
                for (int j = 0; j < 3; j++)
                    pts[i][j] *= scale[j];
            }
            return pts;
        }
        public static Vector3[] Scale(Vector3[] pts, Vector3 scale, Vector3[] vects, Vector3 origin)
        {
            Quaternion q1 = Quaternion.FromToRotation(vects[0], new Vector3(1, 0, 0));
            Quaternion q2 = Quaternion.FromToRotation(new Vector3(1, 0, 0), vects[0]);
            Matrix4x4 matrix1 = Matrix4x4.Rotate(q1);
            Matrix4x4 matrix2 = Matrix4x4.Rotate(q2);

            for (int i = 0; i < pts.Length; i++)
            {
                //push
                pts[i] = pts[i] - origin;
                pts[i] = matrix1 * pts[i];
                //scale
                for (int j = 0; j < 3; j++)
                    pts[i][j] *= scale[j];
                //pop
                pts[i] = matrix2 * pts[i];
                pts[i] = pts[i] + origin;
            }
            return pts;
        }

        public BoundingBox GetBoundingBox(Vector3? direction = null)
        {
            return BoundingBox.CreateFromPoints(vertices, direction);
        }
        public BoundingBox GetBoundingBox(BoundingBox bbox)
        {
            return BoundingBox.CreateFromPoints(vertices, bbox);
        }
    }
    public class TrianglesBase : PointsBase
    {
        public int[] triangles;
        public Vector3[] normals;
        public TrianglesBase() : base()
        {
            triangles = new int[0];
            normals = new Vector3[0];
        }
    }

    public class Meshable : TrianglesBase
    {
        public List<Polyline> displayLines = new List<Polyline>();
        public Vector3 direction = new Vector3(1, 0, 0);

        
        public Meshable() : base()
        {

        }
        public Mesh GetMeshForm()
        {
            Mesh m = new Mesh();
            m.vertices = this.vertices;
            m.triangles = this.triangles;
            //if(normals!=null && normals.Length>0 && normals.Length==vertices.Length)
            //    m.normals = this.normals;

            //m.RecalculateNormals();
            //m.RecalculateBounds();
            return m;
        }
        public virtual void Reverse()
        {
            vertices.Reverse();
        }
        public override PointsBase Clone()
        {
            Meshable mb = new Meshable();
            mb.vertices = vertices.Clone() as Vector3[];
            mb.triangles = triangles.Clone() as int[];
            //if (HasNormal())
            //    mb.normals = normals;
            if (bbox != null)
                mb.bbox = bbox.Clone();
            return mb;

        }
        public virtual Meshable Transform(Matrix4x4 matrix, bool duplicate = false)
        {
            if (duplicate)
            {
                Meshable outmb = new Meshable();
                outmb.vertices = PointsBase.transform(vertices, matrix);
                outmb.triangles = triangles.Clone() as int[];
                return outmb;
            }
            else
                vertices = PointsBase.transform(vertices, matrix);
            return null;

        }
        public virtual Meshable Scale(Vector3 scale, Vector3[] vects, Vector3 origin, bool duplicate = true)
        {
            Vector3[] pts = vertices.Clone() as Vector3[];
            pts = PointsBase.Scale(pts, scale, vects, origin);
            if (duplicate)
            {
                Meshable mb = new Meshable();
                mb.vertices = pts;
                mb.triangles = triangles.Clone() as int[];
                return mb;
            }
            else
            {
                vertices = pts;
            }
            return null;
        }

        public virtual void ReverseTriangle()
        {
            int[] ntris = new int[triangles.Length];
            for (int i = 0; i < triangles.Length; i += 3)
            {
                ntris[i] = triangles[i];
                ntris[i + 1] = triangles[i + 2];
                ntris[i + 2] = triangles[i + 1];
            }
            triangles = ntris;
        }
        public virtual void ReverseSide()
        {
            System.Array.Reverse(vertices);
            //ReverseTriangle();
        }
        public Polygon[] GridByMag(float w, float h)
        {
            if (vertices.Length != 4) return null;
            float sizeX = Vector3.Distance(vertices[0], vertices[1]);
            float sizeY = Vector3.Distance(vertices[0], vertices[3]);
            float countX = Mathf.Round(sizeX / w);
            float countY = Mathf.Round(sizeY / h);
            return GridByCount((int)countX, (int)countY);
        }
        public Polygon[] GridByCountFake(int w, int h)
        {
            displayLines.Clear();
            if (vertices.Length != 4) return null;
            Polygon[] grid = new Polygon[w * h];
            float sx, sy;
            Vector3 vx, vy;
            vx = vertices[1] - vertices[0];
            vy = vertices[3] - vertices[0];
            sx = vx.magnitude;
            sy = vy.magnitude;

            float nx = sx / w;
            float ny = sy / h;

            vx.Normalize();
            vy.Normalize();

            Vector3 mvx = vx * nx;
            Vector3 mvy = vy * ny;
            Polyline[] lines = new Polyline[w + h];
            for (int i = 0; i < w; i++)
            {
                Vector3[] upts = new Vector3[2];
                upts[0] = vertices[0] + (mvx * i);
                upts[1] = upts[0] + mvy;
                lines[i] = new Polyline(upts);
            }
            for (int i = 0; i < h; i++)
            {
                Vector3[] upts = new Vector3[2];
                upts[0] = vertices[0] + (mvy * i);
                upts[1] = upts[0] + mvx;
                lines[w + i] = new Polyline(upts);
            }
            displayLines.AddRange(lines);
            return grid;
        }
        public Polygon[] GridByCount(int w, int h)
        {
            if (vertices.Length != 4) return null;
            Polygon[] grid = new Polygon[w * h];
            float sx, sy;
            Vector3 vx, vy;
            vx = vertices[1] - vertices[0];
            vy = vertices[3] - vertices[0];
            sx = vx.magnitude;
            sy = vy.magnitude;

            float nx = sx / w;
            float ny = sy / h;

            vx.Normalize();
            vy.Normalize();

            Vector3 mvx = vx * nx;
            Vector3 mvy = vy * ny;

            for (int i = 0; i < w; i++)
            {
                for (int j = 0; j < h; j++)
                {
                    int index = (j * w + i);
                    Vector3[] upts = new Vector3[4];
                    upts[0] = vertices[0] + (mvx * i) + (mvy * j);
                    upts[1] = upts[0] + mvx;
                    upts[2] = upts[1] + mvy;
                    upts[3] = upts[0] + mvy;
                    grid[index] = new Polygon(upts);
                }

            }
            return grid;
        }

        /// <summary>
        /// merges the new given Meshable onto its own data
        /// also return the given Meshable with adjusted triangle index  
        /// </summary>
        /// <param name="m"></param>
        /// <returns></returns>
        public void merge(Meshable m)
        {
            int vertCount = this.vertices.Length;
            int[] tris = new int[m.triangles.Length];
            for (int i = 0; i < m.triangles.Length; i++)
            {
                tris[i] = m.triangles[i] + vertCount;
            }

            this.vertices = (this.vertices.Concat(m.vertices)).ToArray();
            this.triangles = (this.triangles.Concat(tris)).ToArray();
            //if (m.HasNormal())
            //{
            //    this.normals = (this.normals.Concat(m.normals)).ToArray();
            //}
        }
        public virtual Meshable[] SplitByPlane(Plane pln)
        {
            Polyline edge;
            return SplitByPlane(pln, out edge);
        }
        public virtual Meshable[] SplitByPlane(Plane pln, out Polyline nakedEdge)
        {
            //Debug.Log("split in Meshable");
            int nullP = 0;
            foreach (Vector3 p in vertices)
            {
                if (p == null) nullP++;
            }
            if (nullP > 0)
                Debug.LogWarningFormat("FOUND NULL POINTS, COUNT={0}", nullP);

            //split polygon by a plane and returns the naked edge
            Vector3? nkp1 = new Vector3?();
            Vector3? nkp2 = new Vector3?();
            List<Vector3> left = new List<Vector3>();
            List<Vector3> right = new List<Vector3>();

            Vector3 lastP = vertices[vertices.Length - 1];
            bool lastIsRight = pln.GetSide(lastP);
            bool isRight;
            List<Vector3> nakedPts = new List<Vector3>();

            for (int i = 0; i < vertices.Length; i++)
            {
                Vector3 p = vertices[i];
                isRight = pln.GetSide(p);

                if (lastIsRight != isRight)
                {
                    Ray r = new Ray(p, lastP - p);
                    float d;
                    pln.Raycast(r, out d);
                    Vector3 xp = r.GetPoint(d);
                    left.Add(xp);
                    right.Add(xp);
                    nakedPts.Add(xp);
                }
                if (isRight) right.Add(p);
                else left.Add(p);

                lastIsRight = isRight;
                lastP = p;
            }
            Polygon[] pgs = new Polygon[2];
            if (left.Count > 2) pgs[0] = new Polygon(left.ToArray());
            else pgs[0] = null;
            if (right.Count > 2) pgs[1] = new Polygon(right.ToArray());
            else pgs[1] = null;

            //Debug.Log(string.Format("leg={0} right={1}", left.Count, right.Count));

            if (nakedPts.Count > 1)
            {
                nakedEdge = new Polyline(nakedPts.ToArray());
            }
            else
            {
                //Debug.LogWarning("no naked edge found!");
                nakedEdge = new Polyline();
            }
            return pgs;
        }
        public Mesh GetNormalizedMesh(BoundingBox bbox=null)
        {
            if (bbox == null)
            {
                bbox = this.bbox;
            }
            //Vector3 org = bbox.position;
            Vector3 org = bbox.position;
            Vector3 to = new Vector3(1, 0, 0);
            Vector3 signedSize = bbox.GetSignedSize();
            if (signedSize[0] < 0)
            {
                to[0] *= -1;

            }
            if (bbox.vects[0].GetType() != typeof(Vector3)) throw new System.Exception("check bbox.vects");
            Quaternion q = Quaternion.FromToRotation(bbox.vects[0], to);
            Matrix4x4 mRotate = Matrix4x4.Rotate(q);

            
            Vector3 scale = bbox.GetSignedSize();
            for (int i = 0; i < 3; i++)
            {
                if (scale[i] == 0) scale[i] = 1;
                scale[i] = 1 / scale[i];
            }
            Matrix4x4 mScale = Matrix4x4.Scale(scale);
            Mesh m = GetMeshForm();
            Vector3[] verts = m.vertices;
            for (int i = 0; i < verts.Length; i++)
            {

                verts[i] -= org;
                verts[i] = mRotate.MultiplyPoint3x4(verts[i]);
                verts[i] = mScale.MultiplyPoint3x4(verts[i]);
                //verts[i].Scale(scale);


                //verts[i] += new Vector3(0.5f, 0, 0.5f);
            }
            
            m.vertices = verts;
            if (signedSize[0] < 0)
            {
                //flip triangles
                int[] tris = triangles.ToArray();
                for (int i = 0; i < triangles.Length; i += 3)
                {
                    tris[i] = triangles[i + 2];
                    tris[i + 1] = triangles[i + 1];
                    tris[i + 2] = triangles[i];
                }
                m.triangles = tris;
            }
            m.RecalculateTangents();
            m.RecalculateNormals();
            m.RecalculateBounds();
            return m;
        }
    }
    public class CompositMeshable : Meshable
    {
        public List<Meshable> components;
        public CompositMeshable()
        {
            this.components = new List<Meshable>();
        }
        public CompositMeshable(IEnumerable<Meshable> mbs)
        {
            this.components = new List<Meshable>();
            if (mbs != null)
                AddRange(mbs);
        }
        public void Add(Meshable m)
        {
            if (m != null)
            {
                merge(m);
                components.Add(m);
            }

        }
        public override void Translate(Vector3 offset)
        {
            base.Translate(offset);
            foreach(Meshable m in components){
                m.Translate(offset); 
            }
        }
        public void AddRange(IEnumerable<Meshable> ms)
        {
            foreach (Meshable m in ms)
            {
                this.Add(m);
            }
        }
        public void Clear()
        {
            components.Clear();
            vertices = new Vector3[0];
            triangles = new int[0];
        }

        public override void Reverse()
        {
            Debug.Log("Composit meshabel Reverse");
            base.Reverse();
        }

        /// <summary>
        /// returns Polygon components facing given direction
        /// </summary>
        /// <param name="direction">0:s, 1:n, 2:e, 3:w</param>
        /// <returns></returns>
        public Polygon[] GetFacing(int direction)
        {
            //0:s, 1:n, 2:e, 3:w
            List<Polygon> possitive = new List<Polygon>();
            List<Polygon> neggative = new List<Polygon>();
            Vector3 compare;
            if (direction <= 1){compare = new Vector3(0, 0, -1);}
            else { compare = new Vector3(1, 0, 0); }
            foreach (Meshable mb in components)
            {
                Polygon pg = (Polygon)mb;
                float dot = Vector3.Dot(pg.GetNormal(), compare);
                if (dot > 0.5) { possitive.Add(pg); }
                else if (dot < -0.5) { neggative.Add(pg); }
            }

            if (direction == 0 || direction == 2) return possitive.ToArray();
            return neggative.ToArray();
        }
        public Meshable Get(int index)
        {
            return this.components[index];
        }

        public override PointsBase Clone()
        {
            List<Meshable> mbs = new List<Meshable>();
            for (int i = 0; i < components.Count; i++)
            {
                mbs.Add((Meshable)components[i].Clone());
            }
            CompositMeshable mb = new CompositMeshable(mbs);
            mb.vertices = vertices.Clone() as Vector3[];
            mb.triangles = triangles.Clone() as int[];
            if (bbox != null)
                mb.bbox = bbox.Clone();
            return mb;
        }
        public override void ReverseTriangle()
        {
            base.ReverseTriangle();
            foreach (Meshable m in components)
            {
                m.ReverseTriangle();
            }
        }
        public override void ReverseSide()
        {
            //base.ReverseTriangle();
            vertices = new Vector3[0];
            triangles = new int[0];
            foreach (Meshable m in components)
            {
                m.ReverseSide();
                merge(m);
            }
        }
        public override Meshable Transform(Matrix4x4 matrix, bool duplicate = false)
        {
            List<Meshable> mbs = new List<Meshable>();

            foreach (Meshable m in components)
            {
                mbs.Add(m.Transform(matrix, duplicate));
            }
            if (duplicate)
            {
                CompositMeshable cmb = new CompositMeshable();
                cmb.vertices = PointsBase.transform(vertices, matrix);
                cmb.AddRange(mbs);
                return cmb;
            }
            vertices = PointsBase.transform(vertices, matrix);
            return null;
        }
        public override Meshable Scale(Vector3 scale, Vector3[] vects, Vector3 origin, bool duplicate = true)
        {
            Meshable dup = base.Scale(scale, vects, origin, duplicate);
            List<Meshable> comps = new List<Meshable>();
            foreach (Meshable m in components)
            {
                comps.Add(m.Scale(scale, vects, origin, true));
            }

            if (duplicate)
            {
                CompositMeshable cm = new CompositMeshable();
                cm.vertices = dup.vertices;
                cm.triangles = dup.triangles;
                cm.components = comps;
                return cm;
            }

            components = comps;
            return null;
        }
        public override Meshable[] SplitByPlane(Plane blade)
        {
            //Debug.Log("split in CompositMeshable");
            List<Polyline> nakedEdges = new List<Polyline>();
            List<Polygon> rights = new List<Polygon>();
            List<Polygon> lefts = new List<Polygon>();
            Form[] forms = new Form[2];
            foreach (Meshable pg in components)
            {
                //TODO: debug why there are empty components generated
                if (pg.vertices == null || pg.vertices.Length < 3)
                {
                    //Debug.LogWarning("empty components generated as CompositMeshable split");
                    continue;
                }

                Polyline edge;
                Meshable[] sides = pg.SplitByPlane(blade, out edge);
                //Debug.Log("edgeVertCount=" + edge.vertices.Length.ToString());
                if (edge.vertices.Length > 1)
                    nakedEdges.Add(edge);
                if (sides[0] != null) rights.Add((Polygon)sides[0]);
                if (sides[1] != null) lefts.Add((Polygon)sides[1]);
            }

            //Debug.Log("nakeEdgeCount=" + nakedEdges.Count.ToString());
            if (nakedEdges.Count > 2)
            {
                Vector3[] capPts = GetCapVerts(nakedEdges, blade);
                Vector3[] RcapPts = capPts.Clone() as Vector3[];
                System.Array.Reverse(RcapPts);
                Polygon leftCap = new Polygon(capPts);
                Polygon rightCap = new Polygon(RcapPts);
                rights.Add(rightCap);
                lefts.Add(leftCap);
            }
            else
            {
                Debug.LogWarning("nakedEdges.Count<2; =" + nakedEdges.Count);
            }

            if (rights.Count > 0) forms[0] = new Form(rights.ToArray());
            if (lefts.Count > 0) forms[1] = new Form(lefts.ToArray());
            return forms;
        }
        Vector3[] GetCapVerts(List<Polyline> nakedEdges, Plane pln)
        {
            //orient the edges according to plan
            Vector3 center = new Vector3();
            foreach (Polyline pl in nakedEdges)
            {
                center += pl.startPoint;
            }
            center /= nakedEdges.Count;



            for (int i = 0; i < nakedEdges.Count; i++)
            {
                Polyline pl = nakedEdges[i];
                Vector3 v1 = (center - pl.startPoint).normalized;
                Vector3 v2 = (pl.endPoint - pl.startPoint).normalized;
                Vector3 nml = Vector3.Cross(v2, v1);
                nml.Normalize();
                bool sameAsPlanNml = nml == pln.normal;
                //Debug.Log("nml=" + nml.ToString() + "pln,nml="+pln.normal.ToString() + sameAsPlanNml);
                if (!sameAsPlanNml)
                {
                    Vector3 temp = pl.vertices[0];
                    pl.vertices[0] = pl.vertices[1];
                    pl.vertices[1] = temp;
                }
            }

            List<Vector3> pts = new List<Vector3>();
            Polyline edge = nakedEdges[0];
            Polyline lastEdge = nakedEdges[nakedEdges.Count - 1];
            //pts.Add(edge.startPoint);
            int count = 0;
            while (edge != lastEdge && count < nakedEdges.Count)
            {
                //Debug.Log("edge=" + edge.ToString() + " count=" + count.ToString());
                count++;
                lastEdge = edge;
                for (int j = 0; j < nakedEdges.Count; j++)
                {
                    Polyline edge2 = nakedEdges[j];
                    //if (edge == edge2) continue;
                    bool flag = edge.endPoint == edge2.startPoint;
                    //Debug.Log(edge.startPoint.ToString() + "-" + edge.endPoint.ToString() + "," + edge2.startPoint.ToString()+"-"+edge2.endPoint.ToString() + flag.ToString());
                    if (flag)
                    {
                        pts.Add(edge2.startPoint);
                        edge = edge2;
                        break;
                    }
                }
                //string txt = "";
                //foreach(Vector3 v in pts)
                //{
                //    txt += v.ToString() + ",";
                //}
                //Debug.Log(txt);
            }
            return pts.ToArray();
        }
    }
    

    //Geometries
    public class Point : PointsBase { }
    public class Line : PointsBase
    {
        public Vector3 startPoint { get { return vertices[0]; } }
        public Vector3 endPoint { get { return vertices[1]; } }
        public Line() : base() { }
        public Line(Vector3 p1, Vector3 p2):base(new Vector3[] { p1, p2 })
        {

        }

    }
    public class Polyline : PointsBase
    {
        Color color;
        bool closed = true;
        public Vector3 startPoint { get { return vertices[0]; } }
        public Vector3 endPoint { get { return vertices[vertices.Length-1]; } }
        public Polyline() : base() { }
        public Polyline(Vector3[] pts) : base(pts)
        {
            color = new Color(1f, 0.82f, 0.25f);
        }
        public override void OnRenderObject()
        {
            base.OnRenderObject();
            SGGeometry.GLRender.Polyline(vertices, closed, null, color);
                
        }
        public Line[] Segments()
        {

            Line[] lns = new Line[this.vertices.Length-1];
            for ( int i = 0; i < vertices.Length - 1; i++)
            {
                Vector3[] pts = new Vector3[2];
                pts[0] = vertices[i];
                pts[1] = vertices[i + 1];
                Line l = new Line();
                l.vertices = pts;
                lns[i] = l;
            }
            return lns;
        }
        public override PointsBase Clone()
        {
            Polyline poly = new Polyline();
            poly.vertices = vertices.Clone() as Vector3[];
            poly.closed = closed;
            poly.color = color;
            if(bbox!=null)
                poly.bbox = bbox.Clone();
            return poly;
        }
        public virtual Polyline[] SplitByPlane(Plane pln)
        {
            
            //Debug.Log("spliting meshable");
            int nullP = 0;
            foreach (Vector3 p in vertices)
            {
                if (p == null) nullP++;
            }
            if (nullP > 0)
                Debug.LogWarningFormat("FOUND NULL POINTS, COUNT={0}", nullP);

            //split polygon by a plane and returns the naked edge
            Vector3? nkp1 = new Vector3?();
            Vector3? nkp2 = new Vector3?();
            List<Vector3> left = new List<Vector3>();
            List<Vector3> right = new List<Vector3>();

            Vector3 lastP = vertices[vertices.Length - 1];
            bool lastIsRight = pln.GetSide(lastP);
            bool isRight;
            List<Vector3> nakedPts = new List<Vector3>();

            for (int i = 0; i < vertices.Length; i++)
            {
                Vector3 p = vertices[i];
                isRight = pln.GetSide(p);

                if (lastIsRight != isRight)
                {
                    Ray r = new Ray(p, lastP - p);
                    float d;
                    pln.Raycast(r, out d);
                    Vector3 xp = r.GetPoint(d);
                    left.Add(xp);
                    right.Add(xp);
                    nakedPts.Add(xp);
                }
                if (isRight) right.Add(p);
                else left.Add(p);

                lastIsRight = isRight;
                lastP = p;
            }
            Polyline[] pls = new Polyline[2];
            if (left.Count > 2) pls[0] = new Polyline(left.ToArray());
            else pls[0] = null;
            if (right.Count > 2) pls[1] = new Polyline(right.ToArray());
            else pls[1] = null;
            
            return pls;
        }
    }
    public class Face : Meshable
    {
        public Face() : base() { }
    }
    public class Quad : Face
    {
        public Quad(Vector3[] verts) : base()
        {
            this.vertices = verts;
            this.triangles = new int[] { 0, 1, 2, 0, 2, 3 };
        }
    }
    public class Triangle : Face
    {
        public Triangle(Vector3[] verts) : base()
        {
            this.vertices = verts;
            this.triangles = new int[] { 0, 1, 2 };
        }
    }
    public class Polygon : Meshable
    {
        public Vector3 center
        {
            get
            {
                Vector3 ct = new Vector3(0, 0, 0);
                for (int i = 0; i < vertices.Length; i++)
                {
                    ct += vertices[i];
                }
                return ct / vertices.Length;
            }
        }
        Polyline boundary;
        public Polygon() : base()
        {
        }
        public Polygon(Polyline ply) : this(ply.vertices)
        {
        }
        public Polygon(Vector3[] pts):base()
        {
            boundary = new Polyline(pts);
            SetTriangles(pts);
            this.vertices = pts;
            //CalculateNormals();
        }
        void SetTriangles(Vector3[] pts)
        {
            if (pts.Length > 4)
            {
                TriangulatorV3 tr = new TriangulatorV3(pts);
                triangles = tr.Triangulate();
            }
            else if (pts.Length == 4)
            {
                triangles = new int[] { 0, 2, 1, 0, 3, 2 };
            }
            else if (pts.Length == 3)
            {
                triangles = new int[] { 0, 2, 1 };
            }
        }
        public Vector3 GetNormal()
        {
            Vector3 v1 = vertices[2] - vertices[1];
            Vector3 v2 = vertices[0] - vertices[1];
            Vector3 n = Vector3.Cross(v1.normalized, v2.normalized);
            return n;
        }
        public float Area()
        {
            float area = 0;
            for (int i = 0; i < triangles.Length; i+=3)
            {
                Vector3 p1 = vertices[triangles[i]];
                Vector3 p2 = vertices[triangles[i+1]];
                Vector3 p3 = vertices[triangles[i+2]];
                area += triangleArea(p1, p2, p3);
            }
            return area;
        }
        public float triangleArea(Vector3 p1, Vector3 p2, Vector3 p3)
        {
            float area = 0;
            float valueA = Vector3.Distance(p1, p2);
            float valueB = Vector3.Distance(p2, p3);
            float valueC = Vector3.Distance(p1, p3);
            float i = (valueA + valueB + valueC) / 2;
            return Mathf.Round(Mathf.Sqrt(i * (i - valueA) * (i - valueB) * (i - valueC)));
        }
        public override void ReverseSide()
        {
            System.Array.Reverse(vertices);
            SetTriangles(vertices);
        }
        public override void Reverse()
        {
            System.Array.Reverse(vertices);
            SetTriangles(vertices);
        }
        public override PointsBase Clone()
        {
            Polygon pg = new Polygon();
            pg.vertices = vertices.Clone() as Vector3[];
            pg.triangles = triangles.Clone() as int[];
            if (bbox != null)
                pg.bbox = bbox;
            if (boundary != null)
                pg.boundary = (Polyline)boundary.Clone();
            return pg;
        }
        public Extrusion Extrude(Vector3 magUp)
        {
            float h = magUp.magnitude;
            if (magUp[1] < 0) h *= -1;
            Extrusion ext = new Extrusion(vertices, h);
            return ext;

            
        }
        public Form ExtrudeToForm(Vector3 magUp)
        {
            List<Polygon> pgs = new List<Polygon>();
            Polygon bot = new Polygon(vertices.Clone() as Vector3[]);
            //bot.ReverseTriangle();
            //bot.ReverseSide();
            if (magUp[1] >= 0)
                bot.ReverseTriangle();
            pgs.Add(bot);
            Vector3[] ptsTop = new Vector3[vertices.Length];
            for (int i = 0; i < vertices.Length; i++)
            {
                ptsTop[i] = vertices[i] + magUp;
                int j = i + 1;
                if (j >= vertices.Length) j = 0;

                Vector3[] pts = new Vector3[4];
                if (magUp[1] >= 0)
                {
                    pts[0] = vertices[i];
                    pts[1] = vertices[j];
                    pts[2] = vertices[j] + magUp;
                    pts[3] = vertices[i] + magUp;
                }
                else
                {
                    pts[3] = vertices[i];
                    pts[2] = vertices[j];
                    pts[1] = vertices[j] + magUp;
                    pts[0] = vertices[i] + magUp;
                }
                
                Polygon pg = new Polygon(pts);
                pgs.Add(pg);
            }
            Polygon top = new Polygon(ptsTop);
            if (magUp[1] < 0)
                top.ReverseTriangle();
            pgs.Add(top);
            Form outForm = new Form(pgs.ToArray());
            return outForm;
        }
        
        public Meshable[] Offset(float d, bool join=false)
        {
            List<Meshable> pgs = new List<Meshable>();
            if (d == 0)
            {
                Polygon pg = (Polygon)Clone();
                pgs.Add(pg);
                return pgs.ToArray();
            }


            Vector3[] offsetPTs = PointsBase.offset(vertices, d);

            if (d > 0)
            {
                Polygon pg = new Polygon(offsetPTs);
                if(bbox!=null)
                    pg.bbox = BoundingBox.CreateFromPoints(offsetPTs, bbox);
                pgs.Add(pg);
            }
                

            for (int i = 0; i < vertices.Length; i++)
            {
                int j = i + 1;
                if (j >= vertices.Length) j = 0;
                Vector3[] pts = new Vector3[4];

                pts[0] = vertices[i];
                pts[1] = offsetPTs[i];
                pts[2] = offsetPTs[j];
                pts[3] = vertices[j];
                
                if (d > 0)
                    System.Array.Reverse(pts);
                Polygon pg = new Polygon(pts);
                pg.bbox = BoundingBox.CreateFromPoints(pts, PointsBase.LongestDirection(pts));
                pgs.Add(pg);
            }
            if (join)
            {
                CompositMeshable cm = new CompositMeshable(pgs.ToArray());
                pgs.Clear();
                pgs.Add(cm);
                return pgs.ToArray();
            }

            return pgs.ToArray();
        }
    } 
    public class Extrusion : CompositMeshable
    {
        public Polygon polygon;
        public float height;
        public Vector3 magUp;

        //topology
        public List<Meshable> sides
        {
            get
            {
                if (components.Count > 2)
                    return components.GetRange(1,components.Count-2);
                return null;
            }
        }
        public Meshable top {
            get
            {
                if(components.Count>0)
                    return components[components.Count - 1];
                return null;
            }
        }
        public Meshable bot
        {
            get
            {
                if (components.Count > 0)
                    return components[0];
                return null;
            }
        }

        public Extrusion():base()
        {
            polygon = new Polygon(vertices);
        }
        public Extrusion(Vector3[] pts, float h):this()
        {
            //Debug.Log("split in extrusion");
            height = h;
            polygon = new Polygon(pts);
            magUp = new Vector3(0, h, 0);
            Form f= polygon.ExtrudeToForm(magUp);
            vertices = f.vertices;
            triangles = f.triangles;
            components = f.components;
            //_Extrude(magUp);
            //if (vertices.Length < 1) throw new System.Exception("vertices.length=0");
        }
        private void _Extrude(Vector3 magUp)
        {
            components = new List<Meshable>();
            sides.Clear();
            Vector3[] ptsTop = new Vector3[vertices.Length];
            for (int i = 0; i < vertices.Length; i++)
            {
                ptsTop[i] = vertices[i] + magUp;
                int j = i + 1;
                if (j >= vertices.Length) j = 0;

                Vector3[] pts = new Vector3[4];
                pts[0] = vertices[i];
                pts[1] = vertices[j];
                pts[2] = vertices[j] + magUp;
                pts[3] = vertices[i] + magUp;
                Polygon pg = new Polygon(pts);
                this.Add(pg);
                sides.Add(pg);
            }
            Polygon top = new Polygon(ptsTop);
            this.Add(top);
        }
        public override void Translate(Vector3 offset)
        {
            //throw new System.Exception("not fix, translate all components");
            base.Translate(offset);
            polygon.Translate(offset);
        }
        public override void Reverse()
        {
            Debug.Log("!!!!Extrusion Reverse()");
            polygon.Reverse();
            magUp = new Vector3(0, height, 0);
            Meshable mb = polygon.ExtrudeToForm(magUp);
            vertices = mb.vertices;
            triangles = mb.triangles;
            components = ((CompositMeshable)mb).components;
        }
        public override Meshable[] SplitByPlane(Plane pln)
        {
            //vertical split
            if (pln.normal == Vector3.up) return SplitVerticallyByPlane(pln);
            //horizontal split
            return SplitHorizontallyByPlane(pln);
        }
        private Meshable[] SplitHorizontallyByPlane(Plane pln)
        {
            Meshable[] mbs = polygon.SplitByPlane(pln);
            Meshable[] outMbs = new Meshable[mbs.Length];
            for (int i = 0; i < mbs.Length; i++)
            {
                if (mbs[i] != null)
                {
                    outMbs[i] = ((Polygon)mbs[i]).Extrude(new Vector3(0, height, 0));
                }
                else
                {
                    outMbs[i] = null;
                }
            }
            return outMbs;
        }
        private Meshable[] SplitVerticallyByPlane(Plane pln)
        {
            float h1 = polygon.vertices[0].y;
            float h2 = h1 + this.height;
            float hp = pln.ClosestPointOnPlane(Vector3.zero).y;
            if(hp>h1 && hp< h2)
            {
                Meshable m1 = polygon.Extrude(new Vector3(0, hp - h1));
                Polygon upPoly = (Polygon)polygon.Clone();
                upPoly.Translate(new Vector3(0, hp - h1, 0));
                Meshable m2 = upPoly.Extrude(new Vector3(0, h2 - hp,0));
                return new Meshable[] {m1, m2};
            }
            else if (hp <= h1)
            {
                return new Meshable[] { null,(Meshable)this.Clone(),null };
            }
            
            return new Meshable[] { null,(Meshable)this.Clone() };
        }
        //public override Meshable Scale(Vector3 scale, Vector3[] vects, Vector3 origin, bool duplicate = true)
        //{
        //    Extrusion ext;
        //    if (duplicate) ext = (Extrusion)this.Clone();
        //    else ext = this;

        //    Meshable smb = base.Scale(scale, vects, origin, true);
        //    ext.vertices = smb.vertices;
        //    ext.polygon.Scale(scale, vects, origin, false);
        //    foreach (Meshable m in ext.components)
        //    {
        //        m.Scale(scale, vects, origin, false);
        //    }
        //    ext.height = height * scale[1];
        //    ext.magUp = new Vector3(0, height, 0);
        //    return ext;
        //}
        public override Meshable Scale(Vector3 scale, Vector3[] vects, Vector3 origin, bool duplicate = true)
        {
            Meshable dup = base.Scale(scale, vects, origin, duplicate);
            List<Meshable> comps = new List<Meshable>();
            Meshable mbpolygon = polygon.Scale(scale, vects, origin, true);
            if (mbpolygon == null) throw new Exception("null scaled polygon");
            Polygon pg = new Polygon(mbpolygon.vertices);
            foreach (Meshable m in components)
            {
                comps.Add(m.Scale(scale, vects, origin, true));
            }

            if (duplicate)
            {
                Extrusion cm = new Extrusion();
                cm.height = height * scale[1];
                cm.magUp = new Vector3(0, cm.height, 0);
                cm.polygon = pg;
                cm.vertices = dup.vertices;
                cm.triangles = dup.triangles;
                cm.components = comps;
                return cm;
            }
            else
            {
                magUp = scale * scale[1];
                components = comps;
            }

            return null;
        }
        public override PointsBase Clone()
        {
            Extrusion cm = new Extrusion();
            cm.height = height;
            cm.magUp = magUp;
            cm.polygon = polygon;
            cm.vertices = vertices;
            cm.triangles = triangles;
            cm.components = components;
            if (bbox != null)
                cm.bbox = bbox;
            return cm;
        }
        public Meshable[] Decompose1S()
        {
            throw new NotImplementedException();
        }
        public Meshable[] Decompose2S()
        {
            throw new NotImplementedException();
        }
        public Meshable[] Decompose4S()
        {
            throw new NotImplementedException();
        }
        
        
    }
    public class Form : CompositMeshable
    {
        public Form() : base()
        {
        }
        public Form(Polygon[] polygons) : base()
        {
            //foreach(Polygon pg in polygons)
            //{
            //    if (pg.vertices.Length > 2) this.Add(pg);
            //}
            this.AddRange(polygons);
        }
        public Form(Meshable[] polygons) : base()
        {
            //foreach(Polygon pg in polygons)
            //{
            //    if (pg.vertices.Length > 2) this.Add(pg);
            //}
            this.AddRange(polygons);
        }



    }
    public class TriangulatorV3
    {
        private List<Vector3> m_points = new List<Vector3>();

        public TriangulatorV3(Vector3[] points)
        {
            points = flipPoints(points);
            m_points = new List<Vector3>(points);

        }

        public Vector3[] flipPoints(Vector3[] ipts)
        {
            Vector3[] pts = new Vector3[ipts.Length];
            for (int i = 0; i < pts.Length; i++)
            {
                float x = ipts[i].x;
                float y = ipts[i].z;
                float z = 0;
                pts[i] = new Vector3(x, y, z);
            }
            return pts;
        }

        public int[] Triangulate()
        {
            List<int> indices = new List<int>();

            int n = m_points.Count;
            if (n < 3)
                return indices.ToArray();

            int[] V = new int[n];
            if (Area() > 0)
            {
                for (int v = 0; v < n; v++)
                    V[v] = v;
            }
            else
            {
                for (int v = 0; v < n; v++)
                    V[v] = (n - 1) - v;
            }

            int nv = n;
            int count = 2 * nv;
            for (int m = 0, v = nv - 1; nv > 2;)
            {
                if ((count--) <= 0)
                    return indices.ToArray();

                int u = v;
                if (nv <= u)
                    u = 0;
                v = u + 1;
                if (nv <= v)
                    v = 0;
                int w = v + 1;
                if (nv <= w)
                    w = 0;

                if (Snip(u, v, w, nv, V))
                {
                    int a, b, c, s, t;
                    a = V[u];
                    b = V[v];
                    c = V[w];
                    indices.Add(a);
                    indices.Add(b);
                    indices.Add(c);
                    m++;
                    for (s = v, t = v + 1; t < nv; s++, t++)
                        V[s] = V[t];
                    nv--;
                    count = 2 * nv;
                }
            }

            indices.Reverse();
            return indices.ToArray();
        }

        private float Area()
        {
            int n = m_points.Count;
            float A = 0.0f;
            for (int p = n - 1, q = 0; q < n; p = q++)
            {
                Vector3 pval = m_points[p];
                Vector3 qval = m_points[q];
                A += pval.x * qval.y - qval.x * pval.y;
            }
            return (A * 0.5f);
        }

        private bool Snip(int u, int v, int w, int n, int[] V)
        {
            int p;
            Vector3 A = m_points[V[u]];
            Vector3 B = m_points[V[v]];
            Vector3 C = m_points[V[w]];
            if (Mathf.Epsilon > (((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x))))
                return false;
            for (p = 0; p < n; p++)
            {
                if ((p == u) || (p == v) || (p == w))
                    continue;
                Vector3 P = m_points[V[p]];
                if (InsideTriangle(A, B, C, P))
                    return false;
            }
            return true;
        }

        private bool InsideTriangle(Vector3 A, Vector3 B, Vector3 C, Vector3 P)
        {
            float ax, ay, bx, by, cx, cy, apx, apy, bpx, bpy, cpx, cpy;
            float cCROSSap, bCROSScp, aCROSSbp;

            ax = C.x - B.x; ay = C.y - B.y;
            bx = A.x - C.x; by = A.y - C.y;
            cx = B.x - A.x; cy = B.y - A.y;
            apx = P.x - A.x; apy = P.y - A.y;
            bpx = P.x - B.x; bpy = P.y - B.y;
            cpx = P.x - C.x; cpy = P.y - C.y;

            aCROSSbp = ax * bpy - ay * bpx;
            cCROSSap = cx * apy - cy * apx;
            bCROSScp = bx * cpy - by * cpx;

            return ((aCROSSbp >= 0.0f) && (bCROSScp >= 0.0f) && (cCROSSap >= 0.0f));
        }
    }
    public class TriangulatorV2
    {
        private List<Vector2> m_points = new List<Vector2>();

        public TriangulatorV2(Vector3[] points)
        {
            Vector2[] pts = v3tov2(points);
            m_points = new List<Vector2>(pts);

        }

        public Vector2[] v3tov2(Vector3[] ipts)
        {
            Vector2[] pts = new Vector2[ipts.Length];
            for (int i = 0; i < pts.Length; i++)
            {
                float x = ipts[i].x;
                float y = ipts[i].z;
                pts[i] = new Vector2(x, y);
            }
            return pts;
        }
        public Vector3[] v2tov3(Vector2[] ipts)
        {
            Vector3[] pts = new Vector3[ipts.Length];
            for (int i = 0; i < pts.Length; i++)
            {
                float x = ipts[i].x;
                float y = ipts[i].y;
                pts[i] = new Vector3(x, 0, y);
            }
            return pts;
        }

        public int[] Triangulate()
        {
            List<int> indices = new List<int>();

            int n = m_points.Count;
            if (n < 3)
                return indices.ToArray();

            int[] V = new int[n];
            if (Area() > 0)
            {
                for (int v = 0; v < n; v++)
                    V[v] = v;
            }
            else
            {
                for (int v = 0; v < n; v++)
                    V[v] = (n - 1) - v;
            }

            int nv = n;
            int count = 2 * nv;
            for (int m = 0, v = nv - 1; nv > 2;)
            {
                if ((count--) <= 0)
                    return indices.ToArray();

                int u = v;
                if (nv <= u)
                    u = 0;
                v = u + 1;
                if (nv <= v)
                    v = 0;
                int w = v + 1;
                if (nv <= w)
                    w = 0;

                if (Snip(u, v, w, nv, V))
                {
                    int a, b, c, s, t;
                    a = V[u];
                    b = V[v];
                    c = V[w];
                    indices.Add(a);
                    indices.Add(b);
                    indices.Add(c);
                    m++;
                    for (s = v, t = v + 1; t < nv; s++, t++)
                        V[s] = V[t];
                    nv--;
                    count = 2 * nv;
                }
            }

            indices.Reverse();
            return indices.ToArray();
        }

        private float Area()
        {
            int n = m_points.Count;
            float A = 0.0f;
            for (int p = n - 1, q = 0; q < n; p = q++)
            {
                Vector2 pval = m_points[p];
                Vector2 qval = m_points[q];
                A += pval.x * qval.y - qval.x * pval.y;
            }
            return (A * 0.5f);
        }

        private bool Snip(int u, int v, int w, int n, int[] V)
        {
            int p;
            Vector2 A = m_points[V[u]];
            Vector2 B = m_points[V[v]];
            Vector2 C = m_points[V[w]];
            if (Mathf.Epsilon > (((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x))))
                return false;
            for (p = 0; p < n; p++)
            {
                if ((p == u) || (p == v) || (p == w))
                    continue;
                Vector2 P = m_points[V[p]];
                if (InsideTriangle(A, B, C, P))
                    return false;
            }
            return true;
        }

        private bool InsideTriangle(Vector2 A, Vector2 B, Vector2 C, Vector2 P)
        {
            float ax, ay, bx, by, cx, cy, apx, apy, bpx, bpy, cpx, cpy;
            float cCROSSap, bCROSScp, aCROSSbp;

            ax = C.x - B.x; ay = C.y - B.y;
            bx = A.x - C.x; by = A.y - C.y;
            cx = B.x - A.x; cy = B.y - A.y;
            apx = P.x - A.x; apy = P.y - A.y;
            bpx = P.x - B.x; bpy = P.y - B.y;
            cpx = P.x - C.x; cpy = P.y - C.y;

            aCROSSbp = ax * bpy - ay * bpx;
            cCROSSap = cx * apy - cy * apx;
            bCROSScp = bx * cpy - by * cpx;

            return ((aCROSSbp >= 0.0f) && (bCROSScp >= 0.0f) && (cCROSSap >= 0.0f));
        }
    }
    public class OldCreator
    {
        public static GameObject CreateMeshObject(Mesh m)
        {
            GameObject obj = new GameObject();
            MeshFilter filter = obj.AddComponent<MeshFilter>() as MeshFilter;
            filter.mesh = m;
            return obj;
        }
        public static GameObject CreateLineObject(SGGeometry.PointsBase line, bool closed=false, float width=0.1f)
        {
            Vector3[] verts = line.vertices;
            GameObject obj = new GameObject();
            LineRenderer renderer = obj.AddComponent<LineRenderer>() as LineRenderer;
            renderer.positionCount = verts.Length;
            renderer.SetPositions(verts);
            renderer.startColor = Color.black;
            renderer.startWidth = width;
            renderer.loop = closed;
            return obj;
        }
            
    }
}

namespace MeshFactory
{
    //public class MeshQuad : RMesh
    //{
    //    public MeshQuad(Vector3[] verts)
    //    {
    //        int[] triangles = new int[]
    //        {
    //        0,1,2,3
    //        };
    //        _mesh.vertices = verts;
    //        _mesh.triangles = triangles;
    //        _mesh.RecalculateNormals();
    //    }
    //}

    /// <summary>
    /// Triangulator is a class for triangulating any given polyline
    /// http://wiki.unity3d.com/index.php?title=Triangulator
    ///    Vector3[] vertices2D = new Vector3[] {.....}
    ///    Triangulator tr = new Triangulator(vertices2D);
    ///    int[] indices = tr.Triangulate();
    ///    Mesh msh = new Mesh();
    ///    msh.vertices = vertices;
    ///    msh.triangles = indices;
    ///    msh.RecalculateNormals();
    ///    msh.RecalculateBounds();
    /// </summary>
    public class TriangulatorV3
    {
        private List<Vector3> m_points = new List<Vector3>();

        public TriangulatorV3(Vector3[] points)
        {
            points = flipPoints(points);
            m_points = new List<Vector3>(points);

        }

        public Vector3[] flipPoints(Vector3[] ipts)
        {
            Vector3[] pts = new Vector3[ipts.Length];
            for (int i = 0; i < pts.Length; i++)
            {
                float x = ipts[i].x;
                float y = ipts[i].z;
                float z = 0;
                pts[i] = new Vector3(x, y, z);
            }
            return pts;
        }

        public int[] Triangulate()
        {
            List<int> indices = new List<int>();

            int n = m_points.Count;
            if (n < 3)
                return indices.ToArray();

            int[] V = new int[n];
            if (Area() > 0)
            {
                for (int v = 0; v < n; v++)
                    V[v] = v;
            }
            else
            {
                for (int v = 0; v < n; v++)
                    V[v] = (n - 1) - v;
            }

            int nv = n;
            int count = 2 * nv;
            for (int m = 0, v = nv - 1; nv > 2;)
            {
                if ((count--) <= 0)
                    return indices.ToArray();

                int u = v;
                if (nv <= u)
                    u = 0;
                v = u + 1;
                if (nv <= v)
                    v = 0;
                int w = v + 1;
                if (nv <= w)
                    w = 0;

                if (Snip(u, v, w, nv, V))
                {
                    int a, b, c, s, t;
                    a = V[u];
                    b = V[v];
                    c = V[w];
                    indices.Add(a);
                    indices.Add(b);
                    indices.Add(c);
                    m++;
                    for (s = v, t = v + 1; t < nv; s++, t++)
                        V[s] = V[t];
                    nv--;
                    count = 2 * nv;
                }
            }

            indices.Reverse();
            return indices.ToArray();
        }

        private float Area()
        {
            int n = m_points.Count;
            float A = 0.0f;
            for (int p = n - 1, q = 0; q < n; p = q++)
            {
                Vector3 pval = m_points[p];
                Vector3 qval = m_points[q];
                A += pval.x * qval.y - qval.x * pval.y;
            }
            return (A * 0.5f);
        }

        private bool Snip(int u, int v, int w, int n, int[] V)
        {
            int p;
            Vector3 A = m_points[V[u]];
            Vector3 B = m_points[V[v]];
            Vector3 C = m_points[V[w]];
            if (Mathf.Epsilon > (((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x))))
                return false;
            for (p = 0; p < n; p++)
            {
                if ((p == u) || (p == v) || (p == w))
                    continue;
                Vector3 P = m_points[V[p]];
                if (InsideTriangle(A, B, C, P))
                    return false;
            }
            return true;
        }

        private bool InsideTriangle(Vector3 A, Vector3 B, Vector3 C, Vector3 P)
        {
            float ax, ay, bx, by, cx, cy, apx, apy, bpx, bpy, cpx, cpy;
            float cCROSSap, bCROSScp, aCROSSbp;

            ax = C.x - B.x; ay = C.y - B.y;
            bx = A.x - C.x; by = A.y - C.y;
            cx = B.x - A.x; cy = B.y - A.y;
            apx = P.x - A.x; apy = P.y - A.y;
            bpx = P.x - B.x; bpy = P.y - B.y;
            cpx = P.x - C.x; cpy = P.y - C.y;

            aCROSSbp = ax * bpy - ay * bpx;
            cCROSSap = cx * apy - cy * apx;
            bCROSScp = bx * cpy - by * cpx;

            return ((aCROSSbp >= 0.0f) && (bCROSScp >= 0.0f) && (cCROSSap >= 0.0f));
        }
    }

    public class TriangulatorV2
    {
        private List<Vector2> m_points = new List<Vector2>();

        public TriangulatorV2(Vector3[] points)
        {
            Vector2[] pts = v3tov2(points);
            m_points = new List<Vector2>(pts);

        }

        public Vector2[] v3tov2(Vector3[] ipts)
        {
            Vector2[] pts = new Vector2[ipts.Length];
            for (int i = 0; i < pts.Length; i++)
            {
                float x = ipts[i].x;
                float y = ipts[i].z;
                pts[i] = new Vector2(x, y);
            }
            return pts;
        }
        public Vector3[] v2tov3(Vector2[] ipts)
        {
            Vector3[] pts = new Vector3[ipts.Length];
            for (int i = 0; i < pts.Length; i++)
            {
                float x = ipts[i].x;
                float y = ipts[i].y;
                pts[i] = new Vector3(x, 0, y);
            }
            return pts;
        }

        public int[] Triangulate()
        {
            List<int> indices = new List<int>();

            int n = m_points.Count;
            if (n < 3)
                return indices.ToArray();

            int[] V = new int[n];
            if (Area() > 0)
            {
                for (int v = 0; v < n; v++)
                    V[v] = v;
            }
            else
            {
                for (int v = 0; v < n; v++)
                    V[v] = (n - 1) - v;
            }

            int nv = n;
            int count = 2 * nv;
            for (int m = 0, v = nv - 1; nv > 2;)
            {
                if ((count--) <= 0)
                    return indices.ToArray();

                int u = v;
                if (nv <= u)
                    u = 0;
                v = u + 1;
                if (nv <= v)
                    v = 0;
                int w = v + 1;
                if (nv <= w)
                    w = 0;

                if (Snip(u, v, w, nv, V))
                {
                    int a, b, c, s, t;
                    a = V[u];
                    b = V[v];
                    c = V[w];
                    indices.Add(a);
                    indices.Add(b);
                    indices.Add(c);
                    m++;
                    for (s = v, t = v + 1; t < nv; s++, t++)
                        V[s] = V[t];
                    nv--;
                    count = 2 * nv;
                }
            }

            indices.Reverse();
            return indices.ToArray();
        }

        private float Area()
        {
            int n = m_points.Count;
            float A = 0.0f;
            for (int p = n - 1, q = 0; q < n; p = q++)
            {
                Vector2 pval = m_points[p];
                Vector2 qval = m_points[q];
                A += pval.x * qval.y - qval.x * pval.y;
            }
            return (A * 0.5f);
        }

        private bool Snip(int u, int v, int w, int n, int[] V)
        {
            int p;
            Vector2 A = m_points[V[u]];
            Vector2 B = m_points[V[v]];
            Vector2 C = m_points[V[w]];
            if (Mathf.Epsilon > (((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x))))
                return false;
            for (p = 0; p < n; p++)
            {
                if ((p == u) || (p == v) || (p == w))
                    continue;
                Vector2 P = m_points[V[p]];
                if (InsideTriangle(A, B, C, P))
                    return false;
            }
            return true;
        }

        private bool InsideTriangle(Vector2 A, Vector2 B, Vector2 C, Vector2 P)
        {
            float ax, ay, bx, by, cx, cy, apx, apy, bpx, bpy, cpx, cpy;
            float cCROSSap, bCROSScp, aCROSSbp;

            ax = C.x - B.x; ay = C.y - B.y;
            bx = A.x - C.x; by = A.y - C.y;
            cx = B.x - A.x; cy = B.y - A.y;
            apx = P.x - A.x; apy = P.y - A.y;
            bpx = P.x - B.x; bpy = P.y - B.y;
            cpx = P.x - C.x; cpy = P.y - C.y;

            aCROSSbp = ax * bpy - ay * bpx;
            cCROSSap = cx * apy - cy * apx;
            bCROSScp = bx * cpy - by * cpx;

            return ((aCROSSbp >= 0.0f) && (bCROSScp >= 0.0f) && (cCROSSap >= 0.0f));
        }
    }

    public class MeshMaker
    {
        public static Mesh joinMeshes(Mesh[] meshs, bool mergeSubMesh = false)
        {
            Mesh outMesh = new Mesh();
            List<Vector3> pts = new List<Vector3>();
            List<int> tris = new List<int>();
            int vertsCount = 0;

            foreach (Mesh mesh in meshs)
            {
                vertsCount = pts.Count;
                foreach (Vector3 p in mesh.vertices)
                {
                    pts.Add(p);
                }
                List<int> mtris = new List<int>();
                foreach (int t in mesh.triangles)
                {
                    int nt = t + vertsCount;
                    tris.Add(nt);
                    mtris.Add(nt);

                }
                
            }

            outMesh.vertices = pts.ToArray();
            outMesh.triangles = tris.ToArray();
            outMesh.RecalculateNormals();

            return outMesh;
        }
        public static Mesh makeQuad(Vector3[] verts)
        {
            Mesh m = new Mesh();
            int[] triangles = new int[]
            {
            0,1,2,3
            };
            m.vertices = verts;
            m.triangles = triangles;
            m.RecalculateNormals();
            return m;
        }
        public static Mesh makeTriangle(Vector3[] verts)
        {
            Mesh m = new Mesh();
            int[] triangles = new int[]
                {
            0,1,2
                };
            m.vertices = verts;
            m.triangles = triangles;
            m.RecalculateNormals();
            return m;
        }
        public static Mesh makePolygon(Vector3[] verts)
        {
            Mesh m = new Mesh();
            TriangulatorV3 tr = new TriangulatorV3(verts);
            int[] triangles = tr.Triangulate();
            m.vertices = verts;
            m.triangles = triangles;
            m.RecalculateNormals();
            m.RecalculateBounds();
            return m;
        }
        public static Mesh makeExtrusion(Vector3[] iverts, float height, bool cap = true)
        {
            Mesh m = new Mesh();
            Vector3 up = Vector3.up * height;
            List<Vector3> verts = new List<Vector3>();
            List<int> tris = new List<int>();
            for (int i = 0; i < iverts.Length; i++)
            {
                int j = i + 1;
                if (j >= iverts.Length)
                {
                    j -= iverts.Length;
                }
                int vc = verts.Count;
                verts.Add(iverts[i]);
                verts.Add(iverts[j]);
                verts.Add(iverts[j] + up);
                verts.Add(iverts[i] + up);

                tris.Add(vc);
                tris.Add(vc + 2);
                tris.Add(vc + 1);
                tris.Add(vc);
                tris.Add(vc + 3);
                tris.Add(vc + 2);
            }
            m.vertices = verts.ToArray();
            m.triangles = tris.ToArray();

            //make caps
            if (cap)
            {
                Vector3[] upbound = MeshMaker.addVects(iverts, up);
                Mesh top = makePolygon(upbound);
                Mesh bot = makePolygon(iverts);
                m = joinMeshes(new Mesh[] { m, top, bot });
            }

            m.RecalculateBounds();
            m.RecalculateNormals();
            return m;
        }

        public static Vector3[] addVects(Vector3[] vects, Vector3 vect)
        {
            List<Vector3> outVects = new List<Vector3>();
            foreach (Vector3 v in vects)
            {
                outVects.Add(vect + v);
            }
            return outVects.ToArray();
        }
        public static Vector3[] addVects(Vector3 vect, Vector3[] vects)
        {
            return addVects(vects, vect);
        }
        public static Vector3[] addVects(Vector3[] vects1, Vector3[] vects2)
        {
            List<Vector3> outVects = new List<Vector3>();
            for (int i = 0; i < vects1.Length; i++)
            {
                outVects.Add(vects1[i] + vects2[i]);
            }
            return outVects.ToArray();
        }
            
    }


}

