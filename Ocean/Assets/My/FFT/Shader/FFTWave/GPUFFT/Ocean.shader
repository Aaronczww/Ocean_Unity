Shader "FFT/Ocean"
{
    Properties
    {
        _Anim("Displacement Map",2D) = "black"{}
        _Height("Height Map",2D) = "black"{}
        _Bump("Normal Map",2D) = "bump"{}
        _White("white Cap Map",2D) = "black"{}
        _LightWrap("Light Wrapping Value",float) = 1
        _Tint("Color Tint",Color) =  (0.5, 0.65, 0.75, 1)
        _SpecColor ("Specular Color", Color) = (1, 0.25, 0, 1)
		_Glossiness ("Glossiness", Float) = 64
		_RimColor ("Rim Color", Color) = (0, 0, 1, 1)
    }
    SubShader
    {

        Pass
        {
            // Cull Back
            ZWrite On
            // ZTest Equal
            ColorMask RGBA

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

			uniform sampler2D _Anim;
			uniform sampler2D _Height;
			uniform sampler2D _Bump;
			uniform sampler2D _White;

			uniform float4 _Tint;
			uniform float4 _SpecColor;
			uniform float _Glossiness;
			uniform float _LightWrap;
			uniform fixed4 _RimColor;

			uniform float4 _LightColor0;

            struct VetexInput
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 texcoord : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float4 color : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            VertexOutput vert (VetexInput v)
            {
                VertexOutput o;

                v.vertex.y += tex2Dlod(_Height,v.texcoord).r / 8;
                // v.vertex.xz += tex2Dlod(_Anim,v.texcoord).rb / 8;

                o.pos = UnityObjectToClipPos(v.vertex);

				o.normal = UnityObjectToWorldNormal(tex2Dlod(_Bump, v.texcoord).rgb);
                o.lightDir = normalize(WorldSpaceLightDir(v.vertex));
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.color = tex2Dlod(_White, v.texcoord).r;
                o.texcoord = v.texcoord;

                return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
                float3 normal = i.normal;
                float3 diffuse = (saturate(dot(normal,i.lightDir)) * _Tint).xyz;
                float3 viewDir = i.viewDir;
                float3 lightDir = i.lightDir;
				float3 H = normalize(i.viewDir + i.lightDir);
				float NdotH = saturate(dot(i.normal, H));
				float3 specular = (_SpecColor * saturate(pow(NdotH, _Glossiness))).xyz;
                // float3 rim = _RimColor * pow(max(0,1 - saturate(dot(normal,viewDir))),1.5);
                float4 col =  float4(diffuse + pow(i.color,2).xyz,1);
                return col;
            }
            ENDCG
        }
    }
}
