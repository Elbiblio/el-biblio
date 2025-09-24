import React from 'react';
import { Text, StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  emphasized: {
    fontWeight: 'bold'
  },
});

export const parseDescription = (text: string) => {
  // Fixed regex to capture content between asterisks properly
  const parts = text.split(/(\*[^*]+\*)/);

  return parts.map((part, index) => {
    // Check if part is wrapped in asterisks
    if (part.startsWith('*') && part.endsWith('*')) {
      return (
        <Text key={index} style={styles.emphasized}>
          {part.slice(1, -1)}
        </Text>
      );
    }
    // Return regular text parts
    return part;
  });
};