using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using SGGeometry;

namespace ArchUtil
{
    public class MaterialManager
    {

        public static Dictionary<Color, Material> materials=new Dictionary<Color, Material>();
        public static Material get(Color key)
        {
            if (!MaterialManager.materials.ContainsKey(key))
            {
                Material mat = new Material(Shader.Find("Diffuse"));
                mat.color = key;
                MaterialManager.materials[key] = mat;
            }
            return MaterialManager.materials[key];
        }

        public static Material get(float r, float g, float b)
        {
            Color key = new Color(r, g, b);
            return get(key);
        }

        public static Material get(int ir, int ig, int ib)
        {
            float r, g, b;
            r = (float)ir / 255f;
            g = (float)ig / 255f;
            b = (float)ib / 255f;
            return get(r, g, b);
        }

        // Sample usage:
        //    Shader shader = Shader.Find("Diffuse");
        //    Material mat = new Material(shader);
        //    mat.color = new Color(1, 0, 0);
        //    Vector3[] pts = new Vector3[]{
        //    new Vector3(0,0,0),
        //    new Vector3(10, 0, 0),
        //    new Vector3(0, 0, 10)
        //    };
        //    ShapeObject so = ShapeObject.CreateExtrusion(pts, 5);
        //    so.SetMaterial(mat);


 
    }
}


