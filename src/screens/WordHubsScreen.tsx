import React, { useState, useCallback, useRef, useEffect, useMemo } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  FlatList,
  Platform,
  ActivityIndicator,
  Switch,
  RefreshControl,
  Alert,
  Modal,
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
  XCircle,
  InfoCircle,
  Check,
} from '../components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { type RootStackParamList, type User, type WordHub, type WordHubMember } from '@/types';
import { formatTimeLeft } from '@/utils/schedule';
import AvatarStack from '@/components/AvatarStack';
import { observer } from 'mobx-react-lite';
import { useWordHubsStore } from '@/stores/StoreProvider';
import { runInAction } from 'mobx';

import { useAuthStore } from '@/stores/StoreProvider';
import { useWebSocket } from '@/services/websocket';
import { toast } from 'sonner-native';
import { useGuestRestrictions } from '@/hooks/useGuestRestrictions';
import GuestRestrictionModal from '@/components/GuestRestrictionModal';
import EmptyState from '@/components/EmptyState';

const tabConfig = {
  discover: {
    title: 'Discover Word Hubs',
    description: 'Explore curated hubs for spiritual growth and meaningful conversations.',
    emptyTitle: 'No Word Hubs Found',
    emptyMessage: 'Be the first to create a Word Hub and start meaningful discussions!'
  },
  joined: {
    title: 'Your Word Hubs',
    description: 'Stay connected with the hubs youve joined and keep the discussions going.',
    emptyTitle: 'No Joined Hubs',
    emptyMessage: 'Join some Word Hubs to see them here.'
  }
} as const;

const normalizeWordHubs = (collection: unknown): WordHub[] => {
  if (!collection) return [];
  if (Array.isArray(collection)) return collection as WordHub[];

  const candidate = collection as any;
  if (typeof candidate.slice === 'function') {
    return candidate.slice();
  }
  if (typeof candidate[Symbol.iterator] === 'function') {
    return Array.from(candidate);
  }

  return [];
};

const WordHubsScreen = ({
  navigation,
}: NativeStackScreenProps<RootStackParamList, 'WordHubsScreen'>) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuthStore();
  const { restrictions } = useGuestRestrictions();
  const { isConnected: wsConnected } = useWebSocket();

  const wordHubsStore = useWordHubsStore();

  const {
    wordHubs,
    isWordHubsLoading: isLoading,
    wordHubsError: error,
    isConnected,
    lastUpdate,
    fetchWordHubs,
    createHub,
    joinHub,
    bookmarkHub,
    shareHub,
    searchHubs,
    fetchJoinedHubs,
    clearErrors,
    setFilters,
    resetFilters,
    setConnectionStatus,
  } = wordHubsStore;

  // States
  const [searchQuery, setSearchQuery] = useState('');
  const [showCreateHub, setShowCreateHub] = useState(false);
  const [activeTab, setActiveTab] = useState<'discover' | 'joined'>('discover');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showRestrictionModal, setShowRestrictionModal] = useState(false);
  const [showAccessCodeModal, setShowAccessCodeModal] = useState(false);
  const [accessCodeInput, setAccessCodeInput] = useState('');
  const [pendingJoinHubId, setPendingJoinHubId] = useState<string | null>(null);

  // Create Hub Form States
  const [hubTitle, setHubTitle] = useState('');
  const [hubDescription, setHubDescription] = useState('');
  const [isPrivate, setIsPrivate] = useState(false);
  const [hubCode, setHubCode] = useState('');
  const [minPoints, setMinPoints] = useState('');
  const [joinCode, setJoinCode] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  const generateHubCode = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
  };

  // Load data on mount
  useEffect(() => {
    loadData();
  }, []);

  // Update connection status
  useEffect(() => {
    setConnectionStatus(wsConnected);
  }, [wsConnected, setConnectionStatus]);

  const loadData = async () => {
    try {
      if (activeTab === 'discover') {
        await fetchWordHubs(1);
      } else {
        await fetchJoinedHubs(1);
      }
    } catch (error) {
      console.error('Error loading data:', error);
    }
  };

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await loadData();
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (error) {
      console.error('Error refreshing:', error);
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleTabChange = async (tab: 'discover' | 'joined') => {
    if (tab === activeTab) return;
    
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setActiveTab(tab);
    clearErrors();
    
    try {
      if (tab === 'discover') {
        await fetchWordHubs(1);
      } else {
        await fetchJoinedHubs(1);
      }
    } catch (error) {
      console.error('Error switching tabs:', error);
    }
  };

  const handleCreateHub = async () => {
    if (!hubTitle.trim() || !hubDescription.trim()) return;

    // Check guest restrictions
    if (restrictions.canPostNotes === false) {
      setShowRestrictionModal(true);
      return;
    }

    try {
      setIsCreating(true);
      const result = await createHub({
        title: hubTitle.trim(),
        description: hubDescription.trim(),
        is_private: isPrivate,
        access_code: isPrivate ? hubCode || generateHubCode() : undefined,
        min_points: minPoints ? parseInt(minPoints) : undefined,
      });

      if (result) {
        setShowCreateHub(false);
        
        // Reset form
        setHubTitle('');
        setHubDescription('');
        setIsPrivate(false);
        setHubCode('');
        setMinPoints('');
        
        // Navigate to the new hub
        navigation.navigate('WordHubDetailScreen', { hubId: result.id });
      }
    } catch (error) {
      console.error('Error creating hub:', error);
    } finally {
      setIsCreating(false);
    }
  };

  const handleJoinHub = async (hub: WordHub, code?: string) => {

    // Check guest restrictions
    if (restrictions.canJoinCommunityChallenges === false) {
      setShowRestrictionModal(true);
      return;
    }

    const alreadyJoined = hub.members?.some((member) => member.user_id === user?.id);
    if (alreadyJoined) {
      wordHubsStore.activateCachedLiveKitSession(hub.id);
      navigation.navigate('WordHubDetailScreen', { hubId: hub.id });
      return;
    }

    if (hub.is_private) {
      if (Platform.OS === 'ios') {
        Alert.prompt(
          'Join Private Hub',
          'Enter the 6-digit access code:',
          [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Join',
              onPress: (codeInput?: string) => {
                const trimmedCode = codeInput?.trim();
                if (trimmedCode) {
                  performJoinHub(hub.id, trimmedCode).catch((err) => console.error('Join hub failed:', err));
                }
              }
            }
          ],
          'plain-text'
        );
      } else {
        setPendingJoinHubId(hub.id);
        setAccessCodeInput('');
        setShowAccessCodeModal(true);
      }
    } else {
      await performJoinHub(hub.id);
    }
  };

  const performJoinHub = async (hubId: string, accessCode?: string) => {
    try {
      const joinResult = await joinHub(hubId, accessCode);
      if (joinResult) {
        // Navigate to hub detail screen
        navigation.navigate('WordHubDetailScreen', { hubId });
      }
    } catch (error) {
      console.error('Error joining hub:', error);
    }
  };

  const handleBookmark = async (hubId: string) => {
    try {
      await bookmarkHub(hubId);
    } catch (error) {
      console.error('Error bookmarking hub:', error);
    }
  };

  const handleShare = async (hubId: string) => {
    try {
      await shareHub(hubId);
    } catch (error) {
      console.error('Error sharing hub:', error);
    }
  };

  const handleSearch = useCallback(async (text: string) => {
    setSearchQuery(text);

    const trimmed = text.trim();
    setFilters({ searchQuery: trimmed || undefined });

    try {
      if (activeTab === 'discover') {
        await fetchWordHubs(1, { searchQuery: trimmed || undefined });
      } else {
        if (trimmed) {
          const results = await searchHubs(trimmed, 50);
          runInAction(() => {
            const normalized = normalizeWordHubs(results);
            wordHubsStore.state.wordHubs = normalized;
          });
        } else {
          await fetchJoinedHubs(1);
        }
      }
    } catch (error) {
      console.error('Error searching hubs:', error);
    }
  }, [activeTab, fetchJoinedHubs, fetchWordHubs, searchHubs, setFilters]);

  const safeWordHubs = normalizeWordHubs(wordHubs);

  const renderHubCard = useCallback((hub: WordHub) => {
    const isJoined = hub.members?.some((member) => member.user_id === user?.id);

    return (
    <TouchableOpacity
      style={styles.hubCard}
      onPress={() => navigation.navigate('WordHubDetailScreen', { hubId: hub.id })}
    >
      <BlurView intensity={10} style={StyleSheet.absoluteFill} />
      <View style={styles.hubContent}>
        <View style={styles.statusRow}>
          {hub.min_points && (
            <View style={[
              styles.pointsBadge,
              { backgroundColor: `${theme.colors.primary}15` }
            ]}>
              <Star size={16} color={theme.colors.primary} />
              <Text style={styles.pointsBadgeText}>
                {hub.min_points}+ points required
              </Text>
            </View>
          )}
          <View style={[
            styles.activityBadge,
            { backgroundColor: `${theme.colors.success}15` }
          ]}>
            <View style={styles.activeDot} />
            <Text style={[styles.activityText, { color: theme.colors.success }]}>
              {hub.activeMembers || 0} online
            </Text>
          </View>
        </View>

        <View style={styles.hubHeader}>
          <View style={styles.hubInfo}>
            <View style={styles.titleRow}>
              <Text style={styles.hubTitle}>{hub.title}</Text>
              {hub.is_private && (
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

        <View style={styles.activityContainer}>
          <LinearGradient
            colors={[`${theme.colors.surface}00`, theme.colors.surface]}
            style={styles.activityBackground}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
          />

          <View style={styles.authorSection}>
            <View style={styles.authorInfo}>
              <AvatarStack
                users={hub.authors?.slice(0, 3) || []}
                maxAvatars={3}
                size={28}
                offset={18}
                showRemaining={false}
              />
              <Text style={styles.authorText}>
                {hub.authors && hub.authors.length > 3 && (
                  <Text style={styles.authorCount}>
                    +{Math.max(0, hub.authors.length - 3)}{' '} {hub.authors.length > 4 ? 'others ' : 'other '}
                  </Text>
                )}
                sharing
              </Text>
            </View>

            <View style={styles.messageCount}>
              <MessageCircle size={16} color={theme.colors.text.secondary} />
              <Text style={styles.messageText}>{hub.messageCount || 0}</Text>
            </View>
          </View>
        </View>

        <View style={styles.hubFooter}>
          <View style={styles.timeInfo}>
            <Clock size={14} color={theme.colors.text.secondary} />
            <Text style={styles.timeText}>
              {hub.expires_at ? formatTimeLeft(hub.expires_at) : 'No expiration'}
            </Text>
          </View>
          <TouchableOpacity
            style={styles.joinButton}
            onPress={() => handleJoinHub(hub)}
          >
            <Text style={styles.joinButtonText}>
              {isJoined ? 'Open Hub' : 'Join Discussion'}
            </Text>
            <ChevronRight size={16} color={theme.colors.text.inverse} />
          </TouchableOpacity>
        </View>
      </View>
    </TouchableOpacity>
    );
  }, [theme, styles, user?.id, navigation, handleBookmark, handleJoinHub]);

  const flatListRenderItem = useCallback(
    ({ item }: { item: WordHub }) => renderHubCard(item),
    [renderHubCard]
  );

  const keyExtractor = useCallback((item: WordHub) => item.id, []);

  const listEmptyContent = useMemo(() => {
    if (isLoading && !isRefreshing) {
      return (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.colors.primary} />
          <Text style={styles.loadingText}>Loading Word Hubs...</Text>
        </View>
      );
    }
    if (error) {
      return (
        <View style={styles.errorContainer}>
          <InfoCircle size={48} color={theme.colors.error} />
          <Text style={styles.errorTitle}>Unable to load Word Hubs</Text>
          <Text style={styles.errorMessage}>{error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={loadData}>
            <Text style={styles.retryButtonText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      );
    }
    return (
      <EmptyState
        title={tabConfig[activeTab].emptyTitle}
        message={tabConfig[activeTab].emptyMessage}
        ctaText={activeTab === 'discover' ? 'Create a Word Hub' : 'Browse Word Hubs'}
        onPressCTA={activeTab === 'discover' ? () => setShowCreateHub(true) : () => handleTabChange('discover')}
        IconComponent={Users as any}
      />
    );
  }, [isLoading, isRefreshing, error, theme.colors.primary, theme.colors.error, styles.loadingContainer, styles.loadingText, styles.errorContainer, styles.errorTitle, styles.errorMessage, styles.retryButton, styles.retryButtonText, activeTab, loadData]);

  const ListEmpty = useCallback(() => listEmptyContent, [listEmptyContent]);

  const ListFooter = useMemo(() => {
    if (!lastUpdate || safeWordHubs.length === 0) return null;
    return (
      <Text style={styles.lastUpdateText}>
        Last updated: {lastUpdate.toLocaleTimeString()}
      </Text>
    );
  }, [lastUpdate, safeWordHubs.length, styles.lastUpdateText]);

  const renderConnectionStatus = () => {
    if (safeWordHubs.length === 0) return null;

    const joinedCount = safeWordHubs.filter((hub: WordHub) => hub.members?.some((member: WordHubMember) => member.user_id === user?.id)).length;
    const availableCount = safeWordHubs.length - joinedCount;

    let label: string | null = null;
    if (joinedCount > 0) {
      const joinedLabel = joinedCount === 1 ? 'hub' : 'hubs';
      label = `${joinedCount} ${joinedLabel} joined`;
    } else if (availableCount > 0) {
      label = `${availableCount} hubs`;
    }

    if (!label) return null;

    return (
      <View style={styles.connectionStatus}>
        <Sparkle size={16} color={theme.colors.primary} />
        <Text style={[styles.connectionText, { color: theme.colors.primary }]}>{label}</Text>
      </View>
    );
  };

  const renderErrorState = () => (
    <View style={styles.errorContainer}>
      <InfoCircle size={48} color={theme.colors.error} />
      <Text style={styles.errorTitle}>Unable to load Word Hubs</Text>
      <Text style={styles.errorMessage}>{error}</Text>
      <TouchableOpacity style={styles.retryButton} onPress={loadData}>
        <Text style={styles.retryButtonText}>Try Again</Text>
      </TouchableOpacity>
    </View>
  );

  const renderEmptyState = () => (
    <EmptyState
      title={tabConfig[activeTab].emptyTitle}
      message={tabConfig[activeTab].emptyMessage}
      ctaText={activeTab === 'discover' ? 'Create a Word Hub' : 'Browse Word Hubs'}
      onPressCTA={activeTab === 'discover' ? () => setShowCreateHub(true) : () => handleTabChange('discover')}
      IconComponent={Users as any}
    />
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <View style={styles.headerCenter}>
          <Text style={styles.title}>Word Hubs</Text>
          {renderConnectionStatus()}
        </View>
        <TouchableOpacity 
          onPress={() => setShowCreateHub(true)}
          disabled={restrictions.canPostNotes === false}
        >
          <Plus size={24} color={theme.colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Tab Selector */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab === 'discover' && styles.activeTab]}
          onPress={() => handleTabChange('discover')}
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
          onPress={() => handleTabChange('joined')}
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
      <FlatList
        data={safeWordHubs}
        renderItem={flatListRenderItem}
        keyExtractor={keyExtractor}
        ListEmptyComponent={ListEmpty}
        ListFooterComponent={ListFooter}
        style={styles.content}
        contentContainerStyle={safeWordHubs.length === 0 ? [styles.scrollContent, { flexGrow: 1 }] : styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={handleRefresh}
            tintColor={theme.colors.primary}
            colors={[theme.colors.primary]}
          />
        }
        windowSize={7}
        maxToRenderPerBatch={10}
      />

      {/* Create Hub Modal */}
      {showCreateHub && (
        <View style={styles.modalOverlay} pointerEvents="box-none">
          <View style={StyleSheet.absoluteFill} pointerEvents="auto" collapsable={false} />
          <BlurView intensity={20} style={StyleSheet.absoluteFill} pointerEvents="none" />
          <View style={styles.modal} onStartShouldSetResponder={() => true}>
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
                disabled={isCreating}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.createButton,
                  (!hubTitle.trim() || !hubDescription.trim() || isCreating) && styles.createButtonDisabled
                ]}
                onPress={handleCreateHub}
                disabled={!hubTitle.trim() || !hubDescription.trim() || isCreating}
              >
                {isCreating ? (
                  <ActivityIndicator size="small" color={theme.colors.text.inverse} />
                ) : (
                  <Text style={styles.createButtonText}>Create Hub</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* Android Private Hub Access Code Modal */}
      {showAccessCodeModal && (
        <View style={styles.modalOverlay} pointerEvents="box-none">
          <View style={StyleSheet.absoluteFill} pointerEvents="auto" collapsable={false} />
          <BlurView intensity={20} style={StyleSheet.absoluteFill} pointerEvents="none" />
          <View style={styles.modal} onStartShouldSetResponder={() => true}>
            <Text style={styles.modalTitle}>Join Private Hub</Text>
            <TextInput
              style={styles.input}
              placeholder="6-digit Access Code"
              value={accessCodeInput}
              onChangeText={setAccessCodeInput}
              keyboardType="number-pad"
              maxLength={6}
            />
            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelButton}
                onPress={() => { setShowAccessCodeModal(false); setPendingJoinHubId(null); }}
              >
                <Text style={styles.cancelButtonText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.createButton,
                  (!accessCodeInput.trim() || !pendingJoinHubId) && styles.createButtonDisabled,
                ]}
                onPress={async () => {
                  if (pendingJoinHubId && accessCodeInput.trim()) {
                    await performJoinHub(pendingJoinHubId, accessCodeInput.trim());
                    setShowAccessCodeModal(false);
                    setPendingJoinHubId(null);
                    setAccessCodeInput('');
                  }
                }}
                disabled={!accessCodeInput.trim() || !pendingJoinHubId}
              >
                <Text style={styles.createButtonText}>Join</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* Guest Restriction Modal */}
      <GuestRestrictionModal
        visible={showRestrictionModal}
        onClose={() => setShowRestrictionModal(false)}
        feature="creating and joining Word Hubs"
      />
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
  headerCenter: {
    alignItems: 'center',
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
  connectionStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: `${theme.colors.success}10`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
  },
  connectionText: {
    ...theme.typography.caption.primary,
  },
  errorContainer: {
    alignItems: 'center',
    paddingVertical: theme.spacing.lg,
    gap: theme.spacing.md,
  },
  errorTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  errorMessage: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    paddingHorizontal: theme.spacing.md,
  },
  retryButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
  },
  retryButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: theme.spacing.lg,
    gap: theme.spacing.md,
  },
  emptyTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  emptyMessage: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    paddingHorizontal: theme.spacing.md,
  },
  createFirstButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
  },
  createFirstButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: theme.spacing.lg,
  },
  loadingText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.sm,
  },
  lastUpdateText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme.spacing.sm,
  },
});

export default observer(WordHubsScreen);