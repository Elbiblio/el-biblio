import React, { useMemo } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Linking, Alert } from 'react-native';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '@/types';
import * as Haptics from 'expo-haptics';
import { ArrowLeft, ArrowRight } from '@/components/Icons';

const PATREON_URL = 'https://www.patreon.com/cw/ElBiblio';

interface DonationTier {
  id: string;
  title: string;
  price: string;
  membersLabel?: string;
  description: string;
}

const TIERS: DonationTier[] = [
  {
    id: 'app-growth',
    title: 'App and Community Growth',
    price: '$5 / month',
    // membersLabel: '0 members',
    description:
      'Donate directly to ElBiblio. Used for server maintenance, outreach, and caring for the team keeping everything running.',
  },
  {
    id: 'circle-of-love',
    title: 'Circle of Love',
    price: '$6 / month',
    description:
      'Focused on programs that unite believers to learn from each other through gatherings, cohorts, and shared experiences.',
  },
  {
    id: 'programs-outreach',
    title: 'Programs and Outreach',
    price: '$12 / month',
    description:
      'Extends love from the ElBiblio community to widows and communities needing tangible Christian support.',
  },
];

const DonateScreen: React.FC = () => {
  const theme = useTheme();
  const styles = useMemo(() => createStyles(theme), [theme]);
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  const handleBack = () => {
    Haptics.selectionAsync();
    navigation.goBack();
  };

  const openPatreon = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    try {
      const supported = await Linking.canOpenURL(PATREON_URL);
      if (supported) {
        await Linking.openURL(PATREON_URL);
      } else {
        throw new Error('Unsupported URL');
      }
    } catch (error) {
      console.error('Failed to launch Patreon link', error);
      Alert.alert('Unable to open Patreon', 'Please try again later or visit patreon.com/cw/ElBiblio from your browser.');
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <View style={styles.header}>
        <TouchableOpacity onPress={handleBack} style={styles.backButton}>
          <ArrowLeft size={20} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <View style={styles.headerTextContainer}>
          <Text style={styles.title}>Support ElBiblio</Text>
          <Text style={styles.subtitle}>
            Partner with us to sustain the app and empower the community we are cultivating together.
          </Text>
        </View>
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {TIERS.map((tier) => (
          <View key={tier.id} style={styles.tierCard}>
            <Text style={styles.tierTitle}>{tier.title}</Text>
            <View style={styles.tierMetaRow}>
              <Text style={styles.tierPrice}>{tier.price}</Text>
              {tier.membersLabel ? (
                <Text style={styles.tierMembers}>{tier.membersLabel}</Text>
              ) : null}
            </View>
            <Text style={styles.tierDescription}>{tier.description}</Text>
          </View>
        ))}

        <TouchableOpacity style={styles.donateCta} onPress={openPatreon}>
          <Text style={styles.donateCtaText}>Give on Patreon</Text>
          <ArrowRight size={18} color={theme.colors.text.inverse} />
        </TouchableOpacity>

        <Text style={styles.footerNote}>
          Every gift helps us keep ElBiblio sustainable, nurture discipleship resources, and respond generously to
          needs inside and outside the app. Thank you for sowing into this work.
        </Text>
      </ScrollView>
    </SafeAreaView>
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
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: theme.spacing.lg,
    gap: theme.spacing.md,
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
  },
  headerTextContainer: {
    flex: 1,
  },
  title: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  subtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  scroll: {
    flex: 1,
  },
  content: {
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.xl,
    gap: theme.spacing.lg,
  },
  tierCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    gap: theme.spacing.sm,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  tierTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  tierMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  tierPrice: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  tierMembers: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.tertiary,
  },
  tierDescription: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    lineHeight: 20,
  },
  donateCta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.sm,
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
  },
  donateCtaText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  footerNote: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    lineHeight: 20,
  },
});

export default DonateScreen;
