Shader "CustomRenderer"
{
    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

    float4 _Crop;
    float2 _ImageDimensions;
    float2 _FocalLength;
    float2 _PrincipalPoint;
    float _NearClip;
    float _FarClip;
    float4x4 _Extrinsics;

    float4x4 _LocalToWorld;

    fixed CalculateHue(fixed3 c)
    {
    #if !defined(UNITY_COLORSPACE_GAMMA)
        c = LinearToGammaSpace(c);
    #endif
        fixed minc = min(min(c.r, c.g), c.b);
        fixed maxc = max(max(c.r, c.g), c.b);
        fixed div = 1 / (6 * max(maxc - minc, 1e-5));
        fixed r = (c.g - c.b) * div;
        fixed g = 1.0 / 3 + (c.b - c.r) * div;
        fixed b = 2.0 / 3 + (c.r - c.g) * div;
        return lerp(r, lerp(g, b, c.g < c.b), c.r < max(c.g, c.b));
    }

    float3 CalculateObjectSpacePosition(float2 coord, float3 depthSample)
    {
        coord = (coord * _Crop.zw + _Crop.xy) * _ImageDimensions - _PrincipalPoint;
        float z = lerp(_NearClip, _FarClip, CalculateHue(depthSample));
        return mul(_Extrinsics, float4(coord * z / _FocalLength, z, 1)).xyz;
    }

    float4 Vertex(
        uint vid : SV_VertexID,
        out half4 color : COLOR
    ) : SV_Position
    {
        float x = (float)(vid % 1024) / 1024;
        float y = (float)(vid / 1024) / 1024;

        float4 uv_d = float4(x, 1 - y / 2, 0, 1);
        float4 uv_c = uv_d - float4(0, 0.5, 0, 0);

        float3 depth_sample = tex2Dlod(_MainTex, uv_d).rgb;
        float3 color_sample = tex2Dlod(_MainTex, uv_c).rgb;

        color = half4(color_sample, dot(depth_sample, 1) > 0.1);

        float3 o_pos = CalculateObjectSpacePosition(float2(x, y), depth_sample);
        return UnityWorldToClipPos(mul(_LocalToWorld, float4(o_pos, 1)));
    }

    float4 Fragment(
        float4 position : SV_Position,
        half4 color : COLOR
    ) : SV_Target
    {
        clip(color.a - 0.001);
        return color;
    }

    ENDCG

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            ENDCG
        }
    }
}
