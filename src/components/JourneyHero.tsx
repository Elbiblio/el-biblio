// src/components/JourneyHero.tsx
import React, { useEffect, useRef } from "react"
import {
  Svg,
  Defs,
  RadialGradient,
  Stop,
  Circle,
  G,
  Path,
  LinearGradient,
  Polygon,
} from "react-native-svg"
import { useTheme } from "@/contexts/ThemeContext"
import { Animated, Easing } from "react-native"

// A standard 5-point star path, centered in a 24x24 viewbox.
const STAR_PATH =
  "M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"

interface JourneyHeroProps {
  progress: number // 0-100
}

const JourneyHero: React.FC<JourneyHeroProps> = ({ progress }) => {
  const theme = useTheme()
  const starColor = theme.colors.primary || '#4A6FA5' // fallback color
  const sunColor = theme.colors.warning || '#D9A441' // fallback color

  

  // --- Dynamic Calculations ---
  // Map progress (0-100) to visual properties.

  // Phase 1 (progress 0): tiny star, no aura/light
  // Phase 7 (progress 100): biggest star, bright aura/light

  // Eased growth: starts modest, grows more noticeably later
  const t = Math.max(0, Math.min(1, progress / 100))
  const eased = Math.pow(t, 0.8)
  // Star Size: 0.5x to 1.6x with easing
  const starScale = 0.5 + eased * 1.1

  // Star Aura: ensure a subtle presence even at phase 1
  const auraRadius = 12 + t * 50
  const auraOpacity = 0.12 + t * 0.38

  // Sun Beam Opacity: 0 (none) to 0.7 (strong light)
  const beamOpacity = (progress / 100) * 0.7

  // Star Fill: Fills after 50% progress (like your original logic)
  const isFilled = progress > 50

  // --- SVG Layout (expanded to accommodate large off-screen sun) ---
  const viewBoxWidth = 420
  const viewBoxHeight = 210
  const starCx = viewBoxWidth * 0.5 // center the star horizontally
  const starCy = viewBoxHeight * 0.70
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
  const AnimatedCircle: any = Animated.createAnimatedComponent(Circle as any)

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
          <Stop offset="0%" stopColor={starColor} stopOpacity="0.25" />
          <Stop offset="100%" stopColor={starColor} stopOpacity="0" />
        </RadialGradient>
        {/* Beam from sun to star */}
        <LinearGradient id="beamGradient" x1="0%" y1="0%" x2="0%" y2="100%">
          <Stop offset="0%" stopColor={sunColor} stopOpacity={beamOpacity} />
          <Stop offset="100%" stopColor={sunColor} stopOpacity="0" />
        </LinearGradient>
      </Defs>

      {/* Big sun off-screen with animated glow */}
      <Circle cx={sunCx} cy={sunCy} r="240" fill="url(#sunGlow)" />
      <AnimatedCircle cx={sunCx} cy={sunCy} r="300" fill={sunColor} opacity={animatedGlowOpacity as unknown as number} />

      {/* Beam (subtle) */}
      {beamOpacity > 0 && (
        <Polygon
          points={`${sunCx},${sunCy} ${starCx - 26},${starCy} ${starCx + 26},${starCy}`}
          fill="url(#beamGradient)"
          opacity={0.45}
        />
      )}

      {/* Star aura so it shines even at phase 1 */}
      <Circle cx={starCx} cy={starCy} r={Math.max(14, 18 * starScale)} fill="url(#starAura)" />

      {/* Star */}
      <G transform={`translate(${starCx}, ${starCy}) scale(${starScale}) translate(-12, -12)`}>
        <Path d={STAR_PATH} fill={isFilled ? starColor : "none"} stroke={starColor} strokeWidth={3} strokeOpacity={0.7} />
        {!isFilled && <Path d={STAR_PATH} fill={starColor} fillOpacity={0.18} />}
      </G>
    </Svg>
  )
}

export default JourneyHero