import React, { useEffect, useMemo, useRef } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView, Pressable, Animated } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { useAuthStore, useFeatureSuggestionsStore } from '@/stores/StoreProvider';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { RootStackParamList } from '@/types';
import * as Haptics from 'expo-haptics';

type Props = NativeStackScreenProps<RootStackParamList, 'FeatureSuggestionDetailScreen'>;

const FeatureSuggestionDetailScreen: React.FC<Props> = ({ navigation, route }) => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuthStore();
  const store = useFeatureSuggestionsStore();
  const { id } = route.params;

  const item = store.items.find((x) => x.id === id);
  const canVote = store.canVote(user);

  useEffect(() => {
    if (!item) {
      store.fetchSuggestions().catch(() => undefined);
    }
  }, [id]);

  if (!item) {
    return (
      <View style={styles.container}>
        <View style={styles.headerRow}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}><Text style={styles.backText}>Back</Text></TouchableOpacity>
          <Text style={styles.title}>Feature</Text>
          <View style={{ width: 48 }} />
        </View>
        <Text style={styles.info}>Loading…</Text>
      </View>
    );
  }

  const voted = store.myVotes.has(item.id);

  const countScale = useRef(new Animated.Value(1)).current;
  const scrollY = useRef(new Animated.Value(0)).current;
  const heroScale = scrollY.interpolate({ inputRange: [0, 120], outputRange: [1, 0.96], extrapolate: 'clamp' });
  const heroTranslateY = scrollY.interpolate({ inputRange: [0, 120], outputRange: [0, -8], extrapolate: 'clamp' });
  const heroOpacity = scrollY.interpolate({ inputRange: [0, 120], outputRange: [1, 0.92], extrapolate: 'clamp' });
  // Animate title scale instead of fontSize to use native driver
  const titleScale = scrollY.interpolate({ inputRange: [0, 120], outputRange: [1, 0.79], extrapolate: 'clamp' });

  return (
    <View style={styles.container}>
      <View style={styles.headerRow}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}><Text style={styles.backText}>Back</Text></TouchableOpacity>
        <Text style={styles.title}>Feature</Text>
        <View style={{ width: 48 }} />
      </View>

      <Animated.ScrollView
        onScroll={Animated.event([{ nativeEvent: { contentOffset: { y: scrollY } } }], { useNativeDriver: true })}
        scrollEventThrottle={16}
        contentContainerStyle={{ padding: 16, paddingBottom: 32 }}
      >
        <Animated.View style={[
          styles.hero,
          { transform: [{ translateY: heroTranslateY }, { scale: heroScale }], opacity: heroOpacity },
        ]}>
          <View style={styles.heroAccent} />
          <View style={styles.heroHeaderRow}>
            <Animated.Text numberOfLines={2} style={[styles.detailTitle, { flex: 1, transform: [{ scale: titleScale }] }]}>{item.title}</Animated.Text>
            <Pressable
              style={({ pressed }) => [
                styles.heroVotePill,
                voted ? styles.heroVoteActive : styles.heroVotePrimary,
                pressed && { transform: [{ scale: 0.98 }] },
              ]}
              disabled={!canVote}
              onPress={() => {
                Haptics.selectionAsync();
                if (voted) {
                  store.unvote(user, item.id);
                } else {
                  store.vote(user, item.id);
                }
                countScale.setValue(1);
                Animated.sequence([
                  Animated.timing(countScale, { toValue: 1.2, duration: 90, useNativeDriver: true }),
                  Animated.spring(countScale, { toValue: 1, friction: 6, tension: 120, useNativeDriver: true }),
                ]).start();
              }}
            >
              <Text style={[voted ? styles.heroVoteTextActive : styles.heroVoteTextPrimary]}>{voted ? 'Voted' : 'Vote'}</Text>
              <Animated.Text style={[styles.heroVoteCount, { transform: [{ scale: countScale }] }]}>{item.votesCount}</Animated.Text>
            </Pressable>
          </View>
          <View style={styles.metaRow}>
            <Text style={styles.detailMeta}>{new Date(item.createdAt).toLocaleDateString()}</Text>
            {(item.status === 'planned' || item.status === 'accepted') && (
              <View style={[styles.badge, item.status==='planned' ? styles.badgePlanned : styles.badgeAccepted]}>
                <Text style={styles.badgeText}>{item.status === 'planned' ? 'Planned' : 'Accepted'}</Text>
              </View>
            )}
            {!!item.eta && (
              <View style={styles.badgeEta}><Text style={styles.badgeEtaText}>{new Date(item.eta).toLocaleDateString()}</Text></View>
            )}
          </View>
          {!!(item as any).tags?.length && (
            <View style={styles.tagsRow}>
              {((item as any).tags as string[]).slice(0,3).map(t => (
                <View key={t} style={styles.tag}><Text style={styles.tagText}>{t}</Text></View>
              ))}
            </View>
          )}
        </Animated.View>

        {item.adminNotes ? <Text style={styles.detailNotes}>{item.adminNotes}</Text> : null}
        <Text style={styles.detailBody}>{item.description}</Text>
      </Animated.ScrollView>

      {/* Footer removed to avoid duplication; vote is now in hero */}
    </View>
  );
};

const createStyles = (theme: ReturnType<typeof useTheme>) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme.colors.background },
  headerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 12 },
  backBtn: { paddingHorizontal: 10, paddingVertical: 8, borderRadius: 10, backgroundColor: theme.colors.surface },
  backText: { color: theme.colors.text.primary },
  title: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 18 },
  info: { color: theme.colors.text.secondary, padding: 16 },
  hero: { backgroundColor: theme.colors.surface, borderRadius: 12, padding: 16, paddingTop: 20, borderWidth: StyleSheet.hairlineWidth, borderColor: theme.colors.border, shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 8, shadowOffset: { width: 0, height: 3 }, elevation: 2, position: 'relative' },
  detailTitle: { color: theme.colors.text.primary, fontWeight: '800', fontSize: 24 },
  metaRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 6, flexWrap: 'wrap' },
  detailMeta: { color: theme.colors.text.secondary },
  badge: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999 },
  badgePlanned: { backgroundColor: `${theme.colors.warning}22` },
  badgeAccepted: { backgroundColor: `${theme.colors.success}22` },
  badgeText: { color: theme.colors.text.secondary, fontWeight: '700' },
  badgeEta: { paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999, backgroundColor: `${theme.colors.primary}10` },
  badgeEtaText: { color: theme.colors.text.secondary, fontWeight: '600' },
  tagsRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 8 },
  tag: { backgroundColor: `${theme.colors.primary}10`, paddingHorizontal: 8, paddingVertical: 4, borderRadius: 999 },
  tagText: { color: theme.colors.text.secondary, fontWeight: '600' },
  detailNotes: { color: theme.colors.text.secondary, marginTop: 12 },
  detailBody: { color: theme.colors.text.primary, marginTop: 12, lineHeight: 20 },
  heroAccent: { position: 'absolute', top: 0, left: 0, right: 0, height: 4, backgroundColor: theme.colors.primary, borderTopLeftRadius: 12, borderTopRightRadius: 12 },
  heroHeaderRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  heroVotePill: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingVertical: 8, paddingHorizontal: 12, borderRadius: 999, borderWidth: 1, borderColor: theme.colors.border, backgroundColor: theme.colors.background, shadowColor: '#000', shadowOpacity: 0.08, shadowRadius: 6, shadowOffset: { width: 0, height: 2 }, elevation: 2 },
  heroVotePrimary: { backgroundColor: theme.colors.primary, borderColor: theme.colors.primary },
  heroVoteActive: { backgroundColor: `${theme.colors.primary}15`, borderColor: theme.colors.primary },
  heroVoteTextPrimary: { color: theme.colors.text.inverse, fontWeight: '700' },
  heroVoteTextActive: { color: theme.colors.primary, fontWeight: '700' },
  heroVoteCount: { color: theme.colors.text.primary, fontWeight: '800' },
  footer: { flexDirection: 'row', alignItems: 'center', justifyContent: 'flex-end', padding: 16, gap: 8 },
  voteBtn: { borderRadius: 999, borderWidth: 1, borderColor: theme.colors.border, paddingVertical: 10, paddingHorizontal: 18, backgroundColor: theme.colors.background, shadowColor: '#000', shadowOpacity: 0.06, shadowRadius: 6, shadowOffset: { width: 0, height: 2 }, elevation: 1 },
  voteBtnPrimary: { backgroundColor: theme.colors.primary, borderColor: theme.colors.primary },
  voteBtnActive: { borderColor: theme.colors.primary, backgroundColor: `${theme.colors.primary}15` },
  voteText: { color: theme.colors.text.secondary },
  voteTextPrimary: { color: theme.colors.text.inverse, fontWeight: '700' },
  voteTextActive: { color: theme.colors.primary, fontWeight: '700' },
  votesCount: { color: theme.colors.text.primary, fontWeight: '700', minWidth: 28, textAlign: 'center' },
  votesCountBold: { color: theme.colors.text.primary, fontWeight: '800', minWidth: 32, textAlign: 'center' },
});

export default FeatureSuggestionDetailScreen;
