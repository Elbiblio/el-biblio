import React, { useState, useMemo } from 'react';
import {
    View,
    Text,
    TouchableOpacity,
    StyleSheet,
    ScrollView,
    Modal,
    Platform,
} from 'react-native';
import { BlurView } from 'expo-blur';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { X, ChevronRight } from '@/components/Icons';

interface VerseSelectorProps {
    visible: boolean;
    onClose: () => void;
    onSelect: (reference: string) => void;
}

interface BibleBook {
    id: string;
    name: string;
    chapters: number;
}

const BIBLE_BOOKS: BibleBook[] = [
    { id: 'gen', name: 'Genesis', chapters: 50 },
    { id: 'exo', name: 'Exodus', chapters: 40 },
    // ... Add all books
];

const VerseSelector: React.FC<VerseSelectorProps> = ({
    visible,
    onClose,
    onSelect,
}) => {
    const theme = useTheme();
    const styles = createStyles(theme);

    const [selectedBook, setSelectedBook] = useState<BibleBook | null>(null);
    const [selectedChapter, setSelectedChapter] = useState<number | null>(null);
    const [selectedVerses, setSelectedVerses] = useState<number[]>([]);
    const [selectionMode, setSelectionMode] = useState<'book' | 'chapter' | 'verse'>('book');

    const handleBookSelect = (book: BibleBook) => {
        setSelectedBook(book);
        setSelectionMode('chapter');
    };

    const handleChapterSelect = (chapter: number) => {
        setSelectedChapter(chapter);
        setSelectionMode('verse');
    };

    const handleVerseSelect = (verse: number) => {
        setSelectedVerses(prev => {
            // Toggle verse selection
            if (prev.includes(verse)) {
                return prev.filter(v => v !== verse);
            }
            // Add verse, keeping array sorted
            const newVerses = [...prev, verse].sort((a, b) => a - b);
            return newVerses;
        });
    };

    const handleConfirm = () => {
        if (!selectedBook || !selectedChapter || selectedVerses.length === 0) return;

        // Format verses (e.g., "John 3:16" or "John 3:16-18")
        const verseRange = selectedVerses.length === 1 
            ? selectedVerses[0].toString()
            : `${selectedVerses[0]}-${selectedVerses[selectedVerses.length - 1]}`;

        const reference = `${selectedBook.name} ${selectedChapter}:${verseRange}`;
        onSelect(reference);
        handleReset();
    };

    const handleReset = () => {
        setSelectedBook(null);
        setSelectedChapter(null);
        setSelectedVerses([]);
        setSelectionMode('book');
        onClose();
    };

    const renderBooks = () => (
        <ScrollView showsVerticalScrollIndicator={false}>
            {BIBLE_BOOKS.map(book => (
                <TouchableOpacity
                    key={book.id}
                    style={styles.item}
                    onPress={() => handleBookSelect(book)}
                >
                    <Text style={styles.itemText}>{book.name}</Text>
                    <ChevronRight size={20} color={theme.colors.text.secondary} />
                </TouchableOpacity>
            ))}
        </ScrollView>
    );

    const renderChapters = () => {
        if (!selectedBook) return null;
        return (
            <ScrollView showsVerticalScrollIndicator={false}>
                {Array.from({ length: selectedBook.chapters }, (_, i) => i + 1).map(chapter => (
                    <TouchableOpacity
                        key={chapter}
                        style={styles.item}
                        onPress={() => handleChapterSelect(chapter)}
                    >
                        <Text style={styles.itemText}>Chapter {chapter}</Text>
                        <ChevronRight size={20} color={theme.colors.text.secondary} />
                    </TouchableOpacity>
                ))}
            </ScrollView>
        );
    };

    const renderVerses = () => {
        if (!selectedBook || !selectedChapter) return null;

        // In a real app, you'd get the actual verse count for the chapter
        const verseCount = 30; // Example count

        return (
            <View style={styles.verseGrid}>
                {Array.from({ length: verseCount }, (_, i) => i + 1).map(verse => (
                    <TouchableOpacity
                        key={verse}
                        style={[
                            styles.verseItem,
                            selectedVerses.includes(verse) && styles.verseItemSelected
                        ]}
                        onPress={() => handleVerseSelect(verse)}
                    >
                        <Text style={[
                            styles.verseText,
                            selectedVerses.includes(verse) && styles.verseTextSelected
                        ]}>
                            {verse}
                        </Text>
                    </TouchableOpacity>
                ))}
            </View>
        );
    };

    const renderHeader = () => (
        <View style={styles.header}>
            <TouchableOpacity onPress={handleReset}>
                <X size={24} color={theme.colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>
                {selectionMode === 'book' ? 'Select Book' :
                 selectionMode === 'chapter' ? `${selectedBook?.name} - Select Chapter` :
                 `${selectedBook?.name} ${selectedChapter} - Select Verses`}
            </Text>
            {selectionMode === 'verse' && selectedVerses.length > 0 && (
                <TouchableOpacity
                    style={styles.confirmButton}
                    onPress={handleConfirm}
                >
                    <Text style={styles.confirmText}>Insert</Text>
                </TouchableOpacity>
            )}
        </View>
    );

    return (
        <Modal
            visible={visible}
            transparent
            animationType="slide"
            onRequestClose={handleReset}
        >
            <BlurView intensity={20} style={StyleSheet.absoluteFill}>
                <View style={styles.container}>
                    {renderHeader()}
                    <View style={styles.content}>
                        {selectionMode === 'book' && renderBooks()}
                        {selectionMode === 'chapter' && renderChapters()}
                        {selectionMode === 'verse' && renderVerses()}
                    </View>
                </View>
            </BlurView>
        </Modal>
    );
};

const createStyles = (theme: Theme) => StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: theme.colors.background,
        marginTop: 100,
        borderTopLeftRadius: theme.borderRadius.xl,
        borderTopRightRadius: theme.borderRadius.xl,
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: theme.spacing.md,
        borderBottomWidth: StyleSheet.hairlineWidth,
        borderBottomColor: theme.colors.border,
    },
    title: {
        ...theme.typography.heading.small,
        color: theme.colors.text.primary,
    },
    content: {
        flex: 1,
        padding: theme.spacing.md,
    },
    item: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: theme.spacing.md,
        borderRadius: theme.borderRadius.lg,
        backgroundColor: theme.colors.surface,
        marginBottom: theme.spacing.sm,
    },
    itemText: {
        ...theme.typography.body.sans,
        color: theme.colors.text.primary,
    },
    verseGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: theme.spacing.sm,
    },
    verseItem: {
        width: 56,
        height: 56,
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: theme.borderRadius.lg,
        backgroundColor: theme.colors.surface,
    },
    verseItemSelected: {
        backgroundColor: theme.colors.primary,
    },
    verseText: {
        ...theme.typography.heading.small,
        color: theme.colors.text.primary,
    },
    verseTextSelected: {
        color: theme.colors.text.inverse,
    },
    confirmButton: {
        backgroundColor: theme.colors.primary,
        paddingHorizontal: theme.spacing.md,
        paddingVertical: theme.spacing.sm,
        borderRadius: theme.borderRadius.full,
    },
    confirmText: {
        ...theme.typography.caption.primary,
        color: theme.colors.text.inverse,
    },
});

export default VerseSelector;