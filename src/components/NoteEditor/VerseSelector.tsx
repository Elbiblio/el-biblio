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
    { id: 'lev', name: 'Leviticus', chapters: 27 },
    { id: 'num', name: 'Numbers', chapters: 36 },
    { id: 'deu', name: 'Deuteronomy', chapters: 34 },
    { id: 'jos', name: 'Joshua', chapters: 24 },
    { id: 'jud', name: 'Judges', chapters: 21 },
    { id: 'rut', name: 'Ruth', chapters: 4 },
    { id: '1sa', name: '1 Samuel', chapters: 31 },
    { id: '2sa', name: '2 Samuel', chapters: 24 },
    { id: '1ki', name: '1 Kings', chapters: 22 },
    { id: '2ki', name: '2 Kings', chapters: 25 },
    { id: '1ch', name: '1 Chronicles', chapters: 29 },
    { id: '2ch', name: '2 Chronicles', chapters: 36 },
    { id: 'ezr', name: 'Ezra', chapters: 10 },
    { id: 'neh', name: 'Nehemiah', chapters: 13 },
    { id: 'est', name: 'Esther', chapters: 10 },
    { id: 'job', name: 'Job', chapters: 42 },
    { id: 'psa', name: 'Psalms', chapters: 150 },
    { id: 'pro', name: 'Proverbs', chapters: 31 },
    { id: 'ecc', name: 'Ecclesiastes', chapters: 12 },
    { id: 'sos', name: 'Song of Solomon', chapters: 8 },
    { id: 'isa', name: 'Isaiah', chapters: 66 },
    { id: 'jer', name: 'Jeremiah', chapters: 52 },
    { id: 'lam', name: 'Lamentations', chapters: 5 },
    { id: 'eze', name: 'Ezekiel', chapters: 48 },
    { id: 'dan', name: 'Daniel', chapters: 12 },
    { id: 'hos', name: 'Hosea', chapters: 14 },
    { id: 'joe', name: 'Joel', chapters: 3 },
    { id: 'amo', name: 'Amos', chapters: 9 },
    { id: 'oba', name: 'Obadiah', chapters: 1 },
    { id: 'jon', name: 'Jonah', chapters: 4 },
    { id: 'mic', name: 'Micah', chapters: 7 },
    { id: 'nah', name: 'Nahum', chapters: 3 },
    { id: 'hab', name: 'Habakkuk', chapters: 3 },
    { id: 'zep', name: 'Zephaniah', chapters: 3 },
    { id: 'hag', name: 'Haggai', chapters: 2 },
    { id: 'zac', name: 'Zechariah', chapters: 14 },
    { id: 'mal', name: 'Malachi', chapters: 4 },
    { id: 'mat', name: 'Matthew', chapters: 28 },
    { id: 'mar', name: 'Mark', chapters: 16 },
    { id: 'luk', name: 'Luke', chapters: 24 },
    { id: 'joh', name: 'John', chapters: 21 },
    { id: 'act', name: 'Acts', chapters: 28 },
    { id: 'rom', name: 'Romans', chapters: 16 },
    { id: '1co', name: '1 Corinthians', chapters: 16 },
    { id: '2co', name: '2 Corinthians', chapters: 13 },
    { id: 'gal', name: 'Galatians', chapters: 6 },
    { id: 'eph', name: 'Ephesians', chapters: 6 },
    { id: 'php', name: 'Philippians', chapters: 4 },
    { id: 'col', name: 'Colossians', chapters: 4 },
    { id: '1th', name: '1 Thessalonians', chapters: 5 },
    { id: '2th', name: '2 Thessalonians', chapters: 3 },
    { id: '1ti', name: '1 Timothy', chapters: 6 },
    { id: '2ti', name: '2 Timothy', chapters: 4 },
    { id: 'tit', name: 'Titus', chapters: 3 },
    { id: 'phm', name: 'Philemon', chapters: 1 },
    { id: 'heb', name: 'Hebrews', chapters: 13 },
    { id: 'jas', name: 'James', chapters: 5 },
    { id: '1pe', name: '1 Peter', chapters: 5 },
    { id: '2pe', name: '2 Peter', chapters: 3 },
    { id: '1jo', name: '1 John', chapters: 5 },
    { id: '2jo', name: '2 John', chapters: 1 },
    { id: '3jo', name: '3 John', chapters: 1 },
    { id: 'jud', name: 'Jude', chapters: 1 },
    { id: 'rev', name: 'Revelation', chapters: 22 },
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