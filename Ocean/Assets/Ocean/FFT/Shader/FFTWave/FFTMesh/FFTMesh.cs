using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTMesh : MonoBehaviour {
    public int _Resolution;
    public float _unitWidth;


    private Mesh mesh;
    private MeshFilter filter;

    private Vector3[] vertices;
    private Vector3[] normals;
    private Vector2[] uvs;

    private Color[] colors;
    private int[] indices;

    public Material spectrumMat;
    public RenderTexture SpectrumMap;

    public Vector2 wind;
    public float Amp;
    private float _RandomSeed1;
    private float _RandomSeed2;

    private Vector2[] displacement;
    private float timer;

    public float len;
    public float tDivision = 1f;

    private void Awake()
    {
        mesh = new Mesh();
        filter = GetComponent<MeshFilter>();
        _RandomSeed1 = 1.5122f;
        _RandomSeed2 = 6.1152f;
        timer = 0.0f;
        len = 16.0f;
    }
    private void Start()
    {
        SetParams();
        GenerateMesh();
    }
    private void Update()
    {
        timer += Time.deltaTime / tDivision;
        Displacement();
    }

    private void SetParams()
    {
        vertices = new Vector3[_Resolution * _Resolution];
        normals = new Vector3[_Resolution * _Resolution];
        uvs = new Vector2[_Resolution * _Resolution];
        indices = new int[(_Resolution - 1) * (_Resolution - 1) * 6];
        displacement = new Vector2[_Resolution * _Resolution];
        colors = new Color[_Resolution * _Resolution];
    }

    private void GenerateMesh()
    {
        int indiceCount = 0;
        int halfResolution = _Resolution / 2;
        for(int i=0;i<_Resolution;i++)
        {
            float horizontalPosition = (i - halfResolution) * _unitWidth;

            for(int j=0;j<_Resolution;j++)
            {
                float verticalPosition = (j - halfResolution) * _unitWidth;

                int currentIndex = i * _Resolution + j;

                uvs[currentIndex] = new Vector2(i / (float)(_Resolution-1), j / (float)(_Resolution-1));
                normals[currentIndex] = new Vector3(0, 1, 0);
                vertices[currentIndex] = new Vector3(horizontalPosition, 0, verticalPosition);
                if (j == _Resolution-1)
                {
                    continue;
                }
                if(i!=_Resolution-1)
                {
                    indices[indiceCount++] = currentIndex;
                    indices[indiceCount++] = currentIndex + 1;
                    indices[indiceCount++] = currentIndex + _Resolution;
                }
                if(i!=0)
                {
                    indices[indiceCount++] = currentIndex;
                    indices[indiceCount++] = currentIndex - _Resolution + 1;
                    indices[indiceCount++] = currentIndex + 1;
                }
            }
        }
        mesh.vertices = vertices;
        mesh.normals = normals;
        mesh.uv = uvs;
        mesh.SetIndices(indices, MeshTopology.Triangles, 0);

        filter.mesh = mesh;
    }
    private void getHeight(int index,float t)
    {
        float PI = 3.14159265f;
        float G = 9.81f;
        Vector2 dis = new Vector2(0, 0);
        Vector2 result = new Vector2(0, 0);
        Vector2 vert = vertices[index];

        for (int i=0;i<_Resolution;i++)
        {
            for(int j=0;j<_Resolution;j++)
            {
                int currentIndex = i * _Resolution + j;

                float n = i - _Resolution/2.0f;
                float m = j - _Resolution/2.0f;

                Vector2 k = new Vector2(2 * PI * n / len,PI * m / len);

                float wk = Mathf.Sqrt(G * k.magnitude);

                float phi1 =FFTMath.Phlillips(n, m, Amp, wind, _Resolution, len);
                float phi2 =FFTMath.Phlillips(_Resolution - n, _Resolution - m, Amp, wind, _Resolution, len);

                Vector2 h0 =FFTMath.hTilde0(uvs[currentIndex],_RandomSeed1 / 2, _RandomSeed2 / 2, phi1);
                Vector2 h0conj =FFTMath.Conj(FFTMath.hTilde0(uvs[currentIndex], _RandomSeed1, _RandomSeed2, phi2));

                Vector2 c0 = new Vector2(Mathf.Cos(t * wk), Mathf.Sin(t * wk));
                Vector2 c1 = new Vector2(c0.x, -c0.y);

                Vector2 hx = FFTMath.ComplexMul(h0, c0);
                Vector2 hz = FFTMath.ComplexMul(h0conj,c1);

                Vector2 Spectrum = hx + hz;
                Complex spec = new Complex(Spectrum.x, Spectrum.y);

                float kx = Vector2.Dot(k, vert);

                Vector2 phase_2 = new Vector2(Mathf.Cos(kx), Mathf.Sin(kx));
                result = FFTMath.ComplexMul(Spectrum, phase_2);
                dis = result + dis;
                colors[currentIndex] = new Color(1, 1, 1, 1);
            }
        }
        displacement[index] = dis;
        mesh.colors = colors;
    }
    private void Displacement()
    {
        for(int i=0;i<_Resolution;i++)
        {
            for(int j=0;j<_Resolution;j++)
            {
                int currentIndex = i * _Resolution + j;
                getHeight(currentIndex,timer);
                Vector3 oldPos = vertices[currentIndex];
                vertices[currentIndex] = new Vector3(oldPos.x, displacement[currentIndex].x, oldPos.z);
            }
        }
        mesh.vertices = vertices;
    }
}
