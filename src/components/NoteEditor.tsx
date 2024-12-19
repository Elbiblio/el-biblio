import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
    View,
    Text,
    TextInput,
    TouchableOpacity,
    StyleSheet,
    Platform,
    ScrollView,
    KeyboardAvoidingView,
    NativeSyntheticEvent,
    TextInputSelectionChangeEventData,
    Keyboard,
    StatusBar,
} from 'react-native';
import { BlurView } from 'expo-blur';
import Animated, {
    useAnimatedStyle,
    useSharedValue,
    withSpring,
    withTiming,
    runOnJS,
} from 'react-native-reanimated';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { Sparkle, X, PencilLock } from '@/components/Icons';
import { AllVirtues } from '@/types';
import { parseMarkdown, formatHelpText } from '@/utils/notes';
import FormattingToolbar from '@/components/NoteEditor/FormattingToolbar';
import { SCREEN_DIMENSIONS } from '@/constants';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import VerseSelector from './NoteEditor/VerseSelector';
import FormatHelp from './NoteEditor/FormatHelp';

const AnimatedBlurView = Animated.createAnimatedComponent(BlurView);
interface NoteEditorProps {
    initialTitle?: string;
    initialContent?: string;
    initialVirtues?: AllVirtues[];
    onSubmit: (note: {
        title: string;
        content: string;
        virtues: AllVirtues[];
    }) => void;
    onCancel: () => void;
    onShowVirtueSelector: () => void;
    selectedVirtues: AllVirtues[];
    isEditing?: boolean;
}

const NoteEditor: React.FC<NoteEditorProps> = ({
    initialTitle = '',
    initialContent = '',
    initialVirtues = [],
    onSubmit,
    onCancel,
    onShowVirtueSelector,
    selectedVirtues,
    isEditing = true,
}) => {
    const theme = useTheme();
    const insets = useSafeAreaInsets();
    const styles = createStyles(theme);

    // Refs for input focus management
    const contentInputRef = useRef<TextInput>(null);
    const titleInputRef = useRef<TextInput>(null);

    // State management
    const [title, setTitle] = useState(initialTitle || "New Note");
    const [content, setContent] = useState(initialContent);
    const [showFormatHelp, setShowFormatHelp] = useState(false);
    const [selection, setSelection] = useState({ start: 0, end: 0 });
    const [formattedContent, setFormattedContent] = useState('');
    const [isKeyboardVisible, setIsKeyboardVisible] = useState(false);
    const [showVerseSelector, setShowVerseSelector] = useState(false);
    const [mode, setMode] = useState<'read' | 'edit'>(isEditing ? 'edit' : 'read');

    // Animated values
    const modalY = useSharedValue(SCREEN_DIMENSIONS.height);
    const titleHeight = useSharedValue(56);
    const toolbarOpacity = useSharedValue(0);
    const modalOpacity = useSharedValue(0);

    // Initialize modal animations
    useEffect(() => {
        StatusBar.setBarStyle('light-content');
        modalOpacity.value = withTiming(1, { duration: 200 });
        modalY.value = withSpring(0, {
            damping: 15,
            stiffness: 90,
        });

        const keyboardWillShow = Keyboard.addListener('keyboardWillShow', () => {
            setIsKeyboardVisible(true);
        });
        const keyboardWillHide = Keyboard.addListener('keyboardWillHide', () => {
            setIsKeyboardVisible(false);
        });

        // Cleanup
        return () => {
            StatusBar.setBarStyle('dark-content');
            keyboardWillShow.remove();
            keyboardWillHide.remove();
        };
    }, []);

    // Update content when props change
    useEffect(() => {
        setTitle(initialTitle || "New Note");
        setContent(initialContent);
        setFormattedContent(parseMarkdown(initialContent));
    }, [initialTitle, initialContent]);

    // Handle closing animation
    const handleClose = useCallback(() => {
        Keyboard.dismiss();
        modalOpacity.value = withTiming(0, { duration: 200 });
        modalY.value = withSpring(SCREEN_DIMENSIONS.height, {
            damping: 15,
            stiffness: 90,
        }, () => {
            runOnJS(onCancel)();
        });
    }, [onCancel]);

    // Animation styles
    const containerStyle = useAnimatedStyle(() => ({
        opacity: modalOpacity.value,
        transform: [{ translateY: modalY.value }],
    }));

    const titleStyle = useAnimatedStyle(() => ({
        height: titleHeight.value,
        display: titleHeight.value === 0 ? 'none' : 'flex',
    }));

    const toolbarStyle = useAnimatedStyle(() => ({
        opacity: toolbarOpacity.value,
        display: toolbarOpacity.value === 0 ? 'none' : 'flex',
    }));

    // Input focus handlers
    const handleContentFocus = useCallback(() => {
        titleHeight.value = withTiming(0);
        toolbarOpacity.value = withTiming(1);
    }, []);

    const handleContentBlur = useCallback(() => {
        if (!content.trim()) {
            titleHeight.value = withTiming(56);
            toolbarOpacity.value = withTiming(0);
        }
    }, [content]);

    const handleKeyPress = useCallback((e: any) => {
        if (e.nativeEvent.key === 'Enter') {
            const lines = content.split('\n');
            const currentLineIndex = content.substring(0, selection.start).split('\n').length - 1;
            const currentLine = lines[currentLineIndex];
            let nextLine = lines[currentLineIndex + 1];

            // Auto-continue lists
            if (currentLine.match(/^(\d+\.\s|\•\s|\-\s)/)) {
                e.preventDefault();

                // If the current line is empty except for the list marker, end the list
                if (currentLine.replace(/^(\d+\.\s|\•\s|\-\s)/, '').trim() === '') {
                    lines[currentLineIndex] = '';
                } else {
                    nextLine = currentLine.match(/^\d+\.\s/)
                        ? `${Number(currentLine.match(/^\d+/)?.[0] || 0) + 1}. `
                        : currentLine.match(/^(\•|\-)\s/) ? `${currentLine[0]} ` : '';

                    lines.splice(currentLineIndex + 1, 0, nextLine);
                }

                const newContent = lines.join('\n');
                setContent(newContent);

                // Update selection to the start of the new line
                const newPosition = newContent.split('\n')
                    .slice(0, currentLineIndex + 1)
                    .join('\n').length + 1;

                setSelection({
                    start: newPosition + nextLine.length,
                    end: newPosition + nextLine.length
                });
            }
        }
    }, [content, selection]);

    const handleSelectionChange = useCallback((e: NativeSyntheticEvent<TextInputSelectionChangeEventData>) => {
        setSelection(e.nativeEvent.selection);
    }, []);

    const isFormatActive = useCallback((format: string) => {
        if (selection.start === selection.end) return false;

        const selectedText = content.substring(selection.start, selection.end);
        const markers = {
            bold: '**',
            italic: '*',
            underline: '_'
        };

        if (format in markers) {
            const marker = markers[format as keyof typeof markers];
            return selectedText.startsWith(marker) && selectedText.endsWith(marker);
        }

        // For block-level formats
        const currentLine = content.split('\n')[
            content.substring(0, selection.start).split('\n').length - 1
        ];

        switch (format) {
            case 'bullet':
                return currentLine.startsWith('• ');
            case 'number':
                return /^\d+\.\s/.test(currentLine);
            case 'quote':
                return currentLine.startsWith('> ');
            default:
                return false;
        }
    }, [content, selection]);

    const handleFormat = useCallback((type: 'bold' | 'italic' | 'underline' | 'bullet' | 'number' | 'quote' | 'verse') => {
        const markers = {
            bold: '**',
            italic: '*',
            underline: '_'
        };

        if (type in markers) {
            const marker = markers[type as keyof typeof markers];
            const selectedText = content.substring(selection.start, selection.end);

            // Check if the selection is already formatted
            const isFormatted = selectedText.startsWith(marker) &&
                selectedText.endsWith(marker) &&
                selectedText.length >= marker.length * 2;

            if (selection.start === selection.end) {
                // No selection, insert markers and place cursor between them
                const newContent =
                    content.slice(0, selection.start) +
                    marker + marker +
                    content.slice(selection.end);

                setContent(newContent);
                setSelection({
                    start: selection.start + marker.length,
                    end: selection.start + marker.length
                });
            } else if (isFormatted) {
                // Remove formatting
                const unformattedText = selectedText.slice(marker.length, -marker.length);
                const newContent =
                    content.slice(0, selection.start) +
                    unformattedText +
                    content.slice(selection.end);

                setContent(newContent);
                setSelection({
                    start: selection.start,
                    end: selection.start + unformattedText.length
                });
            } else {
                // Add formatting
                const newContent =
                    content.slice(0, selection.start) +
                    marker + selectedText + marker +
                    content.slice(selection.end);

                setContent(newContent);
                setSelection({
                    start: selection.start,
                    end: selection.end + (marker.length * 2)
                });
            }
        } else if (type === 'verse') {
            setShowVerseSelector(true);
        } else {
            // Handle block-level formatting
            const lines = content.split('\n');
            const currentLineIndex = content.substring(0, selection.start).split('\n').length - 1;
            const currentLine = lines[currentLineIndex];

            switch (type) {
                case 'bullet':
                    lines[currentLineIndex] = currentLine.startsWith('• ')
                        ? currentLine.substring(2)
                        : `• ${currentLine}`;
                    break;

                case 'number':
                    lines[currentLineIndex] = currentLine.match(/^\d+\.\s/)
                        ? currentLine.replace(/^\d+\.\s/, '')
                        : `1. ${currentLine}`;
                    break;

                case 'quote':
                    lines[currentLineIndex] = currentLine.startsWith('> ')
                        ? currentLine.substring(2)
                        : `> ${currentLine}`;
                    break;
            }

            setContent(lines.join('\n'));
        }

        // Update formatted content for preview
        setFormattedContent(parseMarkdown(content));
    }, [content, selection]);

    return (
        <>
            <Animated.View style={[styles.modalContainer, containerStyle]}>
                <BlurView intensity={20} style={[StyleSheet.absoluteFill, styles.blurBackground]} />

                <KeyboardAvoidingView
                    style={[styles.container, { paddingTop: insets.top }]}
                    behavior={Platform.OS === 'ios' ? 'padding' : undefined}
                    keyboardVerticalOffset={Platform.OS === 'ios' ? -insets.top : 0}
                >
                    <View style={styles.header}>
                        <TouchableOpacity onPress={handleClose}>
                            <X size={24} color={theme.colors.text.primary} />
                        </TouchableOpacity>
                        {mode === 'edit' && (
                            <TouchableOpacity
                                style={styles.virtuesButton}
                                onPress={onShowVirtueSelector}
                            >
                                <Sparkle size={20} color={theme.colors.primary} />
                                <Text style={styles.virtuesButtonText}>
                                    {selectedVirtues.length === 0 ? 'Select Virtues' : `${selectedVirtues.length} selected`}
                                </Text>
                            </TouchableOpacity>
                        )}
                    </View>

                    {mode === 'read' ? (
                        <ScrollView
                            style={styles.readingContainer}
                            showsVerticalScrollIndicator={false}
                        >
                            <View style={styles.readingHeader}>
                                <View style={styles.readingTitleContainer}>
                                    <Text style={styles.readingTitle}>{title}</Text>
                                    <TouchableOpacity
                                        style={styles.editButton}
                                        onPress={() => setMode('edit')}
                                    >
                                        <PencilLock size={20} color={theme.colors.text.inverse} />
                                    </TouchableOpacity>
                                </View>

                                {selectedVirtues.length > 0 && (
                                    <View style={styles.virtuesContainer}>
                                        {selectedVirtues.map(virtue => (
                                            <View
                                                key={virtue}
                                                style={[
                                                    styles.virtueTag,
                                                    { backgroundColor: `${theme.colors.primary}15` }
                                                ]}
                                            >
                                                <Text style={[
                                                    styles.virtueText,
                                                    { color: theme.colors.primary }
                                                ]}>
                                                    {virtue}
                                                </Text>
                                            </View>
                                        ))}
                                    </View>
                                )}

                                <View style={styles.divider} />
                            </View>

                            <Text style={styles.readingContent}>
                                {formattedContent || content}
                            </Text>
                        </ScrollView>
                    ) : (
                        <>
                            <Animated.View style={[styles.titleContainer, titleStyle]}>
                                <TextInput
                                    ref={titleInputRef}
                                    style={styles.titleInput}
                                    placeholder="Note Title"
                                    value={title}
                                    onChangeText={setTitle}
                                    maxLength={60}
                                />
                            </Animated.View>

                            <Animated.View style={[styles.toolbar, toolbarStyle]}>
                                <FormattingToolbar
                                    onFormat={handleFormat}
                                    onShowHelp={() => setShowFormatHelp(!showFormatHelp)}
                                    activeFormats={['bold', 'italic', 'underline', 'bullet', 'number', 'quote', 'verse']
                                        .filter(format => isFormatActive(format))}
                                />
                            </Animated.View>

                            <ScrollView
                                style={styles.contentContainer}
                                keyboardDismissMode="interactive"
                            >
                                <TextInput
                                    ref={contentInputRef}
                                    style={styles.contentInput}
                                    placeholder="Write your thoughts..."
                                    multiline
                                    value={content}
                                    onChangeText={(text) => {
                                        setContent(text);
                                        setFormattedContent(parseMarkdown(text));
                                    }}
                                    onFocus={handleContentFocus}
                                    onBlur={handleContentBlur}
                                    onSelectionChange={handleSelectionChange}
                                    onKeyPress={handleKeyPress}
                                    selection={selection}
                                />
                            </ScrollView>

                            <View style={[
                                styles.actions,
                                isKeyboardVisible && styles.actionsWithKeyboard
                            ]}>
                                <TouchableOpacity
                                    style={styles.cancelButton}
                                    onPress={() => setMode('read')}
                                >
                                    <Text style={styles.cancelText}>Cancel</Text>
                                </TouchableOpacity>
                                <TouchableOpacity
                                    style={[
                                        styles.saveButton,
                                        (!content.trim() || selectedVirtues.length === 0) && styles.saveButtonDisabled
                                    ]}
                                    onPress={() => {
                                        const cleanContent = content.trim();
                                        if (!cleanContent || selectedVirtues.length === 0) return;
                                        onSubmit({
                                            title: title.trim(),
                                            content: cleanContent,
                                            virtues: selectedVirtues
                                        });
                                    }}
                                    disabled={!content.trim() || selectedVirtues.length === 0}
                                >
                                    <Text style={styles.saveButtonText}>Save Note</Text>
                                </TouchableOpacity>
                            </View>
                        </>
                    )}
                </KeyboardAvoidingView>
            </Animated.View>

            {showVerseSelector && (
                <VerseSelector
                    visible={showVerseSelector}
                    onClose={() => setShowVerseSelector(false)}
                    onSelect={(reference) => {
                        const newContent =
                            content.slice(0, selection.start) +
                            `«${reference}»` +
                            content.slice(selection.end);
                        setContent(newContent);
                        setShowVerseSelector(false);
                    }}
                />
            )}

            {showFormatHelp && (
                <FormatHelp
                    visible={showFormatHelp}
                    onClose={() => setShowFormatHelp(false)}
                />
            )}
        </>
    );
};

const createStyles = (theme: Theme) => StyleSheet.create({
    modalContainer: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 1000,
    },
    blurBackground: {
        backgroundColor: `${theme.colors.background}F0`,
    },
    container: {
        flex: 1,
        backgroundColor: theme.colors.background,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: theme.spacing.md,
    },
    titleContainer: {
        paddingHorizontal: theme.spacing.md,
        marginBottom: theme.spacing.sm,
    },
    titleInput: {
        backgroundColor: theme.colors.surface,
        borderRadius: theme.borderRadius.lg,
        padding: theme.spacing.md,
        ...theme.typography.heading.small,
        color: theme.colors.text.primary,
    },
    toolbar: {
        paddingHorizontal: theme.spacing.md,
        marginBottom: theme.spacing.sm,
    },
    contentContainer: {
        flex: 1,
        backgroundColor: theme.colors.surface,
        margin: theme.spacing.md,
        borderRadius: theme.borderRadius.lg,
    },
    contentInput: {
        flex: 1,
        padding: theme.spacing.md,
        ...theme.typography.body.sans,
        color: theme.colors.text.primary,
        textAlignVertical: 'top',
        minHeight: 200,
    },
    actions: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        padding: theme.spacing.md,
        paddingBottom: theme.spacing.md + Platform.OS === 'ios' ? 20 : 10,
        backgroundColor: theme.colors.background,
        borderTopWidth: StyleSheet.hairlineWidth,
        borderTopColor: theme.colors.border,
        gap: theme.spacing.md,
    },
    actionsWithKeyboard: {
        paddingBottom: Platform.OS === 'ios' ? theme.spacing.xl : theme.spacing.md,
    },
    backButton: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: theme.spacing.xs,
    },
    backText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.primary,
    },
    virtuesContainer: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: theme.spacing.xs,
        marginBottom: theme.spacing.md,
    },
    virtueTag: {
        paddingVertical: 4,
        paddingHorizontal: theme.spacing.sm,
        borderRadius: theme.borderRadius.full,
    },
    virtueText: {
        ...theme.typography.caption.primary,
        fontSize: 12,
    },
    virtuesButton: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: theme.spacing.xs,
        backgroundColor: `${theme.colors.primary}15`,
        paddingHorizontal: theme.spacing.md,
        paddingVertical: theme.spacing.sm,
        borderRadius: theme.borderRadius.full,
    },
    virtuesButtonText: {
        ...theme.typography.caption.primary,
        color: theme.colors.primary,
    },
    title: {
        ...theme.typography.heading.small,
        color: theme.colors.text.primary,
        marginBottom: theme.spacing.md,
    },
    content: {
        ...theme.typography.body.sans,
        color: theme.colors.text.primary,
        lineHeight: 24,
    },
    formatHelp: {
        backgroundColor: theme.colors.surface,
        padding: theme.spacing.md,
        borderRadius: theme.borderRadius.lg,
        marginBottom: theme.spacing.md,
    },
    formatHelpText: {
        ...theme.typography.caption.secondary,
        color: theme.colors.text.secondary,
        lineHeight: 20,
    },
    cancelButton: {
        flex: 1,
        paddingVertical: theme.spacing.sm,
        paddingHorizontal: theme.spacing.lg,
        alignItems: 'center',
        borderRadius: theme.borderRadius.full,
    },
    cancelText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.secondary,
    },
    saveButton: {
        flex: 1,
        backgroundColor: theme.colors.primary,
        paddingVertical: theme.spacing.sm,
        paddingHorizontal: theme.spacing.lg,
        borderRadius: theme.borderRadius.full,
        alignItems: 'center',
        ...Platform.select({
            ios: {
                shadowColor: theme.colors.primary,
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 0.2,
                shadowRadius: 8,
            },
            android: {
                elevation: 4,
            },
        }),
    },
    saveButtonDisabled: {
        opacity: 0.5,
    },
    saveButtonText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.inverse,
    },
    editButton: {
        backgroundColor: theme.colors.primary,
        paddingVertical: theme.spacing.sm,
        paddingHorizontal: theme.spacing.lg,
        borderRadius: theme.borderRadius.full,
        alignItems: 'center',
        marginTop: theme.spacing.lg,
        ...Platform.select({
            ios: {
                shadowColor: theme.colors.primary,
                shadowOffset: { width: 0, height: 4 },
                shadowOpacity: 0.2,
                shadowRadius: 8,
            },
            android: {
                elevation: 4,
            },
        }),
    },
    editText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.inverse,
    },
    // Formatted content styles
    formattedParagraph: {
        marginBottom: theme.spacing.sm,
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
        fontStyle: 'italic',
        backgroundColor: `${theme.colors.primary}08`,
        borderRadius: theme.borderRadius.sm,
        padding: theme.spacing.sm,
    },
    listContainer: {
        marginLeft: theme.spacing.sm,
        marginBottom: theme.spacing.sm,
    },
    listItem: {
        flexDirection: 'row',
        paddingLeft: theme.spacing.md,
        marginBottom: theme.spacing.xs,
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
        paddingRight: theme.spacing.sm,
    },
    // Toolbar specific styles
    toolbarContainer: {
        flexDirection: 'row',
        backgroundColor: theme.colors.surface,
        borderRadius: theme.borderRadius.lg,
        padding: theme.spacing.xs,
        marginBottom: theme.spacing.sm,
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
    toolbarGroup: {
        flexDirection: 'row',
        borderRightWidth: StyleSheet.hairlineWidth,
        borderRightColor: theme.colors.border,
        paddingRight: theme.spacing.sm,
        marginRight: theme.spacing.sm,
    },
    toolbarButton: {
        padding: theme.spacing.xs,
        borderRadius: theme.borderRadius.sm,
        marginRight: theme.spacing.xs,
    },
    toolbarButtonActive: {
        backgroundColor: `${theme.colors.primary}15`,
    },
    helpButton: {
        marginLeft: 'auto',
    },
    readingContainer: {
        flex: 1,
        paddingHorizontal: theme.spacing.lg,
    },
    readingHeader: {
        paddingVertical: theme.spacing.lg,
    },
    readingTitleContainer: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
    },
    readingTitle: {
        flex: 1,
        ...theme.typography.heading.large,
        color: theme.colors.text.primary,
        marginBottom: theme.spacing.sm,
    },
    divider: {
        height: StyleSheet.hairlineWidth,
        backgroundColor: theme.colors.border,
        marginVertical: theme.spacing.md,
    },
    readingContent: {
        ...theme.typography.body.serif,
        color: theme.colors.text.primary,
        fontSize: 18,
        lineHeight: 32,
        marginBottom: theme.spacing.xl * 2,
    },
    readingMeta: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: theme.spacing.lg,
        gap: theme.spacing.sm,
    },
    readingDate: {
        ...theme.typography.caption.secondary,
        color: theme.colors.text.secondary,
    },
});

export default NoteEditor;