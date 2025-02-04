import React, { useState, useCallback, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Platform,
  ActivityIndicator,
  Switch,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import * as Haptics from 'expo-haptics';
import {
  ArrowLeft,
  Search,
  BookmarkSimple,
  Plus,
  Users,
  Clock,
  Star,
  Lock,
  ChevronRight,
  Sparkle,
  MessageCircle,
  Share,
} from '../components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { sampleWordHubs, type RootStackParamList, type User, type WordHub } from '@/types';
import { formatTimeLeft } from '@/utils/schedule';
import AvatarStack from '@/components/AvatarStack';
import { apiClient, endpoints } from '@/api/client';

const WordHubsScreen: React.FC<NativeStackScreenProps<RootStackParamList, 'WordHubsScreen'>> = ({
  navigation,
}) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);

  // States
  const [searchQuery, setSearchQuery] = useState('');
  const [showCreateHub, setShowCreateHub] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'discover' | 'joined'>('discover');
  const [wordHubs, setWordHubs] = useState<WordHub[]>([]);
  const [error, setError] = useState<string | null>(null);

  // Create Hub Form States
  const [hubTitle, setHubTitle] = useState('');
  const [hubDescription, setHubDescription] = useState('');
  const [isPrivate, setIsPrivate] = useState(false);
  const [hubCode, setHubCode] = useState('');
  const [minPoints, setMinPoints] = useState('');
  const [joinCode, setJoinCode] = useState('');

  const generateHubCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
  };

  const fetchWordHubs = useCallback(async () => {
    try {
      setIsLoading(true);
      const response = await apiClient.get<WordHub[]>(endpoints.wordHubs.list, {
        params: {
          include: 'user,bookmarks',
          sort: '-created_at',
          per_page: 20
        }
      });
      
      if (response.success) {
        setWordHubs(response.data);
      }
    } catch (error) {
      setError('Failed to load word hubs');
      console.error('Error fetching word hubs:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const handleCreateHub = async () => {
    if (!hubTitle.trim() || !hubDescription.trim()) return;

    try {
      setIsLoading(true);
      const response = await apiClient.post<WordHub>(endpoints.wordHubs.create, {
        title: hubTitle,
        description: hubDescription,
        is_private: isPrivate,
        access_code: isPrivate ? hubCode || generateHubCode() : undefined,
        min_points: minPoints ? parseInt(minPoints) : undefined,
      });

      if (response.success) {
        setWordHubs(prev => [response.data, ...prev]);
        setShowCreateHub(false);
        
        // Reset form
        setHubTitle('');
        setHubDescription('');
        setIsPrivate(false);
        setHubCode('');
        setMinPoints('');
        
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    } catch (error) {
      console.error('Error creating hub:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleJoinHub = async (hub: WordHub) => {
    try {
      setIsLoading(true);
      const response = await apiClient.post<{ member: any }>(
        endpoints.wordHubs.join(hub.id),
        hub.isPrivate ? { access_code: joinCode } : undefined
      );

      if (response.success) {
        // Update local state to reflect membership
        setWordHubs(prev =>
          prev.map(h => h.id === hub.id ? { ...h, isMember: true } : h)
        );
        
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        
        // Navigate to hub detail screen
        navigation.navigate('WordHubDetailScreen', { hubId: hub.id });
      }
    } catch (error) {
      console.error('Error joining hub:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleBookmark = (hubId: string) => {
    // Add bookmark logic here
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  };

  const renderHubCard = (hub: WordHub) => (
    <TouchableOpacity
      key={hub.id}
      style={styles.hubCard}
      onPress={() => handleJoinHub(hub)}
    >
      <BlurView intensity={10} style={StyleSheet.absoluteFill} />
      <View style={styles.hubContent}>
        {/* Status Badge */}
        <View style={styles.statusRow}>
          {hub.minPoints && (
            <View style={[
              styles.pointsBadge,
              { backgroundColor: `${theme.colors.primary}15` }
            ]}>
              <Star size={16} color={theme.colors.primary} />
              <Text style={styles.pointsBadgeText}>
                {hub.minPoints}+ points required
              </Text>
            </View>
          )}
          <View style={[
            styles.activityBadge,
            { backgroundColor: `${theme.colors.success}15` }
          ]}>
            <View style={styles.activeDot} />
            <Text style={[styles.activityText, { color: theme.colors.success }]}>
              {hub.activeMembers} online
            </Text>
          </View>
        </View>

        {/* Hub Info */}
        <View style={styles.hubHeader}>
          <View style={styles.hubInfo}>
            <View style={styles.titleRow}>
              <Text style={styles.hubTitle}>{hub.title}</Text>
              {hub.isPrivate && (
                <Lock size={16} color={theme.colors.text.secondary} />
              )}
            </View>
            <Text style={styles.hubDescription} numberOfLines={2}>
              {hub.description}
            </Text>
          </View>
          <TouchableOpacity
            style={styles.bookmarkButton}
            onPress={() => handleBookmark(hub.id)}
          >
            <BookmarkSimple
              size={20}
              color={hub.isBookmarked ? theme.colors.primary : theme.colors.text.secondary}
              filled={hub.isBookmarked}
            />
          </TouchableOpacity>
        </View>

        {/* Activity Section */}
        <View style={styles.activityContainer}>
          <LinearGradient
            colors={[`${theme.colors.surface}00`, theme.colors.surface]}
            style={styles.activityBackground}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
          />

          {/* Authors Preview */}
          <View style={styles.authorSection}>
            <View style={styles.authorInfo}>
              <AvatarStack
                users={hub.authors}
                maxAvatars={3}
                size={28}
                offset={18}
                showRemaining={false}
              />
              <Text style={styles.authorText}>
                {hub.authors.length > 3 && (
                  <Text style={styles.authorCount}>
                    +{Math.max(0, hub.authors.length - 3)}{' '} {hub.authors.length > 4 ? 'others ' : 'other '}
                  </Text>
                )}
                sharing
              </Text>
            </View>

            <View style={styles.messageCount}>
              <MessageCircle size={16} color={theme.colors.text.secondary} />
              <Text style={styles.messageText}>{hub.messageCount}</Text>
            </View>
          </View>
        </View>

        {/* Footer */}
        <View style={styles.hubFooter}>
          <View style={styles.timeInfo}>
            <Clock size={14} color={theme.colors.text.secondary} />
            <Text style={styles.timeText}>
              {formatTimeLeft(hub.expiresAt)}
            </Text>
          </View>
          <TouchableOpacity
            style={styles.joinButton}
            onPress={() => handleJoinHub(hub)}
          >
            <Text style={styles.joinButtonText}>Join Discussion</Text>
            <ChevronRight size={16} color={theme.colors.text.inverse} />
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
  );

  useEffect(() => {
    fetchWordHubs();
  }, [fetchWordHubs]);

  const handleSearch = useCallback(async (text: string) => {
    setSearchQuery(text);
    
    try {
      setIsLoading(true);
      const response = await apiClient.get<WordHub[]>(endpoints.wordHubs.list, {
        params: {
          search: text,
          include: 'user,bookmarks',
          per_page: 20
        }
      });
      
      if (response.success) {
        setWordHubs(response.data);
      }
    } catch (error) {
      console.error('Error searching hubs:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Word Hubs</Text>
        <TouchableOpacity onPress={() => setShowCreateHub(true)}>
          <Plus size={24} color={theme.colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Tab Selector */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'discover' && styles.activeTab]}
          onPress={() => setActiveTab('discover')}
        >
          <Text style={[
            styles.tabText,
            activeTab === 'discover' && styles.activeTabText
          ]}>
            Discover
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'joined' && styles.activeTab]}
          onPress={() => setActiveTab('joined')}
        >
          <Text style={[
            styles.tabText,
            activeTab === 'joined' && styles.activeTabText
          ]}>
            Joined
          </Text>
        </TouchableOpacity>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <View style={styles.searchInputContainer}>
          <Search size={20} color={theme.colors.text.secondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search by name or code"
            value={searchQuery}
            onChangeText={handleSearch}
            keyboardType={/^\d*$/.test(searchQuery) ? 'numeric' : 'default'}
            maxLength={/^\d*$/.test(searchQuery) ? 6 : undefined}
          />
        </View>
      </View>

      {/* Hub List */}
      <ScrollView
        style={styles.content}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {isLoading ? (
          <ActivityIndicator color={theme.colors.primary} />
        ) : wordHubs?.map(renderHubCard)}
      </ScrollView>

      {/* Create Hub Modal */}
      {showCreateHub && (
        <BlurView intensity={20} style={styles.modalOverlay}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>Create Word Hub</Text>

            <TextInput
              style={styles.input}
              placeholder="Hub Title"
              value={hubTitle}
              onChangeText={setHubTitle}
              maxLength={50}
            />

            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder="Hub Description"
              value={hubDescription}
              onChangeText={setHubDescription}
              multiline
              maxLength={200}
            />

            <View style={styles.toggleContainer}>
              <Text style={styles.toggleLabel}>Private Hub</Text>
              <Switch
                value={isPrivate}
                onValueChange={setIsPrivate}
                trackColor={{ false: theme.colors.border, true: theme.colors.primary }}
              />
            </View>

            {isPrivate && (
              <TextInput
                style={styles.input}
                placeholder="6-digit Access Code (optional)"
                value={hubCode}
                onChangeText={setHubCode}
                maxLength={6}
                keyboardType="number-pad"
              />
            )}

            <TextInput
              style={styles.input}
              placeholder="Minimum Points Required (optional)"
              value={minPoints}
              onChangeText={setMinPoints}
              keyboardType="number-pad"
            />

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelButton}
                onPress={() => setShowCreateHub(false)}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.createButton,
                  (!hubTitle.trim() || !hubDescription.trim()) && styles.createButtonDisabled
                ]}
                onPress={handleCreateHub}
                disabled={!hubTitle.trim() || !hubDescription.trim()}
              >
                <Text style={styles.createButtonText}>Create Hub</Text>
              </TouchableOpacity>
            </View>
          </View>
        </BlurView>
      )}
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
  tabContainer: {
    flexDirection: 'row',
    padding: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  tab: {
    flex: 1,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
  },
  activeTab: {
    backgroundColor: theme.colors.primary,
  },
  tabText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  activeTabText: {
    color: theme.colors.text.inverse,
  },
  searchContainer: {
    padding: theme.spacing.md,
  },
  searchInputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.full,
    paddingHorizontal: theme.spacing.md,
    height: 48,
  },
  searchInput: {
    flex: 1,
    marginLeft: theme.spacing.sm,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  codeButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    backgroundColor: `${theme.colors.primary}15`,
    borderRadius: theme.borderRadius.full,
  },
  codeButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
  },
  content: {
    flex: 1,
  },
  scrollContent: {
    padding: theme.spacing.md,
    gap: theme.spacing.md,
  },
  hubCard: {
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1.5,
    borderColor: `${theme.colors.primary}35`,
  },
  hubContent: {
    padding: theme.spacing.md,
    gap: theme.spacing.md,
  },
  hubHeader: {
    flexDirection: 'row',
    gap: theme.spacing.md,
  },
  hubInfo: {
    flex: 1,
  },
  hubTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  hubDescription: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    fontSize: 14,
  },
  bookmarkButton: {
    padding: theme.spacing.xs,
  },
  hubStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.md,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  modalOverlay: {
    ...StyleSheet.absoluteFillObject,
    padding: theme.spacing.lg,
    justifyContent: 'center',
  },
  modal: {
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.15,
        shadowRadius: 12,
      },
      android: {
        elevation: 8,
      },
    }),
  },
  modalTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.lg,
    textAlign: 'center',
  },
  input: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    marginBottom: theme.spacing.md,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  toggleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md,
  },
  toggleLabel: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: theme.spacing.md,
    marginTop: theme.spacing.md,
  },
  cancelButton: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
  },
  cancelButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  createButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
  },
  createButtonDisabled: {
    opacity: 0.5,
  },
  createButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  pointsBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
    marginBottom: theme.spacing.sm,
    gap: 4,
  },
  pointsBadgeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  statusRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },

  activityBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    gap: 6,
  },

  activeDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: theme.colors.success,
  },

  activityText: {
    ...theme.typography.caption.primary,
    fontSize: 12,
  },

  activityContainer: {
    marginTop: theme.spacing.sm,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.lg,
    backgroundColor: theme.colors.surface,
    position: 'relative',
    overflow: 'hidden',
  },

  activityBackground: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },

  activityStats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
  },

  activityItem: {
    alignItems: 'center',
    gap: 2,
  },

  activityValue: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontSize: 16,
  },

  activityLabel: {
    ...theme.typography.caption.secondary,
    fontSize: 12,
  },

  activityDivider: {
    width: 1,
    height: 24,
    backgroundColor: theme.colors.border,
  },

  hubFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: theme.spacing.md,
  },

  timeInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },

  timeText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },

  authorSection: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: theme.spacing.sm,
  },

  authorInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    flex: 1,
  },

  authorText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: -6,
    marginLeft: 8,
  },

  authorCount: {
  },

  messageCount: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: `${theme.colors.primary}10`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
  },

  messageText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },

  joinButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },

  joinButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
});

export default WordHubsScreen;