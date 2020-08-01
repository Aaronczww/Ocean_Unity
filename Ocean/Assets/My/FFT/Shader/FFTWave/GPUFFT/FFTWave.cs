using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTWave : MonoBehaviour
{

    #region public variables
    public int _Resolution = 256;
    public float unitWidth =1f;
    public float Amp;
    public Vector2 Wind;
    public float length = 256f;
    public float choppiness = 1.5f;
    public float mult = 2f;

    public Shader initialShader;
    public Shader spectrumShader;
    public Shader fftShader;
    public Shader spectrumHeightShader;
    public Shader disperionShader;
    public Shader normalShader;
    public Shader whiteShader;

    #endregion

    #region private variables
    private Mesh mesh;
    private MeshFilter filter;

    private Vector3[] vertices;
    private Vector3[] normals;
    private Vector2[] uvs;
    private int[] indices;

    private bool saved = false;
    private float oldLength;
    private float oldChoppiness;
    private float oldAmplitude;
    private float oldUnitWidth;
    private Vector2 oldWind;

    private Material fftMat;
    private Material heightMat;
    private Material spectrumMat;
    private Material initialMat;
    private Material dispersionMat;
    private Material oceanMat;
    private Material normalMat;
    private Material whiteMat;

    private bool currentPhase = false;

    private RenderTexture initialTexture;
    private RenderTexture spectrumTexture;
    private RenderTexture pingTransformTexture;
    private RenderTexture pongTransformTexture;
    private RenderTexture displacementTexture;
    private RenderTexture pingPhaseTexture;
    private RenderTexture pongPhaseTexture;
    private RenderTexture heightTexture;
    private RenderTexture normalTexture;
    private RenderTexture whiteTexture;


    #endregion

    #region MonoBehaviours

    private void Awake()
    {
        filter = GetComponent<MeshFilter>();
        mesh = new Mesh();
        if (filter == null)
        {
            filter = gameObject.AddComponent<MeshFilter>();
        }
        SetParams();
        GenerateMesh();
        RenderInitial();
    }

    private void Update()
    {
        GenerateTexture();

        if (oldLength != length || oldWind != Wind || oldAmplitude != Amp || oldChoppiness!=choppiness || oldUnitWidth != unitWidth)
        {
            initialMat.SetFloat("_Amplitude", Amp / 10000f);
            initialMat.SetFloat("_Length", length);
            initialMat.SetVector("_Wind", Wind);
            oldLength = length;
            oldChoppiness = choppiness;
            oldAmplitude = Amp;
            oldUnitWidth = unitWidth;
            oldWind.x = Wind.x;
            oldWind.y = Wind.y;
            RenderInitial();
        }
    }

    #endregion


    #region methods

    private void SetParams()
    {
        fftMat = new Material(fftShader);
        heightMat = new Material(spectrumHeightShader);
        initialMat = new Material(initialShader);
        oceanMat = GetComponent<MeshRenderer>().material;
        spectrumMat = new Material(spectrumShader);
        dispersionMat = new Material(disperionShader);
        normalMat = new Material(normalShader);
        whiteMat = new Material(whiteShader);

        vertices = new Vector3[_Resolution * _Resolution];
        normals = new Vector3[_Resolution * _Resolution];
        uvs = new Vector2[_Resolution * _Resolution];
        indices = new int[(_Resolution - 1) * (_Resolution - 1) * 6];

        oldLength = length;
        oldWind = Wind;
        oldAmplitude = Amp;
        oldChoppiness = choppiness;
        oldUnitWidth = unitWidth;

        _Resolution = _Resolution;

        initialTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        pingPhaseTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.RFloat);
        pongPhaseTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.RFloat);
        pingTransformTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        pongTransformTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        spectrumTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        heightTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        displacementTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        normalTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);
        whiteTexture = new RenderTexture(_Resolution, _Resolution, 0, RenderTextureFormat.ARGBFloat);

        initialMat.SetFloat("_RandomSeed1", UnityEngine.Random.value * 10);
        initialMat.SetFloat("_RandomSeed2", UnityEngine.Random.value * 10);
        initialMat.SetFloat("_Amplitude", Amp/10000f);
        initialMat.SetFloat("_Length", length);
        initialMat.SetFloat("_Resolution", _Resolution);
        initialMat.SetVector("_Wind", Wind);

        dispersionMat.SetFloat("_Length", length);
        dispersionMat.SetInt("_Resolution", _Resolution);

        spectrumMat.SetFloat("_Choppiness", choppiness);
        spectrumMat.SetFloat("_Length", length);
        spectrumMat.SetInt("_Resolution", _Resolution);

        heightMat.SetFloat("_Choppiness", choppiness);
        heightMat.SetFloat("_Length", length);
        heightMat.SetInt("_Resolution", _Resolution);

        normalMat.SetFloat("_Length", length);
        normalMat.SetFloat("_Resolution", _Resolution);

        fftMat.SetFloat("_TransformSize", _Resolution);
        //_Resolution /= 8;

    }

    private void GenerateMesh()
    {
        int indiceCount = 0;
        int half_Resolution = _Resolution / 2;
        for (int i = 0; i < _Resolution; i++)
        {
            float horizontalPosition = (i - half_Resolution) * unitWidth;
            for (int j = 0; j < _Resolution; j++)
            {
                int currentIdx = i * (_Resolution) + j;
                float verticalPosition = (j - half_Resolution) * unitWidth;
                vertices[currentIdx] = new Vector3(horizontalPosition + (_Resolution % 2 == 0 ? unitWidth / 2f : 0f), 0f, verticalPosition + (_Resolution % 2 == 0 ? unitWidth / 2f : 0f));
                normals[currentIdx] = new Vector3(0f, 1f, 0f);
                uvs[currentIdx] = new Vector2(i * 1.0f / (_Resolution - 1), j * 1.0f / (_Resolution - 1));
                if (j == _Resolution - 1)
                    continue;
                if (i != _Resolution - 1)
                {
                    indices[indiceCount++] = currentIdx;
                    indices[indiceCount++] = currentIdx + 1;
                    indices[indiceCount++] = currentIdx + _Resolution;
                }
                if (i != 0)
                {
                    indices[indiceCount++] = currentIdx;
                    indices[indiceCount++] = currentIdx - _Resolution + 1;
                    indices[indiceCount++] = currentIdx + 1;
                }
            }
        }
        mesh.vertices = vertices;
        mesh.SetIndices(indices, MeshTopology.Triangles, 0);
        mesh.normals = normals;
        mesh.uv = uvs;
        filter.mesh = mesh;
    }

    private void RenderInitial()
    {
        Graphics.Blit(null, initialTexture, initialMat);
        spectrumMat.SetTexture("_Initial", initialTexture);
        heightMat.SetTexture("_Initial", initialTexture);
    }

    private void GenerateTexture()
    {
        float deltaTime = Time.deltaTime;

        currentPhase = !currentPhase;
        RenderTexture rt = currentPhase ? pingPhaseTexture : pongPhaseTexture;
        dispersionMat.SetTexture("_Phase", currentPhase ? pongPhaseTexture : pingPhaseTexture);
        dispersionMat.SetFloat("_DeltaTime", deltaTime * mult);
        Graphics.Blit(null, rt, dispersionMat);

        spectrumMat.SetTexture("_Phase", currentPhase ? pingPhaseTexture : pongPhaseTexture);
        Graphics.Blit(null, spectrumTexture, spectrumMat);

        fftMat.EnableKeyword("_HORIZONTAL");
        fftMat.DisableKeyword("_VERTICAL");

        int iterations = Mathf.CeilToInt((float)Mathf.Log(_Resolution , 2)) * 2;

        for (int i = 0; i < iterations; i++)
        {
            RenderTexture blitTarget;
            fftMat.SetFloat("_SubTransformSize", Mathf.Pow(2, (i % (iterations / 2)) + 1));
            if (i == 0)
            {
                fftMat.SetTexture("_Input", spectrumTexture);
                blitTarget = pingTransformTexture;
            }
            else if (i == iterations - 1)
            {
                fftMat.SetTexture("_Input", (iterations % 2 == 0) ? pingTransformTexture : pongTransformTexture);
                blitTarget = displacementTexture;
            }
            else if (i % 2 == 1)
            {
                fftMat.SetTexture("_Input", pingTransformTexture);
                blitTarget = pongTransformTexture;
            }
            else
            {
                fftMat.SetTexture("_Input", pongTransformTexture);
                blitTarget = pingTransformTexture;
            }
            if (i == iterations / 2)
            {
                fftMat.DisableKeyword("_HORIZONTAL");
                fftMat.EnableKeyword("_VERTICAL");
            }
            Graphics.Blit(null, blitTarget, fftMat);
        }

        heightMat.SetTexture("_Phase", currentPhase ? pingPhaseTexture : pongPhaseTexture);
        Graphics.Blit(null, spectrumTexture, heightMat);
        fftMat.EnableKeyword("_HORIZONTAL");
        fftMat.DisableKeyword("_VERTICAL");

        for (int i = 0; i < iterations; i++)
        {
            RenderTexture blitTarget;
            fftMat.SetFloat("_SubTransformSize", Mathf.Pow(2, (i % (iterations / 2)) + 1));
            if (i == 0)
            {
                fftMat.SetTexture("_Input", spectrumTexture);
                blitTarget = pingTransformTexture;
            }
            else if (i == iterations - 1)
            {
                fftMat.SetTexture("_Input", (iterations % 2 == 0) ? pingTransformTexture : pongTransformTexture);
                blitTarget = heightTexture;
            }
            else if (i % 2 == 1)
            {
                fftMat.SetTexture("_Input", pingTransformTexture);
                blitTarget = pongTransformTexture;
            }
            else
            {
                fftMat.SetTexture("_Input", pongTransformTexture);
                blitTarget = pingTransformTexture;
            }
            if (i == iterations / 2)
            {
                fftMat.DisableKeyword("_HORIZONTAL");
                fftMat.EnableKeyword("_VERTICAL");
            }
            Graphics.Blit(null, blitTarget, fftMat);
        }

        normalMat.SetTexture("_DisplacementMap", displacementTexture);
        normalMat.SetTexture("_HeightMap", heightTexture);
        Graphics.Blit(null, normalTexture, normalMat);
        whiteMat.SetTexture("_Displacement", displacementTexture);
        whiteMat.SetTexture("_Bump", normalTexture);
        whiteMat.SetFloat("_Resolution", _Resolution);
        whiteMat.SetFloat("_Length", _Resolution);
        Graphics.Blit(null, whiteTexture, whiteMat);

        if (!saved)
        {
            oceanMat.SetTexture("_Anim", displacementTexture);
            oceanMat.SetTexture("_Height", heightTexture);
            oceanMat.SetTexture("_White", whiteTexture);
            oceanMat.SetTexture("_Bump", normalTexture);
            saved = true;
        }

    }
    #endregion
}
