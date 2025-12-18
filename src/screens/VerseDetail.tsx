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
// import { CameraView, CameraType, Camera } from 'expo-camera';
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
  Copy,
  X,
  Book,
} from '@/components/Icons';
import ReflectionCard from '@/components/ReflectionCard';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useFocusEffect } from '@react-navigation/native';
import type { Reflection, RootStackParamList } from '@/types';
import { useTheme } from '@/contexts/ThemeContext';
import CommentsOverlay from '@/components/CommentsOverlay';
import { Theme } from '@/theme';
import { SCREEN_DIMENSIONS } from '@/constants';
import { useVerseStore, useAuthStore } from '@/stores/StoreProvider';
import { useGuestRestrictions } from '@/hooks/useGuestRestrictions';
import { useBibleStore } from '@/stores/BibleStore';
import { apiClient, endpoints } from '@/api/client';
import * as Clipboard from 'expo-clipboard';
import { toast } from 'sonner-native';
import { observer } from 'mobx-react-lite';
import EmptyState from '@/components/EmptyState';
import ReflectionComposeModal from '@/components/ReflectionComposeModal';
import { Share as NativeShare } from 'react-native';
import { formatVerseShareMessage } from '@/utils/share';

type VerseDetailProps = NativeStackScreenProps<RootStackParamList, 'VerseDetail'>;

const FACE2FACE_ENABLED = false;

const VerseDetail = ({ navigation, route }: VerseDetailProps) => {
  const theme = useTheme();
  const insets = useSafeAreaInsets();
  const { user } = useAuthStore();
  const { isGuest, restrictions } = useGuestRestrictions();
  const styles = React.useMemo(() => createStyles(theme, insets.bottom), [theme, insets.bottom]);
  const learnContext = route.params?.learnContext;

  const openInBibleScoped = () => {
    if (!currentVerse) return;
    if (learnContext?.scopedVerses?.length) {
      navigation.navigate('BibleScreen', {
        mode: 'scoped',
        scopedTitle: learnContext.scopedTitle ?? currentVerse.context_reference ?? currentVerse.reference_display,
        scopedSubtitle: learnContext.scopedSubtitle ?? currentVerse.translation,
        scopedVerses: learnContext.scopedVerses || null,
        book: (currentVerse as any).book || undefined,
        chapter: (currentVerse as any).chapter || undefined,
        verse: (currentVerse as any).verse || undefined,
      });
      setShowLearnMore(false);
      return;
    }
    navigation.navigate('BibleScreen', {
      book: (currentVerse as any).book || undefined,
      chapter: (currentVerse as any).chapter || undefined,
      verse: (currentVerse as any).verse || undefined,
    });
    setShowLearnMore(false);
  };
  
  // Store state and actions
  const {
    currentVerse,
    isVerseLoading,
    isReflectionsLoading,
    fetchVerseById,
    createInteraction,
    createReflection,
    createBookmark,
    removeBookmark,
    likeVerse
  } = useVerseStore();

  // Local state
  const [currentReflectionIndex, setCurrentReflectionIndex] = useState(0);
  const [reflectionFilter, setReflectionFilter] = useState<'all' | 'word'>('all');
  const [reflectionSort, setReflectionSort] = useState<'new' | 'top'>('new');
  const [showReflectionInput, setShowReflectionInput] = useState(false);
  const [reflectionText, setReflectionText] = useState('');
  const [activeCommentReflectionId, setActiveCommentReflectionId] = useState<string | null>(null);
  const [pendingReflections, setPendingReflections] = useState<Reflection[]>([]);
  const [pendingPayloads, setPendingPayloads] = useState<Record<string, { content: string; type: number; user_id: string; verse_id: string }>>({});
  const [failedPendingIds, setFailedPendingIds] = useState<Set<string>>(new Set());
  const [retryingId, setRetryingId] = useState<string | null>(null);
  // Face2Face capture state
  const [showFace2Face, setShowFace2Face] = useState(false);
  // const [hasCameraPermission, setHasCameraPermission] = useState<boolean>(false);
  // const [cameraType, setCameraType] = useState<CameraType>('front');
  const cameraRef = useRef<any>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [videoUri, setVideoUri] = useState<string | null>(null);
  const [recordTimer, setRecordTimer] = useState<ReturnType<typeof setTimeout> | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [showFaceTips, setShowFaceTips] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<number>(0);

  // Learn more (Explain) bottom sheet state
  const [showLearnMore, setShowLearnMore] = useState(false);
  const [learnTab, setLearnTab] = useState<'context' | 'compare'>('context');
  const [explainLoading, setExplainLoading] = useState(false);
  const [explainError, setExplainError] = useState<string | null>(null);
  const [explainText, setExplainText] = useState<string>('');
  const learnMoreTranslateY = useSharedValue(SCREEN_DIMENSIONS.height);
  const bibleStore = useBibleStore();
  const [compareLoading, setCompareLoading] = useState(false);
  const [compareError, setCompareError] = useState<string | null>(null);
  const [compareResults, setCompareResults] = useState<Array<{ versionId: string; shortName: string; englishName: string; text: string }>>([]);
  const [compareReference, setCompareReference] = useState<string | null>(null);

  // Animated values
  const scrollY = useSharedValue(0);
  const scrollX = useSharedValue(0);
  const headerOpacity = useSharedValue(1);
  const composerOpacity = useSharedValue(0);
  const composerTranslateY = useSharedValue(100);

  // Refs
  const flatListRef = useRef<FlatList>(null);
  const videoRef = useRef<Video>(null);

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

  useFocusEffect(
    React.useCallback(() => {
      return () => {
        try { videoRef.current?.pauseAsync?.(); } catch {}
        try { videoRef.current?.unloadAsync?.(); } catch {}
      };
    }, [])
  );

  // Load persisted reflection UI prefs
  useEffect(() => {
    (async () => {
      try {
        const [f, s] = await Promise.all([
          AsyncStorage.getItem('vd_reflection_filter'),
          AsyncStorage.getItem('vd_reflection_sort'),
        ]);
        if (f === 'all' || f === 'word') setReflectionFilter(f);
        if (s === 'new' || s === 'top') setReflectionSort(s as any);
      } catch {}
    })();
  }, []);

  // Animate Learn more open/close
  useEffect(() => {
    learnMoreTranslateY.value = withSpring(showLearnMore ? 0 : SCREEN_DIMENSIONS.height, {
      damping: 15,
      stiffness: 90,
    });
  }, [showLearnMore]);

  // Fetch Context (Explain) when sheet opens (fallback when no learnContext is provided)
  useEffect(() => {
    const loadExplain = async () => {
      if (!showLearnMore || learnTab !== 'context' || !currentVerse?.id) return;
      if (learnContext?.scopedVerses?.length) return;
      try {
        setExplainLoading(true);
        setExplainError(null);
        const res = await apiClient.get<any>(endpoints.bible.explain(currentVerse.id));
        if (res.success) {
          const d: any = res.data;
          const text = typeof d === 'string' ? d : (d?.explanation || d?.text || '');
          setExplainText(text || '');
        } else {
          setExplainError(res.message || 'Failed to load explanation');
        }
      } catch (e: any) {
        setExplainError(e?.message || 'Failed to load explanation');
      } finally {
        setExplainLoading(false);
      }
    };
    loadExplain();
  }, [showLearnMore, learnTab, currentVerse?.id]);

  // Fetch Compare tab content using same API pattern as BibleScreen (via endpoints.bible.compare)
  useEffect(() => {
    const getVersionSlug = (version?: { shortName?: string; tableName?: string; englishName?: string } | null): string | null => {
      if (!version) return null;
      if (version.tableName) {
        const normalized = version.tableName
          .replace(/^eng[_-]?/i, '')
          .replace(/_vpl$/i, '')
          .replace(/[^a-z0-9]+/gi, '')
          .toLowerCase();
        if (normalized) return normalized;
      }
      if (version.shortName) {
        const short = version.shortName.trim().toLowerCase();
        if (short.length >= 3) return short;
      }
      if (version.englishName) {
        return version.englishName.trim().toLowerCase().replace(/[^a-z0-9]+/g, '');
      }
      return null;
    };

    const loadCompare = async () => {
      if (!showLearnMore || learnTab !== 'compare' || !currentVerse) return;
      try {
        setCompareLoading(true);
        setCompareError(null);
        if (!bibleStore.availableVersions.length) {
          await bibleStore.fetchBibleVersions?.();
        }
        const baseVersionSlug = getVersionSlug(bibleStore.currentVersion);
        const baseVersionTable = bibleStore.currentVersion?.tableName;
        const additionalVersionSlugs = (bibleStore.availableVersions || [])
          .filter(v => v.tableName !== baseVersionTable)
          .map(v => getVersionSlug(v))
          .filter((s): s is string => !!s);
        const versionsParam = additionalVersionSlugs.length ? `${additionalVersionSlugs.join(',')},` : undefined;
        const reference = currentVerse.reference_display || `${currentVerse.book ?? ''} ${currentVerse.chapter ?? ''}:${currentVerse.verse ?? ''}`.trim();
        if (!baseVersionSlug || !reference) {
          throw new Error('Missing version or reference');
        }
        const resp = await apiClient.get<any>(
          endpoints.bible.compare(baseVersionSlug, reference),
          versionsParam ? { versions: versionsParam } : undefined
        );
        if (!resp.success || !resp.data?.comparisons) {
          throw new Error(resp.message || 'Failed to load comparison');
        }
        const payload = resp.data;
        const mapped = (payload.comparisons as any[]).map((entry: any) => {
          const v = entry?.version || {};
          const text = (entry?.text && String(entry.text).trim())
            || (Array.isArray(entry?.verses) ? entry.verses.map((x: any) => x?.text).filter(Boolean).join(' ') : '')
            || (entry?.message || 'Not available');
          const versionId = (v?.tableName || v?.shortName || v?.englishName || 'version').toString().toLowerCase().replace(/[^a-z0-9]+/g, '');
          return {
            versionId,
            shortName: v?.shortName || versionId.toUpperCase(),
            englishName: v?.englishName || v?.shortName || versionId,
            text: text,
          };
        });
        setCompareResults(mapped);
        setCompareReference(payload?.reference?.formatted || reference);
      } catch (e: any) {
        setCompareError(e?.message || 'Failed to load verse comparison.');
        setCompareResults([]);
      } finally {
        setCompareLoading(false);
      }
    };
    loadCompare();
  }, [showLearnMore, learnTab, currentVerse?.id, bibleStore.currentVersion?.tableName, bibleStore.availableVersions.length]);

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
      const ok = await likeVerse(currentVerse.id);
      if (ok) {
        toast.success('Verse liked');
      } else {
        toast.warning('Failed to like verse');
      }
    } catch {
      toast.warning('Failed to like verse');
    }
  };

  const handleBookmark = async (clipText?: string) => {
    if (!currentVerse || !user) {
      toast.info('Please log in to bookmark verses');
      return;
    }
    
    try {
      if (currentVerse.isBookmarked) {
        const ok = await removeBookmark(currentVerse.id, 'App\\Models\\Verse');
        if (ok) toast.success('Bookmark removed'); else toast.error('Failed to remove bookmark');
      } else {
        const ok = await createBookmark({
          user_id: user.id,
          bookmarkable_type: 'App\\Models\\Verse',
          bookmarkable_id: currentVerse.id,
          clip_text: clipText
        });
        if (ok) {
          toast.success('Verse bookmarked');
        } else {
          // Try to distinguish duplicate vs other errors via server state
          const key = `App\\Models\\Verse_${currentVerse.id}`;
          const exists = useVerseStore().state.bookmarks.has(key);
          if (exists) {
            toast.info('Verse already bookmarked');
          } else {
            toast.error('Failed to bookmark');
          }
        }
      }
    } catch (error: any) {      
      const status = error?.status || error?.response?.status;
      if (status === 409) {
        toast.info('Verse already bookmarked');
      } else {
        toast.error('Failed to bookmark');
      }
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
    
    // Fire-and-forget for a smoother, non-blocking UX when posting text reflections
    const text = reflectionText.trim();

    const type = 1 as const;

    // Create local pending placeholder
    const temp: Reflection = {
      id: `temp-${Date.now()}` as any,
      content: text,
      type: type,
      user: user as any,
      comments: [],
      likes: 0,
      shares: 0,
      isLiked: false,
      created_at: new Date().toISOString() as any,
      media_url: null as any,
    } as unknown as Reflection;
    setPendingReflections((prev) => [temp, ...prev]);
    setPendingPayloads((prev) => ({ ...prev, [temp.id]: { content: text, type: type, user_id: user.id, verse_id: currentVerse.id } }));
    setFailedPendingIds((prev) => {
      const next = new Set(prev);
      next.delete(temp.id as any);
      return next;
    });

    setShowReflectionInput(false);
    setReflectionText('');
    toast.info('Sharing in background…');

    // Post in background; the store will enrich and insert the new reflection on success
    createReflection({ content: text, type: type, user_id: user.id, verse_id: currentVerse.id })
      .then((res) => {
        if (res) {
          // Success: remove pending placeholder and payload
          setPendingReflections((prev) => prev.filter((r) => r.id !== temp.id));
          setPendingPayloads((prev) => { const { [temp.id]: _, ...rest } = prev; return rest; });
          setFailedPendingIds((prev) => { const next = new Set(prev); next.delete(temp.id as any); return next; });
          toast.success('Reflection shared');
        } else {
          setFailedPendingIds((prev) => new Set(prev).add(temp.id as any));
          toast.error('Failed to share reflection');
        }
      })
      .catch(() => {
        setFailedPendingIds((prev) => new Set(prev).add(temp.id as any));
        toast.error('Failed to share reflection');
      });
  };

  const retryPending = async (tempId: string) => {
    const payload = pendingPayloads[tempId];
    if (!payload) return;
    setRetryingId(tempId);
    try {
      const res = await createReflection(payload);
      if (res) {
        setPendingReflections((prev) => prev.filter((r) => r.id !== tempId));
        setPendingPayloads((prev) => { const { [tempId]: _, ...rest } = prev; return rest; });
        setFailedPendingIds((prev) => { const next = new Set(prev); next.delete(tempId); return next; });
        toast.success('Reflection shared');
      } else {
        toast.error('Failed to share reflection');
      }
    } catch {
      toast.error('Failed to share reflection');
    } finally {
      setRetryingId(null);
    }
  };

  const cancelPending = (tempId: string) => {
    setPendingReflections((prev) => prev.filter((r) => r.id !== tempId));
    setPendingPayloads((prev) => { const { [tempId]: _, ...rest } = prev; return rest; });
    setFailedPendingIds((prev) => { const next = new Set(prev); next.delete(tempId); return next; });
  };

  // Face2Face helpers
  // const ensureCameraPermission = async () => {
  //   try {
  //     const existing = await Camera.getCameraPermissionsAsync();
  //     if (existing.status === 'granted') {
  //       setHasCameraPermission(true);
  //       // Also ensure microphone permission for video recording
  //       const mic = await Camera.getMicrophonePermissionsAsync();
  //       if (mic.status !== 'granted') {
  //         const micRes = await Camera.requestMicrophonePermissionsAsync();
  //         if (micRes.status !== 'granted') {
  //           toast.error('Microphone permission is required for Face2Face');
  //           return false;
  //         }
  //       }
  //       return true;
  //     }
  //     const res = await Camera.requestCameraPermissionsAsync();
  //     const granted = res.status === 'granted';
  //     setHasCameraPermission(granted);
  //     if (!granted) toast.error('Camera permission is required for Face2Face');
  //     if (!granted) return false;
  //     // Request microphone permission after camera
  //     const micRes = await Camera.requestMicrophonePermissionsAsync();
  //     const micGranted = micRes.status === 'granted';
  //     if (!micGranted) toast.error('Microphone permission is required for Face2Face');
  //     return micGranted;
  //   } catch {
  //     toast.error('Unable to check camera permission');
  //     return false;
  //   }
  // };

  // const openFace2Face = async () => {
  //   if (!FACE2FACE_ENABLED) return;
  //   if (isGuest || !restrictions.canComment) {
  //     toast.info('Please create an account to share Face2Face reflections');
  //     return;
  //   }
  //   if (!(await ensureCameraPermission())) return;
  //   setShowFace2Face(true);
  // };

  // const startRecording = async () => {
  //   if (!cameraRef.current || isRecording) return;
  //   try {
  //     setIsRecording(true);
  //     // Auto-stop after 90s
  //     const t = setTimeout(stopRecording, 90_000);
  //     setRecordTimer(t);
  //     await (cameraRef.current as any).startRecording({
  //       maxDuration: 90,
  //       onRecordingFinished: (video: { uri?: string }) => {
  //         if (video?.uri) setVideoUri(video.uri);
  //         setIsRecording(false);
  //       },
  //       onRecordingError: () => {
  //         toast.error('Recording error');
  //         setIsRecording(false);
  //       },
  //     } as any);
  //   } catch (e) {
  //     toast.error('Unable to start recording');
  //     setIsRecording(false);
  //   }
  // };

  // const stopRecording = async () => {
  //   if (recordTimer) clearTimeout(recordTimer);
  //   setRecordTimer(null);
  //   try {
  //     (cameraRef.current as any)?.stopRecording();
  //   } catch {}
  //   setIsRecording(false);
  // };

  // useEffect(() => {
  //   if (!showFace2Face && isRecording) {
  //     stopRecording();
  //   }
  // }, [showFace2Face, isRecording]);

  // const flipCamera = () => {
  //   setCameraType((prev: CameraType) => (prev === 'front' ? 'back' : 'front'));
  // };

  // const resetFace2Face = () => {
  //   setVideoUri(null);
  //   setIsRecording(false);
  // };

  // const submitFace2Face = async () => {
  //   if (!currentVerse || !user || !videoUri) return;
  //   try {
  //     setIsUploading(true);
      
  //     setShowFace2Face(false);

      
  //     const fileName = videoUri.split('/').pop() || `face2face_${Date.now()}.mp4`;
  //     const contentType = 'video/mp4';
  //     const directory = `videos/user_${user.id}`;
  //     const acl = 'public-read';
  //     const presign = await apiClient.post<{ uploadUrl: string; publicUrl: string; key: string; expires_in: number; thumbnail?: { uploadUrl: string; publicUrl: string; key: string } | null }>(
  //       endpoints.uploads.presign,
  //       { fileName, contentType, directory, acl }
  //     );
  //     if (!presign.success) throw new Error(presign.message || 'Failed to prepare upload');
  //     const { uploadUrl, publicUrl } = presign.data;

  //     const uploadToS3 = async (signedUrl: string, fileUri: string, mime: string) => {
  //       const fileInfo = await FileSystem.getInfoAsync(fileUri);
  //       if (!fileInfo.exists) {
  //         throw new Error('File not found');
  //       }

  //       setUploadProgress(0);

  //       if (typeof (FileSystem as any).createUploadTask === 'function') {
  //         const task = (FileSystem as any).createUploadTask(
  //           signedUrl,
  //           fileUri,
  //           {
  //             httpMethod: 'PUT',
  //             uploadType: (FileSystem as any).FileSystemUploadType.BINARY_CONTENT,
  //             headers: {
  //               'Content-Type': mime,
  //               'x-amz-acl': acl,
  //             },
  //           },
  //           ({ totalBytesSent, totalBytesExpectedToSend }: { totalBytesSent: number; totalBytesExpectedToSend: number }) => {
  //             if (totalBytesExpectedToSend > 0) {
  //               setUploadProgress(Math.min(1, totalBytesSent / totalBytesExpectedToSend));
  //             }
  //           }
  //         );

  //         const res = await task.uploadAsync();
  //         if (!res || res.status < 200 || res.status >= 300) {
  //           throw new Error(`Upload failed with status ${res?.status ?? 'unknown'}`);
  //         }
  //         setUploadProgress(1);
  //         return;
  //       }

  //       const fallback = await FileSystem.uploadAsync(signedUrl, fileUri, {
  //         httpMethod: 'PUT',
  //         uploadType: FileSystem.FileSystemUploadType.BINARY_CONTENT,
  //         headers: {
  //           'Content-Type': mime,
  //           'x-amz-acl': acl,
  //         },
  //       });

  //       if (!fallback || fallback.status < 200 || fallback.status >= 300) {
  //         throw new Error(`Upload failed with status ${fallback?.status ?? 'unknown'}`);
  //       }

  //       setUploadProgress(1);
  //     };

  //     await uploadToS3(uploadUrl, videoUri, contentType);

  //     const caption = (reflectionText?.trim() || 'Face2Face');
  //     const title = caption.length > 250 ? `${caption.slice(0, 247)}...` : caption;

  //     // 3) Create reflection pointing to uploaded media
  //     await createReflection({
  //       title,
  //       content: caption,
  //       type: 2,
  //       user_id: user.id,
  //       verse_id: currentVerse.id,
  //       media_url: publicUrl,
  //       media_provider: 's3',
  //       // duration_seconds: could be extracted with a probe; omitted for now
  //     });
  //     setVideoUri(null);
  //     setReflectionText('');
  //     setShowReflectionInput(false);
  //     toast.success('Face2Face uploaded');
  //   } catch (e) {
  //     const msg = e instanceof Error ? e.message : 'Failed to save Face2Face';
  //     toast.error(msg);
  //   }
  //   finally {
  //     setIsUploading(false);
  //   }
  // };

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

  // Learn more bottom sheet animation
  const learnMoreStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: learnMoreTranslateY.value }],
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

    // Reveal reflections controls when section is near/in view
    const y = nativeEvent.contentOffset.y || 0;
    if (reflectionsY !== null) {
      const threshold = reflectionsY - 120; // start showing a bit before
      const inView = y >= threshold;
      if (inView !== showReflectionsControls) setShowReflectionsControls(inView);
    }
  }, []);

  // Anchor: measure Reflections section to support precise scrolling
  const reflectionsAnchorRef = useRef<View>(null);
  const scrollViewRef = useRef<ScrollView>(null);
  const [reflectionsY, setReflectionsY] = useState<number | null>(null);
  const [showReflectionsControls, setShowReflectionsControls] = useState<boolean>(false);
  const scrollToReflections = useCallback(() => {
    if (scrollViewRef.current && reflectionsY !== null) {
      const y = Math.max(0, reflectionsY - 8);
      scrollViewRef.current.scrollTo({ y, animated: true });
    }
  }, [reflectionsY, scrollViewRef]);

  // Derived reflections (filter + sort)
  const filteredReflections = useMemo(() => {
    const list = (currentVerse?.reflections || []).filter((r: Reflection) => !r.media_url);
    const filtered = list.filter((r: Reflection) => {
      if (reflectionFilter === 'all') return true;
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
    const list = (currentVerse?.reflections || []).filter((r: Reflection) => !r.media_url);
    const all = list.length;
    const word = list.filter((r: Reflection) => r.type === 1).length;
    return { all, word };
  }, [currentVerse?.reflections]);

  // Reflection rendering
  const renderReflection = useCallback(({ item, index }: { item: Reflection; index: number }) => {
    const isPending = typeof item.id === 'string' && item.id.startsWith('temp-');
    const failed = isPending && failedPendingIds.has(item.id as any);
    return (
      <View style={{ position: 'relative' }}>
        <ReflectionCard
          reflection={item}
          scrollX={scrollX}
          index={index}
          onCommentPress={() => !isPending && setActiveCommentReflectionId(item.id)}
          expanded={false}
          onPress={!isPending ? () => navigation.navigate('ReflectionDetail', { reflection: item }) : undefined}
          style={isPending ? { opacity: 0.6 } as any : undefined}
        />
        {isPending && (
          <View style={styles.pendingOverlay}>
            {!failed ? (
              <View style={styles.pendingBadge}>
                <Text style={styles.pendingBadgeText}>Sending…</Text>
              </View>
            ) : (
              <View style={styles.pendingRow}>
                <Text style={styles.pendingErrorText}>Failed</Text>
                <TouchableOpacity
                  style={[styles.pendingActionBtn, retryingId === item.id && { opacity: 0.6 } as any]}
                  onPress={() => retryPending(item.id as any)}
                  disabled={retryingId === item.id}
                >
                  <Text style={styles.pendingActionText}>{retryingId === item.id ? 'Retrying…' : 'Retry'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.pendingActionBtn}
                  onPress={() => cancelPending(item.id as any)}
                >
                  <Text style={styles.pendingActionText}>Cancel</Text>
                </TouchableOpacity>
              </View>
            )}
          </View>
        )}
      </View>
    );
  }, [navigation, failedPendingIds, retryingId]);

  const keyExtractor = useCallback((item: Reflection) => item.id, []);

  const onReflectionsMomentumEnd = useCallback((e: any) => {
    const cardWidth = SCREEN_DIMENSIONS.width - theme.spacing.md * 2;
    const offsetX = e.nativeEvent.contentOffset.x || 0;
    const idx = Math.round(offsetX / cardWidth);
    const total = pendingReflections.length + filteredReflections.length;
    setCurrentReflectionIndex(Math.max(0, Math.min(idx, total - 1)));
  }, [filteredReflections.length, pendingReflections.length, theme.spacing.md]);

  const trimmedReflection = reflectionText.trim();
  const wordCount = trimmedReflection ? trimmedReflection.split(/\s+/).filter(Boolean).length : 0;
  const exceedsWordLimit = wordCount > 50;
  const canSubmit = !isUploading && !!trimmedReflection && !exceedsWordLimit;
  const submitLabel = isUploading ? 'Uploading…' : 'Share';

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
                      {chipCounts.all}
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
                  onPress={() => setShowLearnMore(true)}
                >
                  <Book size={16} color={theme.colors.text.secondary} />
                  <Text style={styles.copyText}>Learn more</Text>
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
              {showReflectionsControls && (
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
              )}

              {/* Filter chips */}
              {showReflectionsControls && (
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
                </View>
              )}
              
              {isReflectionsLoading ? (
                <ActivityIndicator color={theme.colors.primary} />
              ) : (pendingReflections.length + filteredReflections.length) ? (
                <>
                  <FlatList
                    data={[...pendingReflections, ...filteredReflections]}
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
                    {[...pendingReflections, ...filteredReflections].map((_: Reflection, i: number) => (
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
            <Text style={styles.composerFabText}>Reflect</Text>
          </TouchableOpacity>
        </Animated.View>
      )}

      {/* Reflection Compose Full Screen */}
      <ReflectionComposeModal
        visible={showReflectionInput}
        onClose={() => !isUploading && setShowReflectionInput(false)}
        reflectionText={reflectionText}
        verseText={currentVerse?.text}
        onChangeText={setReflectionText}
        reflectionType={1}
        onChangeType={() => {}}
        isUploading={isUploading}
        canSubmit={canSubmit}
        submitLabel={submitLabel}
        onSubmit={handleSubmitReflection}
        // onOpenFaceTips={() => {}}
        // onOpenFace2Face={FACE2FACE_ENABLED ? openFace2Face : () => {}}
      />

      {/* Face2Face Modal */}
      {/* {FACE2FACE_ENABLED && showFace2Face && (
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
                      ref={videoRef}
                      style={[StyleSheet.absoluteFill, { width: '100%', height: '100%' }]}
                      source={{ uri: videoUri }}
                      useNativeControls
                      resizeMode={ResizeMode.COVER}
                    />
                  )}
                </View>
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
      )} */}

      {/* Background upload status */}
      {FACE2FACE_ENABLED && isUploading && !showFace2Face && (
        <View style={styles.uploadBanner}>
          <Text style={styles.uploadBannerText}>{`Uploading Face2Face… ${Math.round((uploadProgress || 0) * 100)}%`}</Text>
          <View style={styles.progressBarWrap}>
            <View style={[styles.progressBarFill, { width: `${Math.round((uploadProgress || 0) * 100)}%`, backgroundColor: theme.colors.primary }]} />
          </View>
        </View>
      )}

      {/* Learn more bottom sheet */}
      {showLearnMore && (
        <View style={styles.learnOverlay}>
          <BlurView intensity={20} style={StyleSheet.absoluteFill}>
            <TouchableOpacity style={styles.backdrop} activeOpacity={1} onPress={() => setShowLearnMore(false)} />
          </BlurView>
          <Animated.View style={[styles.learnContainer, learnMoreStyle]}>
            <View style={styles.learnHeader}>
              <Text style={styles.learnTitle}>Learn more</Text>
              <TouchableOpacity onPress={() => setShowLearnMore(false)} style={styles.closeButton}>
                <X size={20} color={theme.colors.text.secondary} />
              </TouchableOpacity>
            </View>
            <View style={styles.learnTabs}>
              <TouchableOpacity
                style={[styles.learnTab, learnTab === 'context' && styles.learnTabActive]}
                onPress={() => setLearnTab('context')}
              >
                <Text style={[styles.learnTabText, learnTab === 'context' && styles.learnTabTextActive]}>Context</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.learnTab, learnTab === 'compare' && styles.learnTabActive]}
                onPress={() => setLearnTab('compare')}
              >
                <Text style={[styles.learnTabText, learnTab === 'compare' && styles.learnTabTextActive]}>Compare</Text>
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.learnContent} contentContainerStyle={styles.learnContentInner}>
              {learnTab === 'context' && (
                learnContext?.scopedVerses?.length ? (
                  <View>
                    {learnContext.scopedTitle ? (
                      <Text style={styles.learnTitle}>{learnContext.scopedTitle}</Text>
                    ) : null}
                    {learnContext.scopedSubtitle ? (
                      <Text style={[styles.copyText, { marginBottom: 8 }]}>{learnContext.scopedSubtitle}</Text>
                    ) : null}
                    {learnContext.scopedVerses!.map((v, idx) => (
                      <View key={`${v.reference ?? 'line'}-${idx}`} style={{ marginBottom: 10 }}>
                        {v.reference ? (
                          <Text style={[styles.copyText, { fontWeight: '600', marginBottom: 4 }]}>{v.reference}</Text>
                        ) : null}
                        <Text style={styles.explainText}>{v.text}</Text>
                      </View>
                    ))}
                  </View>
                ) : (
                  explainLoading ? (
                    <View style={styles.loadingContainer}>
                      <ActivityIndicator color={theme.colors.primary} size="large" />
                    </View>
                  ) : explainError ? (
                    <Text style={styles.errorText}>{explainError}</Text>
                  ) : explainText ? (
                    <Text style={styles.explainText}>{explainText}</Text>
                  ) : (
                    <Text style={styles.copyText}>No explanation available.</Text>
                  )
                )
              )}
              {learnTab === 'compare' && (
                compareLoading ? (
                  <View style={styles.loadingContainer}>
                    <ActivityIndicator color={theme.colors.primary} size="large" />
                  </View>
                ) : compareError ? (
                  <Text style={styles.errorText}>{compareError}</Text>
                ) : (
                  <View>
                    {compareReference ? (
                      <Text style={[styles.copyText, { marginBottom: 8 }]}>{compareReference}</Text>
                    ) : null}
                    {compareResults.map((item) => (
                      <View key={item.versionId} style={{ marginBottom: theme.spacing.md }}>
                        <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' }}>
                          <Text style={[styles.copyText, { fontWeight: '600' }]}>{item.englishName}</Text>
                          <Text style={styles.copyText}>{item.shortName}</Text>
                        </View>
                        <Text style={styles.explainText}>{item.text || 'Not available'}</Text>
                      </View>
                    ))}
                    {!compareResults.length ? (
                      <Text style={styles.copyText}>No versions available for comparison.</Text>
                    ) : null}
                  </View>
                )
              )}
              {learnTab === 'compare' && (
                <View />
              )}
            </ScrollView>
            <View style={{ paddingHorizontal: theme.spacing.lg, paddingTop: theme.spacing.sm }}>
              <TouchableOpacity style={styles.learnPrimaryButton} onPress={openInBibleScoped}>
                <Text style={styles.learnPrimaryButtonText}>Open in Bible</Text>
              </TouchableOpacity>
            </View>
          </Animated.View>
        </View>
      )}

      {/* Tips Modal */}
      {FACE2FACE_ENABLED && showFaceTips && (
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
  // Pending overlay
  pendingOverlay: {
    position: 'absolute',
    left: theme.spacing.md,
    right: theme.spacing.md,
    bottom: theme.spacing.md,
    alignItems: 'flex-start',
  },
  pendingBadge: {
    backgroundColor: `${theme.colors.background}CC`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
  },
  pendingBadgeText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  pendingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme.spacing.sm,
    backgroundColor: `${theme.colors.background}CC`,
    paddingHorizontal: theme.spacing.sm,
    paddingVertical: theme.spacing.xs,
    borderRadius: theme.borderRadius.full,
  },
  pendingErrorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
    fontWeight: '600',
  },
  pendingActionBtn: {
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
  },
  pendingActionText: {
    ...theme.typography.caption.primary,
    color: theme.colors.primary,
    fontWeight: '600',
  },
  // Learn more bottom sheet styles
  learnOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  learnContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: theme.colors.background,
    borderTopLeftRadius: theme.borderRadius.xl,
    borderTopRightRadius: theme.borderRadius.xl,
    paddingBottom: safeAreaBottom + theme.spacing.lg,
    paddingTop: theme.spacing.md,
  },
  learnHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.sm,
  },
  learnTitle: {
    ...theme.typography.heading.small,
    color: theme.colors.text.primary,
    fontWeight: '700',
  },
  learnTabs: {
    flexDirection: 'row',
    gap: theme.spacing.xs,
    paddingHorizontal: theme.spacing.lg,
    marginBottom: theme.spacing.sm,
  },
  learnTab: {
    paddingVertical: theme.spacing.xs,
    paddingHorizontal: theme.spacing.md,
    borderRadius: theme.borderRadius.full,
    backgroundColor: theme.colors.surface,
  },
  learnTabActive: {
    backgroundColor: theme.colors.primary,
  },
  learnTabText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
  },
  learnTabTextActive: {
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  learnContent: {
    maxHeight: SCREEN_DIMENSIONS.height * 0.6,
  },
  learnContentInner: {
    paddingHorizontal: theme.spacing.lg,
    paddingBottom: theme.spacing.lg,
  },
  learnPrimaryButton: {
    backgroundColor: theme.colors.primary,
    paddingVertical: theme.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: theme.borderRadius.full,
    marginTop: theme.spacing.sm,
  },
  learnPrimaryButtonText: {
    ...theme.typography.button.secondary,
    color: theme.colors.text.inverse,
    fontWeight: '600',
  },
  closeButton: {
    padding: theme.spacing.xs,
  },
  backdrop: {
    flex: 1,
  },
  explainText: {
    ...theme.typography.body.sans,
    color: theme.colors.text.primary,
    lineHeight: 20,
  },
  errorText: {
    ...theme.typography.caption.primary,
    color: theme.colors.error,
  },
  // Upload banner
  uploadBanner: {
    position: 'absolute',
    left: theme.spacing.md,
    right: theme.spacing.md,
    bottom: safeAreaBottom + theme.spacing.xl + 8,
    backgroundColor: theme.colors.surface,
    borderRadius: theme.borderRadius.lg,
    padding: theme.spacing.md,
    ...theme.shadows.md,
  },
  uploadBannerText: {
    ...theme.typography.caption.primary,
    color: theme.colors.text.secondary,
    marginBottom: theme.spacing.xs,
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