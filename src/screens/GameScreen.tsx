import React, { useEffect, useMemo } from 'react';
import { observer } from 'mobx-react-lite';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useFocusEffect, useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import { BookOpen, Trophy, Lightning, Flame, ChevronRight } from '@/components/Icons';
import { RootStackParamList, GameId } from '@/types';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useTheme } from '@/contexts/ThemeContext';
import { useGameStore, useLeaderboardStore } from '@/stores/StoreProvider';
import { useAuth } from '@/stores/auth';
import { useGameBadgeStore } from '@/stores/GameBadgeStore';

const GameScreen: React.FC = () => {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const gameStore = useGameStore();
  const leaderboardStore = useLeaderboardStore();
  const authStore = useAuth();
  const gameBadgeStore = useGameBadgeStore();

  const { user } = authStore;
  
  // Clear games badge when opening this screen
  useFocusEffect(React.useCallback(() => {
    gameBadgeStore.clearBadge();
  }, [gameBadgeStore]));

  useEffect(() => {
    // Load motivating stats and ensure latest rank is tracked
    const load = async () => {
      if (user?.id) {
        await leaderboardStore.fetchUserStats(user.id);
        const rankResp = await leaderboardStore.fetchUserRank(user.id, 'all');
        if (rankResp?.rank) gameBadgeStore.updateRank('all', rankResp.rank);
      }
    };
    load();
  }, [user?.id, leaderboardStore, gameBadgeStore]);

  const tiles: Array<{ icon: any; title: string; subtitle: string; color: string; route: keyof RootStackParamList; bestKey: GameId; }>= [
    { icon: BookOpen, title: 'Verse Builder', subtitle: 'Assemble the verse', color: theme?.colors.primary, route: 'VerseBuilderScreen', bestKey: 'verse_builder' },
    { icon: Flame, title: 'Virtue Trivia', subtitle: 'Test your knowledge', color: theme?.colors.secondary, route: 'VirtueTriviaScreen', bestKey: 'virtue_trivia' },
    { icon: Lightning, title: 'Virtue Quiz', subtitle: 'Level up your virtue', color: theme?.colors.success, route: 'VirtueQuizScreen', bestKey: 'virtue_quiz' },
  ];

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Play & Grow</Text>
      <Text style={styles.subtitle}>Sharpen your knowledge, build memory, and climb the charts.</Text>

      <View style={styles.tiles}>
        {tiles.map((t) => {
          const best = gameStore.getPersonalBest(t.bestKey) || 0;
          return (
            <TouchableOpacity key={t.title} style={styles.tile} activeOpacity={0.85}
              onPress={() => navigation.navigate(t.route as any)}>
              <LinearGradient colors={[`${t.color}18`, `${t.color}08`]} style={styles.tileGradient} start={{x:0,y:0}} end={{x:1,y:1}} />
              <View style={[styles.tileIcon, { backgroundColor: `${t.color}16` }]}>
                <t.icon size={22} color={t.color} />
              </View>
              <View style={styles.tileContent}>
                <Text style={[styles.tileTitle, { color: t.color }]}>{t.title}</Text>
                <Text style={styles.tileSubtitle}>{t.subtitle}</Text>
                <View style={styles.bestRow}>
                  <Trophy size={14} color={theme?.colors.text.secondary} />
                  <Text style={styles.bestText}>Personal best: {best}</Text>
                </View>
              </View>
              <ChevronRight size={18} color={theme?.colors.text.secondary} />
            </TouchableOpacity>
          );
        })}
      </View>

      <View style={styles.statsCard}>
        <LinearGradient colors={[`${theme?.colors.primary}12`, `${theme?.colors.primary}04`]} style={styles.statsGradient} />
        <Text style={styles.statsTitle}>Your Momentum</Text>
        <View style={styles.statsRow}>
          <Stat label="Total Points" value={`${leaderboardStore.userStats?.totalPoints ?? 0}`} />
          <Stat label="Active Days" value={`${leaderboardStore.userStats?.totalActiveDays ?? 0}`} />
          <Stat label="Streak" value={`${leaderboardStore.userStats?.currentStreak ?? 0} 🔥`} />
        </View>
        <TouchableOpacity style={styles.cta} onPress={() => navigation.navigate('LeaderboardScreen')}>
          <Text style={styles.ctaText}>View Full Leaderboard</Text>
          <ChevronRight size={16} color={'#fff'} />
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const Stat = ({ label, value }: { label: string; value: string }) => {
  const theme = useTheme();
  return (
    <View style={{ alignItems: 'center', flex: 1 }}>
      <Text style={{ color: theme?.colors.text.secondary, fontSize: 12 }}>{label}</Text>
      <Text style={{ color: theme?.colors.text.primary, fontSize: 18, fontWeight: '700', marginTop: 4 }}>{value}</Text>
    </View>
  );
};

const createStyles = (theme: any) => StyleSheet.create({
  container: { flex: 1, backgroundColor: theme?.colors.background },
  content: { padding: theme?.spacing.md },
  title: { fontSize: 24, fontWeight: '800', color: theme?.colors.text.primary, marginBottom: 6 },
  subtitle: { fontSize: 14, color: theme?.colors.text.secondary, marginBottom: theme?.spacing.lg },
  tiles: { gap: theme?.spacing.sm },
  tile: { flexDirection: 'row', alignItems: 'center', borderRadius: 14, padding: 14, overflow: 'hidden' },
  tileGradient: { ...StyleSheet.absoluteFillObject, borderRadius: 14 },
  tileIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  tileContent: { flex: 1 },
  tileTitle: { fontSize: 16, fontWeight: '700' },
  tileSubtitle: { fontSize: 12, color: theme?.colors.text.secondary, marginTop: 2 },
  bestRow: { flexDirection: 'row', alignItems: 'center', marginTop: 6, gap: 6 },
  bestText: { fontSize: 12, color: theme?.colors.text.secondary },
  statsCard: { marginTop: theme?.spacing.lg, borderRadius: 16, overflow: 'hidden', padding: 16 },
  statsGradient: { ...StyleSheet.absoluteFillObject, borderRadius: 16 },
  statsTitle: { fontSize: 16, fontWeight: '800', color: theme?.colors.text.primary },
  statsRow: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 12 },
  cta: { marginTop: 16, backgroundColor: theme?.colors.primary, paddingVertical: 10, borderRadius: 12, alignItems: 'center', flexDirection: 'row', justifyContent: 'center', gap: 6 },
  ctaText: { color: '#fff', fontWeight: '700' },
});

export default observer(GameScreen);
