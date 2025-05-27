Shader "URP/ToonShader_ManualThresholds"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color Base", Color) = (1,1,1,1)
        _AmbientColor ("Ambient Light", Color) = (0.2, 0.2, 0.2, 1)
        _Thresholds ("Light Thresholds", Vector) = (0.95, 0.5, 0.2, 0)
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Range(0,0.1)) = 0.02
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        // OUTLINE PASS
        Pass
        {
            Name "Outline"
            Tags { "LightMode"="SRPDefaultUnlit" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert_outline
            #pragma fragment frag_outline
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _OutlineColor;
                float _OutlineWidth;
            CBUFFER_END

            Varyings vert_outline(Attributes IN)
            {
                Varyings OUT;
                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                float3 offset = normalWS * _OutlineWidth;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS + float4(offset, 0));
                return OUT;
            }

            half4 frag_outline(Varyings IN) : SV_Target
            {
                return _OutlineColor;
            }
            ENDHLSL
        }

        // TOON LIGHTING PASS
        Pass
        {
            Name "ToonLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _AmbientColor;
                float4 _Thresholds;
                sampler2D _MainTex;
                float4 _MainTex_ST;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float3 normal = normalize(IN.normalWS);
                Light light = GetMainLight();
                float NdotL = max(dot(normal, -light.direction), 0.0);

                float shade;
                if (NdotL > _Thresholds.x)
                    shade = 1.0;
                else if (NdotL > _Thresholds.y)
                    shade = 0.7;
                else if (NdotL > _Thresholds.z)
                    shade = 0.4;
                else
                    shade = 0.2;

                float3 texColor = tex2D(_MainTex, IN.uv).rgb;
                float3 finalColor = (_Color.rgb * texColor * shade) + _AmbientColor.rgb;

                return float4(finalColor, _Color.a);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/InternalErrorShader"
}
