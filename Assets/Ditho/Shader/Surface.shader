Shader "Hidden/Ditho/Surface"
{
    CGINCLUDE

    #include "UnityCG.cginc"
    #include "Common.hlsl"
    #include "SimplexNoise3D.hlsl"

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    float2 _NoiseParams; // amp, anim

    float3 _LineColor;
    float2 _LineParams; // repeat, width

    float3 _SparkleColor;
    float _SparkleDensity;

    float _LocalTime;

    void Vertex(
        float2 uv : POSITION,
        out float4 cs_position : SV_Position,
        out float3 ws_position : TEXCOORD0,
        out float3 normal : NORMAL,
        out float4 color : COLOR
    )
    {
        // Center samples
        float3 depth_sample = tex2Dlod(_MainTex, DepthUV(uv)).rgb;
        float3 color_sample = tex2Dlod(_MainTex, ColorUV(uv)).rgb;

        // Color and opacity
        color = half4(color_sample, dot(depth_sample, 1.0 / 3));

        // Object space position
        float3 pos = DepthToPosition(uv, depth_sample);

        // Additional noise
        float3 np = float3(uv * 20, _LocalTime * _NoiseParams.y);
        pos += snoise_grad(np).xyz * float3(0.1, 0.1, 1) * _NoiseParams.x;

        // World/clip space positions
        ws_position = mul(unity_ObjectToWorld, float4(pos, 1));
        cs_position = UnityWorldToClipPos(ws_position);

        // Normal vector calculation
        float3 eps = float3(_MainTex_TexelSize.xy / 2, 0);

        float2 uv_b = uv - eps.zy;
        float2 uv_t = uv + eps.zy;
        float2 uv_l = uv - eps.xz;
        float2 uv_r = uv + eps.xz;

        float3 depth_b = tex2Dlod(_MainTex, DepthUV(uv_b)).rgb;
        float3 depth_t = tex2Dlod(_MainTex, DepthUV(uv_t)).rgb;
        float3 depth_l = tex2Dlod(_MainTex, DepthUV(uv_l)).rgb;
        float3 depth_r = tex2Dlod(_MainTex, DepthUV(uv_r)).rgb;

        float3 pos_b = DepthToPosition(uv_b, depth_b);
        float3 pos_t = DepthToPosition(uv_t, depth_t);
        float3 pos_l = DepthToPosition(uv_l, depth_l);
        float3 pos_r = DepthToPosition(uv_r, depth_r);

        normal = normalize(cross(pos_t - pos_b, pos_r - pos_l));
    }

    float4 Fragment(
        float4 cs_position : SV_Position,
        float3 ws_position : TEXCOORD0,
        float3 normal : NORMAL,
        float4 color : COLOR
    ) : SV_Target
    {
        // Alpha clipping
        clip(color.w - 0.3);

        // Potential
        float pt = ws_position.y * _LineParams.x;

        // Line intensity
        float li = saturate(1 - abs(0.5 - frac(pt)) / (fwidth(pt) * _LineParams.y));

        // World space position based noise field
        float nf = snoise(ws_position * 500);

        // Color mixing
        float3 lc = _LineColor * (1 + nf);
        float3 sc = _SparkleColor * smoothstep(1 - _SparkleDensity, 1, nf);
        return float4(li * saturate(Luminance(color.rgb)) * (lc + sc), 1);
    }

    ENDCG

    SubShader
    {
        Pass
        {
            ZWrite [_ZWrite]
            Cull [_Cull]
            Blend [_SrcBlend] [_DstBlend]
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
