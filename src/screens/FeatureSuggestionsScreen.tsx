import React, { useEffect, useMemo, useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, TextInput, Modal, Animated, useWindowDimensions, Pressable, KeyboardAvoidingView, Platform, ScrollView } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { Star } from '@/components/Icons';
import { toast } from 'sonner-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuthStore, useFeatureSuggestionsStore } from '@/stores/StoreProvider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import * as Haptics from 'expo-haptics';

type Props = NativeStackScreenProps<RootStackParamList, 'FeatureSuggestionsScreen'>;

const FeatureSuggestionsScreen: React.FC<Props> = ({ navigation }) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuthStore();
  const store = useFeatureSuggestionsStore();

  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const pages = useMemo(() => (
    [
      { key: 'new', label: 'New', status: 'all' as const },
      { key: 'proposed', label: 'Proposed', status: 'proposed' as const },
      { key: 'planned', label: 'Planned', status: 'planned' as const },
    ]
  ), []);
  const [pageIndex, setPageIndex] = useState(0);
  const listRef = React.useRef<FlatList<any>>(null);
  const [refreshing, setRefreshing] = useState(false);
  const titleOpacity = useRef(new Animated.Value(1)).current;
  const headerContentOpacity = useRef(new Animated.Value(1)).current;
  const dotsScale = useRef(new Animated.Value(1)).current;
  const contentAnim = useRef(new Animated.Value(1)).current;
  const [sortMode, setSortMode] = useState<'newest' | 'votes'>('newest');
  const { width: windowWidth } = useWindowDimensions();
  const pageWidth = Math.max(320, windowWidth);
  const pageBgColors = useMemo(() => [
    'rgba(100, 150, 255, 0.06)',
    'rgba(140, 200, 180, 0.06)',
    'rgba(255, 200, 120, 0.06)'
  ], []);

  const counts = useMemo(() => {
    const all = store.items.length;
    const proposed = store.items.filter(i => i.status === 'proposed').length;
    const planned = store.items.filter(i => i.status === 'planned' || i.status === 'accepted').length;
    return { all, proposed, planned };
  }, [store.items]);

  useEffect(() => {
    store.fetchSuggestions();
  }, []);

  const canSubmit = store.canSubmit(user);
  const canVote = store.canVote(user);
  const canUse = store.canUseFeature(user);
  const isBoot = store.items.length === 0 && !refreshing;

  useEffect(() => {
    Animated.sequence([
      Animated.timing(titleOpacity, { toValue: 0.2, duration: 100, useNativeDriver: true }),
      Animated.timing(titleOpacity, { toValue: 1, duration: 120, useNativeDriver: true }),
    ]).start();
    Animated.sequence([
      Animated.timing(dotsScale, { toValue: 1.1, duration: 90, useNativeDriver: true }),
      Animated.spring(dotsScale, { toValue: 1, useNativeDriver: true, friction: 5, tension: 120 }),
    ]).start();
    contentAnim.setValue(0);
    Animated.timing(contentAnim, { toValue: 1, duration: 160, useNativeDriver: true }).start();
  }, [pageIndex, sortMode]);

  const getItemsFor = useCallback((status: 'all' | 'proposed' | 'planned', sort: 'newest' | 'votes') => {
    let items = [...store.items];
    if (status !== 'all') {
      if (status === 'planned') {
        items = items.filter(i => i.status === 'planned' || i.status === 'accepted');
      } else {
        items = items.filter(i => i.status === status);
      }
    }
    if (sort === 'newest') items.sort((a,b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    else items.sort((a,b) => (b.votesCount ?? 0) - (a.votesCount ?? 0));
    return items;
  }, [store.items]);

  const listFooterForSuggestions = useMemo(
    () =>
      (!canSubmit || !canVote) ? (
        <View style={{ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 24 }}>
          <Text style={styles.gateHint}>
            {!canVote ? 'Voting unlocks at 100 pts. ' : ''}
            {!canSubmit ? 'Suggesting unlocks at 1000 pts.' : ''}
          </Text>
        </View>
      ) : <View style={{ height: 12 }} />,
    [canSubmit, canVote, styles.gateHint]
  );

  const renderSuggestionItem = useCallback(
    ({ item: sug }: { item: { id: string; title: string; createdAt: string; status: string; eta?: string; votesCount?: number; tags?: string[] } }) => (
      <Pressable
        style={({ pressed }) => [
          styles.card,
          pressed && { transform: [{ scale: 0.98 }] },
        ]}
        onPress={() => navigation.navigate('FeatureSuggestionDetailScreen', { id: sug.id })}
      >
        <View style={{ flex: 1 }}>
          <Text style={styles.cardTitle}>{sug.title}</Text>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 6, flexWrap: 'wrap' }}>
            <Text style={styles.cardMeta}>{new Date(sug.createdAt).toLocaleDateString()}</Text>
            {sug.status === 'planned' && !!sug.eta && (
              <View style={styles.badgeDate}>
                <Text style={styles.badgeDateText}>{new Date(sug.eta).toLocaleDateString()}</Text>
              </View>
            )}
            {(sug.status === 'planned' || sug.status === 'accepted') && (
              <View style={[styles.badge, sug.status === 'planned' ? styles.badgePlanned : styles.badgeAccepted]}>
                <Text style={styles.badgeText}>{sug.status === 'planned' ? 'Planned' : 'Accepted'}</Text>
              </View>
            )}
            {!!(sug as any).tags?.length && (
              <View style={styles.tagsRow}>
                {(() => {
                  const tags = (sug as any).tags as string[];
                  const shown = tags.slice(0, 2);
                  const extra = Math.max(0, tags.length - 2);
                  return (
                    <>
                      {shown.map((t: string) => (
                        <View key={t} style={styles.tag}><Text style={styles.tagText}>{t}</Text></View>
                      ))}
                      {extra > 0 && (<View style={styles.tag}><Text style={styles.tagText}>+{extra}</Text></View>)}
                    </>
                  );
                })()}
              </View>
            )}
          </View>
        </View>
        <View style={styles.voteGroup}>
          {(() => {
            const countScale = new Animated.Value(1);
            const bump = () => {
              countScale.setValue(1);
              Animated.sequence([
                Animated.timing(countScale, { toValue: 1.2, duration: 90, useNativeDriver: true }),
                Animated.spring(countScale, { toValue: 1, friction: 6, tension: 120, useNativeDriver: true }),
              ]).start();
            };
            return (
              <>
                <Pressable
                  style={({ pressed }) => [
                    styles.voteBtn,
                    store.myVotes.has(sug.id) && styles.voteBtnActive,
                    pressed && { transform: [{ scale: 0.97 }] },
                  ]}
                  onPress={() => {
                    if (!canVote) {
                      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
                      toast.error('Voting unlocks at 100 points. Keep engaging to vote.');
                      return;
                    }
                    Haptics.selectionAsync();
                    if (store.myVotes.has(sug.id)) {
                      store.unvote(user, sug.id);
                    } else {
                      store.vote(user, sug.id);
                    }
                    bump();
                  }}
                >
                  <Text style={[styles.voteText, store.myVotes.has(sug.id) && styles.voteTextActive]}>{store.myVotes.has(sug.id) ? 'Voted' : 'Vote'}</Text>
                </Pressable>
                <Animated.Text style={[styles.votesCount, { transform: [{ scale: countScale }] }]}>{sug.votesCount}</Animated.Text>
              </>
            );
          })()}
        </View>
      </Pressable>
    ),
    [navigation, styles.card, styles.cardTitle, styles.cardMeta, styles.badgeDate, styles.badgeDateText, styles.badge, styles.badgePlanned, styles.badgeAccepted, styles.badgeText, styles.tagsRow, styles.tag, styles.tagText, styles.voteGroup, styles.voteBtn, styles.voteBtnActive, styles.voteText, styles.voteTextActive, styles.votesCount, store, user, canVote]
  );

  const renderPageItem = useCallback(
    ({ item }: { item: { key: string; label: string; status: 'all' | 'proposed' | 'planned' } }) => {
      const data = getItemsFor(item.status, sortMode);
      return (
        <Animated.View
          style={{
            width: pageWidth,
            opacity: contentAnim,
            transform: [{
              translateY: contentAnim.interpolate({ inputRange: [0, 1], outputRange: [6, 0] }),
            }],
          }}
        >
          <FlatList
            data={data}
            keyExtractor={(s: { id: string }) => s.id}
            contentContainerStyle={{ padding: 16, gap: 10, minHeight: 300, flexGrow: 1, paddingBottom: 16 + (canSubmit ? 96 : 32) + (insets.bottom || 0) }}
            refreshing={refreshing}
            onRefresh={async () => {
              try {
                setRefreshing(true);
                await store.fetchSuggestions();
              } finally {
                setRefreshing(false);
              }
            }}
            onScroll={(e) => {
              const y = e.nativeEvent.contentOffset.y;
              const target = y > 8 ? 0 : 1;
              Animated.timing(headerContentOpacity, { toValue: target, duration: 120, useNativeDriver: true }).start();
            }}
            scrollEventThrottle={16}
            ListEmptyComponent={
              <View style={styles.emptyWrap}>
                {isBoot || refreshing ? (
                  <>
                    <View style={styles.skelCard} />
                    <View style={styles.skelCard} />
                    <View style={styles.skelCard} />
                  </>
                ) : (
                  <>
                    <Text style={styles.emptyTitle}>No {item.label.toLowerCase()} items</Text>
                    <Text style={styles.emptyText}>We haven't got anything in {item.label} yet. Check back soon or start the conversation.</Text>
                    {!canSubmit && (
                      <Text style={[styles.emptyText, { marginTop: 6 }]}>Earn 1000 points to suggest features. Voting unlocks at 100 points.</Text>
                    )}
                    <View style={{ flexDirection: 'row', gap: 10, marginTop: 12 }}>
                      <TouchableOpacity style={[styles.action, styles.secondary]} onPress={() => store.fetchSuggestions()}>
                        <Text style={styles.secondaryText}>Refresh</Text>
                      </TouchableOpacity>
                      {canSubmit ? (
                        <TouchableOpacity style={[styles.primary]} onPress={() => setShowCreate(true)}>
                          <Text style={styles.primaryText}>Suggest a feature</Text>
                        </TouchableOpacity>
                      ) : null}
                    </View>
                  </>
                )}
              </View>
            }
            renderItem={renderSuggestionItem}
            ListFooterComponent={listFooterForSuggestions}
          />
        </Animated.View>
      );
    },
    [getItemsFor, sortMode, contentAnim, pageWidth, insets.bottom, canSubmit, isBoot, refreshing, styles.emptyWrap, styles.skelCard, styles.emptyTitle, styles.emptyText, styles.action, styles.secondary, styles.primary, styles.primaryText, styles.secondaryText, renderSuggestionItem, listFooterForSuggestions, store, setShowCreate]
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={[styles.bgTop, { backgroundColor: pageBgColors[pageIndex] }]} />
      <View style={styles.headerRow}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}><Text style={styles.backText}>Back</Text></TouchableOpacity>
        <Text style={styles.title}>Feature suggestions</Text>
        <View style={{ width: 48 }} />
      </View>
      <View style={styles.headerDivider} />

      {!canUse ? (
        <Text style={styles.info}>Login required to view suggestions.</Text>
      ) : (
        <>
          <View style={styles.pagerHeader}>
            <Animated.Text numberOfLines={1} ellipsizeMode="tail" style={[styles.pagerTitle, { opacity: Animated.multiply(titleOpacity, headerContentOpacity) }] }>
              {pages[pageIndex]?.label}
            </Animated.Text>
            <View style={styles.sortGroup}>
              <TouchableOpacity
                accessibilityLabel="Sort by newest"
                onPress={() => { setSortMode('newest'); Haptics.selectionAsync(); }}
                style={[styles.sortIconBtn, sortMode==='newest' && styles.sortBtnActive]}
              >
                <FeatherIcon name="clock" size={20} color={sortMode==='newest' ? theme.colors.primary : theme.colors.text.secondary} />
              </TouchableOpacity>
              <TouchableOpacity
                accessibilityLabel="Sort by most votes"
                onPress={() => { setSortMode('votes'); Haptics.selectionAsync(); }}
                style={[styles.sortIconBtn, sortMode==='votes' && styles.sortBtnActive]}
              >
                <Star size={20} color={sortMode==='votes' ? theme.colors.primary : theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>
            {canSubmit ? (
              <TouchableOpacity style={styles.primary} onPress={() => setShowCreate(true)}>
                <Text style={styles.primaryText}>New</Text>
              </TouchableOpacity>
            ) : (
              <View style={{ width: 64 }} />
            )}
          </View>
          

          {/* Removed insight chips to reduce visual noise. Gating hint moved to footer. */}

          <FlatList
            ref={listRef}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            data={pages}
            keyExtractor={(p) => p.key}
            style={{ width: pageWidth }}
            snapToInterval={pageWidth}
            snapToAlignment="start"
            decelerationRate="fast"
            disableIntervalMomentum
            initialNumToRender={3}
            removeClippedSubviews={false}
            getItemLayout={(_, index) => ({ length: pageWidth, offset: pageWidth * index, index })}
            onMomentumScrollEnd={(e) => {
              const idx = Math.round(e.nativeEvent.contentOffset.x / e.nativeEvent.layoutMeasurement.width);
              if (!Number.isNaN(idx)) {
                setPageIndex(idx);
                Haptics.selectionAsync();
              }
            }}
            renderItem={renderPageItem}
          />

          <Modal visible={showCreate} animationType="slide" transparent onRequestClose={() => setShowCreate(false)}>
            <KeyboardAvoidingView style={styles.modalBackdrop} behavior={Platform.OS === 'ios' ? 'padding' : undefined} keyboardVerticalOffset={0}>
              <View style={styles.modalContent}>
                <Text style={styles.modalTitle}>Suggest a Feature</Text>
                <ScrollView keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false} contentContainerStyle={{ gap: 12 }}>
                  <TextInput placeholder="Title" placeholderTextColor={theme.colors.text.tertiary} value={title} onChangeText={setTitle} style={styles.input} />
                  <TextInput placeholder="Describe your idea (markdown ok)" placeholderTextColor={theme.colors.text.tertiary} value={desc} onChangeText={setDesc} style={[styles.input, { height: 120 }]} multiline />
                </ScrollView>
                <View style={styles.modalActions}>
                  <TouchableOpacity style={[styles.action, styles.secondary]} onPress={() => setShowCreate(false)}>
                    <Text style={styles.secondaryText}>Cancel</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.action, styles.primary]}
                    onPress={async () => {
                      if (!title.trim() || !desc.trim()) return;
                      try {
                        await store.createSuggestion(user, { title: title.trim(), description: desc.trim() });
                        setTitle('');
                        setDesc('');
                        setShowCreate(false);
                        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                      } catch {}
                    }}
                  >
                    <Text style={styles.primaryText}>Submit</Text>
                  </TouchableOpacity>
                </View>
              </View>
            </KeyboardAvoidingView>
          </Modal>

          {canSubmit && (
            <TouchableOpacity style={[styles.fab, { bottom: 24 + (insets.bottom || 0) }]} activeOpacity={0.9} onPress={() => setShowCreate(true)}>
              <Text style={styles.fabText}>＋</Text>
            </TouchableOpacity>
          )}
        </>
      )}
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background },
  headerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 12 },
  headerDivider: { height: StyleSheet.hairlineWidth, backgroundColor: theme.colors.border },
  backBtn: { paddingHorizontal: 10, paddingVertical: 8, borderRadius: 10, backgroundColor: theme.colors.surface },
  backText: { color: theme.colors.text.primary },
  title: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 18 },
  subtitle: { color: theme.colors.text.primary, fontWeight: '700' },
  info: { color: theme.colors.text.secondary, padding: 16 },
  toolbar: { paddingHorizontal: 16, paddingBottom: 8, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  pagerHeader: { paddingHorizontal: 8, paddingBottom: 2, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', gap: 6 },
  pagerTitle: { color: theme.colors.text.primary, fontWeight: '700', fontSize: 14, flex: 1, textAlign: 'center' },
  caretBtn: { width: 36, height: 36, borderRadius: 18, alignItems: 'center', justifyContent: 'center', backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  caretDisabled: { opacity: 0.4 },
  caretText: { color: theme.colors.text.primary, fontSize: 20, fontWeight: '800', marginTop: -2 },
  pagerDotsRow: { flexDirection: 'row', justifyContent: 'center', gap: 6, paddingVertical: 6 },
  dot: { width: 6, height: 6, borderRadius: 3 },
  dotInactive: { backgroundColor: theme.colors.border },
  dotActive: { backgroundColor: theme.colors.primary },
  bgTop: { position: 'absolute', top: 0, left: 0, right: 0, height: 96 },
  insightRow: { flexDirection: 'row', justifyContent: 'center', alignItems: 'center', gap: 8, paddingHorizontal: 12, paddingBottom: 4 },
  chip: { paddingVertical: 6, paddingHorizontal: 10, borderRadius: 999, backgroundColor: theme.colors.surface, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border },
  chipActive: { backgroundColor: `${theme.colors.primary}12`, borderColor: theme.colors.primary },
  chipText: { color: theme.colors.text.secondary, fontWeight: '600' },
  chipTextActive: { color: theme.colors.primary },
  gateHint: { color: theme.colors.text.tertiary, textAlign: 'center', marginTop: 4, fontSize: 12 },
  sortGroup: { flexDirection: 'row', backgroundColor: theme.colors.surface, borderRadius: 999, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, overflow: 'hidden' },
  sortBtn: { paddingVertical: 4, paddingHorizontal: 8 },
  sortBtnActive: { backgroundColor: `${theme.colors.primary}12` },
  sortText: { color: theme.colors.text.secondary, fontWeight: '600', fontSize: 12 },
  sortTextActive: { color: theme.colors.primary },
  sortIconBtn: { paddingVertical: 10, paddingHorizontal: 12 },
  sortIcon: { fontSize: 16, color: theme.colors.text.secondary },
  segmented: { flexDirection: 'row', backgroundColor: theme.colors.surface, borderRadius: 10, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, overflow: 'hidden' },
  segmentBtn: { paddingVertical: 8, paddingHorizontal: 10 },
  segmentText: { color: theme.colors.text.secondary, fontWeight: '600' },
  segmentActive: { backgroundColor: `${theme.colors.primary}12` },
  segmentTextActive: { color: theme.colors.primary },
  form: { paddingHorizontal: 16, gap: 8, paddingBottom: 8 },
  input: { backgroundColor: theme.colors.surface, borderColor: theme.colors.border, borderWidth: StyleSheet.hairlineWidth, borderRadius: 10, padding: 10, color: theme.colors.text.primary },
  primary: { backgroundColor: theme.colors.primary, borderRadius: 12, paddingHorizontal: 14, paddingVertical: 10 },
  primaryText: { color: theme.colors.text.inverse, fontWeight: '700' },
  hint: { color: theme.colors.text.secondary },
  fab: { position: 'absolute', right: 16, bottom: 24, width: 52, height: 52, borderRadius: 26, backgroundColor: theme.colors.primary, alignItems: 'center', justifyContent: 'center', shadowColor: '#000', shadowOpacity: 0.15, shadowRadius: 6, elevation: 4 },
  fabText: { color: theme.colors.text.inverse, fontSize: 28, marginTop: -2 },
  card: { flexDirection: 'row', alignItems: 'center', gap: 12, backgroundColor: theme.colors.surface, borderRadius: 12, borderWidth: 0, borderColor: 'transparent', padding: 12, shadowColor: '#000', shadowOpacity: 0.08, shadowRadius: 8, shadowOffset: { width: 0, height: 3 }, elevation: 2 },
  cardTitle: { color: theme.colors.text.primary, fontWeight: '700' },
  cardMeta: { color: theme.colors.text.secondary },
  badge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999 },
  badgePlanned: { backgroundColor: `${theme.colors.warning}22` },
  badgeAccepted: { backgroundColor: `${theme.colors.success}22` },
  badgeText: { color: theme.colors.text.secondary, fontWeight: '700' },
  badgeDate: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999, backgroundColor: `${theme.colors.primary}10` },
  badgeDateText: { color: theme.colors.text.secondary, fontWeight: '600' },
  tagsRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  tag: { backgroundColor: `${theme.colors.primary}10`, paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999 },
  tagText: { color: theme.colors.text.secondary, fontWeight: '600' },
  voteGroup: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  voteBtn: { borderRadius: 999, borderWidth: 1, borderColor: theme.colors.border, paddingVertical: 6, paddingHorizontal: 10, backgroundColor: theme.colors.background },
  voteBtnActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}15` },
  voteText: { color: theme.colors.text.secondary },
  voteTextActive: { color: theme.colors.primary, fontWeight: '700' },
  votesCount: { color: theme.colors.text.primary, fontWeight: '700', minWidth: 28, textAlign: 'center' },
  skelCard: { height: 84, width: '100%', borderRadius: 12, backgroundColor: theme.colors.surface, borderColor: theme.colors.border, borderWidth: StyleSheet.hairlineWidth, opacity: 0.6 },
  emptyWrap: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingVertical: 40 },
  emptyTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 16 },
  emptyText: { color: theme.colors.text.secondary, marginTop: 4 },
  modalBackdrop: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', alignItems: 'center', justifyContent: 'center', padding: 16 },
  modalContent: { width: '100%', maxWidth: 380, backgroundColor: theme.colors.surface, borderRadius: 12, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, padding: 16 },
  modalTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 18, marginBottom: 8 },
  modalActions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 10, marginTop: 12 },
  action: { borderRadius: 10, paddingHorizontal: 14, paddingVertical: 10 },
  secondary: { backgroundColor: theme.colors.background, borderWidth: 1, borderColor: theme.colors.border },
  secondaryText: { color: theme.colors.text.secondary, fontWeight: '600' },
});

export default FeatureSuggestionsScreen;
