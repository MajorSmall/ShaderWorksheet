// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "DissolvePBR"
{
    Properties
    {
		_BaseColor("BaseColor", Color) = (0,0.5051383,0.7830189,1)
		[HDR]_EdgeEmission("EdgeEmission", Color) = (1.148698,0,1.148698,1)
		_EmissionBleed("EmissionBleed", Float) = 1
		_EdgeThickness("EdgeThickness", Float) = 0.1
		_VoroniTilling("VoroniTilling", Vector) = (1,1,0,0)
		_VoronoiScale("VoronoiScale", Float) = 8.19
		_DissolveHieght("DissolveHieght", Range( 0 , 1)) = 0.43
		_DissolveStrength("DissolveStrength", Range( 3 , 50)) = 15.60208
		_DissolveDirection("DissolveDirection", Range( -1 , 1)) = 1

    }


    SubShader
    {
		LOD 0

		
        Tags { "RenderPipeline"="LightweightPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

		Cull Back
		HLSLINCLUDE
		#pragma target 3.0
		ENDHLSL
		
        Pass
        {
			
        	Tags { "LightMode"="LightweightForward" }

        	Name "Base"
			Blend One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
            
        	HLSLPROGRAM
            #define ASE_SRP_VERSION 40100
            #define _AlphaClip 1

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            

        	// -------------------------------------
            // Lightweight Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            
        	// -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
        	#pragma fragment frag

        	

        	#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
        	#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
        	#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/ShaderGraphFunctions.hlsl"

			CBUFFER_START( UnityPerMaterial )
			float4 _BaseColor;
			float4 _EdgeEmission;
			float _VoronoiScale;
			float _DissolveHieght;
			float2 _VoroniTilling;
			float _DissolveStrength;
			float _DissolveDirection;
			float _EdgeThickness;
			float _EmissionBleed;
			CBUFFER_END


            struct GraphVertexInput
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;
                float4 ase_tangent : TANGENT;
                float4 texcoord1 : TEXCOORD1;
				float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

        	struct GraphVertexOutput
            {
                float4 clipPos                : SV_POSITION;
                float4 lightmapUVOrVertexSH	  : TEXCOORD0;
        		half4 fogFactorAndVertexLight : TEXCOORD1; // x: fogFactor, yzw: vertex light
            	float4 shadowCoord            : TEXCOORD2;
				float4 tSpace0					: TEXCOORD3;
				float4 tSpace1					: TEXCOORD4;
				float4 tSpace2					: TEXCOORD5;
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            	UNITY_VERTEX_OUTPUT_STEREO
            };

					float2 voronoihash19( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi19( float2 v, float time, inout float2 id )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mr = 0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash19( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						 		}
						 	}
						}
						return F1;
					}
			

            GraphVertexOutput vert (GraphVertexInput v  )
        	{
        		GraphVertexOutput o = (GraphVertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
            	UNITY_TRANSFER_INSTANCE_ID(v, o);
        		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord7.xy = v.ase_texcoord.xy;
				o.ase_texcoord8 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				float3 vertexValue =  float3( 0, 0, 0 ) ;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal =  v.ase_normal ;

        		// Vertex shader outputs defined by graph
                float3 lwWNormal = TransformObjectToWorldNormal(v.ase_normal);
				float3 lwWorldPos = TransformObjectToWorld(v.vertex.xyz);
				float3 lwWTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				float3 lwWBinormal = normalize(cross(lwWNormal, lwWTangent) * v.ase_tangent.w);
				o.tSpace0 = float4(lwWTangent.x, lwWBinormal.x, lwWNormal.x, lwWorldPos.x);
				o.tSpace1 = float4(lwWTangent.y, lwWBinormal.y, lwWNormal.y, lwWorldPos.y);
				o.tSpace2 = float4(lwWTangent.z, lwWBinormal.z, lwWNormal.z, lwWorldPos.z);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                
         		// We either sample GI from lightmap or SH.
        	    // Lightmap UV and vertex SH coefficients use the same interpolator ("float2 lightmapUV" for lightmap or "half3 vertexSH" for SH)
                // see DECLARE_LIGHTMAP_OR_SH macro.
        	    // The following funcions initialize the correct variable with correct data
        	    OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy);
        	    OUTPUT_SH(lwWNormal, o.lightmapUVOrVertexSH.xyz);

        	    half3 vertexLight = VertexLighting(vertexInput.positionWS, lwWNormal);
        	    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
        	    o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
        	    o.clipPos = vertexInput.positionCS;

        	#ifdef _MAIN_LIGHT_SHADOWS
        		o.shadowCoord = GetShadowCoord(vertexInput);
        	#endif
        		return o;
        	}

        	half4 frag (GraphVertexOutput IN  ) : SV_Target
            {
            	UNITY_SETUP_INSTANCE_ID(IN);

        		float3 WorldSpaceNormal = normalize(float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z));
				float3 WorldSpaceTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldSpaceBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldSpacePosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldSpaceViewDirection = SafeNormalize( _WorldSpaceCameraPos.xyz  - WorldSpacePosition );
    
				float time19 = ( _DissolveHieght * 10.0 );
				float2 uv018 = IN.ase_texcoord7.xy * _VoroniTilling + float2( 0,0 );
				float2 coords19 = uv018 * _VoronoiScale;
				float2 id19 = 0;
				float voroi19 = voronoi19( coords19, time19,id19 );
				float temp_output_75_0 = (-1.0 + (_DissolveHieght - 0.0) * (( _DissolveStrength - 0.1 ) - -1.0) / (1.0 - 0.0));
				float clampResult76 = clamp( temp_output_75_0 , -1.0 , 2.0 );
				float clampResult79 = clamp( temp_output_75_0 , 2.0 , _DissolveStrength );
				float clampResult64 = clamp( clampResult76 , clampResult79 , _DissolveStrength );
				float temp_output_164_0 = ( _DissolveDirection * IN.ase_texcoord8.xyz.y );
				float smoothstepResult49 = smoothstep( clampResult76 , ( clampResult76 - ( _DissolveStrength - clampResult64 ) ) , temp_output_164_0);
				float temp_output_56_0 = step( voroi19 , smoothstepResult49 );
				float temp_output_149_0 = ( _DissolveStrength + ( 1.0 - _EdgeThickness ) );
				float temp_output_123_0 = (-1.0 + (_DissolveHieght - 0.0) * (( temp_output_149_0 - 0.1 ) - -1.0) / (1.0 - 0.0));
				float clampResult124 = clamp( temp_output_123_0 , -1.0 , 2.0 );
				float clampResult125 = clamp( temp_output_123_0 , 2.0 , temp_output_149_0 );
				float clampResult126 = clamp( clampResult124 , clampResult125 , temp_output_149_0 );
				float smoothstepResult131 = smoothstep( clampResult124 , ( clampResult124 - ( temp_output_149_0 - clampResult126 ) ) , temp_output_164_0);
				float temp_output_133_0 = step( voroi19 , smoothstepResult131 );
				float blendOpSrc167 = temp_output_56_0;
				float blendOpDest167 = temp_output_133_0;
				float lerpBlendMode167 = lerp(blendOpDest167,abs( blendOpSrc167 - blendOpDest167 ),_EmissionBleed);
				
				
		        float3 Albedo = _BaseColor.rgb;
				float3 Normal = float3(0, 0, 1);
				float3 Emission = ( _EdgeEmission * ( saturate( lerpBlendMode167 )) ).rgb;
				float3 Specular = float3(0.5, 0.5, 0.5);
				float Metallic = 0;
				float Smoothness = 0.5;
				float Occlusion = 1;
				float Alpha = max( temp_output_56_0 , temp_output_133_0 );
				float AlphaClipThreshold = ( 1.0 - max( smoothstepResult49 , smoothstepResult131 ) );

        		InputData inputData;
        		inputData.positionWS = WorldSpacePosition;

        #ifdef _NORMALMAP
        	    inputData.normalWS = normalize(TransformTangentToWorld(Normal, half3x3(WorldSpaceTangent, WorldSpaceBiTangent, WorldSpaceNormal)));
        #else
            #if !SHADER_HINT_NICE_QUALITY
                inputData.normalWS = WorldSpaceNormal;
            #else
        	    inputData.normalWS = normalize(WorldSpaceNormal);
            #endif
        #endif

        #if !SHADER_HINT_NICE_QUALITY
        	    // viewDirection should be normalized here, but we avoid doing it as it's close enough and we save some ALU.
        	    inputData.viewDirectionWS = WorldSpaceViewDirection;
        #else
        	    inputData.viewDirectionWS = normalize(WorldSpaceViewDirection);
        #endif

        	    inputData.shadowCoord = IN.shadowCoord;

        	    inputData.fogCoord = IN.fogFactorAndVertexLight.x;
        	    inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
        	    inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.lightmapUVOrVertexSH.xyz, inputData.normalWS);

        		half4 color = LightweightFragmentPBR(
        			inputData, 
        			Albedo, 
        			Metallic, 
        			Specular, 
        			Smoothness, 
        			Occlusion, 
        			Emission, 
        			Alpha);

			#ifdef TERRAIN_SPLAT_ADDPASS
				color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
			#else
				color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
			#endif

        #if _AlphaClip
        		clip(Alpha - AlphaClipThreshold);
        #endif

		#if ASE_LW_FINAL_COLOR_ALPHA_MULTIPLY
				color.rgb *= color.a;
		#endif
        		return color;
            }

        	ENDHLSL
        }

		
        Pass
        {
			
        	Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual

            HLSLPROGRAM
            #define ASE_SRP_VERSION 40100
            #define _AlphaClip 1

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            struct GraphVertexInput
            {
                float4 vertex : POSITION;
                float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			CBUFFER_START( UnityPerMaterial )
			float4 _BaseColor;
			float4 _EdgeEmission;
			float _VoronoiScale;
			float _DissolveHieght;
			float2 _VoroniTilling;
			float _DissolveStrength;
			float _DissolveDirection;
			float _EdgeThickness;
			float _EmissionBleed;
			CBUFFER_END


        	struct VertexOutput
        	{
        	    float4 clipPos      : SV_POSITION;
                float4 ase_texcoord7 : TEXCOORD7;
                float4 ase_texcoord8 : TEXCOORD8;
                UNITY_VERTEX_INPUT_INSTANCE_ID
        	};

					float2 voronoihash19( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi19( float2 v, float time, inout float2 id )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mr = 0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash19( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						 		}
						 	}
						}
						return F1;
					}
			

            // x: global clip space bias, y: normal world space bias
            float4 _ShadowBias;
            float3 _LightDirection;

            VertexOutput ShadowPassVertex(GraphVertexInput v )
        	{
        	    VertexOutput o;
        	    UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord7.xy = v.ase_texcoord.xy;
				o.ase_texcoord8 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				float3 vertexValue =  float3(0,0,0) ;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal =  v.ase_normal ;

        	    float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
                float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

                float invNdotL = 1.0 - saturate(dot(_LightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;

                // normal bias is negative since we want to apply an inset normal offset
                positionWS = _LightDirection * _ShadowBias.xxx + positionWS;
				positionWS = normalWS * scale.xxx + positionWS;
                float4 clipPos = TransformWorldToHClip(positionWS);

                // _ShadowBias.x sign depens on if platform has reversed z buffer
                //clipPos.z += _ShadowBias.x;

        	#if UNITY_REVERSED_Z
        	    clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
        	#else
        	    clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
        	#endif
                o.clipPos = clipPos;

        	    return o;
        	}

            half4 ShadowPassFragment(VertexOutput IN  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

               float time19 = ( _DissolveHieght * 10.0 );
               float2 uv018 = IN.ase_texcoord7.xy * _VoroniTilling + float2( 0,0 );
               float2 coords19 = uv018 * _VoronoiScale;
               float2 id19 = 0;
               float voroi19 = voronoi19( coords19, time19,id19 );
               float temp_output_75_0 = (-1.0 + (_DissolveHieght - 0.0) * (( _DissolveStrength - 0.1 ) - -1.0) / (1.0 - 0.0));
               float clampResult76 = clamp( temp_output_75_0 , -1.0 , 2.0 );
               float clampResult79 = clamp( temp_output_75_0 , 2.0 , _DissolveStrength );
               float clampResult64 = clamp( clampResult76 , clampResult79 , _DissolveStrength );
               float temp_output_164_0 = ( _DissolveDirection * IN.ase_texcoord8.xyz.y );
               float smoothstepResult49 = smoothstep( clampResult76 , ( clampResult76 - ( _DissolveStrength - clampResult64 ) ) , temp_output_164_0);
               float temp_output_56_0 = step( voroi19 , smoothstepResult49 );
               float temp_output_149_0 = ( _DissolveStrength + ( 1.0 - _EdgeThickness ) );
               float temp_output_123_0 = (-1.0 + (_DissolveHieght - 0.0) * (( temp_output_149_0 - 0.1 ) - -1.0) / (1.0 - 0.0));
               float clampResult124 = clamp( temp_output_123_0 , -1.0 , 2.0 );
               float clampResult125 = clamp( temp_output_123_0 , 2.0 , temp_output_149_0 );
               float clampResult126 = clamp( clampResult124 , clampResult125 , temp_output_149_0 );
               float smoothstepResult131 = smoothstep( clampResult124 , ( clampResult124 - ( temp_output_149_0 - clampResult126 ) ) , temp_output_164_0);
               float temp_output_133_0 = step( voroi19 , smoothstepResult131 );
               

				float Alpha = max( temp_output_56_0 , temp_output_133_0 );
				float AlphaClipThreshold = ( 1.0 - max( smoothstepResult49 , smoothstepResult131 ) );

         #if _AlphaClip
        		clip(Alpha - AlphaClipThreshold);
        #endif
                return 0;
            }

            ENDHLSL
        }

		
        Pass
        {
			
        	Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ZWrite On
			ColorMask 0

            HLSLPROGRAM
            #define ASE_SRP_VERSION 40100
            #define _AlphaClip 1

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag

            

            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			CBUFFER_START( UnityPerMaterial )
			float4 _BaseColor;
			float4 _EdgeEmission;
			float _VoronoiScale;
			float _DissolveHieght;
			float2 _VoroniTilling;
			float _DissolveStrength;
			float _DissolveDirection;
			float _EdgeThickness;
			float _EmissionBleed;
			CBUFFER_END


            struct GraphVertexInput
            {
                float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

        	struct VertexOutput
        	{
        	    float4 clipPos      : SV_POSITION;
                float4 ase_texcoord : TEXCOORD0;
                float4 ase_texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
        	};

					float2 voronoihash19( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi19( float2 v, float time, inout float2 id )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mr = 0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash19( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						 		}
						 	}
						}
						return F1;
					}
			
           

            VertexOutput vert(GraphVertexInput v  )
            {
                VertexOutput o = (VertexOutput)0;
        	    UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord1 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				float3 vertexValue =  float3(0,0,0) ;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal =  v.ase_normal ;

        	    o.clipPos = TransformObjectToHClip(v.vertex.xyz);
        	    return o;
            }

            half4 frag(VertexOutput IN  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

				float time19 = ( _DissolveHieght * 10.0 );
				float2 uv018 = IN.ase_texcoord.xy * _VoroniTilling + float2( 0,0 );
				float2 coords19 = uv018 * _VoronoiScale;
				float2 id19 = 0;
				float voroi19 = voronoi19( coords19, time19,id19 );
				float temp_output_75_0 = (-1.0 + (_DissolveHieght - 0.0) * (( _DissolveStrength - 0.1 ) - -1.0) / (1.0 - 0.0));
				float clampResult76 = clamp( temp_output_75_0 , -1.0 , 2.0 );
				float clampResult79 = clamp( temp_output_75_0 , 2.0 , _DissolveStrength );
				float clampResult64 = clamp( clampResult76 , clampResult79 , _DissolveStrength );
				float temp_output_164_0 = ( _DissolveDirection * IN.ase_texcoord1.xyz.y );
				float smoothstepResult49 = smoothstep( clampResult76 , ( clampResult76 - ( _DissolveStrength - clampResult64 ) ) , temp_output_164_0);
				float temp_output_56_0 = step( voroi19 , smoothstepResult49 );
				float temp_output_149_0 = ( _DissolveStrength + ( 1.0 - _EdgeThickness ) );
				float temp_output_123_0 = (-1.0 + (_DissolveHieght - 0.0) * (( temp_output_149_0 - 0.1 ) - -1.0) / (1.0 - 0.0));
				float clampResult124 = clamp( temp_output_123_0 , -1.0 , 2.0 );
				float clampResult125 = clamp( temp_output_123_0 , 2.0 , temp_output_149_0 );
				float clampResult126 = clamp( clampResult124 , clampResult125 , temp_output_149_0 );
				float smoothstepResult131 = smoothstep( clampResult124 , ( clampResult124 - ( temp_output_149_0 - clampResult126 ) ) , temp_output_164_0);
				float temp_output_133_0 = step( voroi19 , smoothstepResult131 );
				

				float Alpha = max( temp_output_56_0 , temp_output_133_0 );
				float AlphaClipThreshold = ( 1.0 - max( smoothstepResult49 , smoothstepResult131 ) );

         #if _AlphaClip
        		clip(Alpha - AlphaClipThreshold);
        #endif
                return 0;
            }
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
		
        Pass
        {
			
        	Name "Meta"
            Tags { "LightMode"="Meta" }

            Cull Off

            HLSLPROGRAM
            #define ASE_SRP_VERSION 40100
            #define _AlphaClip 1

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag

            

			uniform float4 _MainTex_ST;
			
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/MetaInput.hlsl"
            #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			CBUFFER_START( UnityPerMaterial )
			float4 _BaseColor;
			float4 _EdgeEmission;
			float _VoronoiScale;
			float _DissolveHieght;
			float2 _VoroniTilling;
			float _DissolveStrength;
			float _DissolveDirection;
			float _EdgeThickness;
			float _EmissionBleed;
			CBUFFER_END


            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature EDITOR_VISUALIZATION


            struct GraphVertexInput
            {
                float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

        	struct VertexOutput
        	{
        	    float4 clipPos      : SV_POSITION;
                float4 ase_texcoord : TEXCOORD0;
                float4 ase_texcoord1 : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
        	};

					float2 voronoihash19( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi19( float2 v, float time, inout float2 id )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mr = 0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash19( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = g - f + o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						 		}
						 	}
						}
						return F1;
					}
			

            VertexOutput vert(GraphVertexInput v  )
            {
                VertexOutput o = (VertexOutput)0;
        	    UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				o.ase_texcoord1 = v.vertex;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;

				float3 vertexValue =  float3(0,0,0) ;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal =  v.ase_normal ;
				
                o.clipPos = MetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST);
        	    return o;
            }

            half4 frag(VertexOutput IN  ) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

           		float time19 = ( _DissolveHieght * 10.0 );
           		float2 uv018 = IN.ase_texcoord.xy * _VoroniTilling + float2( 0,0 );
           		float2 coords19 = uv018 * _VoronoiScale;
           		float2 id19 = 0;
           		float voroi19 = voronoi19( coords19, time19,id19 );
           		float temp_output_75_0 = (-1.0 + (_DissolveHieght - 0.0) * (( _DissolveStrength - 0.1 ) - -1.0) / (1.0 - 0.0));
           		float clampResult76 = clamp( temp_output_75_0 , -1.0 , 2.0 );
           		float clampResult79 = clamp( temp_output_75_0 , 2.0 , _DissolveStrength );
           		float clampResult64 = clamp( clampResult76 , clampResult79 , _DissolveStrength );
           		float temp_output_164_0 = ( _DissolveDirection * IN.ase_texcoord1.xyz.y );
           		float smoothstepResult49 = smoothstep( clampResult76 , ( clampResult76 - ( _DissolveStrength - clampResult64 ) ) , temp_output_164_0);
           		float temp_output_56_0 = step( voroi19 , smoothstepResult49 );
           		float temp_output_149_0 = ( _DissolveStrength + ( 1.0 - _EdgeThickness ) );
           		float temp_output_123_0 = (-1.0 + (_DissolveHieght - 0.0) * (( temp_output_149_0 - 0.1 ) - -1.0) / (1.0 - 0.0));
           		float clampResult124 = clamp( temp_output_123_0 , -1.0 , 2.0 );
           		float clampResult125 = clamp( temp_output_123_0 , 2.0 , temp_output_149_0 );
           		float clampResult126 = clamp( clampResult124 , clampResult125 , temp_output_149_0 );
           		float smoothstepResult131 = smoothstep( clampResult124 , ( clampResult124 - ( temp_output_149_0 - clampResult126 ) ) , temp_output_164_0);
           		float temp_output_133_0 = step( voroi19 , smoothstepResult131 );
           		float blendOpSrc167 = temp_output_56_0;
           		float blendOpDest167 = temp_output_133_0;
           		float lerpBlendMode167 = lerp(blendOpDest167,abs( blendOpSrc167 - blendOpDest167 ),_EmissionBleed);
           		
				
		        float3 Albedo = _BaseColor.rgb;
				float3 Emission = ( _EdgeEmission * ( saturate( lerpBlendMode167 )) ).rgb;
				float Alpha = max( temp_output_56_0 , temp_output_133_0 );
				float AlphaClipThreshold = ( 1.0 - max( smoothstepResult49 , smoothstepResult131 ) );

         #if _AlphaClip
        		clip(Alpha - AlphaClipThreshold);
        #endif

                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo = Albedo;
                metaInput.Emission = Emission;
                
                return MetaFragment(metaInput);
            }
            ENDHLSL
        }
		
    }
    Fallback "Hidden/InternalErrorShader"
	CustomEditor "ASEMaterialInspector"
	
}
/*ASEBEGIN
Version=17400
1927;7;1906;1004;1712.83;-304.1013;1.3;True;False
Node;AmplifyShaderEditor.CommentaryNode;91;-2226.829,104.0764;Inherit;False;1732.5;705.5802;Dissolve Effect;20;56;75;76;61;89;49;108;109;103;102;101;100;66;64;79;82;106;107;105;104;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-2653.877,956.8572;Inherit;False;Property;_DissolveStrength;DissolveStrength;8;0;Create;True;0;0;False;0;15.60208;3.6;3;50;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-2609.1,1412.479;Inherit;False;Property;_EdgeThickness;EdgeThickness;3;0;Create;True;0;0;False;0;0.1;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;154;-2374.013,1442.145;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;100;-2190.514,756.2307;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;111;-2216.727,1294.875;Inherit;False;1732.5;705.5802;Dissolve Effect;15;133;131;130;128;127;126;125;124;123;116;139;150;151;152;149;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;149;-2084.811,1838.645;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;107;-1973.113,735.9309;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-2639.629,817.5217;Inherit;False;Property;_DissolveHieght;DissolveHieght;7;0;Create;True;0;0;False;0;0.43;0.43;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;82;-1889.202,590.0619;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;101;-2190.514,758.2307;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;109;-2183.635,608.4432;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;116;-1906.501,1752.162;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;103;-2188.514,757.2307;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;152;-1726.411,1879.845;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;75;-1893.155,365.9358;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;106;-1632.113,733.9309;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;123;-1929.053,1541.735;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;76;-1653.373,318.9436;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;125;-1667.341,1666.659;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;102;-2191.514,757.2307;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;23;-1582.905,-435.0084;Inherit;False;819.1002;370.9999;Generate Voronoi Noise;5;16;20;21;18;19;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;104;-1634.115,732.2303;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;124;-1643.271,1509.743;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;108;-2183.697,593.0989;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;79;-1654.042,469.5598;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;151;-1723.811,1878.545;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;83;-1662.314,-42.48389;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;64;-1460.693,439.046;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;30;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;126;-1477.992,1601.146;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;30;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;150;-1725.111,1882.445;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;160;-1729.814,855.2443;Inherit;False;465.0137;368.3311;Dissolve Direction;2;129;162;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;16;-1532.905,-243.7402;Inherit;False;Property;_VoroniTilling;VoroniTilling;4;0;Create;True;0;0;False;0;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.WireNode;105;-1629.115,732.2302;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;127;-1314.3,1614.404;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-1231.805,-317.0084;Inherit;False;Property;_VoronoiScale;VoronoiScale;6;0;Create;True;0;0;False;0;8.19;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;66;-1297.001,452.3043;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;18;-1324.628,-241.9912;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;129;-1669.72,1044.575;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;90;-1106.83,-57.14336;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;162;-1711.012,934.9436;Inherit;False;Property;_DissolveDirection;DissolveDirection;9;0;Create;True;0;0;False;0;1;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;61;-1190.695,317.7734;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;130;-1265.574,1483.961;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;128;-1180.593,1508.573;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;164;-1444.512,1035.044;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;19;-991.8052,-314.0084;Inherit;True;0;0;1;0;1;False;1;False;3;0;FLOAT2;0,0;False;1;FLOAT;10;False;2;FLOAT;10;False;2;FLOAT;0;FLOAT;1
Node;AmplifyShaderEditor.WireNode;89;-1275.676,293.1617;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;49;-999.7348,212.7386;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;139;-773.7871,1356.187;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;131;-989.632,1403.538;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;133;-692.5258,1382.322;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;165;-835.9065,733.6545;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;168;-592.3226,9.454475;Inherit;False;Property;_EmissionBleed;EmissionBleed;2;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;166;-716.3248,1216.831;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;56;-736.5569,218.3231;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;167;-374.3821,329.8454;Inherit;True;Difference;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1.13;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;148;-208.3204,893.6945;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;141;-327.6667,151.7191;Inherit;False;Property;_EdgeEmission;EdgeEmission;1;1;[HDR];Create;True;0;0;False;0;1.148698,0,1.148698,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;85;-165.3521,-95.64354;Inherit;False;Property;_BaseColor;BaseColor;0;0;Create;True;0;0;False;0;0,0.5051383,0.7830189,1;0,0.5051383,0.7830189,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;142;-88.0669,261.3191;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-1237.805,-388.0084;Inherit;False;Property;_VoronoiAngle;VoronoiAngle;5;0;Create;True;0;0;False;0;5.7;10;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;169;-218.2158,1176.492;Inherit;False;Standard;WorldNormal;ViewDir;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;147;-206.3112,764.8449;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;132;-78.71239,830.9911;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;141.7,213.2001;Float;False;True;-1;2;ASEMaterialInspector;0;2;DissolvePBR;1976390536c6c564abb90fe41f6ee334;True;Base;0;0;Base;11;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=LightweightPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;True;True;True;True;True;0;False;-1;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=LightweightForward;False;0;Hidden/InternalErrorShader;0;0;Standard;2;Vertex Position,InvertActionOnDeselection;1;Receive Shadows;1;1;_FinalColorxAlpha;0;4;True;True;True;True;False;;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;1;New Amplify Shader;1976390536c6c564abb90fe41f6ee334;True;Meta;0;3;Meta;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=LightweightPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;False;False;True;2;False;-1;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;1;New Amplify Shader;1976390536c6c564abb90fe41f6ee334;True;ShadowCaster;0;1;ShadowCaster;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=LightweightPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;ASEMaterialInspector;0;1;New Amplify Shader;1976390536c6c564abb90fe41f6ee334;True;DepthOnly;0;2;DepthOnly;0;False;False;False;True;0;False;-1;False;False;False;False;False;True;3;RenderPipeline=LightweightPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;False;False;False;True;False;False;False;False;0;False;-1;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;0
WireConnection;154;0;134;0
WireConnection;100;0;65;0
WireConnection;149;0;65;0
WireConnection;149;1;154;0
WireConnection;107;0;100;0
WireConnection;82;0;107;0
WireConnection;101;0;65;0
WireConnection;109;0;80;0
WireConnection;116;0;149;0
WireConnection;103;0;65;0
WireConnection;152;0;149;0
WireConnection;75;0;109;0
WireConnection;75;4;82;0
WireConnection;106;0;101;0
WireConnection;123;0;80;0
WireConnection;123;4;116;0
WireConnection;76;0;75;0
WireConnection;125;0;123;0
WireConnection;125;2;152;0
WireConnection;102;0;65;0
WireConnection;104;0;103;0
WireConnection;124;0;123;0
WireConnection;108;0;80;0
WireConnection;79;0;75;0
WireConnection;79;2;106;0
WireConnection;151;0;149;0
WireConnection;83;0;108;0
WireConnection;64;0;76;0
WireConnection;64;1;79;0
WireConnection;64;2;104;0
WireConnection;126;0;124;0
WireConnection;126;1;125;0
WireConnection;126;2;151;0
WireConnection;150;0;149;0
WireConnection;105;0;102;0
WireConnection;127;0;150;0
WireConnection;127;1;126;0
WireConnection;66;0;105;0
WireConnection;66;1;64;0
WireConnection;18;0;16;0
WireConnection;90;0;83;0
WireConnection;61;0;76;0
WireConnection;61;1;66;0
WireConnection;130;0;124;0
WireConnection;128;0;124;0
WireConnection;128;1;127;0
WireConnection;164;0;162;0
WireConnection;164;1;129;2
WireConnection;19;0;18;0
WireConnection;19;1;90;0
WireConnection;19;2;21;0
WireConnection;89;0;76;0
WireConnection;49;0;164;0
WireConnection;49;1;89;0
WireConnection;49;2;61;0
WireConnection;139;0;19;0
WireConnection;131;0;164;0
WireConnection;131;1;130;0
WireConnection;131;2;128;0
WireConnection;133;0;139;0
WireConnection;133;1;131;0
WireConnection;165;0;49;0
WireConnection;166;0;131;0
WireConnection;56;0;19;0
WireConnection;56;1;49;0
WireConnection;167;0;56;0
WireConnection;167;1;133;0
WireConnection;167;2;168;0
WireConnection;148;0;165;0
WireConnection;148;1;166;0
WireConnection;142;0;141;0
WireConnection;142;1;167;0
WireConnection;147;0;56;0
WireConnection;147;1;133;0
WireConnection;132;0;148;0
WireConnection;0;0;85;0
WireConnection;0;2;142;0
WireConnection;0;6;147;0
WireConnection;0;7;132;0
ASEEND*/
//CHKSM=6FCEA3D36BA59E2E09FA162D0BEB9BE59D878C8C