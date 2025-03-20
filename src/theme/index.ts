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
    xxl: 48,
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
        letterSpacing: 0.15,
      } as TypographyStyle,
      emphasis: {
        fontSize: 20,
        lineHeight: 30,
        fontFamily: 'CrimsonPro_500Medium',
        letterSpacing: 0.15,
      } as TypographyStyle,
    },
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
    body: {
      serif: {
        fontSize: 18,
        lineHeight: 28,
        fontFamily: 'CrimsonPro_400Regular',
        letterSpacing: 0.5,
      } as TypographyStyle,
      sans: {
        fontSize: 16,
        lineHeight: 24,
        fontFamily: 'PlusJakartaSans_400Regular',
        letterSpacing: 0.5,
      } as TypographyStyle,
    },
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
    },
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

// Color themes with light and dark variants
export const themeColors = {
  sage: {
    light: {
      isDark: false,
      primary: '#638B6C',
      primaryLight: '#85A889',
      primaryDark: '#4A6B51',
      secondary: '#8B847D',
      background: '#FDFAF6',
      surface: '#F5F7F3',
      paper: '#f2f5e9',
      paperBorder: '#d8e0d0',
      paperShadow: '#c0d0b0',
      dividerOpacity: 0.35,
      flourishRotation: '4deg',
      dotSize: 6,
      surfaceVariant: '#E8EDE6',
      text: {
        primary: '#2C3830',
        secondary: '#5A6157',
        tertiary: '#7D857A',
        inverse: '#FFFFFF',
        placeholder: '#8A9287',
      },
      border: '#E2E5E0',
      success: '#5B8B6C',
      error: '#B66B68',
      warning: '#D9A441',
      info: '#5B7B9C',
      like: '#C85F4B',
      shadow: '#000',
      input: {
        background: 'rgba(60, 60, 67, 0.5)',
        border: 'rgba(255, 255, 255, 0.25)',
      },
      modal: {
        background: 'rgba(18, 18, 20, 0.98)',
        overlay: 'rgba(0, 0, 0, 0.6)',
      },
    },
    dark: {
      isDark: true,
      primary: '#85A889',
      primaryLight: '#A6C2A9',
      primaryDark: '#4A6B51',
      secondary: '#A39C96',
      background: '#1A1C19',
      surface: '#2A2E28',
      paper: '#1e2a1e',
      paperBorder: '#2e3a2e',
      paperShadow: '#0e1a0e',
      dividerOpacity: 0.35,
      flourishRotation: '4deg',
      dotSize: 6,
      surfaceVariant: '#3A3E38',
      text: {
        primary: '#E6E9E4',
        secondary: '#C4C9C1',
        tertiary: '#A0A59D',
        inverse: '#2C3830',
        placeholder: '#B0B5AD',
      },
      border: '#4A4E48',
      success: '#7BAF8C',
      error: '#E8908D',
      warning: '#F0C674',
      info: '#8BAAC9',
      like: '#F0857A',
      shadow: '#000',
      input: {
        background: 'rgba(60, 60, 67, 0.6)',
        border: 'rgba(255, 255, 255, 0.3)',
      },
      modal: {
        background: 'rgba(18, 18, 20, 0.98)',
        overlay: 'rgba(0, 0, 0, 0.7)',
      },
    },
    name: 'Sage Garden',
    description: 'A calming, nature-inspired theme that promotes reflection and growth',
  },
  wooden: {
    light: {
      isDark: false,
      primary: '#8B5E3C',
      primaryLight: '#A67C52',
      primaryDark: '#6B4423',
      secondary: '#7D7468',
      background: '#FDF8F3',
      surface: '#F5EDE4',
      paper: '#f5ede4',
      paperBorder: '#e0d4c8',
      paperShadow: '#d0c0b0',
      dividerOpacity: 0.3,
      flourishRotation: '5deg',
      dotSize: 6,
      surfaceVariant: '#EAE0D4',
      text: {
        primary: '#2C1810',
        secondary: '#5A4A3E',
        tertiary: '#7D6B5E',
        inverse: '#FDF8F3',
        placeholder: '#8A7A6E',
      },
      border: '#E8D5C4',
      success: '#4A7B58',
      error: '#A94442',
      warning: '#D9A441',
      info: '#5B7B9C',
      like: '#C4442A',
      shadow: '#000',
      input: {
        background: 'rgba(60, 60, 67, 0.5)',
        border: 'rgba(255, 255, 255, 0.25)',
      },
      modal: {
        background: 'rgba(18, 18, 20, 0.98)',
        overlay: 'rgba(0, 0, 0, 0.6)',
      },
    },
    dark: {
      isDark: true,
      primary: '#A67C52',
      primaryLight: '#C19A70',
      primaryDark: '#6B4423',
      secondary: '#A39C96',
      background: '#1A1410',
      surface: '#2A2420',
      surfaceVariant: '#3A3430',
      paper: '#2a241e',
      paperBorder: '#3a322b',
      paperShadow: '#1a1612',
      dividerOpacity: 0.3,
      flourishRotation: '5deg',
      dotSize: 6,
      text: {
        primary: '#F0E6DF',
        secondary: '#D4C9C0',
        tertiary: '#B0A59C',
        inverse: '#2C1810',
        placeholder: '#BFB0A7',
      },
      border: '#4A3E34',
      success: '#7BAF8C',
      error: '#E8908D',
      warning: '#F0C674',
      info: '#8BAAC9',
      like: '#F0857A',
      shadow: '#000',
      input: {
        background: 'rgba(60, 60, 67, 0.6)',
        border: 'rgba(255, 255, 255, 0.3)',
      },
      modal: {
        background: 'rgba(18, 18, 20, 0.98)',
        overlay: 'rgba(0, 0, 0, 0.7)',
      },
    },
    name: 'Classic Parchment',
    description: 'A warm, classic theme inspired by ancient wisdom and timeless scrolls',
  },
  ocean: {
    light: {
      isDark: false,
      primary: '#4A6FA5',
      primaryLight: '#6B8BB8',
      primaryDark: '#385582',
      secondary: '#798089',
      background: '#F8FBFF',
      surface: '#F0F5FA',
      paper: '#f0f5f9',
      paperBorder: '#d0dde8',
      paperShadow: '#b0c0d0',
      dividerOpacity: 0.25,
      flourishRotation: '3deg',
      dotSize: 5,
      surfaceVariant: '#E4ECF5',
      text: {
        primary: '#2C3542',
        secondary: '#5A6370',
        tertiary: '#7D8694',
        inverse: '#FFFFFF',
        placeholder: '#8A93A0',
      },
      border: '#E2E8F0',
      success: '#4B957A',
      error: '#B86268',
      warning: '#D9A441',
      info: '#5B7B9C',
      like: '#E15554',
      shadow: '#000',
      input: {
        background: 'rgba(60, 60, 67, 0.5)',
        border: 'rgba(255, 255, 255, 0.25)',
      },
      modal: {
        background: 'rgba(18, 18, 20, 0.98)',
        overlay: 'rgba(0, 0, 0, 0.6)',
      },
    },
    dark: {
      isDark: true,
      primary: '#6B8BB8',
      primaryLight: '#8CA5CA',
      primaryDark: '#385582',
      secondary: '#A3AAB3',
      background: '#1A1E24',
      surface: '#2A3038',
      paper: '#1a2833',
      paperBorder: '#2a3a47',
      paperShadow: '#0a161f',
      dividerOpacity: 0.25,
      flourishRotation: '3deg',
      dotSize: 5,
      surfaceVariant: '#3A4048',
      text: {
        primary: '#E6ECF2',
        secondary: '#C4CCD6',
        tertiary: '#A0AAB4',
        inverse: '#2C3542',
        placeholder: '#B0BAC4',
      },
      border: '#4A5260',
      success: '#7BAF8C',
      error: '#E8908D',
      warning: '#F0C674',
      info: '#8BAAC9',
      like: '#F0857A',
      shadow: '#000',
      input: {
        background: 'rgba(60, 60, 67, 0.6)',
        border: 'rgba(255, 255, 255, 0.3)',
      },
      modal: {
        background: 'rgba(18, 18, 20, 0.98)',
        overlay: 'rgba(0, 0, 0, 0.7)',
      },
    },
    name: 'Ocean Breeze',
    description: 'A refreshing, contemplative theme that inspires depth and clarity',
  },
} as const;

export type ThemeVariant = keyof typeof themeColors;
export type ColorMode = 'light' | 'dark';
export type ThemeColors = typeof themeColors.sage.light | typeof themeColors.sage.dark
  | typeof themeColors.wooden.light | typeof themeColors.wooden.dark
  | typeof themeColors.ocean.light | typeof themeColors.ocean.dark;

// Create complete themes by combining base theme with color variants
export const createTheme = (colors: ThemeColors) => ({
  ...baseTheme,
  colors,
});

// Pre-built themes
export const themes = {
  sage: {
    light: createTheme(themeColors.sage.light),
    dark: createTheme(themeColors.sage.dark),
  },
  wooden: {
    light: createTheme(themeColors.wooden.light),
    dark: createTheme(themeColors.wooden.dark),
  },
  ocean: {
    light: createTheme(themeColors.ocean.light),
    dark: createTheme(themeColors.ocean.dark),
  },
} as const;

export type Theme = typeof themes.sage.light;

// Default theme
export const defaultTheme = themes.sage.light;

// Utility functions
export const getTheme = (variant: ThemeVariant, colorMode: ColorMode = 'light') => 
  themes[variant][colorMode];

export const getThemeColors = (variant: ThemeVariant, colorMode: ColorMode = 'light') => 
  themeColors[variant][colorMode];

// Accessibility helpers
export const getContrastText = (backgroundColor: string, darkText: string, lightText: string) => {
  // Simple contrast calculation - production code should use a proper color contrast algorithm
  const r = parseInt(backgroundColor.slice(1, 3), 16);
  const g = parseInt(backgroundColor.slice(3, 5), 16);
  const b = parseInt(backgroundColor.slice(5, 7), 16);
  const brightness = (r * 299 + g * 587 + b * 114) / 1000;
  return brightness > 128 ? darkText : lightText;
};

// Semantic color helpers
export const getSemanticColor = (theme: Theme, type: 'success' | 'error' | 'warning' | 'info') => {
  return theme.colors[type];
};