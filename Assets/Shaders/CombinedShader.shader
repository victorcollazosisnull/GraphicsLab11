Shader "Custom/CombinedShaderEmission"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Tint Color", Color) = (1,1,1,1)

        _EmissionMap("Emission Map", 2D) = "black" {}
        [HDR]_EmissionColor("Emission Color", Color) = (0,0,0,0)
        _EmissionStrength("Emission Strength", Range(0, 10)) = 1.0

        _NormalMap("Normal Map", 2D) = "bump" {}

        _HeightMap("Height Map", 2D) = "black" {}
        _HeightScale("Height Scale", Range(0, 0.1)) = 0.05

        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _OcclusionStrength("Occlusion Strength", Range(0, 10)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Emission" = "True" }
        LOD 300

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _EMISSION
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBinormal : TEXCOORD3;
                float3 viewDir : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _Color;

            sampler2D _EmissionMap;
            float4 _EmissionColor;
            float _EmissionStrength;

            sampler2D _NormalMap;

            sampler2D _HeightMap;
            float _HeightScale;

            sampler2D _OcclusionMap;
            float _OcclusionStrength;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                float3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                float3 worldTangent = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.worldNormal = worldNormal;
                o.worldTangent = worldTangent;
                o.worldBinormal = worldBinormal;
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex).xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float height = tex2D(_HeightMap, i.uv).r;
                float2 offset = (i.viewDir.xy * (height * _HeightScale)) / i.viewDir.z;
                float2 parallaxUV = i.uv + offset;

                float4 texColor = tex2D(_MainTex, parallaxUV) * _Color;

                float3 normalMap = tex2D(_NormalMap, parallaxUV).rgb * 2.0 - 1.0;
                float3x3 TBN = float3x3(i.worldTangent, i.worldBinormal, i.worldNormal);
                float3 disturbedNormal = normalize(mul(TBN, normalMap));

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = max(0, dot(disturbedNormal, lightDir));
                float3 diffuse = texColor.rgb * _LightColor0.rgb * NdotL;

                float occlusion = tex2D(_OcclusionMap, parallaxUV).r;
                occlusion = lerp(1.0, occlusion, _OcclusionStrength);
                diffuse *= occlusion;

                float3 emission = tex2D(_EmissionMap, parallaxUV).rgb * _EmissionColor.rgb * _EmissionStrength;

                float3 finalColor = diffuse + emission;
                return float4(finalColor, texColor.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
