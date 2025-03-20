import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  ActivityIndicator,
  Platform
} from 'react-native';
import { useTheme, useThemeVariant } from '@/contexts/ThemeContext';
import { Theme, ThemeVariant, themeColors } from '@/theme';
import { useAuth } from '@/stores/auth';
import AvatarSelectionModal from '@/components/AvatarSelectionModal';
import { SafeAreaView } from 'react-native-safe-area-context';
import { FoundationalVirtue, AllVirtues } from '@/types';
import * as Haptics from 'expo-haptics';
import { Shield, BookOpen, MessageCircle, FileText, Award, Edit2, Users, ArrowRight } from '../components/Icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { RootStackParamList } from '@/types';

const ProfileScreen = () => {
  const theme = useTheme();
  const setThemeVariant = useThemeVariant();
  const { user, updateAvatar } = useAuth();
  const [avatarModalVisible, setAvatarModalVisible] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);

  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  
  const styles = useMemo(() => createStyles(theme), [theme]);

  // Mock data (replace with actual data from your API)
  const userStats = {
    totalChallenges: 24,
    totalComments: 37,
    totalReflections: 16,
    totalNotes: 42,
    topVirtues: [
      { name: 'love', progress: 85 },
      { name: 'knowledge', progress: 72 },
      { name: 'wisdom', progress: 65 },
      { name: 'perseverance', progress: 58 }
    ] as { name: AllVirtues, progress: number }[]
  };

  const handleAvatarChange = async (avatarUrl: string) => {
    setIsUpdating(true);
    try {
      await updateAvatar(avatarUrl);
      setAvatarModalVisible(false);
    } finally {
      setIsUpdating(false);
    }
  };

  const handleThemeChange = (themeVariant: ThemeVariant) => {
    setThemeVariant(themeVariant);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  if (!user) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  const getVirtueColor = (virtue: AllVirtues): string => {
    // Different color based on virtue type
    if (['love', 'compassion', 'kindness', 'generosity'].includes(virtue)) {
      return theme.colors.like;
    } else if (['knowledge', 'wisdom', 'discernment'].includes(virtue)) {
      return theme.colors.info;
    } else if (['faith', 'hope', 'perseverance'].includes(virtue)) {
      return theme.colors.primary;
    } else if (['humility', 'patience', 'gentleness'].includes(virtue)) {
      return theme.colors.success;
    }
    return theme.colors.secondary;
  };

  // Determine current theme variant
  const getCurrentThemeVariant = (): ThemeVariant => {
    // Compare theme.colors with themeColors to find the matching variant
    for (const [variant, colors] of Object.entries(themeColors)) {
      if (colors.light.primary === theme.colors.primary || 
          colors.dark.primary === theme.colors.primary) {
        return variant as ThemeVariant;
      }
    }
    return 'sage'; // Default fallback
  };

  const currentThemeVariant = getCurrentThemeVariant();

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView 
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Profile Header */}
        <View style={styles.header}>
          {/* Avatar */}
          <TouchableOpacity 
            style={styles.avatarContainer}
            onPress={() => setAvatarModalVisible(true)}
            disabled={isUpdating}
          >
            {isUpdating ? (
              <View style={styles.avatarLoading}>
                <ActivityIndicator color={theme.colors.primary} />
              </View>
            ) : (
              <>
                <Image 
                  source={{ 
                    uri: user.avatar || 'https://api.elbiblio.com/avatars/1.png' 
                  }} 
                  style={styles.avatar} 
                />
                <View style={styles.editIconContainer}>
                  <Edit2 size={16} color={theme.colors.text.inverse} />
                </View>
              </>
            )}
          </TouchableOpacity>

          {/* User Details */}
          <Text style={styles.userName}>
            {user.first_name} {user.last_name}
          </Text>
          
          <View style={styles.pointsContainer}>
            <Award size={20} color={theme.colors.primary} />
            <Text style={styles.pointsText}>{user.points || 0} points</Text>
          </View>
        </View>

        {/* Top Virtues */}
        <View style={styles.sectionContainer}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Top Virtues</Text>
            <Text style={styles.sectionSubtitle}>Learning Progress</Text>
          </View>
          <View style={styles.virtuesContainer}>
            {userStats.topVirtues.map((virtueData, index) => (
              <View key={index} style={styles.virtueItem}>
                <View 
                  style={[
                    styles.virtueChip,
                    { backgroundColor: getVirtueColor(virtueData.name) }
                  ]}
                >
                  <Text style={styles.virtueText}>
                    {virtueData.name.charAt(0).toUpperCase() + virtueData.name.slice(1)}
                  </Text>
                </View>
                <View style={styles.progressContainer}>
                  <View 
                    style={[
                      styles.progressBar, 
                      { 
                        width: `${virtueData.progress}%`,
                        backgroundColor: getVirtueColor(virtueData.name)
                      }
                    ]} 
                  />
                  <Text style={styles.progressText}>{virtueData.progress}%</Text>
                </View>
              </View>
            ))}
          </View>
        </View>

        {/* Leaderboard Link */}
        <TouchableOpacity 
          style={styles.leaderboardButton}
          onPress={() => {
            // Navigate to leaderboard
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            navigation.navigate("LeaderboardScreen")
          }}
        >
          <View style={styles.leaderboardIconContainer}>
            <Users size={20} color={theme.colors.text.inverse} />
          </View>
          <Text style={styles.leaderboardText}>Global Leaderboard</Text>
          <ArrowRight size={18} color={theme.colors.text.secondary} />
        </TouchableOpacity>

        {/* Stats */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>Activity</Text>
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Shield size={24} color={theme.colors.primary} />
              <Text style={styles.statValue}>{userStats.totalChallenges}</Text>
              <Text style={styles.statLabel}>Challenges</Text>
            </View>
            
            <View style={styles.statCard}>
              <MessageCircle size={24} color={theme.colors.info} />
              <Text style={styles.statValue}>{userStats.totalComments}</Text>
              <Text style={styles.statLabel}>Comments</Text>
            </View>
            
            <View style={styles.statCard}>
              <BookOpen size={24} color={theme.colors.success} />
              <Text style={styles.statValue}>{userStats.totalReflections}</Text>
              <Text style={styles.statLabel}>Reflections</Text>
            </View>
            
            <View style={styles.statCard}>
              <FileText size={24} color={theme.colors.secondary} />
              <Text style={styles.statValue}>{userStats.totalNotes}</Text>
              <Text style={styles.statLabel}>Notes</Text>
            </View>
          </View>
        </View>

        {/* Theme Selection */}
        <View style={styles.sectionContainer}>
          <Text style={styles.sectionTitle}>Theme</Text>
          <ScrollView 
            style={styles.themesScrollView}
            contentContainerStyle={{ gap: theme.spacing.md }}
            showsVerticalScrollIndicator={false}
          >
            {(Object.entries(themeColors) as [ThemeVariant, typeof themeColors.sage][]).map(
              ([variant, colors]) => (
                <TouchableOpacity
                  key={variant}
                  style={[
                    styles.themeOption,
                    variant === currentThemeVariant && styles.selectedTheme,
                    { backgroundColor: colors.light.surface }
                  ]}
                  onPress={() => handleThemeChange(variant as ThemeVariant)}
                >
                  <View style={[
                    styles.colorPreview, 
                    { backgroundColor: colors.light.primary }
                  ]} />
                  <View style={styles.themeTextContainer}>
                    <Text style={[
                      styles.themeTitle,
                      { color: colors.light.text.primary }
                    ]}>
                      {colors.name}
                    </Text>
                    <Text style={[
                      styles.themeDescription,
                      { color: colors.light.text.secondary }
                    ]}>
                      {colors.description}
                    </Text>
                  </View>
                </TouchableOpacity>
              )
            )}
          </ScrollView>
        </View>
      </ScrollView>

      <AvatarSelectionModal
        visible={avatarModalVisible}
        onClose={() => setAvatarModalVisible(false)}
        onSelect={handleAvatarChange}
      />
    </SafeAreaView>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.background,
  },
  scrollContent: {
    paddingBottom: theme.spacing.xl,
  },
  header: {
    alignItems: 'center',
    paddingVertical: theme.spacing.xl,
    backgroundColor: theme.colors.surface,
    borderBottomLeftRadius: theme.borderRadius.lg,
    borderBottomRightRadius: theme.borderRadius.lg,
    marginBottom: theme.spacing.lg,
    ...theme.shadows.md,
  },
  avatarContainer: {
    width: 120,
    height: 120,
    borderRadius: 60,
    marginBottom: theme.spacing.md,
    backgroundColor: theme.colors.surfaceVariant,
    ...Platform.select({
      ios: {
        shadowColor: theme.colors.shadow,
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 10,
      },
      android: {
        elevation: 6,
      },
    }),
  },
  avatar: {
    width: '100%',
    height: '100%',
    borderRadius: 60,
  },
  avatarLoading: {
    width: '100%',
    height: '100%',
    borderRadius: 60,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
  },
  editIconContainer: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    backgroundColor: theme.colors.primary,
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 3,
    borderColor: theme.colors.background,
  },
  userName: {
    ...theme.typography.heading.large,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  pointsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
  },
  pointsText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    marginLeft: theme.spacing.xs,
  },
  sectionContainer: {
    marginHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.lg,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    ...theme.shadows.sm,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.md,
  },
  sectionTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.md,
  },
  sectionSubtitle: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  virtuesContainer: {
    gap: theme.spacing.md,
  },
  virtueItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  virtueChip: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    minWidth: 100,
    alignItems: 'center',
  },
  virtueText: {
    ...theme.typography.caption.primary,
    color: '#FFFFFF',
  },
  progressContainer: {
    flex: 1,
    height: 8,
    backgroundColor: theme.colors.surfaceVariant,
    borderRadius: theme.borderRadius.full,
    marginRight: theme.spacing.xxl,
    flexDirection: 'row',
    alignItems: 'center',
  },
  progressBar: {
    height: '100%',
    borderRadius: theme.borderRadius.full,
  },
  progressText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginLeft: theme.spacing.md,
    position: 'absolute',
    right: 0 - theme.spacing.xxl,
  },
  leaderboardButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    marginHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.lg,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.lg,
    ...theme.shadows.sm,
  },
  leaderboardIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: theme.colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: theme.spacing.md,
  },
  leaderboardText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    flex: 1,
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: theme.spacing.md,
  },
  statCard: {
    flex: 1,
    minWidth: '45%',
    alignItems: 'center',
    backgroundColor: theme.colors.surfaceVariant,
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
  },
  statValue: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginTop: theme.spacing.xs,
  },
  statLabel: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  themesScrollView: {
    minHeight: 300,
  },
  themeOption: {
    flexDirection: 'row',
    padding: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    marginBottom: theme.spacing.sm,
    borderWidth: 1,
    borderColor: 'transparent',
    alignItems: 'center',
  },
  selectedTheme: {
    borderColor: theme.colors.primary,
    borderWidth: 2,
  },
  colorPreview: {
    width: 48,
    height: 48,
    borderRadius: 24,
    marginRight: theme.spacing.md,
  },
  themeTextContainer: {
    flex: 1,
  },
  themeTitle: {
    ...theme.typography.body.sans,
    marginBottom: theme.spacing.xs,
  },
  themeDescription: {
    ...theme.typography.caption.secondary,
  },
});

export default ProfileScreen; 