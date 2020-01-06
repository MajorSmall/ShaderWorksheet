// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "LightBeam_Surface"
{
	Properties
	{
		_Texture0("Texture 0", 2D) = "white" {}
		_LightTexture("Light Texture", 2D) = "white" {}
		_Albedo("Albedo", Color) = (0.5235849,0.8053764,1,1)
		[HDR]_Emission("Emission", Color) = (0.5235849,0.8053764,1,1)
		_FadeThickness("Fade Thickness", Float) = 0.54
		_FadeStrength("Fade Strength", Float) = 1
		_RotationSpeed("Rotation Speed", Vector) = (0,0.5,0,0)
		_LightBeamScale("Light Beam Scale", Range( -2 , 2)) = 2
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 viewDir;
			INTERNAL_DATA
			float3 worldPos;
		};

		uniform float4 _Albedo;
		uniform sampler2D _LightTexture;
		uniform float4 _LightTexture_ST;
		uniform float2 _RotationSpeed;
		uniform float4 _Emission;
		uniform sampler2D _Texture0;
		uniform float4 _Texture0_ST;
		uniform float _FadeStrength;
		uniform float _FadeThickness;
		uniform float _LightBeamScale;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Normal = float3(0,0,1);
			float2 uv0_LightTexture = i.uv_texcoord * _LightTexture_ST.xy + _LightTexture_ST.zw;
			float2 uv_TexCoord132 = i.uv_texcoord + ( _Time.y * _RotationSpeed );
			o.Albedo = ( _Albedo * tex2D( _LightTexture, ( uv0_LightTexture + uv_TexCoord132 ) ) ).rgb;
			float2 uv0_Texture0 = i.uv_texcoord * _Texture0_ST.xy + _Texture0_ST.zw;
			o.Emission = ( _Emission * tex2D( _Texture0, ( uv_TexCoord132 + uv0_Texture0 ) ) ).rgb;
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float smoothstepResult96 = smoothstep( 0.0 , 1.0 , min( min( ( _FadeThickness - i.viewDir.x ) , ( _FadeThickness + i.viewDir.x ) ) , ( _LightBeamScale - ase_vertex3Pos.y ) ));
			o.Alpha = ( _FadeStrength * smoothstepResult96 );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard alpha:fade keepalpha fullforwardshadows exclude_path:deferred 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17400
1927;7;1906;1004;1830.458;-346.215;1;False;True
Node;AmplifyShaderEditor.CommentaryNode;133;-2125.4,17.79996;Inherit;False;637.7815;291;Rotate Texure;4;130;129;131;132;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;119;-1570.103,663.4509;Inherit;False;1341.071;601.0001;Fade the edges based on view direction;6;95;94;67;98;116;118;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;111;-1266.929,-367.9333;Inherit;False;1035.856;525.7274;Albedo Texture and Color;2;109;108;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;129;-2087.4,155.7999;Inherit;False;Property;_RotationSpeed;Rotation Speed;6;0;Create;True;0;0;False;0;0,0.5;0,0.5;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleTimeNode;130;-2082.4,73.79994;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;115;-1441.727,165.9978;Inherit;False;1214.49;493.5003;Emission Texture and Color;2;114;113;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;118;-1520.103,924.2841;Inherit;False;272.4128;207.068;View vector in Tangent space;1;93;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;93;-1479.69,963.3521;Inherit;False;Tangent;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;141;-1567.077,1278.042;Inherit;False;1337.689;467.4919;Revealing the Light;4;145;148;144;146;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;67;-1460.103,786.2841;Inherit;False;Property;_FadeThickness;Fade Thickness;4;0;Create;True;0;0;False;0;0.54;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;131;-1903.619,123.8773;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;108;-1252.381,-317.2461;Inherit;False;698.9124;448.9275;Set Albedo Texture;4;4;8;138;139;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;113;-1432.951,210.0004;Inherit;False;858.799;433.237;Set Emission Texture;5;136;137;104;102;140;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;116;-1202.046,713.4509;Inherit;False;584;509.0001;With the tangent vector ;3;92;91;90;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-1151.046,980.4509;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;146;-1437.642,1500.751;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;90;-1152.046,763.4509;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;144;-1477.642,1392.751;Inherit;False;Property;_LightBeamScale;Light Beam Scale;7;0;Create;True;0;0;False;0;2;0.2117647;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;132;-1759.619,128.8773;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;8;-1236.899,-259.7685;Inherit;True;Property;_LightTexture;Light Texture;1;0;Create;True;0;0;False;0;None;None;False;white;LockedToTexture2D;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.TexturePropertyNode;102;-1314.638,261.1127;Inherit;True;Property;_Texture0;Texture 0;0;0;Create;True;0;0;False;0;None;None;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;138;-1235.286,-60.23261;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;136;-1276.486,447.3674;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMinOpNode;92;-892.9964,884.0677;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;148;-1078.642,1426.751;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;140;-1379.651,562.4495;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;114;-549.3258,211.9978;Inherit;False;302;366.2194;Set Emission color of Texture;2;105;106;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-996.2861,-20.23257;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;137;-1009.886,495.1673;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;98;-582.0319,820.3686;Inherit;False;317;167;Gets ride of a wierd effect on edges;1;96;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;109;-530.819,-326.4695;Inherit;False;282.2076;460.8493;Set Albedo Color of Texture;2;97;52;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMinOpNode;145;-675.6421,1344.751;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-573.0319,726.3686;Inherit;False;Property;_FadeStrength;Fade Strength;5;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;52;-480.8186,-276.4695;Inherit;False;Property;_Albedo;Albedo;2;0;Create;True;0;0;False;0;0.5235849,0.8053764,1,1;0.5235849,0.8053764,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;105;-499.3258,261.9977;Inherit;False;Property;_Emission;Emission;3;1;[HDR];Create;True;0;0;False;0;0.5235849,0.8053764,1,1;0.5235849,0.8053764,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;104;-881.1519,255.4536;Inherit;True;Property;_TextureSample1;Texture Sample 1;0;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;4;-866.9185,-237.9232;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;96;-532.0319,870.3686;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-468.9927,445.2171;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;-472.611,-103.6203;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-392.0319,726.3686;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;88;-65.23447,398.8299;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;LightBeam_Surface;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;131;0;130;0
WireConnection;131;1;129;0
WireConnection;91;0;67;0
WireConnection;91;1;93;1
WireConnection;90;0;67;0
WireConnection;90;1;93;1
WireConnection;132;1;131;0
WireConnection;138;2;8;0
WireConnection;136;2;102;0
WireConnection;92;0;90;0
WireConnection;92;1;91;0
WireConnection;148;0;144;0
WireConnection;148;1;146;2
WireConnection;140;0;132;0
WireConnection;139;0;138;0
WireConnection;139;1;132;0
WireConnection;137;0;140;0
WireConnection;137;1;136;0
WireConnection;145;0;92;0
WireConnection;145;1;148;0
WireConnection;104;0;102;0
WireConnection;104;1;137;0
WireConnection;4;0;8;0
WireConnection;4;1;139;0
WireConnection;96;0;145;0
WireConnection;106;0;105;0
WireConnection;106;1;104;0
WireConnection;97;0;52;0
WireConnection;97;1;4;0
WireConnection;95;0;94;0
WireConnection;95;1;96;0
WireConnection;88;0;97;0
WireConnection;88;2;106;0
WireConnection;88;9;95;0
ASEEND*/
//CHKSM=A221786AF89D63FEC1ACF5FA1A0ADAA08D17CFE4