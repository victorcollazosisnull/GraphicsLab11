using UnityEngine;

public class DayNightCycle : MonoBehaviour
{
    [Range(0.0f, 24f)] public float time = 12f;
    public Transform sun;
    public ParticleSystem starParticles;
    private Material starMat;

    private float sunX;
    public float durationTime = 1;

    private void Start()
    {
        if (starParticles != null)
        {
            starMat = starParticles.GetComponent<ParticleSystemRenderer>().material;
        }
    }

    private void Update()
    {
        time += Time.deltaTime * (24 / (60 * durationTime));

        if (time >= 24)
        {
            time = 0;
        }

        RotateSun();
        UpdateStarVisibility();
    }

    public void RotateSun()
    {
        sunX = 15 * time;
        sun.localEulerAngles = new Vector3(sunX, 0, 0);

        bool isNight = time < 6 || time > 18;
        sun.GetComponent<Light>().intensity = isNight ? 0 : 1;
    }

    private void UpdateStarVisibility()
    {
        if (starMat == null) return;

        float alpha = 0f;

        if (time >= 21f || time <= 3f)
        {
            alpha = 1f;
        }
        else if (time > 3f && time <= 6f) 
        {
            alpha = Mathf.InverseLerp(6f, 3f, time); 
        }
        else if (time >= 18f && time < 21f) 
        {
            alpha = Mathf.InverseLerp(18f, 21f, time); 
        }
        else
        {
            alpha = 0f; 
        }

        Color c = starMat.color;
        c.a = alpha;
        starMat.color = c;
    }
}