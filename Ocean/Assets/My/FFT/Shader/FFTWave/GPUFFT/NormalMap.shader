Shader "FFT/Normal Map"
{
    Properties
    {
		_DisplacementMap ("Displacement Map", 2D) = "black" {}
		_HeightMap ("Height Map", 2D) = "black" {}
		_Length ("Wave Length", Float) = 512
		_Resolution ("Resolution", Float) = 512
    }
    SubShader
    {
        Pass
        {
            Cull Off
		    ZWrite Off
		    ZTest Off
		    ColorMask RGBA

            CGPROGRAM

            #include "FFTCommon.cginc"
            #pragma vertex vert_quad
            #pragma fragment frag

            uniform sampler2D _DisplacementMap;
            uniform sampler2D _HeightMap;
            uniform float _Length;
            uniform float _Resolution;

            inline float3 GetVec(float2 tc)
            {
                float2 xz = tex2D(_DisplacementMap,tc).rb;
                float y = tex2D(_HeightMap,tc).r;
                return float3(xz.x,y,xz.y);
            }
            fixed4 frag (FFTVertexOutput i) : SV_Target
            {
                float texel = 1 / _Resolution;
                float texelSize = _Length / _Resolution;

                float3 center = tex2D(_DisplacementMap,i.texcoord).rgb;
                float3 right = float3(texelSize,0,0) + GetVec(i.texcoord + float2(texel,0)) - center;
                float3 left = float3(-texelSize,0,0) + GetVec(i.texcoord + float2(-texel,0)) - center;
                float3 top = float3(0,0,-texelSize) + GetVec(i.texcoord + float2(0,-texel)) - center;
                float3 bottom = float3(0,0,texelSize) + GetVec(i.texcoord + float2(0,texel)) - center;

                float3 topRight = cross(right,top);
                float3 topLeft = cross(top,left);
                float3 bottomleft = cross(left,bottom);
                float3 bottomRight = cross(bottom,right);

                return float4(normalize(topRight + topLeft + bottomleft + bottomRight),1);
            }
            ENDCG
        }
    }
}
