struct VS_OUTPUT
{
    float4 pos : SV_POSITION;
};

struct HS_Tri_Tess_Factors
{
    float Edges[3]  : SV_TessFactor;
    float Inside    : SV_InsideTessFactor;
};

HS_Tri_Tess_Factors ConstantHS_Tri(InputPatch<VS_OUTPUT, 3> ip)
{
    HS_Tri_Tess_Factors Output;
    float TessAmount = 30.0;
    Output.Edges[0] = Output.Edges[1] = Output.Edges[2] = TessAmount;
    Output.Inside = TessAmount;
    return Output;
}

[domain("tri")]
[partitioning("fractional_even")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("ConstantHS_Tri")]
VS_OUTPUT main(InputPatch<VS_OUTPUT, 3> patch,
uint i : SV_OutputControlPointID)
{
    VS_OUTPUT Output;
    Output.pos = patch[i].pos;
    return Output;
}