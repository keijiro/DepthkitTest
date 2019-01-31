Shader "Hidden/Ditho/Fiber"
{
    CGINCLUDE

    #include "UnityCG.cginc"
    #include "Common.hlsl"
    #include "SimplexNoise2D.hlsl"

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    float2 _CurveParams; // freq, speed
    float2 _NoiseParams; // amp, speed

    float3 _LineColor;
    float _Attenuation;

    float _LocalTime;

    void Vertex(
        uint vid : SV_VertexID,
        out float4 cs_position : SV_Position,
        out float alpha : COLOR
    )
    {
        // Noise parameters
        float n1 = vid * _CurveParams.x;
        float n2 = _LocalTime * _CurveParams.y;
        float n3 = _LocalTime * _NoiseParams.y;

        // UV coordinates
        float2 uv = float2(
            snoise(float2(n1, 98.32 + n2)),
            snoise(float2(12.32 - n2, n1))
        );
        uv = frac(uv * 0.75 + 0.5);

        // Object space position
        float3 depth_sample = tex2Dlod(_MainTex, DepthUV(uv)).rgb;
        float3 pos = DepthToPosition(uv, depth_sample);

        // Additional noise
        pos.z *= 1 + snoise(float2(n3, n1 * -10)) * _NoiseParams.x;

        // Attenuation noise
        float atten = saturate(10 * (snoise(_LocalTime * 2) / 2 + snoise(_LocalTime)));
        atten *= saturate(10 * snoise(pos.xy * 5 + _LocalTime * 10));
        atten = lerp(0, atten, saturate(_Attenuation * 2));
        atten = lerp(atten, 1, saturate(_Attenuation * 2 - 1));

        // Output
        cs_position = UnityObjectToClipPos(float4(pos, 1));
        alpha = dot(depth_sample, 1.0 / 3) * atten;
    }

    float4 Fragment(
        float4 cs_position : SV_Position,
        float alpha : COLOR
    ) : SV_Target
    {
        clip(alpha - 0.3);
        return float4(_LineColor, 1);
    }

    ENDCG

    SubShader
    {
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma target 4.5
            ENDCG
        }
        Pass
        {
            Tags { "LightMode"="ShadowCaster" }
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma target 4.5
            ENDCG
        }
    }
}
