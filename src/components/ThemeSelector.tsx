import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { themeColors, ThemeVariant } from '../theme';
import { useTheme, useThemeVariant } from '../contexts/ThemeContext';
import { usePreferences } from '@/stores/PreferencesStore';

import * as Haptics from 'expo-haptics';

interface ThemeSelectorProps {
  onSelect?: (variant: ThemeVariant) => void;
  closeAfterSelection?: boolean;
}

const ThemeSelector: React.FC<ThemeSelectorProps> = ({ 
  onSelect,
  closeAfterSelection = false
}) => {
  const theme = useTheme();
  const setThemeVariant = useThemeVariant();
  const { preferredTheme, setPreferredTheme } = usePreferences();

  const handleSelect = (variant: ThemeVariant) => {
    // Update the theme variant in the theme context
    setThemeVariant(variant);
    
    // Save preference to persistent storage
    setPreferredTheme(variant);
    
    // Provide haptic feedback
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    
    // Call the onSelect callback if provided
    if (onSelect) {
      onSelect(variant);
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: theme.colors.background }]}>
      <Text style={[styles.title, { color: theme.colors.text.primary }]}>
        Choose your theme
      </Text>
      <Text style={[styles.subtitle, { color: theme.colors.text.secondary }]}>
        Select a theme that resonates with you
      </Text>
      
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        {(Object.entries(themeColors) as [ThemeVariant, typeof themeColors.sage][]).map(
          ([variant, colors]) => (
            <TouchableOpacity
              key={variant}
              style={[
                styles.option,
                { backgroundColor: colors.light.surface },
                preferredTheme === variant && styles.selectedOption,
              ]}
              onPress={() => handleSelect(variant)}
            >
              <View style={[styles.colorPreview, { backgroundColor: colors.light.primary }]} />
              <View style={styles.textContainer}>
                <Text style={[
                  styles.optionTitle,
                  { color: colors.light.text.primary }
                ]}>
                  {colors.name}
                </Text>
                <Text style={[
                  styles.optionDescription,
                  { color: colors.light.text.secondary }
                ]}>
                  {colors.description}
                </Text>
              </View>
            </TouchableOpacity>
          )
        )}
      </ScrollView>

      {closeAfterSelection && (
        <TouchableOpacity
          style={[
            styles.continueButton,
            { backgroundColor: theme.colors.primary }
          ]}
          onPress={() => onSelect && onSelect(preferredTheme)}
        >
          <Text style={[
            styles.continueButtonText,
            { color: theme.colors.text.inverse }
          ]}>
            Continue
          </Text>
        </TouchableOpacity>
      )}
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
  selectedOption: {
    borderWidth: 2,
    borderColor: '#4A6FA5', // Using ocean theme primary color as default
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
  optionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 4,
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