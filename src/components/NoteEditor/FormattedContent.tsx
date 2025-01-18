import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Theme } from '@/theme';

interface FormattedContentProps {
  content: string;
  theme: Theme;
}

const FormattedContent: React.FC<FormattedContentProps> = ({ content, theme }) => {
  const styles = createStyles(theme);

  const renderFormattedContent = (text: string) => {
    const lines = text.split('\n');
    
    return lines.map((line, index) => {
      // Handle blockquotes
      if (line.startsWith('> ')) {
        return (
          <View key={index} style={styles.blockquote}>
            <Text style={styles.blockquoteText}>
              {line.substring(2)}
            </Text>
          </View>
        );
      }

      // Handle numbered lists
      if (/^\d+\.\s/.test(line)) {
        const number = line.match(/^\d+/)?.[0];
        const content = line.replace(/^\d+\.\s/, '');
        return (
          <View key={index} style={styles.listItem}>
            <Text style={styles.numberPoint}>{number}.</Text>
            <Text style={styles.listContent}>{formatInlineStyles(content)}</Text>
          </View>
        );
      }

      // Handle bullet lists
      if (line.startsWith('• ') || line.startsWith('- ')) {
        const content = line.substring(2);
        return (
          <View key={index} style={styles.listItem}>
            <Text style={styles.bulletPoint}>•</Text>
            <Text style={styles.listContent}>{formatInlineStyles(content)}</Text>
          </View>
        );
      }

      // Handle verse references
      if (line.includes('«') && line.includes('»')) {
        return (
          <Text key={index} style={styles.paragraph}>
            {formatInlineStyles(line)}
          </Text>
        );
      }

      // Regular paragraph
      return (
        <Text key={index} style={styles.paragraph}>
          {formatInlineStyles(line)}
        </Text>
      );
    });
  };

  const formatInlineStyles = (text: string) => {
    // Split the text into parts that need different styling
    const parts: JSX.Element[] = [];
    let currentIndex = 0;

    // Regular expression for finding markdown patterns
    const patterns = [
      { regex: /\*\*(.*?)\*\*/g, style: { fontWeight: 'bold' } },
      { regex: /\*(.*?)\*/g, style: { fontStyle: 'italic' } },
      { regex: /_(.*?)_/g, style: { textDecorationLine: 'underline' } },
      { regex: /«(.*?)»/g, style: { color: theme.colors.primary, fontWeight: '600', fontFamily: theme.typography.verse.emphasis.fontFamily, textDecorationLine: 'underline', textDecorationColor: `${theme.colors.primary}40` } },
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

  return <View style={styles.container}>{renderFormattedContent(content)}</View>;
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
  },
  paragraph: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    fontSize: 18,
    lineHeight: 32,
    marginBottom: theme.spacing.md,
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
    fontFamily: theme.typography.verse.emphasis.fontFamily,
    textDecorationLine: 'underline',
    textDecorationColor: `${theme.colors.primary}40`,
  },
  blockquote: {
    borderLeftWidth: 2,
    borderLeftColor: theme.colors.primary,
    paddingLeft: theme.spacing.md,
    marginVertical: theme.spacing.sm,
    backgroundColor: `${theme.colors.primary}08`,
    borderRadius: theme.borderRadius.sm,
    padding: theme.spacing.sm,
    marginBottom: theme.spacing.md,
  },
  blockquoteText: {
    ...theme.typography.body.serif,
    fontStyle: 'italic',
    color: theme.colors.text.primary,
    fontSize: 18,
    lineHeight: 32,
  },
  listItem: {
    flexDirection: 'row',
    paddingLeft: theme.spacing.md,
    marginBottom: theme.spacing.md,
    alignItems: 'flex-start',
  },
  bulletPoint: {
    width: 20,
    textAlign: 'center',
    color: theme.colors.text.secondary,
    marginRight: theme.spacing.xs,
    marginTop: 2,
  },
  numberPoint: {
    width: 24,
    textAlign: 'right',
    marginRight: theme.spacing.sm,
    color: theme.colors.text.secondary,
    marginTop: 2,
  },
  listContent: {
    flex: 1,
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    fontSize: 18,
    lineHeight: 32,
  },
});

export default FormattedContent;