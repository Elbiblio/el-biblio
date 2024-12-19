import React from 'react';
import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity,
    ScrollView,
    Modal,
    Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { X, Bold, Italic, Underline, List, ListOrdered, Quote, Bible, IconProps } from '@/components/Icons';

interface FormatHelpProps {
    visible: boolean;
    onClose: () => void;
}

interface FormatExample {
    label: string;
    markup: string;
    result: string;
    icon: React.FC<IconProps>;
}

const FormatHelp: React.FC<FormatHelpProps> = ({ visible, onClose }) => {
    const theme = useTheme();
    const styles = createStyles(theme);

    const formatExamples: FormatExample[] = [
        {
            label: 'Bold',
            markup: '**text**',
            result: 'Makes text bold',
            icon: Bold,
        },
        {
            label: 'Italic',
            markup: '*text*',
            result: 'Makes text italic',
            icon: Italic,
        },
        {
            label: 'Underline',
            markup: '_text_',
            result: 'Underlines text',
            icon: Underline,
        },
        {
            label: 'Bullet List',
            markup: '• item',
            result: 'Creates bullet point',
            icon: List,
        },
        {
            label: 'Numbered List',
            markup: '1. item',
            result: 'Creates numbered list',
            icon: ListOrdered,
        },
        {
            label: 'Quote',
            markup: '> text',
            result: 'Creates block quote',
            icon: Quote,
        },
        {
            label: 'Verse',
            markup: '«John 3:16»',
            result: 'Marks Bible reference',
            icon: Bible,
        }
    ];

    return (
        <Modal
            visible={visible}
            transparent
            animationType="fade"
            onRequestClose={onClose}
        >
            <BlurView intensity={20} style={StyleSheet.absoluteFill}>
                <View style={styles.container}>
                    <View style={styles.content}>
                        <View style={styles.header}>
                            <Text style={styles.title}>Text Formatting</Text>
                            <TouchableOpacity
                                onPress={onClose}
                                style={styles.closeButton}
                            >
                                <X size={24} color={theme.colors.text.primary} />
                            </TouchableOpacity>
                        </View>

                        <Text style={styles.description}>
                            Basic text formatting is supported using markdown-style syntax. 
                            Don't worry if you see symbols like ** in your text - they'll 
                            be hidden when viewing the note.
                        </Text>

                        <ScrollView
                            style={styles.examples}
                            showsVerticalScrollIndicator={false}
                        >
                            {formatExamples.map((example, index) => (
                                <View key={index} style={styles.exampleItem}>
                                    <View style={styles.exampleHeader}>
                                        <example.icon 
                                            size={20} 
                                            color={theme.colors.primary} 
                                        />
                                        <Text style={styles.exampleLabel}>
                                            {example.label}
                                        </Text>
                                    </View>
                                    <View style={styles.exampleContent}>
                                        <Text style={styles.markup}>
                                            {example.markup}
                                        </Text>
                                        <Text style={styles.result}>
                                            {example.result}
                                        </Text>
                                    </View>
                                </View>
                            ))}
                        </ScrollView>

                        <TouchableOpacity
                            style={styles.gotItButton}
                            onPress={onClose}
                        >
                            <Text style={styles.gotItText}>Got it</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </BlurView>
        </Modal>
    );
};

const createStyles = (theme: Theme) => StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        padding: theme.spacing.lg,
    },
    content: {
        backgroundColor: theme.colors.background,
        borderRadius: theme.borderRadius.xl,
        width: '100%',
        maxWidth: 400,
        maxHeight: '80%',
        padding: theme.spacing.lg,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: theme.spacing.md,
    },
    title: {
        ...theme.typography.heading.medium,
        color: theme.colors.text.primary,
    },
    closeButton: {
        padding: theme.spacing.xs,
    },
    description: {
        ...theme.typography.body.sans,
        color: theme.colors.text.secondary,
        marginBottom: theme.spacing.lg,
        lineHeight: 22,
    },
    examples: {
        marginBottom: theme.spacing.lg,
    },
    exampleItem: {
        marginBottom: theme.spacing.md,
        backgroundColor: theme.colors.surface,
        borderRadius: theme.borderRadius.lg,
        padding: theme.spacing.md,
    },
    exampleHeader: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: theme.spacing.sm,
        marginBottom: theme.spacing.sm,
    },
    exampleLabel: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.primary,
        fontWeight: '600',
    },
    exampleContent: {
        paddingLeft: theme.spacing.xl,
    },
    markup: {
        ...theme.typography.body.sans,
        color: theme.colors.primary,
        marginBottom: theme.spacing.xs,
        fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    },
    result: {
        ...theme.typography.caption.secondary,
        color: theme.colors.text.secondary,
    },
    gotItButton: {
        backgroundColor: theme.colors.primary,
        paddingVertical: theme.spacing.sm,
        paddingHorizontal: theme.spacing.lg,
        borderRadius: theme.borderRadius.full,
        alignItems: 'center',
        alignSelf: 'center',
    },
    gotItText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.inverse,
        fontWeight: '600',
    },
});

export default FormatHelp;