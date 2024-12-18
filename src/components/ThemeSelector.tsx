import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { themeColors, ThemeVariant } from '../theme';
import { useTheme, useThemeVariant } from '../contexts/ThemeContext';
import { useThemeStore } from '@/theme/store';

interface ThemeSelectorProps {
  onSelect: (variant: ThemeVariant) => void;
}

const ThemeSelector: React.FC<ThemeSelectorProps> = ({ onSelect }) => {
  const setThemeVariant = useThemeVariant();
  const theme = useThemeStore(state => state.current);


  const handleSelect = (variant: ThemeVariant) => {
    setThemeVariant(variant);
    onSelect(variant);
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <Text style={[styles.title, { color: theme.colors.text.primary }]}>
        Choose your theme
      </Text>
      <Text style={[styles.subtitle, { color: theme.colors.text.secondary }]}>
        Select a theme that resonates with you, or continue with our default Sage Garden theme
      </Text>
      
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {(Object.entries(themeColors) as [ThemeVariant, typeof themeColors.sage][]).map(
          ([variant, colors]) => (
            <TouchableOpacity
              key={variant}
              style={[
                styles.option,
                { backgroundColor: colors.surface },
                variant === 'sage' && styles.defaultOption,
              ]}
              onPress={() => handleSelect(variant)}
            >
              <View style={[styles.colorPreview, { backgroundColor: colors.primary }]} />
              <View style={styles.textContainer}>
                <View style={styles.titleContainer}>
                  <Text style={[
                    styles.optionTitle,
                    { color: colors.text.primary }
                  ]}>
                    {colors.name}
                  </Text>
                  {variant === 'sage' && (
                    <Text style={[
                      styles.defaultBadge,
                      { color: colors.primary }
                    ]}>
                      Default
                    </Text>
                  )}
                </View>
                <Text style={[
                  styles.optionDescription,
                  { color: colors.text.secondary }
                ]}>
                  {colors.description}
                </Text>
              </View>
            </TouchableOpacity>
          )
        )}
      </ScrollView>

      <TouchableOpacity
        style={[
          styles.continueButton,
          { backgroundColor: theme.colors.primary }
        ]}
        onPress={() => handleSelect('sage')}
      >
        <Text style={[
          styles.continueButtonText,
          { color: theme.colors.text.inverse }
        ]}>
          Continue with {theme.colors.name}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: '600',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    marginBottom: 24,
  },
  scrollView: {
    flex: 1,
  },
  option: {
    flexDirection: 'row',
    padding: 16,
    borderRadius: 12,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  defaultOption: {
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  colorPreview: {
    width: 48,
    height: 48,
    borderRadius: 24,
    marginRight: 16,
  },
  textContainer: {
    flex: 1,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  optionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginRight: 8,
  },
  defaultBadge: {
    fontSize: 12,
    fontWeight: '500',
  },
  optionDescription: {
    fontSize: 14,
  },
  continueButton: {
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 16,
  },
  continueButtonText: {
    fontSize: 16,
    fontWeight: '600',
  },
});

export default ThemeSelector;