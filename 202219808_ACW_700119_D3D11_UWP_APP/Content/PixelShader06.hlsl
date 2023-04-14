struct PixelShaderInput
{
    float4 pos : SV_POSITION;
    float3 nor : NORMAL;
    float2 tex : TEXCOORD0;
};

float4 main(PixelShaderInput input) : SV_TARGET
{
    return float4(input.tex, 1.0, 1.0);
}