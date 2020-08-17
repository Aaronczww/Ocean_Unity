Shader "FFT/Ocean"
{
    Properties
    {
        [HideInInspector] _HeightMap ("", 2D) = "black" {}

        _Anim("Displacement Map",2D) = "black"{}
        _Height("Height Map",2D) = "black"{}
        _Bump("Normal Map",2D) = "bump"{}
        _White("white Cap Map",2D) = "black"{}
        // _LightWrap("Light Wrapping Value",float) = 1
        // _Tint("Color Tint",Color) =  (0.5, 0.65, 0.75, 1)
        _SpecColor ("Specular Color", Color) = (1, 0.25, 0, 1)
		_Glossiness ("Glossiness", Float) = 64
		// _RimColor ("Rim Color", Color) = (0, 0, 1, 1)


        [Header(Textures)]
		// _FoamTex ("Foam Texture", 2D) = "white" {} 
		// _NormalTex ("Normal Map", 2D) = "white" {}
		// _ShallowMaskOffset("Shallow Mask Offset",Vector) = (-0.1,0.2,0,0)
		_Skybox("Skybox", Cube) = "" {}
		// _NormalSpeed("Normal Moving Speed", Float) = 1.0

		_HeightMapTransform("Height Map Divide Scale XZ",Vector) = (640,640,0.3,0.3)


		[Header(Scattering Color)]
		_DeepColor("Deep Color", Color) = (0.04,0.125,0.62,1.0)
		_ShallowColor("Shallow Color", Color) = (0.275,0.855,1.0,1.0)


		[Header(Refractive Distortion)]
		_RefractionStrength("Refractive Distortion Strength",Float) = 1.0
		_WaterClarity("Water Clarity",Range(4,30)) = 12.0
		_WaterClarityAttenuationFactor("Water Clarity Attenuation Factor",Range(0.1,3)) = 1.0
		_WaterDepthChangeFactor("Water Depth Change Factor",Range(0.1,2)) = 1.0

		[Header(Fake SSS)]
		_DirectTranslucencyPow("Direct Translucency Power",Range(0.1,3)) = 1.5
		_EmissionStrength("Directional Scattering Strength",Range(0.1,2)) = 1.0
		_DirectionalScatteringColor("Directional Scattering Color", Color) = (0.00,0.65,0.34,1.0)
		_waveMaxHeight("Wave Height Factor For Scattering", Float) = 5.0

		[Header(Reflective)]

		[Toggle(_USE_SKYBOX)] _UseSkybox ("Use Skybox ONLY", Float) = 0
		_AirRefractiveIndex("Air Refractive Index", Float) = 1.0
		_WaterRefractiveIndex("Water Refractive Index", Float) = 1.333
		_FresnelPower("Fresnel Power", Range(0.1,50)) = 5
		_ReflectionDistortionStrength("Reflective Distortion Strength",Float) = 1.0


		[Header(Specular)]
		_SunAnglePow("Sunlight Angle Strength", Range(0.1,2)) = 1
		_Shininess("Shininess",Range(50,800)) = 400

		// _WaveTex("Wave",2D) = "gray" {}
    }
    SubShader
    {
        
        GrabPass { "_WaterBackground" }

        Pass
        {
            Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" "LightMode"="ForwardBase" }
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


	            samplerCUBE _Skybox;
	            sampler2D _FoamTex;
	            sampler2D _NormalTex;
	            sampler2D _WaterBackground;
	            sampler2D _CameraDepthTexture;
	            sampler2D _ReflectionTex;
	            sampler2D _ReflectionBlockTex;
	            sampler2D _HeightMap;
	            sampler2D _ShadowMask;
	            sampler2D _FoamMap;

	            float4 _FoamTex_ST;
	            float4 _NormalTex_ST;

				float _S;
				float _A1,_A2,_A3,_A4,_A5,_A6,_A7,_A8,_A9,_A10,_A11,_A12;
				float _Stp1,_Stp2,_Stp3,_Stp4,_Stp5,_Stp6,_Stp7,_Stp8,_Stp9,_Stp10,_Stp11,_Stp12;
				float _D1,_D2,_D3,_D4,_D5,_D6,_D7,_D8,_D9,_D10,_D11,_D12;

				float4 _DeepColor;
				float4 _ShallowColor;
				float4 _DirectionalScatteringColor;

				float4 _CameraDepthTexture_TexelSize;

				float _Shininess;
				float _SunAnglePow;
				float _NormalSpeed;
				float _ShoreWaveAttenuation;
				float _AirRefractiveIndex;
				float _WaterRefractiveIndex;
				float _FresnelPower;
				float _RefractionStrength;
				float _WaterClarity;
				float _WaterDepthChangeFactor;
				float _WaterClarityAttenuationFactor;
				float _DirectTranslucencyPow;
				float _EmissionStrength;
				float _waveMaxHeight;
				float _ReflectionDistortionStrength;

				int _resolution;

				float2 _ShallowMaskOffset;
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
                float3 worldPos : TEXCOORD5;
	            float4 grabPos : TEXCOORD6;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            	            //Calculating fresnel factor
	            float CalculateFresnel (float3 I, float3 N)
	            {
	            	float R_0 = (_AirRefractiveIndex - _WaterRefractiveIndex) / (_AirRefractiveIndex + _WaterRefractiveIndex);
	            	R_0 *= R_0;
	            	return  R_0 + (1.0 - R_0) * pow((1.0 - saturate(dot(I, N))), _FresnelPower);
	            }

	            float2 AlignWithGrabTexel (float2 uv)
	            {
	            	return (floor(uv * _CameraDepthTexture_TexelSize.zw) + 0.5) * abs( _CameraDepthTexture_TexelSize.xy);
	            }

	            //Fake Sub-suraface scattering calculation
	            float4 CalculateSSSColor(float3 lightDirection, float3 worldNormal, float3 viewDir,float waveHeight, float shadowFactor){
	            	float lightStrength = sqrt(saturate(lightDirection.y));
	            	float SSSFactor = pow(saturate(dot(viewDir ,lightDirection) )+saturate(dot(worldNormal ,-lightDirection)) ,_DirectTranslucencyPow) * shadowFactor * lightStrength * _EmissionStrength;
	            	return _DirectionalScatteringColor * (SSSFactor + waveHeight * 0.6);
	            }

            	            float4 CalculateRefractiveColor(float3 worldPos, float4 grabPos, float3 worldNormal, float3 viewDir,float3 lightDirection,float landHeight,float waveHeight,float shadowFactor)
	            {
	            	//USING DEPTH TEXTURE(.W) BUT NOT ACTUAL RAYLENGTH IN WATER, NEED TO FIX
	           		float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, grabPos));
	            	float surfaceDepth = grabPos.w;
	            	float viewWaterDepthNoDistortion = backgroundDepth - surfaceDepth;

	            	float4 distortedUV = grabPos;
	            	float2 uvOffset = worldNormal.xz * _RefractionStrength;

	            	//Distortion near water surface should be attenuated
					uvOffset *= saturate(viewWaterDepthNoDistortion);


					distortedUV.xy = AlignWithGrabTexel(distortedUV.xy + uvOffset);

					//Resample depth to avoid false distortion above water
	            	backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, distortedUV));

	            	surfaceDepth = grabPos.w;
	            	float viewWaterDepth = backgroundDepth - surfaceDepth;

					float tmp = step(viewWaterDepth,0);
	            	distortedUV.xy = tmp * AlignWithGrabTexel(grabPos.xy) + (1 - tmp) * distortedUV.xy;
	            	viewWaterDepth = tmp * viewWaterDepthNoDistortion + (1 - tmp) * viewWaterDepth;
	            	            	           	
	            	float4 transparentColor =  tex2Dproj(_WaterBackground , distortedUV);
	            	float shallowWaterFactor = 0;

					shallowWaterFactor = saturate(pow(landHeight,_WaterDepthChangeFactor)) ;

					float4 scatteredColor = _DeepColor  + _ShallowColor * shallowWaterFactor * (shadowFactor + 1) * 0.5;

					float viewWaterDepthFactor = pow(saturate(viewWaterDepth / _WaterClarity), _WaterClarityAttenuationFactor);
					float4 emissionSSSColor = CalculateSSSColor(lightDirection, worldNormal,  viewDir, waveHeight, shadowFactor);

	            	return lerp(transparentColor , scatteredColor, viewWaterDepthFactor) + emissionSSSColor;
	            }

	            //Calculate reflective color
	            float4 CalculateReflectiveColor(float3 worldPos, float4 grabPos, float3 worldNormal, float3 viewDir, out float4 distortedUV)
	            {
	            	float2 uvOffset = worldNormal.xz * _ReflectionDistortionStrength;

	            	uvOffset.y -= worldPos.y;
	            	distortedUV = grabPos; distortedUV.xy += uvOffset;
	            	#if _USE_SKYBOX	
	            		return texCUBE(_Skybox, reflect(viewDir,worldNormal));
	            	#endif
	            	float4 skyColor = texCUBE(_Skybox, reflect(viewDir,worldNormal));
	            	return lerp(tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(distortedUV)),skyColor,0.65);


	            }

            VertexOutput vert (VetexInput v)
            {
                VertexOutput o;

                v.vertex.y += tex2Dlod(_Height,v.texcoord).r / 8;
                // v.vertex.xz += tex2Dlod(_Anim,v.texcoord).rb / 8;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);


                o.pos = UnityObjectToClipPos(v.vertex);

    				o.worldPos = worldPos;
    				o.grabPos = ComputeGrabScreenPos(o.pos);

				o.normal = UnityObjectToWorldNormal(tex2Dlod(_Bump, v.texcoord).rgb);
                o.lightDir = normalize(WorldSpaceLightDir(v.vertex));
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
                o.color = tex2Dlod(_White, v.texcoord).r;
                o.texcoord = v.texcoord;

                return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
	            	float landHeight = tex2D(_HeightMap,i.texcoord);
	            	float waveHeight = saturate(i.worldPos.y/_waveMaxHeight) ;

                float3 normal = normalize(i.normal);
                float3 diffuse = (saturate(dot(normal,i.lightDir)) * _Tint).xyz;
                float3 viewDir = i.viewDir;
                float3 lightDir = i.lightDir;
				float3 H = normalize(i.viewDir + i.lightDir);
				float NdotH = saturate(dot(i.normal, H));
				float3 specular = (_SpecColor * saturate(pow(NdotH, _Glossiness))).xyz;

                float shadowFactor = 1;

					float4 reflectiveDistortedUV;


				float3 reflectedColor = CalculateReflectiveColor(i.worldPos, i.grabPos, normal,viewDir,reflectiveDistortedUV);
				float F = CalculateFresnel (-viewDir, normal);
				float4 refractiveColor = CalculateRefractiveColor(i.worldPos, i.grabPos, normal,viewDir,lightDir,landHeight,waveHeight,shadowFactor);

                // float3 rim = _RimColor * pow(max(0,1 - saturate(dot(normal,viewDir))),1.5);
 				float4 white = float4( pow(i.color,2).xyz,1);
                 float4 col = float4(lerp(refractiveColor ,reflectedColor ,F),1);

                return refractiveColor + white;
            }
            ENDCG
        }
    }
}
