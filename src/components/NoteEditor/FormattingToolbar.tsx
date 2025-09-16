import React from 'react';
import { View, TouchableOpacity, StyleSheet, Platform } from 'react-native';
import {
  Bold,
  Italic,
  Underline,
  HelpCircle,
  List,
  ListOrdered,
  Quote,
  Bible,
  IconProps,
} from '@/components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';

interface FormattingToolbarProps {
  onFormat: (type: 'bold' | 'italic' | 'underline' | 'bullet' | 'number' | 'quote' | 'verse') => void;
  onShowHelp: () => void;
  activeFormats?: string[];
}

type FormatButton = {
  type: 'bold' | 'italic' | 'underline' | 'bullet' | 'number' | 'quote' | 'verse';
  Icon: React.FC<IconProps>;
  tooltip?: string;
};

const FormattingToolbar: React.FC<FormattingToolbarProps> = ({
  onFormat,
  onShowHelp,
  activeFormats = [],
}) => {
  const theme = useTheme();
  const styles = createStyles(theme);

  const textFormatButtons: FormatButton[] = [
    { type: 'bold', Icon: Bold, tooltip: 'Bold (⌘+B)' },
    { type: 'italic', Icon: Italic, tooltip: 'Italic (⌘+I)' },
    { type: 'underline', Icon: Underline, tooltip: 'Underline (⌘+U)' },
  ];

  const listFormatButtons: FormatButton[] = [
    { type: 'bullet', Icon: List, tooltip: 'Bullet List' },
    { type: 'number', Icon: ListOrdered, tooltip: 'Numbered List' },
  ];

  const specialFormatButtons: FormatButton[] = [
    { type: 'quote', Icon: Quote, tooltip: 'Blockquote' },
    { type: 'verse', Icon: Bible, tooltip: 'Mark Verse Reference' },
  ];

  const renderFormatGroup = (buttons: FormatButton[], isLast = false) => (
    <View style={[styles.group, !isLast && styles.groupWithBorder]}>
      {buttons.map(({ type, Icon, tooltip }) => (
        <TouchableOpacity
          key={type}
          style={[
            styles.button,
            activeFormats.includes(type) && styles.activeButton,
          ]}
          onPress={() => onFormat(type)}
          activeOpacity={0.7}
        >
          <Icon
            size={20}
            color={activeFormats.includes(type) ? theme.colors.primary : theme.colors.text.primary}
          />
        </TouchableOpacity>
      ))}
    </View>
  );

  return (
    <View style={styles.container}>
      {renderFormatGroup(textFormatButtons)}
      {renderFormatGroup(listFormatButtons)}
      {renderFormatGroup(specialFormatButtons, true)}

      <TouchableOpacity
        style={[styles.button, styles.helpButton]}
        onPress={onShowHelp}
        activeOpacity={0.7}
      >
        <HelpCircle size={20} color={theme.colors.text.secondary} />
      </TouchableOpacity>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.xs,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  group: {
    flexDirection: 'row',
    paddingRight: theme.spacing.sm,
    marginRight: theme.spacing.sm,
  },
  groupWithBorder: {
    borderRightWidth: StyleSheet.hairlineWidth,
    borderRightColor: theme.colors.border,
  },
  button: {
    padding: theme.spacing.xs,
    borderRadius: theme.borderRadius.sm,
    marginRight: theme.spacing.xs,
  },
  activeButton: {
    backgroundColor: `${theme.colors.primary}15`,
  },
  helpButton: {
    marginLeft: 'auto',
    backgroundColor: `${theme.colors.text.secondary}10`,
  },
  separator: {
    width: StyleSheet.hairlineWidth,
    height: '60%',
    backgroundColor: theme.colors.border,
    marginHorizontal: theme.spacing.xs,
  },
});

export default FormattingToolbar;