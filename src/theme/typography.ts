// Primary Font: Crimson Pro - Elegant serif font for verses and reflections
// Secondary Font: Plus Jakarta Sans - Modern sans-serif for UI elements
// Both fonts are available on Google Fonts and work well with Expo

export const typography = {
  fonts: {
    // Serif font for verses and reflections
    serif: {
      regular: 'CrimsonPro_400Regular',
      medium: 'CrimsonPro_500Medium',
      semibold: 'CrimsonPro_600SemiBold',
      bold: 'CrimsonPro_700Bold',
      italic: 'CrimsonPro_400Regular_Italic',
    },
    // Sans-serif font for UI elements
    sans: {
      regular: 'PlusJakartaSans_400Regular',
      medium: 'PlusJakartaSans_500Medium',
      semibold: 'PlusJakartaSans_600SemiBold',
      bold: 'PlusJakartaSans_700Bold',
    }
  },
  // Font sizes follow a modular scale
  sizes: {
    xs: 12,
    sm: 14,
    base: 16,
    lg: 18,
    xl: 20,
    '2xl': 24,
    '3xl': 30,
    '4xl': 36,
  },
  styles: {
    // Verse styles
    verse: {
      fontSize: 24,
      fontFamily: 'CrimsonPro_500Medium',
      lineHeight: 32,
    },
    verseReference: {
      fontSize: 16,
      fontFamily: 'CrimsonPro_600SemiBold',
      lineHeight: 24,
    },
    // Reflection styles
    reflectionText: {
      fontSize: 18,
      fontFamily: 'CrimsonPro_400Regular',
      lineHeight: 28,
    },
    // UI text styles
    heading: {
      fontSize: 20,
      fontFamily: 'PlusJakartaSans_600SemiBold',
      lineHeight: 28,
    },
    body: {
      fontSize: 16,
      fontFamily: 'PlusJakartaSans_400Regular',
      lineHeight: 24,
    },
    caption: {
      fontSize: 14,
      fontFamily: 'PlusJakartaSans_400Regular',
      lineHeight: 20,
    },
  }
};
