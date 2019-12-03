// Upgrade NOTE: upgraded instancing buffer 'DissolveShader' to new syntax.

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DissolveShader"
{
	Properties
	{
		_Vector0("Vector 0", Vector) = (0,0,0,0)
		_Float0("Float 0", Float) = 0.5
		_Float1("Float 1", Float) = 0.5
		_Float2("Float 2", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma multi_compile_instancing
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		struct Input
		{
			half filler;
		};

		uniform float _Float0;
		uniform float _Float1;
		uniform float _Float2;

		UNITY_INSTANCING_BUFFER_START(DissolveShader)
			UNITY_DEFINE_INSTANCED_PROP(float4, _Vector0)
#define _Vector0_arr DissolveShader
		UNITY_INSTANCING_BUFFER_END(DissolveShader)

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 _Vector0_Instance = UNITY_ACCESS_INSTANCED_PROP(_Vector0_arr, _Vector0);
			o.Albedo = _Vector0_Instance.xyz;
			o.Metallic = _Float0;
			o.Smoothness = _Float1;
			o.Occlusion = _Float2;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17400
1921;1;1918;1016;1118.217;434.2477;1;True;True
Node;AmplifyShaderEditor.Vector4Node;17;-698.2168,-170.2477;Inherit;True;InstancedProperty;_Vector0;Vector 0;0;0;Create;True;0;0;False;0;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;19;-317.2168,-33.24768;Inherit;False;Property;_Float1;Float 1;2;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-327.2168,-102.2477;Inherit;False;Property;_Float0;Float 0;1;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-305.2168,33.75232;Inherit;False;Property;_Float2;Float 2;3;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-94,-161;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;DissolveShader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;0;0;17;0
WireConnection;0;3;18;0
WireConnection;0;4;19;0
WireConnection;0;5;20;0
ASEEND*/
//CHKSM=E1F444502D4D6023274C509F550162F5FABC9747