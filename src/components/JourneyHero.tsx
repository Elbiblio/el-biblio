// src/components/JourneyHero.tsx
import React, { useEffect, useRef } from "react"
import {
  Svg,
  Defs,
  RadialGradient,
  Stop,
  Circle,
  LinearGradient,
  Polygon,
} from "react-native-svg"
import { useTheme } from "@/contexts/ThemeContext"
import { Animated, Easing } from "react-native"

interface JourneyHeroProps {
  progress: number // 0-100
}

const JourneyHero: React.FC<JourneyHeroProps> = ({ progress }) => {
  const theme = useTheme()
  const sunColor = theme.colors.warning || '#D9A441' // fallback color

  

  // --- Dynamic Calculations ---
  // Map progress (0-100) to visual properties.

  // Phase 1 (progress 0): tiny star, no aura/light
  // Phase 7 (progress 100): biggest star, bright aura/light

  // Eased growth: more pronounced scaling with smoother easing
  const t = Math.max(0, Math.min(1, progress / 100))
  const eased = Easing.bezier(0.4, 0, 0.2, 1)(t) // Smoother easing curve
  
  // Candle core and aura sizing
  const coreRadius = 20 + eased * 16
  
  // Pulsing effect for the star
  const pulseAnim = useRef(new Animated.Value(1)).current
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.04,
          duration: 2200,
          useNativeDriver: true,
          easing: Easing.inOut(Easing.ease)
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 2000,
          useNativeDriver: true,
          easing: Easing.inOut(Easing.ease)
        })
      ])
    ).start()
  }, [pulseAnim])

  // Enhanced star aura with more dynamic glow
  const haloRadius = coreRadius + 18 + t * 10
  const haloOpacity = 0.12 + t * 0.22
  const auraScale = 1 + (eased * 0.15)

  // Sun Beam Opacity: 0 (none) to 0.7 (strong light)
  const beamOpacity = (progress / 100) * 0.4

  // --- SVG Layout (expanded to accommodate large off-screen sun) ---
  const viewBoxWidth = 420
  const viewBoxHeight = 210
  const glowCx = viewBoxWidth * 0.5 // center the light horizontally
  const glowCy = viewBoxHeight * 0.70
  const sunCx = viewBoxWidth * 1.25 // push even further right so less arc shows
  const sunCy = -120 // further up for a thinner visible arc

  // --- Animated sun glow ---
  const glowAnim = useRef(new Animated.Value(0)).current
  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(glowAnim, { toValue: 1, duration: 1800, easing: Easing.inOut(Easing.quad), useNativeDriver: false }),
        Animated.timing(glowAnim, { toValue: 0, duration: 1800, easing: Easing.inOut(Easing.quad), useNativeDriver: false }),
      ])
    )
    loop.start()
    return () => loop.stop()
  }, [glowAnim])
  const animatedGlowOpacity = glowAnim.interpolate({ inputRange: [0, 1], outputRange: [0.12, 0.3] })
  // Create typed animated components
const AnimatedCircle = Animated.createAnimatedComponent(Circle)

  return (
    <Svg width="100%" height="150" viewBox={`0 0 ${viewBoxWidth} ${viewBoxHeight}`}>
      <Defs>
        {/* Sun soft radial glow */}
        <RadialGradient id="sunGlow" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor={sunColor} stopOpacity="0.9" />
          <Stop offset="60%" stopColor={sunColor} stopOpacity="0.35" />
          <Stop offset="100%" stopColor={sunColor} stopOpacity="0" />
        </RadialGradient>
        {/* Star aura */}
        <RadialGradient id="starAura" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor={sunColor} stopOpacity="0.25" />
          <Stop offset="100%" stopColor={sunColor} stopOpacity="0" />
        </RadialGradient>
        {/* Enhanced beam gradient with multiple stops */}
        <LinearGradient id="beamGradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <Stop offset="0%" stopColor={sunColor} stopOpacity={beamOpacity * 0.8} />
          <Stop offset="50%" stopColor={sunColor} stopOpacity={beamOpacity * 0.4} />
          <Stop offset="100%" stopColor={sunColor} stopOpacity="0" />
        </LinearGradient>
        
      </Defs>

      {/* Big sun off-screen with animated glow */}
      <Circle cx={sunCx} cy={sunCy} r="240" fill="url(#sunGlow)" />
      <AnimatedCircle cx={sunCx} cy={sunCy} r="300" fill={sunColor} opacity={animatedGlowOpacity as unknown as number} />

      {/* Beam (subtle) */}
      {beamOpacity > 0 && (
        <Polygon
          points={`${sunCx},${sunCy} ${glowCx - 26},${glowCy} ${glowCx + 26},${glowCy}`}
          fill="url(#beamGradient)"
          opacity={0.45}
        />
      )}

      {/* Halo */}
      <AnimatedCircle
        cx={glowCx}
        cy={glowCy}
        r={Math.max(24, haloRadius)}
        fill="url(#starAura)"
        opacity={0.85}
        scale={auraScale}
        originX={glowCx}
        originY={glowCy}
      />

      {/* Candle core */}
      <AnimatedCircle
        cx={glowCx}
        cy={glowCy}
        r={coreRadius}
        fill={sunColor}
        opacity={0.75}
        scale={pulseAnim}
        originX={glowCx}
        originY={glowCy}
      />

      {/* Inner ember */}
      <AnimatedCircle
        cx={glowCx}
        cy={glowCy - (6 + eased * 4)}
        r={Math.max(8, 10 + eased * 6)}
        fill={theme.colors.background}
        opacity={0.35}
        scale={pulseAnim}
        originX={glowCx}
        originY={glowCy}
      />
    </Svg>
  )
}

export default JourneyHero