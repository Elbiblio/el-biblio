import React from 'react';
import { View, StyleSheet } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';

const FooterFlourish = () => {
  const theme = useTheme();
  
  return (
    <View style={styles.container}>
      <View style={[styles.line, { 
        backgroundColor: theme.colors.text.secondary,
        transform: [{ rotate: '-2deg' }]
      }]} />
      <View style={[styles.line, { 
        backgroundColor: theme.colors.text.secondary,
        transform: [{ rotate: '2deg' }]
      }]} />
      <View style={[styles.dot, { backgroundColor: theme.colors.text.secondary }]} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginTop: 24,
  },
  line: {
    width: 40,
    height: 2,
    opacity: 0.3,
    marginVertical: 2,
  },
  dot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    marginTop: 4,
    opacity: 0.4,
  },
});

export default FooterFlourish;