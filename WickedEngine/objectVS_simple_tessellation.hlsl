#include "objectHF.hlsli"


// Vertex layout declaration:
RAWBUFFER(vertexBuffer_POS, VBSLOT_0);
RAWBUFFER(vertexBuffer_NOR, VBSLOT_1);
RAWBUFFER(vertexBuffer_TEX, VBSLOT_2);
RAWBUFFER(vertexBuffer_PRE, VBSLOT_3);
STRUCTUREDBUFFER(instanceBuffer, Input_Instance, VBSLOT_4);
STRUCTUREDBUFFER(instanceBuffer_Prev, Input_InstancePrev, VBSLOT_5);


struct HullInputType
{
	float3 pos								: POSITION;
	float3 posPrev							: POSITIONPREV;
	float3 tex								: TEXCOORD0;
	float4 nor								: NORMAL;
	nointerpolation float3 instanceColor	: INSTANCECOLOR;
	nointerpolation float dither			: DITHER;
};


HullInputType main(uint vID : SV_VERTEXID, uint instanceID : SV_INSTANCEID)
{
	// Custom fetch vertex buffer:
	const uint fetchAddress = vID * 16;
	Input_Object_ALL input;
	input.pos = asfloat(vertexBuffer_POS.Load4(fetchAddress));
	input.nor = asfloat(vertexBuffer_NOR.Load4(fetchAddress));
	input.tex = asfloat(vertexBuffer_TEX.Load4(fetchAddress));
	input.pre = asfloat(vertexBuffer_PRE.Load4(fetchAddress));
	input.instance = instanceBuffer[instanceID];
	input.instancePrev = instanceBuffer_Prev[instanceID];


	HullInputType Out = (HullInputType)0;


	float4x4 WORLD = MakeWorldMatrixFromInstance(input.instance);

	float4 pos = float4(input.pos.xyz, 1);


	pos = mul(pos, WORLD);
	affectWind(pos.xyz, input.pos.w, g_xFrame_Time);

	float3 normal = mul(normalize(input.nor.xyz), (float3x3)WORLD);

	Out.pos = pos.xyz;
	Out.tex = input.tex.xyz;

	// note: simple vs doesn't have normal but this needs it because tessellation is using normal information
	Out.nor = float4(normalize(normal), input.nor.w);

	// todo: leave these but I'm lazy to create appropriate hull/domain shaders now...
	Out.posPrev = 0;
	Out.instanceColor = 0;
	Out.dither = 0;

	return Out;
}