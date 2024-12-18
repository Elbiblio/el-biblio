import { TextStyle } from "react-native";

interface TypographyStyle extends TextStyle {
  fontFamily: string;
}

// Base theme configuration that's shared across all themes
const baseTheme = {
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
  },
  borderRadius: {
    sm: 4,
    md: 8,
    lg: 16,
    xl: 24,
    full: 9999,
  },
  typography: {
    verse: {
      regular: {
        fontSize: 20,
        lineHeight: 30,
        fontFamily: 'CrimsonPro_400Regular',
      } as TypographyStyle,
      emphasis: {
        fontSize: 20,
        lineHeight: 30,
        fontFamily: 'CrimsonPro_500Medium',
      } as TypographyStyle,
    },
    heading: {
      large: {
        fontSize: 24,
        lineHeight: 32,
        fontFamily: 'PlusJakartaSans_600SemiBold',
      } as TypographyStyle,
      medium: {
        fontSize: 20,
        lineHeight: 28,
        fontFamily: 'PlusJakartaSans_600SemiBold',
      } as TypographyStyle,
      small: {
        fontSize: 18,
        lineHeight: 24,
        fontFamily: 'PlusJakartaSans_400Regular',
      } as TypographyStyle,
    },
    body: {
      serif: {
        fontSize: 18,
        lineHeight: 28,
        fontFamily: 'CrimsonPro_400Regular',
      } as TypographyStyle,
      sans: {
        fontSize: 16,
        lineHeight: 24,
        fontFamily: 'PlusJakartaSans_400Regular',
      } as TypographyStyle,
    },
    caption: {
      primary: {
        fontSize: 14,
        lineHeight: 20,
        fontFamily: 'PlusJakartaSans_500Medium',
      } as TypographyStyle,
      secondary: {
        fontSize: 13,
        lineHeight: 18,
        fontFamily: 'PlusJakartaSans_400Regular',
      } as TypographyStyle,
    },
  },
  shadows: {
    sm: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.05,
      shadowRadius: 2,
      elevation: 2,
    },
    md: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.1,
      shadowRadius: 4,
      elevation: 4,
    },
    lg: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.1,
      shadowRadius: 8,
      elevation: 8,
    },
  },
} as const;

// Color themes
export const themeColors = {
  sage: {
    primary: '#638B6C',
    primaryLight: '#85A889',
    primaryDark: '#4A6B51',
    secondary: '#8B847D',
    background: '#FDFAF6',
    surface: '#F5F7F3',
    text: {
      primary: '#2C3830',
      secondary: '#6B7167',
      inverse: '#FFFFFF',
    },
    border: '#E2E5E0',
    success: '#5B8B6C',
    error: '#B66B68',
    like: '#C85F4B',
    name: 'Sage Garden',
    description: 'A calming, nature-inspired theme that promotes reflection and growth',
  },
  wooden: {
    primary: '#8B5E3C',
    primaryLight: '#A67C52',
    primaryDark: '#6B4423',
    secondary: '#7D7468',
    background: '#FDF8F3',
    surface: '#F5EDE4',
    text: {
      primary: '#2C1810',
      secondary: '#6B5D4E',
      inverse: '#FDF8F3',
    },
    border: '#E8D5C4',
    success: '#4A7B58',
    error: '#A94442',
    like: '#C4442A',
    name: 'Classic Parchment',
    description: 'A warm, classic theme inspired by ancient wisdom and timeless scrolls',
  },
  ocean: {
    primary: '#4A6FA5',
    primaryLight: '#6B8BB8',
    primaryDark: '#385582',
    secondary: '#798089',
    background: '#F8FBFF',
    surface: '#F0F5FA',
    text: {
      primary: '#2C3542',
      secondary: '#5F6B7A',
      inverse: '#FFFFFF',
    },
    border: '#E2E8F0',
    success: '#4B957A',
    error: '#B86268',
    like: '#E15554',
    name: 'Ocean Breeze',
    description: 'A refreshing, contemplative theme that inspires depth and clarity',
  },
} as const;

export type ThemeVariant = keyof typeof themeColors;
export type ThemeColors = typeof themeColors.sage | typeof themeColors.wooden | typeof themeColors.ocean;

// Create complete themes by combining base theme with color variants
export const createTheme = (colors: ThemeColors) => ({
  ...baseTheme,
  colors,
});

// Pre-built themes
export const themes = {
  sage: createTheme(themeColors.sage),
  wooden: createTheme(themeColors.wooden),
  ocean: createTheme(themeColors.ocean),
} as const;

export type Theme = typeof themes.sage;

// Default theme
export const defaultTheme = themes.sage;

// Utility functions
export const getTheme = (variant: ThemeVariant) => themes[variant];
export const getThemeColors = (variant: ThemeVariant) => themeColors[variant];