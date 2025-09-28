import React, { useEffect, useMemo, useState, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, StatusBar, FlatList, TextInput, ActivityIndicator, RefreshControl, Modal, ScrollView } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useTheme } from '@/contexts/ThemeContext';
import { Theme } from '@/theme';
import { type RootStackParamList, type PrayerRequest } from '@/types';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { ArrowLeft, ChevronDown, Sparkle, Heart } from '@/components/Icons';
import { observer } from 'mobx-react-lite';
import { usePrayerRequestsStore } from '@/stores/StoreProvider';
import EmptyState from '@/components/EmptyState';
import Animated, { useSharedValue, withSpring, useAnimatedStyle, withTiming } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { toast } from 'sonner-native';

export type PrayerRequestsScreenProps = NativeStackScreenProps<RootStackParamList, 'PrayerRequestsScreen'>;

const PrayerRequestsScreen = ({ navigation }: PrayerRequestsScreenProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const styles = useMemo(() => createStyles(theme), [theme]);

  const prayerRequestsStore = usePrayerRequestsStore();
  const { requests, isLoading, pagination, fetchRequests, createRequest, prayForRequest } = prayerRequestsStore;

  const [isRefreshing, setIsRefreshing] = useState(false);
  const [currentCategory, setCurrentCategory] = useState<'all' | string>('all');
  const [showCategoryPicker, setShowCategoryPicker] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [showPrayerModal, setShowPrayerModal] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(120);
  const [showComposeModal, setShowComposeModal] = useState(false);
  const [composeDraft, setComposeDraft] = useState('');
  const [isPosting, setIsPosting] = useState(false);
  const [isBulkPraying, setIsBulkPraying] = useState(false);

  const categories = useMemo(() => (
    ['all','healing','guidance','provision','thanksgiving','protection','relationships','work','other']
  ), []);

  useEffect(() => {
    fetchRequests(1, { category: currentCategory });
  }, [fetchRequests, currentCategory]);

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

    const payload: { content: string; visibility: 'public'; category?: string } = {
      content: body,
      visibility: 'public',
    };

    if (currentCategory !== 'all') {
      payload.category = currentCategory;
    }

    setIsPosting(true);
    try {
      const created = await createRequest(payload);
      if (created) {
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        toast.success('Prayer request shared');
        setComposeDraft('');
        setShowComposeModal(false);
      } else {
        toast.error('We could not share your prayer request. Please try again.');
      }
    } catch (error) {
      toast.error('We could not share your prayer request. Please try again.');
    } finally {
      setIsPosting(false);
    }
  }, [composeDraft, currentCategory, createRequest]);

  const handlePray = useCallback(async (id: string) => {
    await prayForRequest(id);
  }, [prayForRequest]);

  const onRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await fetchRequests(1, { category: currentCategory });
    setIsRefreshing(false);
  }, [fetchRequests, currentCategory]);

  const loadMore = useCallback(() => {
    if (isLoading || !pagination.hasMore) return;
    fetchRequests((pagination.currentPage || 1) + 1, { category: currentCategory });
  }, [isLoading, pagination, fetchRequests, currentCategory]);

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
    try {
      const ids = Array.from(selectedIds);
      for (const id of ids) {
        // best-effort; continue on failures
        // eslint-disable-next-line no-await-in-loop
        await prayForRequest(id);
      }
      setSelectedIds(new Set());
      setShowPrayerModal(false);
    } finally {
      setIsBulkPraying(false);
    }
  }, [selectedIds, prayForRequest, isBulkPraying]);

  const PrayButton = ({ count, onPress }: { count?: number; onPress: () => void }) => {
    const scale = useSharedValue(1);
    const burstScale = useSharedValue(0.6);
    const burstOpacity = useSharedValue(0);

    const btnStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
    const burstStyle = useAnimatedStyle(() => ({ opacity: burstOpacity.value, transform: [{ scale: burstScale.value }] }));

    const handlePress = async () => {
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
          <TouchableOpacity style={styles.prayButton} onPress={handlePress}>
            <Text style={styles.prayButtonText}>I prayed 🙏 {count ? `(${count})` : ''}</Text>
          </TouchableOpacity>
        </View>
      </Animated.View>
    );
  };

  const renderItem = ({ item }: { item: PrayerRequest }) => {
    const isSelected = selectedIds.has(item.id);
    return (
      <TouchableOpacity activeOpacity={0.9} onPress={() => toggleSelect(item.id)}>
        <View style={[styles.card, isSelected && { borderColor: theme.colors.primary }]}>
          <View style={styles.cardHeaderRow}>
            <Text style={styles.cardAuthor}>{item.user ? `${item.user.first_name} ${item.user.last_name}` : 'Anonymous'}</Text>
            <View style={[styles.checkbox, isSelected && { backgroundColor: theme.colors.primary }]} />
          </View>
          <Text style={styles.cardContent}>{item.content}</Text>
          <Text style={styles.cardTime}>{new Date(item.created_at).toLocaleString()}</Text>
          <View style={styles.cardActions}>
            <PrayButton count={item.prayed_count} onPress={() => handlePray(item.id)} />
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
              title={`No ${currentCategory === 'all' ? '' : currentCategory + ' '}requests yet`}
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
        <View style={styles.modalBackdrop}>
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
              />
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
        </View>
      </Modal>

      {/* Prayer modal */}
      <Modal visible={showPrayerModal} animationType="slide" transparent>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Prayer Time</Text>
            <Text style={styles.modalSubtitle}>Lift these intentions for the next 2 minutes</Text>
            <ScrollView style={{ maxHeight: 200 }} contentContainerStyle={{ paddingVertical: 8 }}>
              {Array.from(selectedIds).map(id => {
                const req = requests.find(r => r.id === id);
                if (!req) return null;
                return (
                  <View key={id} style={styles.intentItem}>
                    <Text style={styles.intentAuthor}>{req.user ? `${req.user.first_name} ${req.user.last_name}` : 'Anonymous'}</Text>
                    <Text style={styles.intentText}>{req.content}</Text>
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
  chipText: {},
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
  cardActions: {
    marginTop: theme.spacing.sm,
    flexDirection: 'row',
    justifyContent: 'flex-end',
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
  },
});

export default observer(PrayerRequestsScreen);
