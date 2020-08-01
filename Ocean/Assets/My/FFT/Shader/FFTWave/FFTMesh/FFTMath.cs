using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTMath : MonoBehaviour
{

    static float EPSILON = 0.00000001f;
    static float PI = 3.14159265f;

    public static float UVRandom(Vector2 uv, float salt, float random)
    {
        uv += new Vector2(salt, random);
        return Mathf.Sin(Vector2.Dot(uv, new Vector2(12.9898f, 78.233f))) * 43758.5453f;
    }

    public static Vector2 hTilde0(Vector2 uv, float r1, float r2, float phi)
    {
        Vector2 r;

        float rand1 = UVRandom(uv, 10.612f, r1);
        float rand2 = UVRandom(uv, 11.899f, r2);

        rand1 = Random.value;
        rand1 = Random.value;

        rand1 = Mathf.Clamp(rand1, EPSILON, 1);
        rand2 = Mathf.Clamp(rand2, EPSILON, 1);
        float x = Mathf.Sqrt(-2 * Mathf.Log(rand1));
        float y = 2 * PI * rand2;
        r.x = x * Mathf.Cos(y);
        r.y = x * Mathf.Sin(y);
        return r * Mathf.Sqrt(phi / 2);
    }

    public static float Phlillips(float n, float m, float amp, Vector2 wind, float res, float len)
    {
        float G = 9.81f;
        Vector2 k =new Vector2(2 * PI * n / len, 2 * PI * m / len);
        float klen = k.magnitude;
        float klen2 = klen * klen;
        float klen4 = klen2 * klen2;
        if (klen < EPSILON)
            return 0;
        float kDotW = Vector2.Dot(k.normalized,wind.normalized);
        float kDotW2 = kDotW * kDotW;
        float wlen = wind.magnitude;
        float l = wlen * wlen / G;
        float l2 = l * l;
        float damping = 0.01f;
        float L2 = l2 * damping * damping;
        return amp * Mathf.Exp(-1 / (klen2 * l2)) / klen4 * kDotW2 * Mathf.Exp(-klen2 * L2);
    }

    public static Vector2 Conj(Vector2 a)
    {
        return new Vector2(a.x, -a.y);
    }

    public static Vector2 ComplexMul(Vector2 a, Vector2 b)
    {
        Vector2 result =new Vector2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
        return result;
    }
}
