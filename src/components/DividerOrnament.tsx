import React from 'react';
import { View, StyleSheet } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';

const DividerOrnament = () => {
  const theme = useTheme();
  
  return (
    <View style={styles.container}>
      <View style={[styles.line, { backgroundColor: theme.colors.text.secondary }]} />
      <View style={styles.ornamentContainer}>
        {[...Array(3)].map((_, i) => (
          <View 
            key={i}
            style={[
              styles.ornamentDot,
              { 
                backgroundColor: theme.colors.text.secondary,
                transform: [{ rotate: `${i * 45}deg` }]
              }
            ]}
          />
        ))}
      </View>
      <View style={[styles.line, { backgroundColor: theme.colors.text.secondary }]} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 16,
  },
  line: {
    flex: 1,
    height: 1,
    opacity: 0.3,
  },
  ornamentContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 8,
  },
  ornamentDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginHorizontal: 2,
  },
});

export default DividerOrnament;