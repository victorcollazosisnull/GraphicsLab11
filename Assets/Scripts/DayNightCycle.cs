using UnityEngine;

public class DayNightCycle : MonoBehaviour
{
    [Range(0.0f, 24f)] public float time = 12f;
    public Transform sun;
    public ParticleSystem starParticles;
    private Material starMat;

    private float sunX;
    public float durationTime = 1;

    [Header("Materials")]
    public Material buildingMaterial;
    public Material buildingMaterial2;
    public float emissionMax = 10f;
    public float emissionMin = 0f;
    public float nightStart = 18f;
    public float nightEnd = 6f;

    [Header("Emission Colors")]
    public Color dayEmissionColor = Color.black;  
    public Color nightEmissionColor = Color.yellow;
    [Header("Night Emission Colors")]
    public Color[] nightColors;
    public float colorChangeSpeed = 1f;
    private int currentColorIndex = 0;
    private float colorLerpT = 0f;
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
        UpdateBuildingEmission();
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
    private void UpdateBuildingEmission()
    {
        if (buildingMaterial == null || buildingMaterial2 == null) return;

        float emissionStrength = 0f;
        Color emissionColor = dayEmissionColor;

        bool isNight = time >= nightStart || time <= nightEnd;

        if (isNight)
        {
            if (time >= nightStart && time <= 24f)
            {
                float t = Mathf.InverseLerp(nightStart, 21f, time);
                emissionStrength = Mathf.Lerp(emissionMin, emissionMax, t);
            }
            else if (time >= 0f && time <= nightEnd)
            {
                float t = Mathf.InverseLerp(nightEnd, 3f, time);
                emissionStrength = Mathf.Lerp(emissionMax, emissionMin, 1f - t);
            }
            else
            {
                emissionStrength = emissionMax;
            }

            if (nightColors != null && nightColors.Length > 1)
            {
                colorLerpT += Time.deltaTime * colorChangeSpeed;

                if (colorLerpT >= 1f)
                {
                    colorLerpT = 0f;
                    currentColorIndex = (currentColorIndex + 1) % nightColors.Length;
                }

                int nextColorIndex = (currentColorIndex + 1) % nightColors.Length;
                emissionColor = Color.Lerp(nightColors[currentColorIndex], nightColors[nextColorIndex], colorLerpT);
            }
        }
        else
        {
            emissionStrength = emissionMin;
            emissionColor = dayEmissionColor;
            currentColorIndex = 0; 
            colorLerpT = 0f;
        }

        buildingMaterial.SetColor("_EmissionColor", emissionColor);
        buildingMaterial.SetFloat("_EmissionStrength", emissionStrength);

        buildingMaterial2.SetColor("_EmissionColor", emissionColor);
        buildingMaterial2.SetFloat("_EmissionStrength", emissionStrength);
    }
}