#include "UnityCG.cginc"

static float PI = 3.1415926f;

// struct VertexInput
// {
// 	float4 vertex:POSITION;
// 	float2 uv : TEXCOORD0;
// 	float4 tangent:TANGENT;
// 	float3 normal:NORMAL;
// };

// struct VertexOutput
// {
// 	float4 pos : SV_POSITION;
// 	float2 uv : TEXCOORD0;
// 	float4 world_Pos:TEXCOORD1;
// 	float4 world_Normal:TEXCOORD2;
// 	float4 world_Tangent:TEXCOORD3;
// };

inline float4 IBLEnvLight(sampler2D LutMap,samplerCUBE Skybox,float roughness,float3 N,float3 V,float3 R,float Metallic)
{
	float lambert =  saturate(max(0,dot(N,_WorldSpaceLightPos0)));
	float4 EnvDiffuse = texCUBElod(Skybox,float4(N,5)) *  lambert;

	float NdotV = saturate(dot(N,V));
	float2 brdfUV = float2(NdotV,roughness);
	float2 preBRDF = tex2D(LutMap,brdfUV).xy;
	float4 EnvSpecluar = texCUBElod(Skybox,float4(R,roughness*5)) * (Metallic * preBRDF.x + preBRDF.y);
	
	float VdotH5 = pow(1.0f - NdotV, 5);
	float F = Metallic + (1.0f - Metallic) * VdotH5;

	return lerp(EnvDiffuse,EnvSpecluar,F);
}

//D
inline float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return nom / denom;
}

 //G
inline float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
inline float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

float3 Fresnel(float VoH,float3 F0)
{
    float3 F = F0 + (float3(1,1,1) - F0) * pow(1-VoH,5);
    return F;
}

inline float4 PBRDirectLight(float3 N,float3 V,float3 L,float3 F0,float Roughness,float Metallic,float4 Tint)
{
	float3 H = normalize(L+V);

    float3 H_temp = normalize(-L + V);

	float NdotL = dot(N,L);
	float NdotV = dot(N,V);
	float NdotH = dot(N,H);
    float VdotH = dot(V,H_temp);

	float D = DistributionGGX(N,H,Roughness);
	float G = GeometrySmith(N,V,L,Roughness);
	float3 F = Fresnel(VdotH,F0);
	float3 nominator = D*G*F;
	float denominator = 4 * max(NdotV,0) * max(NdotL,0) + 0.001;
	float3 directSpecular = nominator / denominator;

    float4 Specluar = float4(directSpecular,1);

    float3 kS = F;
    float3 kD = float3(1.0,1.0,1.0) - kS;
    kD = kD * (1.0 - Metallic);

    float4 kD_temp = float4(kD,1);

    float4 dircetDiffuse = Tint * kD_temp / PI;

	float4 directLight = dircetDiffuse * (NdotL + 0.5);

    return directLight;
}



/*
            float3 diffuseIrradiance(samplerCUBE cubeMap,float3 worldNormal)
            {
                float3 diffuseIrradiance = float3(0,0,0);
                //������ͼ����
                float sampleDelta = 0.025;
                float nSamples = 0;

                float3 n = normalize(worldNormal);
                float3 up    = float3(0.0, 1.0, 0.0);
                float3 right = cross(up, n);
                up           = cross(n, right);

                for(float phi=0;phi<2*PI;phi+=sampleDelta)
                {
                    for(float theata=0;theata<0.5*PI;theata+=sampleDelta)
                    {
                        //�������굽�ѿ�������
                        float3 tangentSample = float3(sin(theata)*cos(phi),sin(theata)*sin(phi),cos(theata));
                        
                        // tangentSample.x = dot(Tspace0,tangentSample.x);
                        // tangentSample.y = dot(Tspace1,tangentSample.y);
                        // tangentSample.z = dot(Tspace2,tangentSample.z);

                        float3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * n; 
                        
                        diffuseIrradiance = diffuseIrradiance + texCUBE(cubeMap,normalize(sampleVec)).xyz * cos(theata) * sin(theata);
                        nSamples++;
                    }
                }
                return PI*diffuseIrradiance*(1/nSamples);
            }

            //low-discrepancy sequence

            //Radical Inversion 
            float IntegerRadicalInverse(int Base,int i)
            {
                int numPoints,inverse;
                numPoints = 1;
                for(inverse = 0;i>0;i/=Base)
                {
                    inverse = inverse * Base + (i % Base);
                    numPoints = numPoints * Base;
                }
                return inverse/(float)numPoints;
            } 

            float VanDerCorpus(int n,int base)
            {
                float invBase = 1.0/(float)base;
                float denom = 1.0;
                float result = 0.0;
                for(int i=0;i<32;++i)
                {
                    if(n>0)
                    {
                        denom = fmod(float(n),2.0);
                        result += denom * invBase;
                        invBase = invBase / 2.0;
                        n = int(float(n)/2.0);
                    }
                }
                return result;
            }

            //Hammersley�㼯
            float2 Hammerseley(int i,int N)
            {
                return float2(float(i)/float(N),VanDerCorpus(i,2)); 
            }

            //��Ҫ�Բ������ذ������
            float3 ImportanceSampleGGX(float2 Xi,float3 N,float roughness)
            {
                float a = roughness * roughness;

                float phi = 2.0 * PI * Xi.x;
                float cosTheta = sqrt((1-Xi.y)/(1.0+(a*a-1)*Xi.y));
                float sinTheta = sqrt(1.0-cosTheta*cosTheta);

                float3 H;
                H.x = cos(phi) * sinTheta;
                H.y = sin(phi) * sinTheta;
                H.z = cosTheta;

                float3 up = abs(N.z) < 0.999 ? float3(0,0,1):float3(1,0,0);
                float3 tangent = normalize(cross(up,N));
                float3 bitangent = cross(N,tangent);

                float3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
                return normalize(sampleVec);
            }

            //prefilteredColor
            float3 prefilteredColor(float3 WorldPos,samplerCUBE cubeMap,float roughness)
            {
                float3 N = normalize(WorldPos);
                float3 R = N;
                float3 V = R;

                int SampleCount = 1024;
                float totalWeight = 0.0;
                float3 result = float3(0,0,0);
                float k = roughness * roughness / 2.0;

                for(int i=0;i<SampleCount;i++)
                {
                    float2 Xi = Hammerseley(i,SampleCount);
                    float3 H = ImportanceSampleGGX(Xi,N,roughness);
                    float3 L = normalize(2.0*dot(V,H)*H - V);

                    float NdotL = max(dot(N,L),0);
                    if(NdotL > 0.0)
                    {
                        float D = GeometrySmith(N,V,L,k);
                        float NdotH = max(dot(N,H),0);
                        float HdotV = max(dot(H,V),0);

                        float pdf = D * NdotH / ((4*HdotV) + 0.0001);
                        float saSample = 1.0/(float(SampleCount) * pdf + 0.0001);
                        float mipLevel = roughness == 0.0 ? 0.0 : 0.5 * log2(saSample / (2/1980*1080));

                        result = result + texCUBE(cubeMap,L).xyz * NdotL;
                        //result = result + texCUBElod(_CubeMap,L,mipLevel).xyz * NdotL;
                        totalWeight = totalWeight + NdotL;
                    }
                }

                return (result / totalWeight);
            }

            //BRDF LUT Map
            float3 IntegrateBRDF(float NdotV,float roughness)
            {
                float3 V;
                V.x = sqrt(1-NdotV*NdotV);
                V.y = 0.0;
                V.z = NdotV;

                float A = 0.0;
                float B = 0.0;
                float C = 0.0;

                float3 N = float3(0,0,1.0);
                int SampleCount = 1024;
                float3 result = float3(0,0,0);
                
                for(int i=0;i<SampleCount;++i)
                {
                    float2 Xi = Hammerseley(i,SampleCount);
                    float3 H = ImportanceSampleGGX(Xi,N,roughness);
                    float3 L = normalize(2.0*dot(V,H)*H - V);

                    float NdotL = max(L.z,0);
                    float NdotH = max(H.z,0);
                    float VdotH = max(dot(V,H),0);

                    if(NdotL > 0.0)
                    {
                        float G = GeometrySmith(N,V,L,roughness);
                        float G_Vis = (G * VdotH) / (NdotH * NdotV);
                        float Fc = pow(1-VdotH,5);

                        A = A + (1-Fc) * G_Vis;
                        B = B + Fc * G_Vis;
                    }
                }
                result = float3 (A,B,0);
                return result /(float)SampleCount;
            }
*/
