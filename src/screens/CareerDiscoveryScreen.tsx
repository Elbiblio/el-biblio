import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { observer } from 'mobx-react-lite';
import { useTheme } from '@/contexts/ThemeContext';
import type { Theme } from '@/theme';
import type { RootStackParamList } from '@/types';
import { ArrowLeft, Brain } from '@/components/Icons';

export type CareerDiscoveryScreenProps = NativeStackScreenProps<RootStackParamList, 'CareerDiscoveryScreen'>;

const CareerDiscoveryScreen = ({ navigation }: CareerDiscoveryScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}> 
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Career Discovery</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.iconHeaderRow}>
          <View style={styles.iconCircle}>
            <Brain size={24} color={theme.colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.introTitle}>Your life is more than a job</Text>
            <Text style={styles.introBody}>
              Before any earthly title or role, you are a child of God and a citizen of His Kingdom.
              The same Holy Spirit manifests differently in each person, giving unique gifts and
              assignments in the Body of Christ. This is your true calling.
            </Text>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Look beyond the fallen world</Text>
          <Text style={styles.cardBody}>
            Many careers in the fallen world are built around survival, status, or the worship of
            money. In the Kingdom, your true spiritual career is about co-creating with God –
            bringing forth His Kingdom, directly or indirectly, in whatever context He places you.
          </Text>
          <Text style={styles.cardBody}>
            Instead of saying "I need money, What job should I do?", we ask: "How has God wired me to
            serve and co-create with Him? What do I find the most joy in doing?" From there, you can discern earthly roles that match your spiritual nature or strengths.
          </Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Two ways to explore</Text>
          <Text style={styles.cardBody}>
            You can begin with a gentle reflection on how God has already used you historically,
            or you can dive straight into a deeper interactive assessment.
          </Text>

          <View style={styles.optionCard}>
            <Text style={styles.optionTitle}>Historic meditation</Text>
            <Text style={styles.optionBody}>
              The world often says that earning money is proof of your talents. In the Kingdom,
              your true talents are often revealed by the work you are joyful doing for its own
              sake, even when no one is paying you. Like Jesus said, "My food is to do the will of the Father."
            </Text>
            <Text style={styles.optionBody}>
              Open the historic meditation to walk through an interactive reflection on the work
              you have most loved doing and how it points to your spiritual strengths.
            </Text>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => navigation.navigate('CareerHistoricMeditationScreen')}
            >
              <Text style={styles.primaryButtonText}>Open historic meditation</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.optionCard}>
            <Text style={styles.optionTitle}>Career quiz game</Text>
            <Text style={styles.optionBody}>
              If you want a different approach, you can use the interactive Spiritual Career game.
              It is meant only to serve as a guide but can likewise help reveal
              your talents or gifts and Kingdom roles.
            </Text>
            <TouchableOpacity
              style={styles.primaryButton}
              activeOpacity={0.9}
              onPress={() => navigation.navigate('SpiritualCareerScreen')}
            >
              <Text style={styles.primaryButtonText}>Open career quiz game</Text>
            </TouchableOpacity>
          </View>
        </View>
      </ScrollView>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  title: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  content: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  iconHeaderRow: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    alignItems: 'flex-start',
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: `${theme.colors.primary}10`,
  },
  introTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  introBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  card: {
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: theme.colors.border,
    gap: theme.spacing.sm,
  },
  cardTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  cardBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  optionCard: {
    marginTop: theme.spacing.sm,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.border}90`,
    backgroundColor: theme.colors.background,
    gap: theme.spacing.sm,
  },
  optionTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  optionBody: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  bulletList: {
    marginTop: theme.spacing.xs,
    gap: 2,
  },
  bulletItem: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  primaryButton: {
    marginTop: theme.spacing.sm,
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  primaryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
});

export default observer(CareerDiscoveryScreen);
