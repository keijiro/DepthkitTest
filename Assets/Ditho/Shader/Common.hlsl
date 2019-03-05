// Hash function from H. Schechter & R. Bridson, goo.gl/RXiKaH
uint Hash(uint s)
{
    s ^= 2747636419u;
    s *= 2654435769u;
    s ^= s >> 16;
    s *= 2654435769u;
    s ^= s >> 16;
    s *= 2654435769u;
    return s;
}

float Random(uint seed)
{
    return float(Hash(seed)) / 4294967295.0; // 2^32-1
}

// Depthkit UV space
float4 DepthUV(float2 coord)
{
    return float4(coord.x, 1 - coord.y / 2, 0, 1);
}

float4 ColorUV(float2 coord)
{
    return float4(coord.x, 0.5 - coord.y / 2, 0, 1);
}

// Hue value calculation
fixed RGB2Hue(fixed3 c)
{
#if !defined(UNITY_COLORSPACE_GAMMA)
    c = LinearToGammaSpace(c);
#endif
    fixed minc = min(min(c.r, c.g), c.b);
    fixed maxc = max(max(c.r, c.g), c.b);
    half div = 1 / (6 * max(maxc - minc, 1e-5));
    half r = (c.g - c.b) * div;
    half g = 1.0 / 3 + (c.b - c.r) * div;
    half b = 2.0 / 3 + (c.r - c.g) * div;
    return frac(c.r > max(c.g, c.b) ? r : (c.g > c.b ? g : b));
}

// Depthkit metadata
float4 _Crop;
float2 _ImageDimensions;
float2 _FocalLength;
float2 _PrincipalPoint;
float _NearClip;
float _FarClip;
float4x4 _Extrinsics;

// Check if a depth sample is valid or not.
bool ValidateDepth(float3 depthSample)
{
    return dot(depthSample, 1) > 0.3;
}

// Object space position from depth sample
float3 DepthToPosition(float2 coord, float3 depthSample)
{
    coord = (coord * _Crop.zw + _Crop.xy) * _ImageDimensions - _PrincipalPoint;
    float d = ValidateDepth(depthSample) ? RGB2Hue(depthSample) : 1;
    float z = lerp(_NearClip, _FarClip, d);
    return mul(_Extrinsics, float4(coord * z / _FocalLength, z, 1)).xyz;
}
