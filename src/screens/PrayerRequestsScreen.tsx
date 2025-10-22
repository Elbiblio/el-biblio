import React, { useEffect, useMemo, useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, StatusBar, FlatList, TextInput, ActivityIndicator, RefreshControl, Modal, ScrollView, KeyboardAvoidingView, Platform } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { type RootStackParamList, type PrayerRequest, PRAYER_CATEGORIES, type PrayerCategory } from '@/types';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ArrowLeft, ChevronDown, Sparkle, Heart, MessageCircle } from '@/components/Icons';
import { observer } from 'mobx-react-lite';
import { usePrayerRequestsStore, useAuthStore } from '@/stores/StoreProvider';
import EmptyState from '@/components/EmptyState';
import Animated, { useSharedValue, withSpring, useAnimatedStyle, withTiming } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const getPrayedCount = (request: PrayerRequest): number => {
  if (typeof request.prayed_count === 'number') {
    return request.prayed_count;
  }
  if (Array.isArray(request.prayed_users)) {
    return request.prayed_users.length;
  }
  return 0;
};

const hasUserPrayed = (request: PrayerRequest, userId?: string): boolean => {
  if (!userId) {
    return false;
  }
  if (request.has_prayed) {
    return true;
  }
  if (Array.isArray(request.prayed_users)) {
    return request.prayed_users.some(prayedUser => String(prayedUser) === userId);
  }
  return false;
};

const hasUserAmen = (request: PrayerRequest, userId?: string): boolean => {
  if (!userId) {
    return false;
  }
  if (Array.isArray(request.amen_users)) {
    return request.amen_users.some(amenUser => String(amenUser) === userId);
  }
  return false;
};

const hasUserAmenComment = (comment: any, userId?: string): boolean => {
  if (!userId) return false;
  if (Array.isArray(comment.amen_users)) {
    return comment.amen_users.some((amenUser: any) => String(amenUser) === userId);
  }
  return false;
};

export type PrayerRequestsScreenProps = NativeStackScreenProps<RootStackParamList, 'PrayerRequestsScreen'>;

const PrayerRequestsScreen = ({ navigation }: PrayerRequestsScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const prayerRequestsStore = usePrayerRequestsStore();
  const { requests, isLoading, pagination } = prayerRequestsStore;
  const { fetchRequests, createRequest, prayForRequest, toggleAmen, addComment, toggleCommentAmen } = prayerRequestsStore;
  const { user } = useAuthStore();

  const [isRefreshing, setIsRefreshing] = useState(false);
  const [currentCategory, setCurrentCategory] = useState<PrayerCategory>('healing');
  const [currentType, setCurrentType] = useState<'all' | 'prayer' | 'testimony'>('all');
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [showPrayerModal, setShowPrayerModal] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(120);
  const [showComposeModal, setShowComposeModal] = useState(false);
  const [composeDraft, setComposeDraft] = useState('');
  const [isPosting, setIsPosting] = useState(false);
  const [isBulkPraying, setIsBulkPraying] = useState(false);
  const [showPrayGuideModal, setShowPrayGuideModal] = useState(false);
  const [activePrayerId, setActivePrayerId] = useState<string | null>(null);
  const guideDuration = 15;
  const [guideSecondsLeft, setGuideSecondsLeft] = useState(guideDuration);
  const [hasSeenPrayerGuide, setHasSeenPrayerGuide] = useState(false);
  const [isRecordingPrayer, setIsRecordingPrayer] = useState(false);
  const [prayedIds, setPrayedIds] = useState<string[]>([]);

  const [composeCategory, setComposeCategory] = useState<PrayerCategory>('healing');
  const [composeVisibility, setComposeVisibility] = useState<'anonymous'|'first_name'|'full_name'>('anonymous');
  const [composeType, setComposeType] = useState<'prayer' | 'testimony'>('prayer');
  const [amenLoadingId, setAmenLoadingId] = useState<string | null>(null);
  const [selectedRequestId, setSelectedRequestId] = useState<string | null>(null);
  const [commentDraft, setCommentDraft] = useState('');
  const [isCommentPosting, setIsCommentPosting] = useState(false);

  const categories = PRAYER_CATEGORIES;

  const activePrayerRequest = useMemo(() => {
    if (!activePrayerId) return null;
    return requests.find(r => r.id === activePrayerId) ?? null;
  }, [activePrayerId, requests]);

  const activeDetailRequest = useMemo(() => {
    if (!selectedRequestId) return null;
    return requests.find(r => r.id === selectedRequestId) ?? null;
  }, [selectedRequestId, requests]);

  const prayedIdSet = useMemo(() => new Set(prayedIds), [prayedIds]);
  const userId = useMemo(() => (user?.id ? String(user.id) : undefined), [user?.id]);

  useEffect(() => {
    AsyncStorage.getItem('prayer_requests_guide_seen')
      .then(value => {
        if (value === 'true') {
          setHasSeenPrayerGuide(true);
        }
      })
      .catch(error => {
        console.error('Failed to load prayer guide preference:', error);
      });
  }, []);

  useEffect(() => {
    fetchRequests(1, { category: currentCategory, type: currentType });
  }, [currentCategory, currentType, fetchRequests]);

  useEffect(() => {
    if (!userId) {
      return;
    }

    const ids = requests
      .filter(req => hasUserPrayed(req, userId))
      .map(req => req.id);

    if (!ids.length) {
      return;
    }

    setPrayedIds(prev => {
      const merged = new Set(prev);
      ids.forEach(id => merged.add(id));
      if (merged.size === prev.length) {
        return prev;
      }
      return Array.from(merged);
    });
  }, [requests, userId]);

  useEffect(() => {
    if (!showPrayGuideModal) {
      return;
    }
    if (guideSecondsLeft <= 0) {
      return;
    }

    const timeout = setTimeout(() => {
      setGuideSecondsLeft(prev => Math.max(prev - 1, 0));
    }, 1000);

    return () => clearTimeout(timeout);
  }, [showPrayGuideModal, guideSecondsLeft]);

  const openComposeModal = useCallback((draft: string = '') => {
    setComposeDraft(draft);
    setShowComposeModal(true);
  }, []);

  const submitRequest = useCallback(async () => {
    const body = composeDraft.trim();
    if (!body) {
      toast.warning('Please share a prayer request before posting.');
      return;
    }

    if (body.length < 10) {
      toast.warning('Please write at least 10 characters.');
      return;
    }

    if (body.length > 500) {
      toast.warning('Prayer request is too long. Please keep it under 500 characters.');
      return;
    }

    const cat = currentCategory ?? composeCategory;

    setIsPosting(true);
    const created = await createRequest({
      content: body,
      visibility: composeVisibility,
      category: cat,
      type: composeType,
    });
    
    if (created) {
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      setComposeDraft('');
      setComposeCategory('healing');
      setComposeVisibility('anonymous');
      setComposeType('prayer');
      setShowComposeModal(false);
    }
    setIsPosting(false);
  }, [composeDraft, currentCategory, createRequest, composeCategory, composeVisibility]);

  const handlePray = useCallback((id: string, alreadyPrayed?: boolean) => {
    if (alreadyPrayed) {
      return;
    }
    setActivePrayerId(id);
    setGuideSecondsLeft(guideDuration);
    setShowPrayGuideModal(true);
  }, [guideDuration]);

  const closePrayGuide = useCallback(() => {
    setShowPrayGuideModal(false);
    setGuideSecondsLeft(guideDuration);
    setActivePrayerId(null);
    setIsRecordingPrayer(false);
  }, [guideDuration]);

  const confirmPrayerRecording = useCallback(async () => {
    if (!activePrayerId) return;
    setIsRecordingPrayer(true);
    const success = await prayForRequest(activePrayerId);

    if (success) {
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      toast.success('Prayer recorded');
      if (!hasSeenPrayerGuide) {
        setHasSeenPrayerGuide(true);
        AsyncStorage.setItem('prayer_requests_guide_seen', 'true').catch(error => {
          console.error('Failed to persist prayer guide preference:', error);
        });
      }
      setPrayedIds(prev => (prev.includes(activePrayerId) ? prev : [...prev, activePrayerId]));
      closePrayGuide();
    } else {
      toast.error('Could not record prayer. Please try again.');
    }

    setIsRecordingPrayer(false);
  }, [activePrayerId, prayForRequest, hasSeenPrayerGuide, closePrayGuide]);

  const onRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await fetchRequests(1, { category: currentCategory, type: currentType });
    setIsRefreshing(false);
  }, [fetchRequests, currentCategory, currentType]);

  const loadMore = useCallback(() => {
    if (isLoading || !pagination.hasMore) return;
    fetchRequests(pagination.currentPage + 1, { category: currentCategory, type: currentType });
  }, [isLoading, pagination, fetchRequests, currentCategory, currentType]);

  const toggleSelect = useCallback((id: string) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
        return next;
      }
      if (next.size >= 5) {
        return prev; // limit to 5
      }
      next.add(id);
      return next;
    });
  }, []);

  const openBulkPray = useCallback(() => {
    if (selectedIds.size === 0) return;
    setSecondsLeft(120);
    setShowPrayerModal(true);
  }, [selectedIds]);

  useEffect(() => {
    if (!showPrayerModal) return;
    const interval = setInterval(() => {
      setSecondsLeft((s) => {
        if (s <= 1) {
          clearInterval(interval);
          return 0;
        }
        return s - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [showPrayerModal]);

  const completeBulkPrayer = useCallback(async () => {
    if (isBulkPraying) return;
    setIsBulkPraying(true);
    
    const ids = Array.from(selectedIds);
    let successCount = 0;
    for (const id of ids) {
      // eslint-disable-next-line no-await-in-loop
      const success = await prayForRequest(id);
      if (success) {
        successCount++;
        setPrayedIds(prev => (prev.includes(id) ? prev : [...prev, id]));
      }
    }
    
    setSelectedIds(new Set());
    setShowPrayerModal(false);
    setIsBulkPraying(false);
    
    await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    toast.success(`Prayed for ${successCount} request${successCount !== 1 ? 's' : ''}`);
  }, [selectedIds, prayForRequest, isBulkPraying]);

  const PrayButton = ({ count, onPress, disabled, label }: { count?: number; onPress: () => void; disabled?: boolean; label: string }) => {
    const scale = useSharedValue(1);
    const burstScale = useSharedValue(0.6);
    const burstOpacity = useSharedValue(0);

    const btnStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
    const burstStyle = useAnimatedStyle(() => ({ opacity: burstOpacity.value, transform: [{ scale: burstScale.value }] }));

    const handlePress = async () => {
      if (disabled) {
        return;
      }
      // micro interaction
      scale.value = withSpring(1.07, { damping: 12 }, () => { scale.value = withSpring(1); });
      burstOpacity.value = 1; burstScale.value = 0.6; burstScale.value = withSpring(1.2, { damping: 10, stiffness: 120 });
      burstOpacity.value = withTiming(0, { duration: 500 });
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      onPress();
    };

    return (
      <Animated.View style={btnStyle}>
        <View style={{ position: 'relative' }}>
          <Animated.View pointerEvents="none" style={[styles.prayBurstOverlay, burstStyle]}>
            <Heart size={40} color={theme.colors.success} filled={true} />
          </Animated.View>
          <TouchableOpacity
            style={[styles.prayButton, disabled && { backgroundColor: `${theme.colors.success}08` }]}
            onPress={handlePress}
            disabled={disabled}
          >
            <Text style={[styles.prayButtonText, disabled && { color: `${theme.colors.success}80` }]}>
              {label} {count ? `(${count})` : ''}
            </Text>
          </TouchableOpacity>
        </View>
      </Animated.View>
    );
  };

  const handleAmen = useCallback(async (id: string) => {
    setAmenLoadingId(id);
    const success = await toggleAmen(id);
    if (!success) {
      toast.error('Unable to update amen right now.');
    }
    setAmenLoadingId(null);
  }, [toggleAmen]);

  const openDetail = useCallback((id: string) => {
    setSelectedRequestId(id);
    setCommentDraft('');
  }, []);

  const handleCommentAmen = useCallback(async (commentId: string) => {
    const success = await toggleCommentAmen(commentId);
    if (!success) {
      toast.error('Unable to update comment amen.');
    }
  }, [toggleCommentAmen]);

  const submitComment = useCallback(async () => {
    if (!selectedRequestId) return;
    const trimmed = commentDraft.trim();
    if (!trimmed) {
      toast.warning('Share a short encouragement first.');
      return;
    }
    setIsCommentPosting(true);
    const result = await addComment(selectedRequestId, trimmed);
    if (result) {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setCommentDraft('');
    } else {
      toast.error('Could not post your comment. Please retry.');
    }
    setIsCommentPosting(false);
  }, [addComment, commentDraft, selectedRequestId]);

  const amenCount = (request: PrayerRequest) => {
    if (typeof request.amen_count === 'number') {
      return request.amen_count;
    }
    if (Array.isArray(request.amen_users)) {
      return request.amen_users.length;
    }
    return 0;
  };

  const renderItem = ({ item }: { item: PrayerRequest }) => {
    const isSelected = selectedIds.has(item.id);
    const displayContent = item.content || item.detail || 'No content';
    const displayAuthor = item.user 
      ? `${item.user.first_name || ''} ${item.user.last_name || ''}`.trim() || 'Anonymous'
      : 'Anonymous';
    const alreadyPrayed = hasUserPrayed(item, userId) || prayedIdSet.has(item.id);
    const prayedCount = getPrayedCount(item);
    const amened = hasUserAmen(item, userId);
    const amenTotal = amenCount(item);
    const prayButtonLabel = alreadyPrayed ? 'Prayed 🙏' : 'Pray now 🙏';

    return (
      <TouchableOpacity activeOpacity={0.9} onPress={() => toggleSelect(item.id)}>
        <View style={[styles.card, isSelected && { borderColor: theme.colors.primary }]}>
          <View style={styles.cardHeaderRow}>
            <Text style={styles.cardAuthor}>{displayAuthor}</Text>
            <View style={[styles.checkbox, isSelected && { backgroundColor: theme.colors.primary }]} />
          </View>
          <View style={styles.cardMetaRow}>
            <View style={[styles.typeBadge, item.type === 'testimony' && { backgroundColor: `${theme.colors.like}20` }]}>
              <Text style={[styles.typeBadgeText, item.type === 'testimony' && { color: theme.colors.like }]}>
                {item.type === 'testimony' ? 'Testimony' : 'Prayer'}
              </Text>
            </View>
            <Text style={styles.cardTime}>{new Date(item.created_at).toLocaleString()}</Text>
          </View>
          <Text style={styles.cardContent}>{displayContent}</Text>
          <View style={styles.cardActions}>
            <PrayButton
              count={prayedCount}
              onPress={() => handlePray(item.id, alreadyPrayed)}
              disabled={alreadyPrayed}
              label={prayButtonLabel}
            />
          </View>
          {prayedCount > 0 && (
            <Text style={styles.prayerCountText}>
              {prayedCount} prayed so far
            </Text>
          )}
          <View style={styles.communityActions}>
            <TouchableOpacity
              style={[styles.communityButton, amened && styles.communityButtonActive]}
              onPress={() => handleAmen(item.id)}
              disabled={amenLoadingId === item.id}
            >
              <Heart size={16} color={amened ? theme.colors.like : theme.colors.text.secondary} filled={amened} />
              <Text style={[styles.communityButtonText, amened && { color: theme.colors.like }]}>
                Amen {amenTotal ? `(${amenTotal})` : ''}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.communityButton}
              onPress={() => openDetail(item.id)}
            >
              <MessageCircle size={16} color={theme.colors.primary} />
              <Text style={styles.communityButtonText}>
                Encourage {item.comments_count ? `(${item.comments_count})` : ''}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  const cycleCategory = useCallback(() => {
    const idx = categories.indexOf(currentCategory);
    const next = categories[(idx + 1) % categories.length];
    setCurrentCategory(next);
  }, [categories, currentCategory]);

  const renderCategoryControl = () => (
    <View style={styles.categoryControlRow}>
      <TouchableOpacity style={styles.categoryPill} onPress={cycleCategory}>
        <Text style={styles.categoryPillText}>{currentCategory[0].toUpperCase() + currentCategory.slice(1)}</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.categoryCaret} onPress={() => setShowCategoryPicker(true)}>
        <ChevronDown size={18} color={theme.colors.text.primary} />
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <StatusBar barStyle="dark-content" />
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.title}>Prayer Requests</Text>
        <View style={{ width: 24 }} />
      </View>

      <View style={styles.composer}>
        <TouchableOpacity style={styles.composeLauncher} onPress={() => openComposeModal('')}>
          <Sparkle size={20} color={theme.colors.primary} />
          <View style={styles.composeLauncherTextWrap}>
            <Text style={styles.composeLauncherTitle}>Share a prayer request</Text>
            <Text style={styles.composeLauncherSubtitle}>Open the composer to invite others to pray</Text>
          </View>
        </TouchableOpacity>
      </View>

      {/* Category toggle / dropdown */}
      <View style={styles.categoryWrap}>
        {renderCategoryControl()}
        <View style={styles.typeToggleRow}>
          {(['all', 'prayer', 'testimony'] as const).map(typeOption => (
            <TouchableOpacity
              key={typeOption}
              style={[styles.typeChip, currentType === typeOption && styles.typeChipActive]}
              onPress={() => setCurrentType(typeOption)}
            >
              <Text style={[styles.typeChipText, currentType === typeOption && styles.typeChipTextActive]}>
                {typeOption === 'all' ? 'All' : typeOption === 'prayer' ? 'Prayers' : 'Testimonies'}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {isLoading && requests.length === 0 ? (
        <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
          <ActivityIndicator color={theme.colors.primary} />
        </View>
      ) : (
        <FlatList
          data={requests}
          keyExtractor={(i) => i.id}
          contentContainerStyle={styles.listContent}
          renderItem={renderItem}
          showsVerticalScrollIndicator={false}
          onEndReached={loadMore}
          onEndReachedThreshold={0.5}
          refreshControl={(
            <RefreshControl
              refreshing={isRefreshing}
              onRefresh={onRefresh}
              tintColor={theme.colors.primary}
            />
          )}
          ListFooterComponent={isLoading && requests.length > 0 ? (
            <View style={{ paddingVertical: theme.spacing.md }}>
              <ActivityIndicator color={theme.colors.primary} />
            </View>
          ) : null}
          ListEmptyComponent={(
            <EmptyState
              title={`No ${currentCategory ?? '' + ' '}requests yet`}
              message={'Be the first to share a prayer request and invite others to pray.'}
              ctaText={'Create a request'}
              onPressCTA={() => openComposeModal('')}
              IconComponent={Heart as any}
            />
          )}
        />
      )}

      {/* Bulk pray action bar */}
      {selectedIds.size > 0 && (
        <View style={[styles.bulkBar, { paddingBottom: insets.bottom || theme.spacing.sm }]}>
          <Text style={styles.bulkText}>{selectedIds.size} selected (max 5)</Text>
          <TouchableOpacity style={[styles.bulkPrayBtn, { opacity: selectedIds.size === 0 ? 0.6 : 1 }]} onPress={openBulkPray}>
            <Text style={styles.bulkPrayText}>Pray ({selectedIds.size})</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Category picker modal */}
      <Modal visible={showCategoryPicker} animationType="fade" transparent>
        <View style={styles.modalBackdrop}>
          <View style={styles.pickerCard}>
            <Text style={styles.modalTitle}>Choose Category</Text>
            <ScrollView style={{ maxHeight: 320 }}>
              {categories.map(cat => (
                <TouchableOpacity
                  key={cat}
                  style={[styles.pickerItem, currentCategory === cat && { backgroundColor: `${theme.colors.primary}10`, borderColor: `${theme.colors.primary}30` }]}
                  onPress={() => { setCurrentCategory(cat); setShowCategoryPicker(false); }}
                >
                  <Text style={[styles.pickerText, currentCategory === cat && { color: theme.colors.primary, fontWeight: '600' }]}>
                    {cat[0].toUpperCase() + cat.slice(1)}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
            <TouchableOpacity style={[styles.modalBtn, { marginTop: theme.spacing.sm, backgroundColor: `${theme.colors.error}15`, borderColor: `${theme.colors.error}40` }]} onPress={() => setShowCategoryPicker(false)}>
              <Text style={[styles.modalBtnText, { color: theme.colors.error }]}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Compose modal */}
      <Modal visible={showComposeModal} animationType="slide" transparent>
        <KeyboardAvoidingView
          style={styles.modalBackdrop}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <View style={styles.composeCard}>
            <Text style={styles.modalTitle}>Share a Prayer Request</Text>
            <Text style={styles.modalSubtitle}>Write from the heart. Others will pray with you.</Text>
            <ScrollView style={{ maxHeight: 260 }}>
              <TextInput
                style={styles.composeInput}
                value={composeDraft}
                onChangeText={setComposeDraft}
                placeholder="Type your prayer request..."
                placeholderTextColor={theme.colors.text.placeholder}
                autoFocus
                multiline
                textAlignVertical="top"
                maxLength={500}
              />
              <Text style={{ ...theme.typography.caption.secondary, color: theme.colors.text.secondary, textAlign: 'right', marginTop: 4 }}>
                {composeDraft.length}/500
              </Text>
              <View style={{ marginTop: theme.spacing.sm }}>
                <Text style={{ ...theme.typography.caption.primary, color: theme.colors.text.secondary, marginBottom: theme.spacing.xs }}>Category</Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: theme.spacing.xs }}>
                  {categories.map(cat => (
                    <TouchableOpacity
                      key={cat}
                      style={{
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        borderRadius: 999,
                        borderWidth: 1,
                        borderColor: composeCategory === cat ? theme.colors.primary : `${theme.colors.border}80`,
                        backgroundColor: composeCategory === cat ? `${theme.colors.primary}10` : 'transparent',
                      }}
                      onPress={() => setComposeCategory(cat)}
                    >
                      <Text style={{ color: composeCategory === cat ? theme.colors.primary : theme.colors.text.primary }}>
                        {cat.replace('_', ' ')}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
              <View style={{ marginTop: theme.spacing.sm }}>
                <Text style={{ ...theme.typography.caption.primary, color: theme.colors.text.secondary, marginBottom: theme.spacing.xs }}>Visibility</Text>
                <View style={{ flexDirection: 'row', gap: theme.spacing.xs }}>
                  {(['anonymous','first_name','full_name'] as const).map(v => (
                    <TouchableOpacity
                      key={v}
                      style={{
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        borderRadius: 999,
                        borderWidth: 1,
                        borderColor: composeVisibility === v ? theme.colors.primary : `${theme.colors.border}80`,
                        backgroundColor: composeVisibility === v ? `${theme.colors.primary}10` : 'transparent',
                      }}
                      onPress={() => setComposeVisibility(v)}
                    >
                      <Text style={{ color: composeVisibility === v ? theme.colors.primary : theme.colors.text.primary }}>
                        {v.replace('_', ' ')}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
              <View style={{ marginTop: theme.spacing.sm }}>
                <Text style={{ ...theme.typography.caption.primary, color: theme.colors.text.secondary, marginBottom: theme.spacing.xs }}>Share as</Text>
                <View style={{ flexDirection: 'row', gap: theme.spacing.xs }}>
                  {(['prayer','testimony'] as const).map(typeOpt => (
                    <TouchableOpacity
                      key={typeOpt}
                      style={{
                        paddingVertical: 6,
                        paddingHorizontal: 10,
                        borderRadius: 999,
                        borderWidth: 1,
                        borderColor: composeType === typeOpt ? theme.colors.primary : `${theme.colors.border}80`,
                        backgroundColor: composeType === typeOpt ? `${theme.colors.primary}10` : 'transparent',
                      }}
                      onPress={() => setComposeType(typeOpt)}
                    >
                      <Text style={{ color: composeType === typeOpt ? theme.colors.primary : theme.colors.text.primary }}>
                        {typeOpt === 'prayer' ? 'Prayer Request' : 'Testimony'}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            </ScrollView>
            <View style={{ flexDirection: 'row', gap: theme.spacing.sm, marginTop: theme.spacing.md }}>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: `${theme.colors.error}15`, borderColor: `${theme.colors.error}40` }]}
                onPress={() => { if (!isPosting) { setShowComposeModal(false); setComposeDraft(''); } }}
                disabled={isPosting}
              >
                <Text style={[styles.modalBtnText, { color: theme.colors.error }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: theme.colors.primary, borderColor: theme.colors.primary, opacity: isPosting ? 0.8 : 1 }]}
                onPress={submitRequest}
                disabled={isPosting}
              >
                <Text style={[styles.modalBtnText, { color: theme.colors.text.inverse }]}>{isPosting ? 'Posting…' : 'Post'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>

      {/* Pray guide modal */}
      <Modal visible={showPrayGuideModal} animationType="fade" transparent>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Committment to God</Text>
            <Text style={styles.modalSubtitle}>
              {hasSeenPrayerGuide
                ? 'Take a focused moment to lift this intention before the Lord Jesus who loves us all so much.'
                : 'Elbiblio prayer requests unite brethren in testimony. Intercessory prayer reflects are unselfish and refelect God’s nature obtaining graces for both the one who prays and the one lifted up to God in prayer.'}
            </Text>
            <View style={{ alignItems: 'center', marginVertical: theme.spacing.md }}>
              <Text style={styles.timerText}>00:{String(Math.max(guideSecondsLeft, 0)).padStart(2, '0')}</Text>
              <Text style={{ ...theme.typography.caption.secondary, color: theme.colors.text.secondary, marginTop: theme.spacing.xs }}>
                Take these {guideDuration} seconds to pray before recording your Amen.
              </Text>
            </View>
            {guideSecondsLeft <= 0 && activePrayerRequest && (
              <View style={{ marginBottom: theme.spacing.md }}>
                <Text style={{ ...theme.typography.caption.primary, color: theme.colors.text.secondary, marginBottom: theme.spacing.xs }}>
                  You're praying for {activePrayerRequest.user?.first_name || activePrayerRequest.user?.last_name || 'Anonymous'}:
                </Text>
                <View style={{ padding: theme.spacing.sm, borderRadius: theme.borderRadius.md, backgroundColor: `${theme.colors.surface}80` }}>
                  <Text style={{ ...theme.typography.body.sans, color: theme.colors.text.primary }}>
                    {activePrayerRequest?.detail || activePrayerRequest?.content || 'No content'}
                  </Text>
                </View>
              </View>
            )}
            <View style={{ flexDirection: 'row', gap: theme.spacing.sm, marginTop: theme.spacing.lg }}>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: `${theme.colors.error}15`, borderColor: `${theme.colors.error}40` }]}
                onPress={closePrayGuide}
                disabled={isRecordingPrayer}
              >
                <Text style={[styles.modalBtnText, { color: theme.colors.error }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: theme.colors.primary, borderColor: theme.colors.primary, opacity: guideSecondsLeft > 0 || isRecordingPrayer ? 0.6 : 1 }]}
                onPress={confirmPrayerRecording}
                disabled={guideSecondsLeft > 0 || isRecordingPrayer}
              >
                <Text style={[styles.modalBtnText, { color: theme.colors.text.inverse }]}>
                  {isRecordingPrayer ? 'Recording…' : guideSecondsLeft > 0 ? 'Pray first…' : 'Record Prayer'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Prayer modal */}
      <Modal visible={showPrayerModal} animationType="slide" transparent>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Thanksgiving</Text>
            <Text style={styles.modalSubtitle}>Lift these intentions in thanksgiving for the next 2 minutes</Text>
            <ScrollView style={{ maxHeight: 200 }} contentContainerStyle={{ paddingVertical: 8 }}>
              {Array.from(selectedIds).map(id => {
                const req = requests.find(r => r.id === id);
                if (!req) return null;
                const displayContent = req.content || req.detail || 'No content';
                const displayAuthor = req.user 
                  ? `${req.user.first_name || ''} ${req.user.last_name || ''}`.trim() || 'Anonymous'
                  : 'Anonymous';
                return (
                  <View key={id} style={styles.intentItem}>
                    <Text style={styles.intentAuthor}>{displayAuthor}</Text>
                    <Text style={styles.intentText}>{displayContent}</Text>
                  </View>
                );
              })}
            </ScrollView>
            <Text style={styles.timerText}>{Math.floor(secondsLeft / 60)}:{String(secondsLeft % 60).padStart(2, '0')}</Text>
            <View style={{ flexDirection: 'row', gap: theme.spacing.sm, marginTop: theme.spacing.md }}>
              <TouchableOpacity style={[styles.modalBtn, { backgroundColor: `${theme.colors.error}15`, borderColor: `${theme.colors.error}40` }]} onPress={() => setShowPrayerModal(false)} disabled={isBulkPraying}>
                <Text style={[styles.modalBtnText, { color: theme.colors.error }]}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.modalBtn, { backgroundColor: theme.colors.primary }]} onPress={completeBulkPrayer} disabled={secondsLeft > 0 || isBulkPraying}>
                <Text style={[styles.modalBtnText, { color: theme.colors.text.inverse }]}>{isBulkPraying ? 'Submitting...' : 'Mark as Prayed'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Detail modal */}
      <Modal visible={!!selectedRequestId} animationType="slide" transparent>
        <KeyboardAvoidingView
          style={styles.detailBackdrop}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <View style={styles.detailCard}>
            <TouchableOpacity style={styles.detailClose} onPress={() => setSelectedRequestId(null)}>
              <Text style={styles.detailCloseText}>Close</Text>
            </TouchableOpacity>
            {activeDetailRequest ? (
              <>
                <Text style={styles.detailTitle}>{activeDetailRequest.title || (activeDetailRequest.type === 'testimony' ? 'Testimony' : 'Prayer Request')}</Text>
                <Text style={styles.detailAuthor}>
                  {activeDetailRequest.user ? `${activeDetailRequest.user.first_name || ''} ${activeDetailRequest.user.last_name || ''}`.trim() || 'Anonymous' : 'Anonymous'} · {new Date(activeDetailRequest.created_at).toLocaleString()}
                </Text>
                <ScrollView style={styles.detailBody}>
                  <Text style={styles.detailContent}>{activeDetailRequest.detail || activeDetailRequest.content || 'No content provided.'}</Text>
                  <View style={styles.detailMetaRow}>
                    <Text style={styles.detailMetaText}>Prayers: {getPrayedCount(activeDetailRequest)}</Text>
                    <Text style={styles.detailMetaText}>Amens: {amenCount(activeDetailRequest)}</Text>
                    <Text style={styles.detailMetaText}>Comments: {activeDetailRequest.comments_count ?? 0}</Text>
                  </View>
                  <View style={styles.commentSection}>
                    <Text style={styles.commentHeading}>Community Replies</Text>
                    {(activeDetailRequest.comments ?? []).length === 0 ? (
                      <Text style={styles.commentEmpty}>Be the first to encourage this request.</Text>
                    ) : (
                      (activeDetailRequest.comments ?? []).map(comment => (
                        <View key={comment.id} style={styles.commentBubble}>
                          <View style={styles.commentHeader}>
                            <Text style={styles.commentAuthor}>
                              {comment.user ? `${comment.user.first_name || ''} ${comment.user.last_name || ''}`.trim() || 'Anonymous' : 'Anonymous'}
                            </Text>
                            <TouchableOpacity
                              style={[styles.commentAmenButton, hasUserAmenComment(comment, userId) && styles.commentAmenButtonActive]}
                              onPress={() => handleCommentAmen(comment.id)}
                            >
                              <Heart size={12} color={hasUserAmenComment(comment, userId) ? theme.colors.like : theme.colors.text.secondary} filled={hasUserAmenComment(comment, userId)} />
                              <Text style={[styles.commentAmenText, hasUserAmenComment(comment, userId) && { color: theme.colors.like }]}>
                                {comment.amen_count || 0}
                              </Text>
                            </TouchableOpacity>
                          </View>
                          <Text style={styles.commentBody}>{comment.content}</Text>
                          <Text style={styles.commentTimestamp}>{new Date(comment.created_at).toLocaleString()}</Text>
                        </View>
                      ))
                    )}
                  </View>
                </ScrollView>
                <View style={styles.commentComposer}>
                  <TextInput
                    style={styles.commentInput}
                    value={commentDraft}
                    onChangeText={setCommentDraft}
                    placeholder="Let them know you prayed or share encouragement..."
                    placeholderTextColor={theme.colors.text.placeholder}
                    multiline
                  />
                  <TouchableOpacity
                    style={[styles.commentSendButton, { opacity: isCommentPosting ? 0.6 : 1 }]}
                    onPress={submitComment}
                    disabled={isCommentPosting}
                  >
                    <Text style={styles.commentSendText}>{isCommentPosting ? 'Sending…' : 'Send'}</Text>
                  </TouchableOpacity>
                </View>
              </>
            ) : (
              <View style={styles.detailLoading}>
                <ActivityIndicator color={theme.colors.primary} />
              </View>
            )}
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  categoryWrap: {
    paddingHorizontal: theme.spacing.md,
    paddingBottom: theme.spacing.sm,
  },
  categoryControlRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
  },
  categoryPill: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: 8,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
  },
  categoryPillText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  categoryCaret: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: theme.colors.surface,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
  },
  bulkBar: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: theme.colors.surface,
    borderTopWidth: 1,
    borderColor: `${theme.colors.primary}10`,
    paddingHorizontal: theme.spacing.md,
    paddingTop: theme.spacing.sm,
  },
  bulkText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  bulkPrayBtn: {
    paddingHorizontal: theme.spacing.lg,
    paddingVertical: 10,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  bulkPrayText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  modalCard: {
    width: '100%',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
  },
  pickerCard: {
    width: '100%',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
  },
  composeCard: {
    width: '100%',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
  },
  pickerItem: {
    paddingVertical: 10,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
    marginBottom: 8,
  },
  pickerText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  composeInput: {
    minHeight: 160,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    backgroundColor: theme.colors.surface,
    padding: theme.spacing.md,
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
  },
  modalTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: 4,
  },
  modalSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  intentItem: {
    marginBottom: theme.spacing.sm,
  },
  intentAuthor: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: 2,
  },
  intentText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
  },
  timerText: {
    ...theme.typography.heading.small,
    color: theme.colors.primary,
    textAlign: 'center',
    marginTop: theme.spacing.sm,
  },
  modalBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    alignItems: 'center',
  },
  modalBtnText: {
    ...theme.typography.caption.primary,
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
  chipsRow: {},
  chip: {},
  composer: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  composeLauncher: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    backgroundColor: `${theme.colors.primary}08`,
    borderRadius: theme.borderRadius.lg,
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}20`,
  },
  composeLauncherTextWrap: {
    flex: 1,
  },
  composeLauncherTitle: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  composeLauncherSubtitle: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  listContent: {
    padding: theme.spacing.md,
    paddingBottom: theme.spacing.xl,
    gap: theme.spacing.md,
  },
  typeToggleRow: {
    flexDirection: 'row',
    gap: theme.spacing.xs,
    marginTop: theme.spacing.sm,
  },
  typeChip: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
    backgroundColor: theme.colors.surface,
  },
  typeChipActive: {
    borderColor: theme.colors.primary,
    backgroundColor: `${theme.colors.primary}12`,
  },
  typeChipText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  typeChipTextActive: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  card: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
  },
  cardHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  cardMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.xs,
  },
  typeBadge: {
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.primary}10`,
  },
  typeBadgeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  checkbox: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}60`,
    backgroundColor: 'transparent',
  },
  cardAuthor: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: 4,
  },
  cardContent: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  cardTime: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 11,
  },
  prayerCountText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  cardActions: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  communityActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.sm,
  },
  communityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.surface}90`,
    borderWidth: 1,
    borderColor: `${theme.colors.border}80`,
  },
  communityButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '600',
  },
  communityButtonActive: {
    backgroundColor: `${theme.colors.like}15`,
    borderColor: `${theme.colors.like}40`,
  },
  prayButton: {
    backgroundColor: `${theme.colors.success}15`,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: 6,
    borderRadius: theme.borderRadius.full,
  },
  prayButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.success,
    fontWeight: '600',
  },
  prayBurstOverlay: {
    position: 'absolute',
    top: -12,
    left: -12,
    right: -12,
    bottom: -12,
    alignItems: 'center',
    justifyContent: 'center',
    pointerEvents: 'none',
    zIndex: -1,
  },
  detailBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'center',
    padding: theme.spacing.lg,
  },
  detailCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}10`,
    maxHeight: '90%',
    padding: theme.spacing.lg,
  },
  detailClose: {
    alignSelf: 'flex-end',
    paddingVertical: 4,
    paddingHorizontal: theme.spacing.sm,
  },
  detailCloseText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    fontWeight: '600',
  },
  detailTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.xs,
  },
  detailAuthor: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.sm,
  },
  detailBody: {
    maxHeight: 320,
  },
  detailContent: {
    ...theme.typography.body.serif,
    color: theme.colors.text.primary,
    marginBottom: theme.spacing.sm,
  },
  detailMetaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
  },
  detailMetaText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  commentSection: {
    marginTop: theme.spacing.md,
    gap: theme.spacing.sm,
  },
  commentHeading: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    fontWeight: '600',
    marginBottom: theme.spacing.xs,
  },
  commentEmpty: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontStyle: 'italic',
  },
  commentBubble: {
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.md,
    backgroundColor: `${theme.colors.surface}95`,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}08`,
    marginBottom: theme.spacing.xs,
  },
  commentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.xs,
  },
  commentAmenButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.surface}90`,
    borderWidth: 1,
    borderColor: `${theme.colors.border}40`,
  },
  commentAmenButtonActive: {
    backgroundColor: `${theme.colors.like}15`,
    borderColor: `${theme.colors.like}40`,
  },
  commentAmenText: {
    fontSize: 11,
    color: theme.colors.text.secondary,
    fontWeight: '600',
  },
  commentAuthor: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: 4,
  },
  commentBody: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  commentTimestamp: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
    fontSize: 10,
    marginTop: 4,
  },
  commentComposer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.md,
  },
  commentInput: {
    flex: 1,
    minHeight: 48,
    maxHeight: 120,
    borderRadius: theme.borderRadius.md,
    borderWidth: 1,
    borderColor: `${theme.colors.primary}15`,
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  commentSendButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.primary,
  },
  commentSendText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  detailLoading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.lg,
  },
});

export default observer(PrayerRequestsScreen);
