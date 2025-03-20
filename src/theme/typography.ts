// Primary Font: Crimson Pro - Elegant serif font for verses and reflections
// Secondary Font: Plus Jakarta Sans - Modern sans-serif for UI elements
// Both fonts are available on Google Fonts and work well with Expo

// Typography System

// Interface for type styles
export interface TypographyStyle {
  fontSize: number;
  fontFamily: string;
  lineHeight: number;
  letterSpacing?: number;
  fontWeight?: string;
}

// Define base typography system
export const typography = {
  // Font families
  fonts: {
    // Serif font for verses, reflections, and book-like content
    serif: {
      regular: 'CrimsonPro_400Regular',
      medium: 'CrimsonPro_500Medium',
      semibold: 'CrimsonPro_600SemiBold',
      bold: 'CrimsonPro_700Bold',
      italic: 'CrimsonPro_400Regular_Italic',
      mediumItalic: 'CrimsonPro_500Medium_Italic',
      boldItalic: 'CrimsonPro_700Bold_Italic',
    },
    // Sans-serif font for UI elements and interactive components
    sans: {
      regular: 'PlusJakartaSans_400Regular',
      medium: 'PlusJakartaSans_500Medium',
      semibold: 'PlusJakartaSans_600SemiBold',
      bold: 'PlusJakartaSans_700Bold',
      extrabold: 'PlusJakartaSans_800ExtraBold',
    }
  },
  
  // Display typography (large, impactful text)
  display: {
    large: {
      fontSize: 36,
      lineHeight: 44,
      fontFamily: 'PlusJakartaSans_700Bold',
      letterSpacing: -0.5,
    } as TypographyStyle,
    medium: {
      fontSize: 30,
      lineHeight: 38,
      fontFamily: 'PlusJakartaSans_600SemiBold',
      letterSpacing: -0.25,
    } as TypographyStyle,
    small: {
      fontSize: 24,
      lineHeight: 32,
      fontFamily: 'PlusJakartaSans_600SemiBold',
      letterSpacing: 0,
    } as TypographyStyle,
  },
  
  // Verse-specific typography
  verse: {
    serif: {
      fontSize: 22,
      lineHeight: 34,
      fontFamily: 'CrimsonPro_400Regular',
      letterSpacing: 0.15,
    } as TypographyStyle,
    emphasis: {
      fontSize: 22,
      lineHeight: 34,
      fontFamily: 'CrimsonPro_500Medium',
      letterSpacing: 0.15,
    } as TypographyStyle,
    reference: {
      fontSize: 16,
      lineHeight: 22,
      fontFamily: 'CrimsonPro_600SemiBold',
      letterSpacing: 0.1,
    } as TypographyStyle,
  },
  
  // Heading typography for section titles and screens
  heading: {
    large: {
      fontSize: 24,
      lineHeight: 32,
      fontFamily: 'PlusJakartaSans_600SemiBold',
      letterSpacing: 0,
    } as TypographyStyle,
    medium: {
      fontSize: 20,
      lineHeight: 28,
      fontFamily: 'PlusJakartaSans_600SemiBold',
      letterSpacing: 0.15,
    } as TypographyStyle,
    small: {
      fontSize: 18,
      lineHeight: 24,
      fontFamily: 'PlusJakartaSans_500Medium',
      letterSpacing: 0.15,
    } as TypographyStyle,
  },
  
  // Body typography for main content
  body: {
    serif: {
      fontSize: 18,
      lineHeight: 28,
      fontFamily: 'CrimsonPro_400Regular',
      letterSpacing: 0.5,
    } as TypographyStyle,
    serifLarge: {
      fontSize: 20,
      lineHeight: 32,
      fontFamily: 'CrimsonPro_400Regular',
      letterSpacing: 0.3,
    } as TypographyStyle,
    serifEmphasis: {
      fontSize: 18,
      lineHeight: 28,
      fontFamily: 'CrimsonPro_500Medium',
      letterSpacing: 0.35,
    } as TypographyStyle,
    sans: {
      fontSize: 16,
      lineHeight: 24,
      fontFamily: 'PlusJakartaSans_400Regular',
      letterSpacing: 0.5,
    } as TypographyStyle,
    sansEmphasis: {
      fontSize: 16,
      lineHeight: 24,
      fontFamily: 'PlusJakartaSans_500Medium',
      letterSpacing: 0.3,
    } as TypographyStyle,
  },
  
  // Caption typography for supplementary information
  caption: {
    primary: {
      fontSize: 14,
      lineHeight: 20,
      fontFamily: 'PlusJakartaSans_500Medium',
      letterSpacing: 0.25,
    } as TypographyStyle,
    secondary: {
      fontSize: 13,
      lineHeight: 18,
      fontFamily: 'PlusJakartaSans_400Regular',
      letterSpacing: 0.4,
    } as TypographyStyle,
    serif: {
      fontSize: 14,
      lineHeight: 20,
      fontFamily: 'CrimsonPro_500Medium',
      letterSpacing: 0.2,
    } as TypographyStyle,
  },
  
  // Button typography
  button: {
    primary: {
      fontSize: 16,
      lineHeight: 24,
      fontFamily: 'PlusJakartaSans_600SemiBold',
      letterSpacing: 0.5,
    } as TypographyStyle,
    secondary: {
      fontSize: 14,
      lineHeight: 20,
      fontFamily: 'PlusJakartaSans_500Medium',
      letterSpacing: 0.25,
    } as TypographyStyle,
    small: {
      fontSize: 12,
      lineHeight: 16,
      fontFamily: 'PlusJakartaSans_500Medium',
      letterSpacing: 0.4,
    } as TypographyStyle,
  },
  
  // Book-style typography for immersive reading experiences
  book: {
    title: {
      fontSize: 26,
      lineHeight: 34,
      fontFamily: 'CrimsonPro_600SemiBold',
      letterSpacing: 0.25,
    } as TypographyStyle,
    subtitle: {
      fontSize: 20,
      lineHeight: 28,
      fontFamily: 'CrimsonPro_500Medium_Italic',
      letterSpacing: 0.15,
    } as TypographyStyle,
    body: {
      fontSize: 18,
      lineHeight: 32, // Increased line height for better readability
      fontFamily: 'CrimsonPro_400Regular',
      letterSpacing: 0.2,
    } as TypographyStyle,
    emphasis: {
      fontSize: 18,
      lineHeight: 32,
      fontFamily: 'CrimsonPro_500Medium',
      letterSpacing: 0.2,
    } as TypographyStyle,
    quote: {
      fontSize: 17,
      lineHeight: 30,
      fontFamily: 'CrimsonPro_400Regular_Italic',
      letterSpacing: 0.3,
    } as TypographyStyle,
    dropcap: {
      fontSize: 54,
      lineHeight: 54,
      fontFamily: 'CrimsonPro_600SemiBold',
      letterSpacing: 0,
    } as TypographyStyle,
    caption: {
      fontSize: 14,
      lineHeight: 20,
      fontFamily: 'CrimsonPro_500Medium',
      letterSpacing: 0.2,
    } as TypographyStyle,
  },
  
  // Helper scales and constants
  scales: {
    fontSizes: {
      xs: 12,
      sm: 14,
      base: 16,
      lg: 18,
      xl: 20,
      '2xl': 24,
      '3xl': 30,
      '4xl': 36,
      '5xl': 48,
    },
    lineHeights: {
      tight: 1.25,  // For headings
      normal: 1.5,  // For most text
      relaxed: 1.75, // For lengthy reading
      loose: 2,     // For very spaced out text
    },
    letterSpacings: {
      tighter: -0.5,
      tight: -0.25,
      normal: 0,
      wide: 0.25,
      wider: 0.5,
      widest: 1,
    },
  },
  
  // Utility functions
  utils: {
    // Calculate relative font size
    calcFontSize: (baseSize: number, scale: number) => baseSize * scale,
    
    // Calculate appropriate line height
    calcLineHeight: (fontSize: number, multiplier: number = 1.5) => Math.ceil(fontSize * multiplier),
  }
};

export default typography;
