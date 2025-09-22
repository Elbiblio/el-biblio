import React, { useState, useRef, useCallback, useEffect, useMemo } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Platform,
  TextInput,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { BlurView } from 'expo-blur';
import { CameraView, CameraType, Camera } from 'expo-camera';
import { Video, ResizeMode } from 'expo-av';
import * as FileSystem from 'expo-file-system';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  Heart,
  MessageCircle,
  Share,
  BookmarkSimple,
  ArrowLeft,
  Send,
  Copy,
  Sparkle,
  X,
} from '@/components/Icons';
import ReflectionCard from '@/components/ReflectionCard';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { Reflection, RootStackParamList } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import CommentsOverlay from '@/components/CommentsOverlay';
import { Theme } from '@/theme';
import { SCREEN_DIMENSIONS } from '@/constants';
import { useVerseStore, useAuthStore } from '@/stores/StoreProvider';
import { apiClient, endpoints } from '@/api/client';
import * as Clipboard from 'expo-clipboard';
import { toast } from 'sonner-native';
import { observer } from 'mobx-react-lite';
import EmptyState from '@/components/EmptyState';

type VerseDetailProps = NativeStackScreenProps<RootStackParamList, 'VerseDetail'>;

const VerseDetail = ({ navigation, route }: VerseDetailProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  
  // Store state and actions
  const {
    currentVerse,
    isVerseLoading,
    isReflectionsLoading,
    fetchVerseById,
    createInteraction,
    createReflection,
    createBookmark
  } = useVerseStore();

  // Local state
  const [currentReflectionIndex, setCurrentReflectionIndex] = useState(0);
  const [reflectionFilter, setReflectionFilter] = useState<'all' | 'word' | 'face'>('all');
  const [reflectionSort, setReflectionSort] = useState<'new' | 'top'>('new');
  const [showReflectionInput, setShowReflectionInput] = useState(false);
  const [reflectionText, setReflectionText] = useState('');
  const [reflectionType, setReflectionType] = useState<1 | 2>(1); // 1: story, 2: insight
  const [activeCommentReflectionId, setActiveCommentReflectionId] = useState<string | null>(null);
  // Face2Face capture state
  const [showFace2Face, setShowFace2Face] = useState(false);
  const [hasCameraPermission, setHasCameraPermission] = useState<boolean>(false);
  const [cameraType, setCameraType] = useState<CameraType>('front');
  const cameraRef = useRef<any>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [videoUri, setVideoUri] = useState<string | null>(null);
  const [recordTimer, setRecordTimer] = useState<ReturnType<typeof setTimeout> | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [showFaceTips, setShowFaceTips] = useState(false);

  // Animated values
  const scrollY = useSharedValue(0);
  const scrollX = useSharedValue(0);
  const headerOpacity = useSharedValue(1);

  // Refs
  const flatListRef = useRef<FlatList>(null);

  // Load verse data
  useEffect(() => {
    const loadVerse = async () => {
      // First load verse without reflections for quick display
      await fetchVerseById(route.params.verse.id);
      // Then load with reflections
      await fetchVerseById(route.params.verse.id, true);
    };
    loadVerse();
  }, [route.params.verse.id]);

  // Load persisted reflection UI prefs
  useEffect(() => {
    (async () => {
      try {
        const [f, s] = await Promise.all([
          AsyncStorage.getItem('vd_reflection_filter'),
          AsyncStorage.getItem('vd_reflection_sort'),
        ]);
        if (f === 'all' || f === 'word' || f === 'face') setReflectionFilter(f);
        if (s === 'new' || s === 'top') setReflectionSort(s as any);
      } catch {}
    })();
  }, []);

  // Persist prefs on change
  useEffect(() => {
    AsyncStorage.setItem('vd_reflection_filter', reflectionFilter).catch(() => {});
  }, [reflectionFilter]);
  useEffect(() => {
    AsyncStorage.setItem('vd_reflection_sort', reflectionSort).catch(() => {});
  }, [reflectionSort]);

  // Event handlers
  const handleLike = async () => {
    if (!currentVerse || !user) {
      toast.info('Please log in to like verses');
      return;
    }
    
    try {
      await createInteraction({
        interactable_id: currentVerse.id,
        interactable_type: 'App\\Models\\Verse',
        type: 1, // Like
        user_id: user.id
      });
      toast.success(currentVerse.isLiked ? 'Verse unliked' : 'Verse liked');
    } catch (error) {
      toast.warning('Failed to like verse');
    }
  };

  const handleBookmark = async (clipText?: string) => {
    if (!currentVerse || !user) {
      toast.info('Please log in to bookmark verses');
      return;
    }
    
    try {
      await createBookmark({
        user_id: user.id,
        bookmarkable_type: 'App\\Models\\Verse',
        bookmarkable_id: currentVerse.id,
        clip_text: clipText
      });
      toast.success(currentVerse.isBookmarked ? 'Bookmark removed' : 'Verse bookmarked');
    } catch (error) {      
      toast.error('Failed to bookmark verse');
    }
  };

  const handleShare = async () => {
    if (!currentVerse) return;
    
    try {
      await createInteraction({
        interactable_id: currentVerse.id,
        interactable_type: 'App\\Models\\Verse',
        type: 3, // Share
        user_id: user?.id || ''
      });
      
      // todo: Implement sharing
      // await Share.share({
      //   message: `${currentVerse.text} (${currentVerse.reference})`
      // });
      
    } catch (error) {
      toast.error('Failed to share verse');
    }
  };

  const handleCopyVerse = async () => {
    if (!currentVerse) return;
    
    try {
      await Clipboard.setStringAsync(
        `${currentVerse.text} (${currentVerse.reference})`
      );
      toast.success('Verse copied to clipboard');
    } catch (error) {
      toast.error('Failed to copy verse');
    }
  };

  const handleSubmitReflection = async () => {
    if (!reflectionText.trim() || !currentVerse || !user) {
      if (!user) {
        toast.info('Please log in to share reflections');
      }
      return;
    }
    
    try {
      await createReflection({
        content: reflectionText.trim(),
        type: reflectionType,
        user_id: user.id,
        verse_id: currentVerse.id
      });
      
      setReflectionText('');
      setShowReflectionInput(false);
      toast.success('Reflection shared successfully');
    } catch (error) {
      toast.error('Failed to share reflection');
    }
  };

  // Face2Face helpers
  const ensureCameraPermission = async () => {
    try {
      const existing = await Camera.getCameraPermissionsAsync();
      if (existing.status === 'granted') {
        setHasCameraPermission(true);
        return true;
      }
      const res = await Camera.requestCameraPermissionsAsync();
      const granted = res.status === 'granted';
      setHasCameraPermission(granted);
      if (!granted) toast.error('Camera permission is required for Face2Face');
      return granted;
    } catch {
      toast.error('Unable to check camera permission');
      return false;
    }
  };

  const openFace2Face = async () => {
    if (!(await ensureCameraPermission())) return;
    setShowFace2Face(true);
  };

  const startRecording = async () => {
    if (!cameraRef.current || isRecording) return;
    try {
      setIsRecording(true);
      // Auto-stop after 90s
      const t = setTimeout(stopRecording, 90_000);
      setRecordTimer(t);
      await (cameraRef.current as any).startRecording({
        maxDuration: 90,
        onRecordingFinished: (video: { uri?: string }) => {
          if (video?.uri) setVideoUri(video.uri);
          setIsRecording(false);
        },
        onRecordingError: () => {
          toast.error('Recording error');
          setIsRecording(false);
        },
      } as any);
    } catch (e) {
      toast.error('Unable to start recording');
      setIsRecording(false);
    }
  };

  const stopRecording = async () => {
    if (recordTimer) clearTimeout(recordTimer);
    setRecordTimer(null);
    try {
      (cameraRef.current as any)?.stopRecording();
    } catch {}
    setIsRecording(false);
  };

  const flipCamera = () => {
    setCameraType((prev: CameraType) => (prev === 'front' ? 'back' : 'front'));
  };

  const resetFace2Face = () => {
    setVideoUri(null);
    setIsRecording(false);
  };

  const submitFace2Face = async () => {
    if (!currentVerse || !user || !videoUri) return;
    try {
      setIsUploading(true);
      // 1) Presign upload (S3 PUT)
      const fileName = videoUri.split('/').pop() || `face2face_${Date.now()}.mp4`;
      const contentType = 'video/mp4';
      const directory = `videos/user_${user.id}`;
      const presign = await apiClient.post<{ uploadUrl: string; publicUrl: string; key: string; expires_in: number; thumbnail?: { uploadUrl: string; publicUrl: string; key: string } | null }>(
        endpoints.uploads.presign,
        { fileName, contentType, directory, acl: 'public-read' }
      );
      if (!presign.success) throw new Error(presign.message || 'Failed to prepare upload');
      const { uploadUrl, publicUrl } = presign.data;

      // 2) PUT binary to S3
      const uploadRes = await FileSystem.uploadAsync(uploadUrl, videoUri, {
        httpMethod: 'PUT',
        headers: { 'Content-Type': contentType },
        uploadType: FileSystem.FileSystemUploadType.BINARY_CONTENT,
      });
      if (uploadRes.status !== 200) throw new Error('Upload failed');

      // 3) Create reflection pointing to uploaded media
      await createReflection({
        content: (reflectionText?.trim() || 'Face2Face'),
        type: 2,
        user_id: user.id,
        verse_id: currentVerse.id,
        media_url: publicUrl,
        media_provider: 's3',
        // duration_seconds: could be extracted with a probe; omitted for now
      });
      setShowFace2Face(false);
      setVideoUri(null);
      setReflectionText('');
      setShowReflectionInput(false);
      toast.success('Face2Face uploaded');
    } catch (e) {
      toast.error('Failed to save Face2Face');
    }
    finally {
      setIsUploading(false);
    }
  };

  // Animation styles
  const headerStyle = useAnimatedStyle(() => ({
    opacity: headerOpacity.value,
    transform: [{
      translateY: interpolate(
        scrollY.value,
        [0, 60],
        [0, -10],
        Extrapolation.CLAMP
      )
    }],
  }));

  const navigationStyle = useAnimatedStyle(() => ({
    opacity: interpolate(
      scrollY.value,
      [0, 100],
      [0.8, 1],
      Extrapolation.CLAMP
    ),
    backgroundColor: `${theme.colors.background}${
      interpolate(scrollY.value, [0, 100], [0, 99], Extrapolation.CLAMP)
        .toString(16)
        .padStart(2, '0')
    }`,
  }));

  const handleScroll = useCallback(({ nativeEvent }: { nativeEvent: any }) => {
    scrollY.value = nativeEvent.contentOffset.y;
    headerOpacity.value = withTiming(
      interpolate(
        nativeEvent.contentOffset.y,
        [0, 100],
        [1, 0],
        Extrapolation.CLAMP
      )
    );
  }, []);

  // Derived reflections (filter + sort)
  const filteredReflections = useMemo(() => {
    const list = currentVerse?.reflections || [];
    const filtered = list.filter((r: Reflection) => {
      if (reflectionFilter === 'all') return true;
      if (reflectionFilter === 'face') return !!r.media_url || r.type === 2;
      if (reflectionFilter === 'word') return !r.media_url && r.type === 1;
      return true;
    });
    const sorted = [...filtered].sort((a, b) => {
      if (reflectionSort === 'top') return (b.likes || 0) - (a.likes || 0);
      const ad = new Date(a.created_at).getTime();
      const bd = new Date(b.created_at).getTime();
      return bd - ad;
    });
    return sorted;
  }, [currentVerse?.reflections, reflectionFilter, reflectionSort]);

  // Chip counts
  const chipCounts = useMemo(() => {
    const list = currentVerse?.reflections || [];
    const all = list.length;
    const face = list.filter((r: Reflection) => !!r.media_url || r.type === 2).length;
    const word = list.filter((r: Reflection) => !r.media_url && r.type === 1).length;
    return { all, word, face };
  }, [currentVerse?.reflections]);

  // Reflection rendering
  const renderReflection = useCallback(({ item, index }: { item: Reflection; index: number }) => (
    <ReflectionCard
      reflection={item}
      scrollX={scrollX}
      index={index}
      onCommentPress={() => setActiveCommentReflectionId(item.id)}
      expanded={false}
      onPress={() => navigation.navigate('ReflectionDetail', { reflection: item })}
    />
  ), [navigation]);

  const keyExtractor = useCallback((item: Reflection) => item.id, []);

  const onReflectionsMomentumEnd = useCallback((e: any) => {
    const cardWidth = SCREEN_DIMENSIONS.width - theme.spacing.md * 2;
    const offsetX = e.nativeEvent.contentOffset.x || 0;
    const idx = Math.round(offsetX / cardWidth);
    setCurrentReflectionIndex(Math.max(0, Math.min(idx, filteredReflections.length - 1)));
  }, [filteredReflections.length, theme.spacing.md]);

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Navigation Header */}
      <Animated.View style={[styles.navigationHeader, navigationStyle]}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <ArrowLeft size={24} color={theme.colors.text.primary} />
        </TouchableOpacity>
        <Text style={styles.navigationTitle}>{currentVerse?.reference}</Text>
        <View style={styles.navigationRight} />
      </Animated.View>

      {/* Main Content */}
      <ScrollView
        style={styles.mainContent}
        onScroll={handleScroll}
        scrollEventThrottle={16}
        showsVerticalScrollIndicator={false}
      >
        {isVerseLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator color={theme.colors.primary} size="large" />
          </View>
        ) : currentVerse ? (
          <>
            {/* Verse Content */}
            <Animated.View style={[styles.verseContent, headerStyle]}>
              <Text style={styles.verseTitle}>
                {currentVerse.reference}
                <Text style={styles.translation}> · {currentVerse.translation}</Text>
              </Text>
              <Text style={styles.verseText}>{currentVerse.text}</Text>

              {/* Verse Actions */}
              <View style={styles.actionRow}>
                <View style={styles.actionGroup}>
                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={handleLike}
                  >
                    <Heart
                      size={24}
                      color={currentVerse.isLiked ? theme.colors.like : theme.colors.text.secondary}
                      filled={currentVerse.isLiked}
                    />
                    <Text style={styles.actionCount}>{currentVerse.likes}</Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={() => setShowReflectionInput(true)}
                  >
                    <MessageCircle size={24} color={theme.colors.text.secondary} />
                    <Text style={styles.actionCount}>
                      {currentVerse.reflections?.length || 0}
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.actionButton}
                    onPress={handleShare}
                  >
                    <Share size={24} color={theme.colors.text.secondary} />
                  </TouchableOpacity>
                </View>

                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={() => handleBookmark()}
                >
                  <BookmarkSimple
                    size={24}
                    color={currentVerse.isBookmarked ? theme.colors.primary : theme.colors.text.secondary}
                    filled={currentVerse.isBookmarked}
                  />
                </TouchableOpacity>
              </View>

              <TouchableOpacity
                style={styles.copyButton}
                onPress={handleCopyVerse}
              >
                <Copy size={16} color={theme.colors.text.secondary} />
                <Text style={styles.copyText}>Copy Verse</Text>
              </TouchableOpacity>
            </Animated.View>

            {/* Reflections Section */}
            <View style={styles.reflectionsSection}>
              <View style={styles.reflectionsHeaderRow}>
                <Text style={styles.sectionTitle}>Reflections</Text>
                <View style={styles.sortToggleGroup}>
                  <TouchableOpacity
                    style={[styles.sortToggle, reflectionSort === 'new' && styles.sortToggleActive]}
                    onPress={() => setReflectionSort('new')}
                  >
                    <Text style={[styles.sortToggleText, reflectionSort === 'new' && styles.sortToggleTextActive]}>Newest</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.sortToggle, reflectionSort === 'top' && styles.sortToggleActive]}
                    onPress={() => setReflectionSort('top')}
                  >
                    <Text style={[styles.sortToggleText, reflectionSort === 'top' && styles.sortToggleTextActive]}>Top</Text>
                  </TouchableOpacity>
                </View>
              </View>

              {/* Filter chips */}
              <View style={styles.filterChipsRow}>
                <TouchableOpacity
                  style={[styles.chip, reflectionFilter === 'all' && styles.chipActive]}
                  onPress={() => setReflectionFilter('all')}
                >
                  <Text style={[styles.chipText, reflectionFilter === 'all' && styles.chipTextActive]}>All ({chipCounts.all})</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.chip, reflectionFilter === 'word' && styles.chipActive]}
                  onPress={() => setReflectionFilter('word')}
                >
                  <Text style={[styles.chipText, reflectionFilter === 'word' && styles.chipTextActive]}>Word Bites ({chipCounts.word})</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.chip, reflectionFilter === 'face' && styles.chipActive]}
                  onPress={() => setReflectionFilter('face')}
                >
                  <Text style={[styles.chipText, reflectionFilter === 'face' && styles.chipTextActive]}>Face2Face ({chipCounts.face})</Text>
                </TouchableOpacity>
              </View>
              
              {isReflectionsLoading ? (
                <ActivityIndicator color={theme.colors.primary} />
              ) : filteredReflections.length ? (
                <>
                  <FlatList
                    data={filteredReflections}
                    renderItem={renderReflection}
                    keyExtractor={keyExtractor}
                    horizontal
                    showsHorizontalScrollIndicator={false}
                    snapToAlignment="center"
                    snapToInterval={SCREEN_DIMENSIONS.width - theme.spacing.md * 2}
                    decelerationRate="fast"
                    ref={flatListRef}
                    onMomentumScrollEnd={onReflectionsMomentumEnd}
                    contentContainerStyle={[styles.reflectionsList, { paddingHorizontal: theme.spacing.md }]}
                    ListHeaderComponent={<View style={{ width: theme.spacing.md }} />}
                    ListFooterComponent={<View style={{ width: theme.spacing.md }} />}
                  />
                  {/* Page dots */}
                  <View style={styles.pageDotsRow}>
                    {filteredReflections.map((_: Reflection, i: number) => (
                      <View
                        key={`dot-${i}`}
                        style={[styles.pageDot, i === currentReflectionIndex && styles.pageDotActive]}
                      />
                    ))}
                  </View>
                </>
              ) : (
                <EmptyState
                  title={reflectionFilter === 'all' ? 'No reflections yet' : 'No reflections in this filter'}
                  message={reflectionFilter === 'all' ? 'Be the first to share your thoughts.' : 'Try switching filters or share one to get things started.'}
                  ctaText="Share a reflection"
                  onPressCTA={() => setShowReflectionInput(true)}
                />
              )}
            </View>
          </>
        ) : null}
      </ScrollView>

      {/* Reflection Input Modal */}
      {showReflectionInput && (
        <BlurView intensity={20} style={[styles.reflectionInputContainer, {paddingBottom: theme.spacing.lg + Platform.OS === "ios" ? 20 : 0 }]}>
          <View style={styles.reflectionTypeSelector}>
            <TouchableOpacity
              style={[
                styles.typeButton,
                reflectionType === 1 && styles.typeButtonActive
              ]}
              onPress={() => setReflectionType(1)}
            >
              <Text style={[
                styles.typeButtonText,
                reflectionType === 1 && styles.typeButtonTextActive
              ]}>Word Bite</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.typeButton,
                reflectionType === 2 && styles.typeButtonActive
              ]}
              onPress={() => setReflectionType(2)}
            >
              <Text style={[
                styles.typeButtonText,
                reflectionType === 2 && styles.typeButtonTextActive
              ]}>Face2Face</Text>
            </TouchableOpacity>
          </View>
          
          <TextInput
            style={styles.reflectionInput}
            placeholder={reflectionType === 1 ? "Share a Word Bite... (<= 50 words)" : "Face2Face: short video (<= 90s, square) — caption (optional)"}
            multiline
            maxLength={500}
            value={reflectionText}
            onChangeText={setReflectionText}
            autoFocus
          />
          {/* Word count for Word Bites */}
          {reflectionType === 1 && (
            <Text style={[styles.actionCount, { alignSelf: 'flex-end', marginRight: 8 }]}>
              {reflectionText.trim().split(/\s+/).filter(Boolean).length}/50 words
            </Text>
          )}
          {/* Face2Face capture controls */}
          {reflectionType === 2 && (
            <View style={{ flexDirection: 'row', justifyContent: 'flex-end', marginTop: theme.spacing.xs }}>
              <View style={{ flexDirection: 'row', gap: theme.spacing.sm }}>
                <TouchableOpacity style={[styles.copyButton]} onPress={() => setShowFaceTips(true)}>
                  <Sparkle size={16} color={theme.colors.text.secondary} />
                  <Text style={styles.copyText}>Tips</Text>
                </TouchableOpacity>
                <TouchableOpacity style={[styles.copyButton]} onPress={openFace2Face}>
                  <Text style={styles.copyText}>{videoUri ? 'Retake Face2Face' : 'Record Face2Face'}</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
          
          {/* Helper hint */}
          <View style={{ marginTop: theme.spacing.xs, paddingHorizontal: theme.spacing.xs }}>
            {reflectionType === 1 ? (
              <Text style={[styles.actionCount, { alignSelf: 'flex-start' }]}>Keep it concise and heartfelt. Max 50 words.</Text>
            ) : (
              <Text style={[styles.actionCount, { alignSelf: 'flex-start' }]}>Square portrait · up to 90s · good lighting · speak clearly. Caption optional.</Text>
            )}
          </View>

          <View style={styles.inputActions}>
            <TouchableOpacity
              style={styles.cancelButton}
              onPress={() => !isUploading && setShowReflectionInput(false)}
              disabled={isUploading}
            >
              <Text style={styles.cancelText}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.submitButton,
                (isUploading || !reflectionText.trim() || (reflectionType === 1 && (reflectionText.trim().split(/\s+/).filter(Boolean).length > 50))) && styles.submitButtonDisabled
              ]}
              onPress={isUploading ? undefined : (reflectionType === 2 && videoUri ? submitFace2Face : handleSubmitReflection)}
              disabled={isUploading || !reflectionText.trim() || (reflectionType === 1 && (reflectionText.trim().split(/\s+/).filter(Boolean).length > 50))}
            >
              <Text style={styles.submitText}>{isUploading ? 'Uploading…' : (reflectionType === 2 ? (videoUri ? 'Share' : 'Add video to share') : 'Share')}</Text>
              <Send size={16} color={theme.colors.text.inverse} />
            </TouchableOpacity>
          </View>
        </BlurView>
      )}

      {/* Face2Face Modal */}
      {showFace2Face && (
        <View style={styles.faceModalOverlay}>
          <View style={styles.faceModal}>
            {!videoUri ? (
              <>
                <CameraView
                  ref={(r) => (cameraRef.current = r)}
                  style={styles.camera}
                  facing={cameraType}
                  ratio="1:1"
                />
                {/* Uploading overlay */}
                {isUploading && (
                  <View style={styles.overlayCenter}>
                    <ActivityIndicator color={theme.colors.primary} size="large" />
                    <Text style={[styles.copyText, { marginTop: theme.spacing.sm }]}>Uploading… Please keep the app open</Text>
                  </View>
                )}
                <View style={styles.faceControls}>
                  <TouchableOpacity style={styles.faceBtn} onPress={flipCamera}>
                    <Text style={styles.faceBtnText}>Flip</Text>
                  </TouchableOpacity>
                  {isRecording ? (
                    <TouchableOpacity style={[styles.faceBtn, styles.stopBtn]} onPress={isUploading ? undefined : stopRecording} disabled={isUploading}>
                      <Text style={[styles.faceBtnText, { color: '#FFF' }]}>Stop</Text>
                    </TouchableOpacity>
                  ) : (
                    <TouchableOpacity style={[styles.faceBtn, styles.recordBtn]} onPress={isUploading ? undefined : startRecording} disabled={isUploading}>
                      <Text style={[styles.faceBtnText, { color: '#FFF' }]}>Rec • 90s</Text>
                    </TouchableOpacity>
                  )}
                  <TouchableOpacity style={styles.faceBtn} onPress={() => !isUploading && setShowFace2Face(false)} disabled={isUploading}>
                    <Text style={styles.faceBtnText}>Close</Text>
                  </TouchableOpacity>
                </View>
              </>
            ) : (
              <>
                <View style={[styles.camera]}>
                  {!!videoUri && (
                    <Video
                      style={[StyleSheet.absoluteFill, { width: '100%', height: '100%' }]}
                      source={{ uri: videoUri }}
                      useNativeControls
                      resizeMode={ResizeMode.COVER}
                    />
                  )}
                </View>
                {/* Uploading overlay */}
                {isUploading && (
                  <View style={styles.overlayCenter}>
                    <ActivityIndicator color={theme.colors.primary} size="large" />
                    <Text style={[styles.copyText, { marginTop: theme.spacing.sm }]}>Uploading… Please keep the app open</Text>
                  </View>
                )}
                <View style={styles.faceControls}>
                  <TouchableOpacity style={styles.faceBtn} onPress={isUploading ? undefined : resetFace2Face} disabled={isUploading}>
                    <Text style={styles.faceBtnText}>Retake</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.faceBtn, styles.recordBtn]} onPress={() => !isUploading && setShowFace2Face(false)} disabled={isUploading}>
                    <Text style={[styles.faceBtnText, { color: '#FFF' }]}>{isUploading ? 'Uploading…' : 'Use Video'}</Text>
                  </TouchableOpacity>
                </View>
              </>
            )}
          </View>
        </View>
      )}

      {/* Tips Modal */}
      {showFaceTips && (
        <View style={styles.faceModalOverlay}>
          <View style={styles.tipsModal}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={styles.tipsTitle}>Tips for a great Face2Face</Text>
              <TouchableOpacity onPress={() => setShowFaceTips(false)}>
                <X size={20} color={theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>
            <View style={styles.tipsList}>
              <Text style={styles.tipsItem}>• Keep it under 90 seconds and shoot in a quiet place</Text>
              <Text style={styles.tipsItem}>• Use good lighting and frame your face in the center</Text>
              <Text style={styles.tipsItem}>• Share what the verse means to you and a practical takeaway</Text>
              <Text style={styles.tipsItem}>• Optionally add a short caption to summarize your message</Text>
              <Text style={styles.tipsItem}>• Be respectful and encouraging — our community values kindness</Text>
            </View>
            <TouchableOpacity style={[styles.faceBtn, styles.recordBtn, { alignSelf: 'flex-end' }]} onPress={() => setShowFaceTips(false)}>
              <Text style={[styles.faceBtnText, { color: '#FFF' }]}>Got it</Text>
            </TouchableOpacity>
          </View>
        </View>
      )}
      {/* Comments Overlay */}
      {activeCommentReflectionId && currentVerse?.reflections && (
        <CommentsOverlay
          visible={true}
          onClose={() => setActiveCommentReflectionId(null)}
          reflection={currentVerse.reflections.find(
            (r: Reflection) => r.id === activeCommentReflectionId
          )!}
        />
      )}
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  navigationHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: theme.colors.border,
  },
  backButton: {
    padding: theme.spacing.xs,
  },
  navigationTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  navigationRight: {
    width: 40, // Balance layout with back button
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: theme.spacing.xl * 2,
  },
  mainContent: {
    flex: 1,
  },
  verseContent: {
    padding: theme.spacing.lg,
  },
  verseTitle: {
    ...theme.typography.verse.emphasis,
    color: theme.colors.primary,
    fontSize: 20,
    marginBottom: theme.spacing.sm,
  },
  translation: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  verseText: {
    ...theme.typography.verse.regular,
    color: theme.colors.text.primary,
    fontSize: 24,
    lineHeight: 36,
    marginBottom: theme.spacing.lg,
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: theme.spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderColor: theme.colors.border,
  },
  actionGroup: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.md,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    padding: theme.spacing.xs,
  },
  actionCount: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    alignSelf: 'flex-start',
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
    marginTop: theme.spacing.sm,
  },
  copyText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  reflectionsSection: {
    paddingTop: theme.spacing.xl,
  },
  reflectionsHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.lg,
  },
  sortToggleGroup: {
    flexDirection: 'row',
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.full,
    overflow: 'hidden',
  },
  sortToggle: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
  },
  sortToggleActive: {
    backgroundColor: theme.colors.primary,
  },
  sortToggleText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  sortToggleTextActive: {
    color: theme.colors.text.inverse,
  },
  filterChipsRow: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    paddingHorizontal: theme.spacing.lg,
    marginTop: theme.spacing.sm,
    marginBottom: theme.spacing.sm,
  },
  chip: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
  },
  chipActive: {
    backgroundColor: `${theme.colors.primary}20`,
    borderWidth: 1,
    borderColor: theme.colors.primary,
  },
  chipText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  chipTextActive: {
    color: theme.colors.primary,
    fontWeight: '600',
  },
  sectionTitle: {
    ...theme.typography.heading.medium,
    color: theme.colors.text.primary,
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.md,
  },
  reflectionsList: {
    paddingHorizontal: theme.spacing.md,
  },
  pageDotsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
    paddingVertical: theme.spacing.sm,
  },
  pageDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: theme.colors.surfaceVariant,
  },
  pageDotActive: {
    backgroundColor: theme.colors.primary,
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  emptyState: {
    padding: theme.spacing.xl,
    alignItems: 'center',
  },
  emptyText: {
    ...theme.typography.body.serif,
    color: theme.colors.text.secondary,
    textAlign: 'center',
  },
  reflectionInputContainer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: theme.spacing.lg,
  },
  reflectionTypeSelector: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    marginBottom: theme.spacing.md,
  },
  typeButton: {
    flex: 1,
    padding: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
    alignItems: 'center',
  },
  typeButtonActive: {
    backgroundColor: theme.colors.primary,
  },
  typeButtonText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
  },
  typeButtonTextActive: {
    color: theme.colors.text.inverse,
  },
  reflectionInput: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    maxHeight: 120,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
  },
  inputActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.sm,
  },
  cancelButton: {
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
  },
  cancelText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  submitButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.primary,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  submitButtonDisabled: {
    opacity: 0.5,
  },
  submitText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.inverse,
  },
  // Face2Face styles
  faceModalOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.5)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: theme.spacing.md,
  },
  faceModal: {
    width: '100%',
    maxWidth: 520,
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
  },
  camera: {
    width: '100%',
    aspectRatio: 1,
    backgroundColor: '#000',
  },
  faceControls: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: theme.spacing.md,
    backgroundColor: theme.colors.surface,
  },
  faceBtn: {
    paddingVertical: theme.spacing.sm,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: `${theme.colors.text.secondary}10`,
  },
  stopBtn: {
    backgroundColor: theme.colors.error,
  },
  recordBtn: {
    backgroundColor: theme.colors.primary,
  },
  faceBtnText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.primary,
    fontWeight: '600',
  },
  previewText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  overlayCenter: {
    ...StyleSheet.absoluteFillObject as any,
    backgroundColor: 'rgba(0,0,0,0.3)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  tipsModal: {
    width: '100%',
    maxWidth: 520,
    backgroundColor: theme.colors.background,
    borderRadius: theme.borderRadius.lg,
    overflow: 'hidden',
    padding: theme.spacing.lg,
  },
  tipsTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
  },
  tipsList: {
    marginVertical: theme.spacing.md,
    gap: theme.spacing.xs,
  },
  tipsItem: {
    ...theme.typography.body.sans,
    color: theme.colors.text.secondary,
  },
});

export default observer(VerseDetail);