using System.Collections;
using System.Collections.Generic;
using System;
using UnityEngine;

public class Demo_meshables : MonoBehaviour {
    public Material mat;

	// Use this for initialization
	void Start () {
        // test both clock-wise and counter clock-wise ordered will work on extrusion
        // clock wise ordered points
        Vector3[] cw_points1 = new Vector3[]
        {
            new Vector3(0,0,0),
            new Vector3(10,0,0),
            new Vector3(10,0,10),
            new Vector3(0,0,10),
        };
        // counter clock wise right points
        Vector3[] ccw_points = new Vector3[]
        {
            new Vector3(-10,0,0),
            new Vector3(-10,0,10),
            new Vector3(-20,0,10),
            new Vector3(-20,0,0),
        };

        //create extrusion for each
        foreach(Vector3[] pts in new Vector3[][] {cw_points1,ccw_points })
        {
            // Extrusion, the Extrusion:Meshable is abstract
            SGGeometry.Extrusion ext = new SGGeometry.Extrusion(pts, 20);

            // requires a shape object to show the mesh
            // ShapeObject which inherits monobehabiour can not be created by new.
            ShapeObject shp_ext = ShapeObject.CreateBasic();
            shp_ext.SetMeshable(ext);
            shp_ext.SetMaterial(mat);

            Debug.Log("size=" + shp_ext.Size + " vects="+shp_ext.Vects[0]);
        }

        //teset Translation
        Vector3 offset = new Vector3(40, 0, 10);
        float rot = 15;
        SGGeometry.Extrusion msb = new SGGeometry.Extrusion(cw_points1, 30);
        Quaternion q = Quaternion.Euler(0, rot, 0);
        Matrix4x4 mr = Matrix4x4.Rotate(q);
        
        msb.Transform(mr);
        msb.Translate(offset);
        ShapeObject shp = ShapeObject.CreateMeshable(msb);



        
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
