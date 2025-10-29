import React, { useState, useRef, useCallback, useEffect, useMemo } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  TouchableWithoutFeedback,
  StyleSheet,
  Platform,
  TextInput,
  ScrollView,
  ActivityIndicator,
  KeyboardAvoidingView,
  Keyboard,
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
import { Platform as RNPlatform } from 'react-native';
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
  Book,
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
import ReflectionComposeModal from '@/components/ReflectionComposeModal';
import { Share as NativeShare } from 'react-native';
import { formatVerseShareMessage } from '@/utils/share';

type VerseDetailProps = NativeStackScreenProps<RootStackParamList, 'VerseDetail'>;

const VerseDetail = ({ navigation, route }: VerseDetailProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const styles = React.useMemo(() => createStyles(theme, insets.bottom), [theme, insets.bottom]);
  
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
  const [showGuide, setShowGuide] = useState(false);
  const [guideCountdown, setGuideCountdown] = useState(30);
  const guideTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
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
  const [uploadProgress, setUploadProgress] = useState<number>(0);

  // Animated values
  const scrollY = useSharedValue(0);
  const scrollX = useSharedValue(0);
  const headerOpacity = useSharedValue(1);
  const composerOpacity = useSharedValue(0);
  const composerTranslateY = useSharedValue(100);

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

  // When opening composer, decide whether to show first-time guide
  useEffect(() => {
    (async () => {
      if (!showReflectionInput) return;
      try {
        const seen = await AsyncStorage.getItem('vd_reflection_guide_seen');
        if (seen === '1') {
          setShowGuide(false);
          return;
        }
        setShowGuide(true);
        setGuideCountdown(30);
        if (guideTimerRef.current) clearInterval(guideTimerRef.current);
        guideTimerRef.current = setInterval(() => {
          setGuideCountdown(prev => {
            if (prev <= 1) {
              if (guideTimerRef.current) clearInterval(guideTimerRef.current);
              guideTimerRef.current = null;
              AsyncStorage.setItem('vd_reflection_guide_seen', '1').catch(() => {});
              setShowGuide(false);
              return 0;
            }
            return prev - 1;
          });
        }, 1000);
      } catch {
        setShowGuide(false);
      }
    })();
    return () => {
      if (guideTimerRef.current) clearInterval(guideTimerRef.current);
      guideTimerRef.current = null;
    };
  }, [showReflectionInput]);

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

  // Removed obsolete handleShare (use handleShareVerse instead)

  const handleCopyVerse = async () => {
    try {
      await Clipboard.setStringAsync(`${currentVerse?.text} (${currentVerse?.reference_display})`);
      toast.success('Verse copied to clipboard');
    } catch (e) {
      toast.error('Failed to copy');
    }
  };

  const handleShareVerse = async () => {
    if (!currentVerse) return;
    try {
      const message = formatVerseShareMessage({
        text: currentVerse.text,
        reference: currentVerse.reference,
        reference_display: (currentVerse as any).reference_display ?? currentVerse.reference,
        book: (currentVerse as any).book ?? undefined,
        chapter: (currentVerse as any).chapter ?? undefined,
        verse: (currentVerse as any).verse ?? undefined,
      });
      await NativeShare.share({ message });
    } catch (error) {
      toast.error('Failed to share verse');
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

      const uploadToS3 = async (uploadUrl: string, fileUri: string, contentType: string) => {
        return new Promise<void>(async (resolve, reject) => {
          try {
            // Read file into blob/binary
            const fileInfo = await FileSystem.getInfoAsync(fileUri);
            if (!fileInfo.exists) throw new Error('File not found');

            // Use XMLHttpRequest to get progress events
            const xhr = new XMLHttpRequest();
            xhr.open('PUT', uploadUrl);
            xhr.setRequestHeader('Content-Type', contentType);
            xhr.upload.onprogress = (evt: any) => {
              if (evt && evt.total) {
                setUploadProgress(Math.min(1, evt.loaded / evt.total));
              }
            };
            xhr.onload = function () {
              if (xhr.status >= 200 && xhr.status < 300) {
                setUploadProgress(1);
                resolve();
              } else {
                reject(new Error(`Upload failed with status ${xhr.status}`));
              }
            };
            xhr.onerror = function () {
              reject(new Error('Upload failed'));
            };
            // Send file as binary
            if (RNPlatform.OS === 'ios') {
              // iOS requires fetching file as blob via fetch
              const res = await fetch(fileUri);
              const blob = await res.blob();
              xhr.send(blob as any);
            } else {
              // Android can use RNFS-like path; fetch to blob for consistency
              const res = await fetch(fileUri);
              const blob = await res.blob();
              xhr.send(blob as any);
            }
          } catch (e) {
            reject(e);
          }
        });
      };

      await uploadToS3(uploadUrl, videoUri, contentType);

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
    
    // Show sticky composer after scrolling past verse content (~400px)
    const shouldShowComposer = nativeEvent.contentOffset.y > 400;
    composerOpacity.value = withTiming(shouldShowComposer ? 1 : 0, { duration: 200 });
    composerTranslateY.value = withSpring(shouldShowComposer ? 0 : 100, {
      damping: 20,
      stiffness: 90,
    });
  }, []);

  // Anchor: measure Reflections section to support precise scrolling
  const reflectionsAnchorRef = useRef<View>(null);
  const scrollViewRef = useRef<ScrollView>(null);
  const [reflectionsY, setReflectionsY] = useState<number | null>(null);
  const scrollToReflections = useCallback(() => {
    if (scrollViewRef.current && reflectionsY !== null) {
      const y = Math.max(0, reflectionsY - 8);
      scrollViewRef.current.scrollTo({ y, animated: true });
    }
  }, [reflectionsY, scrollViewRef]);

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

  const trimmedReflection = reflectionText.trim();
  const wordCount = trimmedReflection ? trimmedReflection.split(/\s+/).filter(Boolean).length : 0;
  const isWordBiteType = reflectionType === 1;
  const isFace2FaceType = reflectionType === 2;
  const exceedsWordLimit = isWordBiteType && wordCount > 50;
  const canSubmit = !isUploading && (
    (isWordBiteType && !!trimmedReflection && !exceedsWordLimit) ||
    (isFace2FaceType && !!videoUri)
  );
  const submitLabel = isUploading
    ? 'Uploading…'
    : isFace2FaceType
      ? (videoUri ? 'Share' : 'Add video to share')
      : 'Share';

  const stickyComposerStyle = useAnimatedStyle(() => ({
    opacity: composerOpacity.value,
    transform: [{ translateY: composerTranslateY.value }],
  }));

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
        <Text style={styles.navigationTitle}>{currentVerse?.reference_display}</Text>
        <View style={styles.navigationRight} />
      </Animated.View>

      {/* Main Content */}
      <ScrollView
        style={styles.mainContent}
        ref={scrollViewRef}
        contentContainerStyle={[
          styles.scrollContent,
          { paddingBottom: (insets.bottom || 0) + (showReflectionInput ? 96 : 72) }
        ]}
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
                {currentVerse.reference_display}
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
                    onPress={handleShareVerse}
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

              {/* Secondary Actions */}
              <View style={styles.secondaryActions}>
                <TouchableOpacity
                  style={styles.copyButton}
                  onPress={handleCopyVerse}
                >
                  <Copy size={16} color={theme.colors.text.secondary} />
                  <Text style={styles.copyText}>Copy Verse</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.copyButton}
                  onPress={() => {
                    if (!currentVerse) return;
                    navigation.navigate('BibleScreen', {
                      book: currentVerse.book || undefined,
                      chapter: currentVerse.chapter || undefined,
                      verse: currentVerse.verse || undefined,
                    } as any);
                  }}
                >
                  <Book size={16} color={theme.colors.text.secondary} />
                  <Text style={styles.copyText}>View Context</Text>
                </TouchableOpacity>
              </View>
            </Animated.View>

            {/* Reflections Section */}
            <View
              ref={reflectionsAnchorRef}
              style={[
                styles.reflectionsSection,
                (!isReflectionsLoading && filteredReflections.length === 0) && { minHeight: SCREEN_DIMENSIONS.height * 0.5 }
              ]}
              onLayout={(e) => setReflectionsY(e.nativeEvent.layout.y)}
            >
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

      {/* Sticky Composer FAB */}
      {!showReflectionInput && (
        <Animated.View style={[styles.stickyComposer, stickyComposerStyle]}>
          <TouchableOpacity
            style={styles.composerFab}
            onPress={() => {
              scrollToReflections();
              setTimeout(() => setShowReflectionInput(true), 150);
            }}
          >
            <MessageCircle size={20} color={theme.colors.text.inverse} />
            <Text style={styles.composerFabText}>Share a reflection</Text>
          </TouchableOpacity>
        </Animated.View>
      )}

      {/* Reflection Compose Full Screen */}
      <ReflectionComposeModal
        visible={showReflectionInput}
        onClose={() => !isUploading && setShowReflectionInput(false)}
        reflectionText={reflectionText}
        onChangeText={setReflectionText}
        reflectionType={reflectionType}
        onChangeType={(t) => setReflectionType(t)}
        isUploading={isUploading}
        canSubmit={canSubmit}
        submitLabel={submitLabel}
        onSubmit={isFace2FaceType ? submitFace2Face : handleSubmitReflection}
        onOpenFaceTips={() => setShowFaceTips(true)}
        onOpenFace2Face={openFace2Face}
      />

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
                    <View style={styles.progressBarWrap}>
                      <View style={[styles.progressBarFill, { width: `${Math.round((uploadProgress || 0) * 100)}%`, backgroundColor: theme.colors.primary }]} />
                    </View>
                    <Text style={[styles.copyText, { marginTop: theme.spacing.xs }]}>
                      {`Uploading… ${Math.round((uploadProgress || 0) * 100)}%`}
                    </Text>
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

const createStyles = (theme: Theme, safeAreaBottom: number = 0) => {

  return StyleSheet.create({
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
  scrollContent: {
    paddingBottom: 0,
  },
  verseContent: {
    padding: theme.spacing.lg,
    paddingTop: theme.spacing.lg,
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
    marginBottom: theme.spacing.md,
  },
  actionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: theme.spacing.md,
    marginTop: theme.spacing.sm,
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
  secondaryActions: {
    flexDirection: 'row',
    gap: theme.spacing.sm,
    marginTop: theme.spacing.md,
  },
  copyButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.surface,
    paddingHorizontal: theme.spacing.md,
    paddingVertical: theme.spacing.sm,
    borderRadius: theme.borderRadius.full,
  },
  copyText: {
    ...theme.typography.caption.secondary,
    color: theme.colors.text.secondary,
  },
  reflectionsSection: {
    paddingTop: theme.spacing.md,
  },
  reflectionsHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.xs,
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
  stickyComposer: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: theme.spacing.md,
    paddingBottom: safeAreaBottom + theme.spacing.md,
    paddingTop: theme.spacing.sm,
    backgroundColor: theme.colors.background,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: theme.colors.border,
    ...theme.shadows.lg,
  },
  composerFab: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: theme.spacing.xs,
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.borderRadius.full,
    ...theme.shadows.md,
  },
  composerFabText: {
    ...theme.typography.button.secondary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
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
  reflectionInput: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    minHeight: 100,
    maxHeight: 160,
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
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
  progressBarWrap: {
    marginTop: theme.spacing.sm,
    width: 220,
    height: 6,
    borderRadius: 3,
    backgroundColor: theme.colors.surfaceVariant,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 3,
  },
});
};

export default observer(VerseDetail);