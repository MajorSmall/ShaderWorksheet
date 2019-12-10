using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DissolvePlayer : MonoBehaviour
{
	public Transform EndPoint;
	public ParticleSystem particles;
	public Transform player;
	public Material mat;

	public Posseccing poss;

	public float dissolveSpeed = 0.5f;

	int dissolveDirection = 0;
	float time = 1;

    // Update is called once per frame
    void Update()
    {
		var main = particles.main;
		
  
		if (Input.GetKeyDown(KeyCode.Space))
		{
			particles.transform.localRotation = new Quaternion();
			particles.transform.localPosition = Vector3.zero;
			main.startSpeed = Vector3.Distance(player.position, EndPoint.position);
			
			particles.Play();
			dissolveDirection = 1;
		}

		if (Input.GetKeyDown(KeyCode.Return))
		{
			particles.transform.position = EndPoint.position;
			particles.transform.LookAt(player.position);
			main.startSpeed = Vector3.Distance(EndPoint.position, player.position);

			particles.Play();
			dissolveDirection = -1;
		}

		if (dissolveDirection == 1)
		{
			time -= Time.deltaTime * dissolveSpeed;
			mat.SetFloat("_DissolveHieght", time);
			poss.glow = true;
		}
		if (dissolveDirection == -1)
		{
			time += Time.deltaTime * dissolveSpeed;
			mat.SetFloat("_DissolveHieght", time);
			poss.glow = false;
		}

    }
}
