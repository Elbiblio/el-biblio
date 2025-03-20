import React from 'react';
import { View, Text, StyleSheet, Platform } from 'react-native';
import { Theme } from '@/theme';

interface FormattedContentProps {
  content: string;
  theme: Theme;
  isBookStyle?: boolean;
}

const FormattedContent: React.FC<FormattedContentProps> = ({ content, theme, isBookStyle = false }) => {
  const styles = createStyles(theme, isBookStyle);

  const renderFormattedContent = (text: string) => {
    // Split into paragraphs for proper spacing
    const paragraphs = text.split('\n\n');
    
    return paragraphs.map((paragraph, paragraphIndex) => {
      const lines = paragraph.split('\n');
      
      // Handle different paragraph types
      // Check if it's a list (bullet or numbered)
      const isBulletList = lines.every(line => line.trim().startsWith('• ') || line.trim().startsWith('- '));
      const isNumberedList = lines.every(line => /^\d+\.\s/.test(line.trim()));
      
      // Handle list blocks
      if (isBulletList) {
        return (
          <View key={`p-${paragraphIndex}`} style={styles.listContainer}>
            {lines.map((line, lineIndex) => (
              <View key={`bullet-${lineIndex}`} style={styles.listItem}>
                <Text style={styles.bulletPoint}>•</Text>
                <Text style={styles.listContent}>{formatInlineStyles(line.substring(line.indexOf(' ') + 1), theme, isBookStyle)}</Text>
              </View>
            ))}
          </View>
        );
      }
      
      if (isNumberedList) {
        return (
          <View key={`p-${paragraphIndex}`} style={styles.listContainer}>
            {lines.map((line, lineIndex) => {
              const number = line.match(/^\d+/)?.[0];
              const content = line.replace(/^\d+\.\s/, '');
              return (
                <View key={`number-${lineIndex}`} style={styles.listItem}>
                  <Text style={styles.numberPoint}>{number}.</Text>
                  <Text style={styles.listContent}>{formatInlineStyles(content, theme, isBookStyle)}</Text>
                </View>
              );
            })}
          </View>
        );
      }
      
      // Handle blockquotes
      if (lines.every(line => line.trim().startsWith('> '))) {
        return (
          <View key={`p-${paragraphIndex}`} style={styles.blockquote}>
            <Text style={styles.blockquoteText}>
              {formatInlineStyles(
                lines.map(line => line.substring(line.indexOf('> ') + 2)).join('\n'),
                theme,
                isBookStyle
              )}
            </Text>
          </View>
        );
      }
      
      // Regular paragraph with special treatment
      if (paragraphIndex === 0 && isBookStyle) {
        // First paragraph in book style with drop cap
        return (
          <View key={`p-${paragraphIndex}`} style={[styles.paragraphContainer, styles.firstParagraph]}>
            <Text style={styles.paragraph}>
              <Text style={styles.dropCap}>{paragraph.charAt(0)}</Text>
              <Text>{formatInlineStyles(paragraph.substring(1), theme, isBookStyle)}</Text>
            </Text>
          </View>
        );
      } else if (isBookStyle) {
        // Non-first paragraphs in book style with indentation
        return (
          <View key={`p-${paragraphIndex}`} style={styles.paragraphContainer}>
            <Text style={styles.paragraph}>
              <Text style={styles.indentSpace}>{'\u00A0\u00A0\u00A0\u00A0\u00A0\u00A0'}</Text>
              {formatInlineStyles(paragraph, theme, isBookStyle)}
            </Text>
          </View>
        );
      } else {
        // Regular paragraph in standard mode
        return (
          <View key={`p-${paragraphIndex}`} style={styles.paragraphContainer}>
            <Text style={styles.paragraph}>
              {formatInlineStyles(paragraph, theme, isBookStyle)}
            </Text>
          </View>
        );
      }
    });
  };

  return <View style={styles.container}>{renderFormattedContent(content)}</View>;
};

const formatInlineStyles = (text: string, theme: Theme, isBookStyle: boolean) => {
  // Split the text into parts that need different styling
  const parts: JSX.Element[] = [];
  let currentIndex = 0;

  // Get appropriate emphasis font family
  const emphasisFontFamily = isBookStyle
    ? theme.typography.body.serif.fontFamily // Fallback to serif body
    : theme.typography.body.sans.fontFamily;

  // Regular expression for finding markdown patterns
  const patterns = [
    { regex: /\*\*(.*?)\*\*/g, style: { fontWeight: 'bold' } },
    { regex: /\*(.*?)\*/g, style: { fontStyle: 'italic' } },
    { regex: /_(.*?)_/g, style: { textDecorationLine: 'underline' } },
    { regex: /«(.*?)»/g, style: { 
      color: theme.colors.primary, 
      fontWeight: '600', 
      fontFamily: emphasisFontFamily,
      textDecorationLine: 'underline', 
      textDecorationColor: `${theme.colors.primary}40` 
    }},
  ];

  while (currentIndex < text.length) {
    let earliestMatch: { index: number; length: number; style: React.CSSProperties | undefined; content: string } = { index: text.length, length: 0, style: undefined, content: '' };
    
    // Find the earliest matching pattern
    for (const pattern of patterns) {
      pattern.regex.lastIndex = currentIndex;
      const match = pattern.regex.exec(text);
      if (match && match.index < earliestMatch.index) {
        earliestMatch = {
          index: match.index,
          length: match[0].length,
          style: pattern.style,
          content: match[1], // The text between the markers
        };
      }
    }

    // Add any plain text before the match
    if (earliestMatch.index > currentIndex) {
      parts.push(
        <Text key={parts.length}>
          {text.substring(currentIndex, earliestMatch.index)}
        </Text>
      );
    }

    // Add the styled text if we found a match
    if (earliestMatch.style) {
      parts.push(
        <Text key={parts.length} style={earliestMatch.style as any}>
          {earliestMatch.content}
        </Text>
      );
      currentIndex = earliestMatch.index + earliestMatch.length;
    } else {
      // No more matches, add the rest of the text
      parts.push(
        <Text key={parts.length}>
          {text.substring(currentIndex)}
        </Text>
      );
      break;
    }
  }

  return parts;
};

const createStyles = (theme: Theme, isBookStyle: boolean) => StyleSheet.create({
  container: {
    flex: 1,
  },
  paragraphContainer: {
    marginBottom: isBookStyle ? theme.spacing.lg : theme.spacing.md,
  },
  firstParagraph: {
    // First paragraph styles specific for book mode
  },
  paragraph: {
    ...(isBookStyle ? theme.typography.body.serif : theme.typography.body.sans),
    color: theme.colors.text.primary,
    // Use appropriate typography based on style mode
    fontSize: isBookStyle ? 18 : theme.typography.body.sans.fontSize,
    lineHeight: isBookStyle ? 32 : theme.typography.body.sans.lineHeight,
    textAlign: isBookStyle ? 'justify' : 'left',
  },
  indentSpace: {
    // This creates the indentation effect for paragraphs in book style
    letterSpacing: 0,
  },
  dropCap: {
    ...(isBookStyle ? theme.typography.body.serif : theme.typography.body.sans),
    fontSize: 54,
    lineHeight: 54,
    fontWeight: '600',
    color: theme.colors.primary,
    // Platform specific adjustments for the drop cap
    ...Platform.select({
      ios: {
        marginRight: 4,
      },
      android: {
        marginRight: 2,
        marginBottom: -8,
      },
    }),
    // Text shadow for subtle depth
    textShadowColor: `${theme.colors.primary}20`,
    textShadowOffset: { width: 1, height: 1 },
    textShadowRadius: 1,
  },
  blockquote: {
    borderLeftWidth: 3,
    borderLeftColor: isBookStyle ? `${theme.colors.primary}60` : theme.colors.primary,
    paddingLeft: theme.spacing.md,
    marginVertical: theme.spacing.lg,
    marginHorizontal: isBookStyle ? theme.spacing.md : 0,
    backgroundColor: `${theme.colors.primary}08`,
    borderRadius: theme.borderRadius.sm,
    padding: theme.spacing.md,
  },
  blockquoteText: {
    ...(isBookStyle ? theme.typography.body.serif : theme.typography.body.sans),
    fontStyle: 'italic',
    color: isBookStyle ? theme.colors.text.secondary : theme.colors.text.primary,
    // Book-style quotes typically have more letter spacing
    letterSpacing: isBookStyle ? 0.3 : theme.typography.body.sans.letterSpacing,
  },
  listContainer: {
    marginBottom: theme.spacing.lg,
    marginLeft: isBookStyle ? theme.spacing.md : 0,
  },
  listItem: {
    flexDirection: 'row',
    marginBottom: theme.spacing.sm,
    alignItems: 'flex-start',
  },
  bulletPoint: {
    width: 24,
    textAlign: 'center',
    ...(isBookStyle ? theme.typography.body.serif : theme.typography.body.sans),
    color: isBookStyle ? `${theme.colors.primary}80` : theme.colors.text.secondary,
    marginRight: theme.spacing.xs,
    marginTop: isBookStyle ? 4 : 2,
  },
  numberPoint: {
    width: 30,
    textAlign: 'right',
    ...(isBookStyle ? theme.typography.body.serif : theme.typography.body.sans),
    color: isBookStyle ? `${theme.colors.primary}80` : theme.colors.text.secondary,
    fontWeight: isBookStyle ? '500' : 'normal',
    marginRight: theme.spacing.sm,
    marginTop: isBookStyle ? 4 : 2,
  },
  listContent: {
    flex: 1,
    ...(isBookStyle ? theme.typography.body.serif : theme.typography.body.sans),
    color: theme.colors.text.primary,
    textAlign: isBookStyle ? 'justify' : 'left',
  },
  bold: {
    fontWeight: 'bold',
  },
  italic: {
    fontStyle: 'italic',
  },
  underline: {
    textDecorationLine: 'underline',
  },
  verseReference: {
    color: theme.colors.primary,
    fontWeight: '600',
    fontFamily: isBookStyle 
      ? theme.typography.body.serif.fontFamily
      : (theme.typography.verse?.emphasis?.fontFamily || theme.typography.body.sans.fontFamily),
    textDecorationLine: 'underline',
    textDecorationColor: `${theme.colors.primary}40`,
  },
});

export default FormattedContent;