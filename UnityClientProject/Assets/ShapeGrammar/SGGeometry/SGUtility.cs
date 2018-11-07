using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGGeometry
{
    
    public class SGUtility 
    {

        public static Color colorScale(Color[] colors, float i)
        {
            i *= colors.Length;
            float zone = Mathf.Floor(i);
            int indexA = (int)zone;
            int indexB = (int)zone + 1;
            float pos = i - zone;

            if (indexB < colors.Length)
            {
                Color c1 = colors[indexA];
                Color c2 = colors[indexB];
                Color co = new Color();
                for (int j = 0; j < 4; j++)
                {
                    co[j] = c1[j] + ((c2[j] - c1[j]) * pos);
                }
                float r = c1.r + (c2.r - c1.r) * pos;
                return co;
            }
            return colors[colors.Length - 1];
        }

        public static Vector3 CenterOfGravity(Vector3[] pts)
        {
            Vector3 p = Vector3.zero;
            foreach(Vector3 v in pts)
            {
                p += v;
            }
            return p / pts.Length;
        }
        public static bool PointInBoundaryA(Vector3[] pts, Vector3 point)
        {

            for (int i = 0; i < pts.Length; i++)
            {
                int j = i + 1;
                if (j >= pts.Length) j = 0;
                Vector3 cp1 = pts[i];
                Vector3 cp2 = pts[j];
                Vector3 v1 = (cp2 - cp1).normalized;
                Vector3 v2 = (point - cp1).normalized;
                Vector3 cpN = Vector3.Cross(v1, v2);
                if (cpN.y > 0) return false;
            }

            return true ;
        }
        public static Vector3 CapPointInBoundaryA(Vector3[] pts, Vector3 point)
        {

            for (int i = 0; i < pts.Length; i++)
            {
                int j = i + 1;
                if (j >= pts.Length) j = 0;
                Vector3 cp1 = pts[i];
                Vector3 cp2 = pts[j];
                Vector3 v1 = (cp2 - cp1).normalized;
                Vector3 v2 = (point - cp1).normalized;
                Vector3 cpN = Vector3.Cross(v1, v2);
                if (cpN.y > 0)
                {
                    Vector3 csp = PolylineClosesPoint(pts, point);
                    return csp;
                }
            }

            return point;
        }
        
        

        public static Meshable[] DivideFormToLength(Meshable mb,float length,int axis)
        {
            float total = mb.bbox.size[axis];
            int count = Mathf.RoundToInt(total / length);
            return DivideFormByCount(mb, count, axis);
        }
        public static Meshable[] DivideFormByCount(Meshable mb, int count, int axis)
        {
            float ratio = (float)1 / (float)count;
            float[] divs = new float[count];
            for (int i = 0; i < divs.Length; i++)
            {
                divs[i] = ratio;
                //Debug.LogFormat("ratio[{0}]={1}", i,ratio);
            }

            return DivideFormByDivsRatio(mb, divs, axis);
        }
        public static Meshable[] DivideFormByDivsRatio(Meshable mb, float[] divs, int axis)
        {
            List<Meshable> outMeshable = new List<Meshable>();

            if (divs.Length == 0)
            {
                outMeshable.Add((Meshable)mb.Clone());
                return outMeshable.ToArray();
            }
            Vector3 n = mb.bbox.vects[axis];
            //Debug.Log("n=" + n);
            Vector3 org = mb.bbox.vertices[0];
            Vector3 offset = n * divs[0] * mb.bbox.size[axis];
            org += offset;
            
            //Debug.Log("offset=" + offset);
            
            Plane pln = new Plane(n, org);
            Meshable[] splits = mb.SplitByPlane(pln);
            if (splits[0] != null)
            {
                splits[0].bbox = BoundingBox.CreateFromPoints(splits[0].vertices, mb.bbox);
                outMeshable.Add(splits[0]);
            }
            else
            {
                throw new System.Exception("splits[0] is null!");
            }

            Meshable remain = splits[1];
            int counter = 0;
            while (remain != null && counter<divs.Length)
            {
                org += offset;
                //Debug.Log("org=" + org);
                pln = new Plane(n, org);
                splits = remain.SplitByPlane(pln);
                //splits = Rules.Bisect.SplitByPlane(remain, pln);
                if (splits[0] != null)
                {
                    splits[0].bbox = BoundingBox.CreateFromPoints(splits[0].vertices, mb.bbox);
                    outMeshable.Add(splits[0]);
                }
                else
                {
                    break;
                    //throw new System.Exception("splits[0] is null!");
                }
                remain = splits[1];
                counter++;
            }
            return outMeshable.ToArray();
        }
        public static void ScaleForm(Meshable mb, float scale, Alignment? alignment = null)
        {
            Vector3 vscale = new Vector3(scale, scale, scale);
            ScaleForm(mb, vscale, alignment);
        }
        public static void ScaleForm(Meshable mb, Vector3 scale, Alignment? alignment=null)
        {
            Vector3 org = mb.bbox.GetOriginFromAlignment(alignment);
            mb.Scale(scale, mb.bbox.vects, org, false);
        }

        public static void RemoveExtraShapeObjects(ref List<ShapeObject> sos, int count)
        {
            for (int i= 0; i < count; i++)
            {
                int index = sos.Count - 1;
                try
                {
                    GameObject.Destroy(sos[index].gameObject);
                }
                catch { }
                sos.RemoveAt(index);
            }
        }
        public static void RemoveExtraGameObjects(ref List<GameObject> objects, int count)
        {
            for (int i = 0; i < count; i++)
            {
                int index = objects.Count - 1;
                try
                {
                    GameObject.Destroy(objects[index]);
                }
                catch { }
                objects.RemoveAt(index);
            }
        }

        // Find the point of intersection between
        // the lines p1 --> p2 and p3 --> p4.
        public static void LineLineIntersection(
            Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4,
            out bool lines_intersect, out bool segments_intersect,
            out Vector2 intersection,
            out Vector2 close_p1, out Vector2 close_p2)
        {
            // Get the segments' parameters.
            float dx12 = p2.x - p1.x;
            float dy12 = p2.y - p1.y;
            float dx34 = p4.x - p3.x;
            float dy34 = p4.y - p3.y;

            // Solve for t1 and t2
            float denominator = (dy12 * dx34 - dx12 * dy34);

            float t1 =
                ((p1.x - p3.x) * dy34 + (p3.y - p1.y) * dx34)
                    / denominator;
            if (float.IsInfinity(t1))
            {
                // The lines are parallel (or close enough to it).
                lines_intersect = false;
                segments_intersect = false;
                intersection = new Vector2(float.NaN, float.NaN);
                close_p1 = new Vector2(float.NaN, float.NaN);
                close_p2 = new Vector2(float.NaN, float.NaN);
                return;
            }
            lines_intersect = true;

            float t2 =
                ((p3.x - p1.x) * dy12 + (p1.y - p3.y) * dx12)
                    / -denominator;

            // Find the point of intersection.
            intersection = new Vector2(p1.x + dx12 * t1, p1.y + dy12 * t1);

            // The segments intersect if t1 and t2 are between 0 and 1.
            segments_intersect =
                ((t1 >= 0) && (t1 <= 1) &&
                 (t2 >= 0) && (t2 <= 1));

            // Find the closest points on the segments.
            if (t1 < 0)
            {
                t1 = 0;
            }
            else if (t1 > 1)
            {
                t1 = 1;
            }

            if (t2 < 0)
            {
                t2 = 0;
            }
            else if (t2 > 1)
            {
                t2 = 1;
            }

            close_p1 = new Vector2(p1.x + dx12 * t1, p1.y + dy12 * t1);
            close_p2 = new Vector2(p3.x + dx34 * t2, p3.y + dy34 * t2);
        }

        public static Vector3 LineClosesPoint2D(Vector3 p1, Vector3 p2, Vector3 point)
        {
            Vector3 n = Vector3.Cross((p2 - p1).normalized, Vector3.up);
            n *= 1000000;
            Vector3 p3 = point + n;
            Vector3 p4 = point - n;
            Vector3? xp = Intersect.LineLine2D(p1, p2, p3, p4);
            if (xp.HasValue)
            {
                return xp.Value;
            }
            float d1 = Vector3.Distance(p1, point);
            float d2 = Vector3.Distance(p2, point);
            if (d1 < d2) return p1;
            return p2;

        }
        public static Vector3 PolylineClosesPoint(Vector3[] poly, Vector3 point)
        {
            List<Vector3> pts = new List<Vector3>();
            for (int i = 0; i < poly.Length; i++)
            {
                int j = i + 1;
                if (j >= poly.Length) j = 0;
                Vector3 csp = LineClosesPoint2D(poly[i], poly[j], point);
                pts.Add(csp);
            }
            float minD = Vector3.Distance(pts[0], point);
            Vector3 mincsp = pts[0];
            foreach(Vector3 v in pts)
            {
                if (v == pts[0]) continue;
                float d = Vector3.Distance(v, point);
                if (d < minD)
                {
                    minD = d;
                    mincsp = v;
                }
            }
            return mincsp;
        }
    }

    public class Intersect
    {
        public static Vector3[] LinePolyline2D(Vector3 p1, Vector3 p2, Vector3[] poly)
        {
            List<Vector3> xps = new List<Vector3>();
            for (int i = 0; i < poly.Length; i++)
            {
                int j = i + 1;
                if (j >= poly.Length) j = 0;
                Vector3? xp = LineLine2D(p1, p2, poly[i], poly[j]);
                if (xp.HasValue)
                    xps.Add(xp.Value);
            }
            return xps.ToArray();
        }
        public static Vector3 PolylineClosesPoint(Vector3[] poly, Vector3 point)
        {
            List<Vector3> pts = new List<Vector3>();
            for (int i = 0; i < poly.Length; i++)
            {
                int j = i + 1;
                if (j >= poly.Length) j = 0;
                Vector3 n = Vector3.Cross((poly[j] - poly[i]).normalized, Vector3.up);
                n *= 10000000000;
                Vector3 p1 = point + n;
                Vector3 p2 = point - n;
                Vector3? xp = LineLine2D(p1, p2, poly[i], poly[j]);
                if (xp.HasValue)
                    pts.Add(xp.Value);
            }
            pts.AddRange(poly);
            Debug.Log(pts.Count);
            float minD = Vector3.Distance(pts[0], point);
            Vector3 csp = pts[0];
            foreach(Vector3 p in pts)
            {
                float d = Vector3.Distance(p, point);
                if (d < minD)
                {
                    minD = d;
                    csp = p;
                }
            }
            return csp;
        }
        public static Vector3? LineLine2D(Vector3 ap1, Vector3 ap2, Vector3 bp1, Vector3 bp2)
        {
            bool lines_Intersect;
            bool segments_intersect;
            Vector2 intersection;
            Vector2 close_p1, close_p2;

            Vector2 p1 = new Vector2(ap1.x, ap1.z);
            Vector2 p2 = new Vector2(ap2.x, ap2.z);
            Vector2 p3 = new Vector2(bp1.x, bp1.z);
            Vector2 p4 = new Vector2(bp2.x, bp2.z);

            SGUtility.LineLineIntersection(p1, p2, p3, p4, out lines_Intersect, out segments_intersect, out intersection, out close_p1, out close_p2);

            Vector3 intersectionV3=new Vector3(intersection.x,0,intersection.y);
            Vector3 close_p1V3 = new Vector3(close_p1.x, 0, close_p1.y);
            Vector3 close_p2V3 = new Vector3(close_p2.x, 0, close_p2.y);

            //Debug.Log("lines_intersect:" + lines_Intersect);
            //Debug.Log("segment_intersect:" + segments_intersect);
            //Debug.Log("intersection:" + intersectionV3);
            //Debug.Log("clase_p1:" + close_p1V3);
            //Debug.Log("clase_p2:" + close_p2V3);

            if (segments_intersect)
            {
                return intersectionV3;
            }
            return null;

        }
        public static Vector3? LineLine2D(Vector3 ap1, Vector3 ap2, Vector3 bp1, Vector3 bp2, out Vector3 close_p1V3, out Vector3 close_p2V3)
        {
            bool lines_Intersect;
            bool segments_intersect;
            Vector2 intersection;
            Vector2 close_p1, close_p2;

            Vector2 p1 = new Vector2(ap1.x, ap1.z);
            Vector2 p2 = new Vector2(ap2.x, ap2.z);
            Vector2 p3 = new Vector2(bp1.x, bp1.z);
            Vector2 p4 = new Vector2(bp2.x, bp2.z);

            SGUtility.LineLineIntersection(p1, p2, p3, p4, out lines_Intersect, out segments_intersect, out intersection, out close_p1, out close_p2);

            Vector3 intersectionV3 = new Vector3(intersection.x, 0, intersection.y);
            close_p1V3 = new Vector3(close_p1.x, 0, close_p1.y);
            close_p2V3 = new Vector3(close_p2.x, 0, close_p2.y);

            //Debug.Log("lines_intersect:" + lines_Intersect);
            //Debug.Log("segment_intersect:" + segments_intersect);
            //Debug.Log("intersection:" + intersectionV3);
            //Debug.Log("clase_p1:" + close_p1V3);
            //Debug.Log("clase_p2:" + close_p2V3);

            if (segments_intersect)
            {
                return intersectionV3;
            }
            return null;

        }
    }

}
