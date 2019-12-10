using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Posseccing : MonoBehaviour
{

	public bool glow;
	public Material mat;

    // Start is called before the first frame update
    void Start()
    {
		mat.SetColor("_ShineColor", new Color(0, 0, 0));
	}

    // Update is called once per frame
    void Update()
    {
        if (glow)
		{
			mat.SetColor("_ShineColor", new Color(0, 81, 191));
		}
		if (!glow)
		{

			mat.SetColor("_ShineColor", new Color(0, 0, 0));
		}
    }
}
