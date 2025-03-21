import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Platform,
  Image,
  FlatList,
  Dimensions,
  ActivityIndicator,
  Alert
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  withSequence,
  withSpring,
  interpolate,
  Extrapolation,
} from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';
import {
  ArrowLeft,
  Star,
  Clock,
  Lock,
  Heart,
  Lightbulb,
  BookOpen,
  Users,
  ChevronRight,
  Sparkle,
  Shield,
  Scales,
  Leaf,
  Flame,
  HomeLight
} from '@/components/Icons';
import { Theme } from '@/theme';
import { useTheme } from '@/contexts/ThemeContext';
import { AppVirtue, DENOMINATIONS, DenominationType, Note, RootStackParamList, THEMES, Virtue, VIRTUE_NOTES, VirtueGroups } from '@/types';
import { useAuth } from '@/stores/auth';
import AvatarStack from '@/components/AvatarStack';
import AuthModal from '@/components/AuthModal';

const VIRTUES: AppVirtue[] = [
  ...VirtueGroups.foundational.virtues.map(id => ({
    id,
    name: THEMES[id]?.title.split(' ')[0] || id,
    description: THEMES[id]?.description || '',
    color_code: THEMES[id]?.color || '#9C27B0',
    icon: THEMES[id]?.Icon || Star,
    userProgress: {
      current_level: Math.floor(Math.random() * 3),
      theme_id: id,
      virtue: id,
      level: Math.floor(Math.random() * 3),
      total_minutes: 0,
      total_points: 0,
      total_challenges: 0, 
      total_levels: 3
    },
    totalUsers: Math.floor(Math.random() * 3000) + 500,
    scriptureReference: 'Romans 12:2',
  })),
  ...VirtueGroups.derived.virtues.slice(0, 8).map(id => ({
    id,
    name: id.charAt(0).toUpperCase() + id.slice(1),
    description: `The virtue of ${id} helps us grow in our spiritual journey.`,
    color_code: id.includes('wisdom') || id.includes('discernment') ? THEMES.knowledge.color :
           id.includes('patience') || id.includes('self-control') ? THEMES.humility.color :
           id.includes('hope') || id.includes('trust') ? THEMES.faith.color : THEMES.love.color,
    icon: id.includes('wisdom') || id.includes('discernment') ? Lightbulb :
          id.includes('patience') || id.includes('self-control') ? Clock :
          id.includes('hope') || id.includes('trust') ? HomeLight : Heart,
    userProgress: {
      current_level: Math.floor(Math.random() * 3),
      theme_id: id,
      virtue: id,
      level: Math.floor(Math.random() * 3),
      total_minutes: 0,
      total_points: 0,
      total_challenges: 0,
      total_levels: 3
    },
    totalUsers: Math.floor(Math.random() * 2000) + 300,
    scriptureReference: 'Galatians 5:22-23',
  })),
];  

type VirtueScreenProps = NativeStackScreenProps<RootStackParamList, 'VirtueScreen'>;

type TabType = 'explore' | 'learn' | 'notes';

const DynamicIcon = ({ 
  icon: IconComponent, 
  size, 
  color 
}: { 
  icon: React.ComponentType<any>; 
  size: number; 
  color: string 
}) => {
  return <IconComponent size={size} color={color} />;
};

const VirtueScreen: React.FC<VirtueScreenProps> = ({ navigation, route }) => {
  const insets = useSafeAreaInsets();
  const theme = useTheme();
  const styles = React.useMemo(() => createStyles(theme), [theme]);
  const { user } = useAuth();
  
  const [activeTab, setActiveTab] = useState<TabType>('explore');
  const [selectedVirtue, setSelectedVirtue] = useState<AppVirtue | null>(null);
  const [selectedDenomination, setSelectedDenomination] = useState<DenominationType>('all');
  const [loading, setLoading] = useState(false);
  const [showAuthModal, setShowAuthModal] = useState(false);
  
  // Animation values
  const tabIndicatorPosition = useSharedValue(0);
  const cardScale = useSharedValue(1);
  const scrollY = useSharedValue(0);
  const featuredScale = useSharedValue(1);
  
  const filteredNotes = useMemo(() => {
    let notes = [...VIRTUE_NOTES];
    
    if (selectedVirtue) {
      notes = notes.filter(note => note.theme_id === selectedVirtue.id);
    }
    
    if (selectedDenomination !== 'all') {
      notes = notes.filter(note => note.denomination?.name === selectedDenomination);
    }
    
    return notes;
  }, [selectedVirtue, selectedDenomination]);
  
  const handleTabChange = (tab: TabType) => {
    const tabPositions = {
      explore: 0,
      learn: 1,
      notes: 2,
    };
    
    tabIndicatorPosition.value = withTiming(tabPositions[tab as keyof typeof tabPositions], {
      duration: 300,
    });
    
    setActiveTab(tab);
  };
  
  const handleVirtuePress = (virtue: AppVirtue) => {
    if (!user) {
      setShowAuthModal(true);
      return;
    }
    
    setSelectedVirtue(virtue);
    cardScale.value = withSequence(
      withTiming(0.95, { duration: 100 }),
      withTiming(1, { duration: 200 })
    );
    
    // If on explore tab, switch to learn tab
    if (activeTab === 'explore') {
      handleTabChange('learn');
    }
  };
  
  const startQuiz = (virtue: Virtue, level?: number) => {
    if (!user) {
      setShowAuthModal(true);
      return;
    }
    
    navigation.navigate('VirtueQuizScreen', {
      virtueId: virtue.id,
      level: level || (virtue.userProgress?.current_level || 0) + 1
    });
  };
  
  const viewNote = (note: Note) => {
    if (!user) {
      setShowAuthModal(true);
      return;
    }
    
    // Navigate to note detail
    navigation.navigate('NoteDetail', { noteId: note.id });
  };
    // Join a community challenge
    const joinChallenge = () => {
        if (!user) {
            setShowAuthModal(true);
            return;
        }
        
        Alert.alert('Join Challenge', 'You have joined the community challenge!');
        };

  const handleScroll = (event: any) => {
    scrollY.value = event.nativeEvent.contentOffset.y;
  };
  
  // Animated styles
  const headerAnimatedStyle = useAnimatedStyle(() => ({
    opacity: interpolate(
      scrollY.value,
      [0, 100],
      [1, 0.8],
      Extrapolation.CLAMP
    ),
  }));
  
  const tabIndicatorAnimatedStyle = useAnimatedStyle(() => {
    const translateX = interpolate(
      tabIndicatorPosition.value,
      [0, 1, 2],
      [0, 100, 200],
      Extrapolation.CLAMP
    );
    
    return {
      transform: [{ translateX: translateX }]
    };
  });
  
  const featuredCardAnimatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: featuredScale.value }]
  }));
  
  // Render functions
  const renderHeader = () => (
    <Animated.View style={[styles.header, headerAnimatedStyle]}>
      <View style={styles.headerContent}>
        <TouchableOpacity 
          style={styles.backButton}
          onPress={() => navigation.goBack()}
        >
          <ArrowLeft size={24} color={theme?.colors.text.primary} />
        </TouchableOpacity>
        
        <Text style={styles.headerTitle}>SoulForge</Text>
        <Star size={24} color={theme?.colors.text.primary} style={{marginLeft: 10}} filled />
        {/* <CircleButton
          Icon={Star}
          onPress={() => {
            if (!user) {
              setShowAuthModal(true);
              return;
            }
            navigation.navigate('LeaderboardScreen');
          }}
          size={40}
          style={
            {
              backgroundColor: theme?.colors.primary,
            }
          }
        /> */}
      </View>
      
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, activeTab == 'explore' && styles.activeTab]}
          onPress={() => handleTabChange('explore')}
        >
          <Text style={[
            styles.tabText,
            activeTab === 'explore' && styles.activeTabText
          ]}>
            Explore
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[styles.tab, activeTab == 'learn' && styles.activeTab]}
          onPress={() => handleTabChange('learn')}
        >
          <Text style={[
            styles.tabText,
            activeTab === 'learn' && styles.activeTabText
          ]}>
            Learn
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[styles.tab, activeTab === 'notes' && styles.activeTab]}
          onPress={() => handleTabChange('notes')}
        >
          <Text style={[
            styles.tabText,
            activeTab === 'notes' && styles.activeTabText
          ]}>
            Notes
          </Text>
        </TouchableOpacity>
        
        <Animated.View style={[styles.tabIndicator, tabIndicatorAnimatedStyle]} />
      </View>
    </Animated.View>
  );
  
  const renderExploreTab = () => (
    <View style={styles.tabContent}>
      {/* Featured Virtue */}
      <Animated.View style={[styles.section, featuredCardAnimatedStyle]}>
        <Text style={styles.sectionTitle}>FEATURED VIRTUE</Text>
        
        <TouchableOpacity
          style={styles.featuredCard}
          onPress={() => handleVirtuePress(VIRTUES[0])}
        >
          <LinearGradient
            colors={[`${VIRTUES[0].color_code}20`, `${VIRTUES[0].color_code}05`]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.featuredGradient}
          />
          
          <View style={styles.featuredContent}>
            <View style={[styles.featuredIconContainer, { backgroundColor: `${VIRTUES[0].color_code}20` }]}>
              <DynamicIcon icon={VIRTUES[0].icon} size={32} color={VIRTUES[0].color_code} />
            </View>
            
            <View style={styles.featuredTextContainer}>
              <Text style={styles.featuredTitle}>{VIRTUES[0].name}</Text>
              <Text style={styles.featuredDescription}>
                {VIRTUES[0].description}
              </Text>
              
              <View style={styles.featuredMeta}>
                <View style={styles.featuredMetaItem}>
                  <Users size={16} color={theme?.colors.text.secondary} />
                  <Text style={styles.featuredMetaText}>
                    {VIRTUES[0].totalUsers?.toLocaleString()} learning
                  </Text>
                </View>
                
                <View style={styles.featuredMetaItem}>
                  <BookOpen size={16} color={theme?.colors.text.secondary} />
                  <Text style={styles.featuredMetaText}>
                    {VIRTUES[0].scriptureReference}
                  </Text>
                </View>
              </View>
            </View>
          </View>
          
          <View style={styles.featuredActions}>
            <TouchableOpacity
              style={[styles.actionButton, { backgroundColor: VIRTUES[0].color_code }]}
              onPress={() => startQuiz(VIRTUES[0])}
            >
              <Text style={styles.actionButtonText}>Start Quiz</Text>
            </TouchableOpacity>
          </View>
        </TouchableOpacity>
      </Animated.View>
      
      {/* All Virtues Grid */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>ALL VIRTUES</Text>
        
        <View style={styles.virtuesGrid}>
          {VIRTUES.map(virtue => (
            <TouchableOpacity
              key={virtue.id}
              style={styles.virtueGridCard}
              onPress={() => handleVirtuePress(virtue)}
            >
              <LinearGradient
                colors={[`${virtue.color_code}15`, `${virtue.color_code}05`]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.virtueGridGradient}
              />
              
              <View style={[styles.virtueIconContainer, { backgroundColor: `${virtue.color_code}20` }]}>
                <DynamicIcon icon={virtue.icon} size={24} color={virtue.color_code} />
              </View>
              
              <Text style={styles.virtueGridName}>{virtue.name}</Text>
              
              {virtue.userProgress && virtue.userProgress.current_level > 0 && (
                <View style={styles.progressIndicator}>
                  <View style={styles.progressBar}>
                    <View 
                      style={[
                        styles.progressFill, 
                        { 
                          width: `${(virtue.userProgress.current_level / virtue.userProgress.total_levels) * 100}%`,
                          backgroundColor: virtue.color_code 
                        }
                      ]} 
                    />
                  </View>
                </View>
              )}
            </TouchableOpacity>
          ))}
        </View>
      </View>
      
      {/* Community Spotlight */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>COMMUNITY SPOTLIGHT</Text>
        
        <View style={styles.communityCard}>
          <View style={styles.communityHeader}>
            <Text style={styles.communityTitle}>Weekly Challenge</Text>
            <AvatarStack
              users={[
                { id: '1', avatar: '', first_name: 'User1', last_name: 'User1' },
                { id: '2', avatar: '', first_name: 'User2', last_name: 'User2' },
                { id: '3', avatar: '', first_name: 'User3', last_name: 'User3' },
              ]}
              maxAvatars={3}
              size={24}
            />
          </View>
          
          <Text style={styles.challengeText}>
            Practice patience in daily interactions and journal your experiences
          </Text>
          
          <View style={styles.communityStats}>
            <View style={styles.statItem}>
              <Users size={16} color={theme?.colors.text.secondary} />
              <Text style={styles.statText}>128 participants</Text>
            </View>
            
            <View style={styles.statItem}>
              <Sparkle size={16} color={theme?.colors.primary} />
              <Text style={styles.statText}>Earn 50 points</Text>
            </View>
          </View>
          
          <TouchableOpacity
            style={styles.joinChallengeButton}
            onPress={joinChallenge}
          >
            <Text style={styles.joinChallengeText}>Join Challenge</Text>
          </TouchableOpacity>
        </View>
      </View>
    </View>
  );
  
  const renderLearnTab = () => (
    <View style={styles.tabContent}>
      {/* Virtue Selection */}
      {!selectedVirtue ? (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>SELECT A VIRTUE TO LEARN</Text>
          
          <View style={styles.virtuesGrid}>
            {VIRTUES.map((virtue: AppVirtue) => (
              <TouchableOpacity
                key={virtue.id}
                style={styles.virtueGridCard}
                onPress={() => setSelectedVirtue(virtue)}
              >
                <LinearGradient
                  colors={[`${virtue.color_code}15`, `${virtue.color_code}05`]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                  style={styles.virtueGridGradient}
                />
                
                <View style={[styles.virtueIconContainer, { backgroundColor: `${virtue.color_code}20` }]}>
                  <DynamicIcon icon={virtue.icon} size={24} color={virtue.color_code} />
                </View>
                
                <Text style={styles.virtueGridName}>{virtue.name}</Text>
                
                {virtue.userProgress && virtue.userProgress.current_level > 0 && (
                  <View style={styles.progressIndicator}>
                    <View style={styles.progressBar}>
                      <View 
                        style={[
                          styles.progressFill, 
                          { 
                            width: `${(virtue.userProgress.current_level / virtue.userProgress.total_levels) * 100}%`,
                            backgroundColor: virtue.color_code 
                          }
                        ]} 
                      />
                    </View>
                  </View>
                )}
              </TouchableOpacity>
            ))}
          </View>
        </View>
      ) : (
        <>
          {/* Virtue Detail */}
          <View style={styles.section}>
            <View style={styles.virtueDetailHeader}>
              <TouchableOpacity
                style={styles.backToVirtuesButton}
                onPress={() => setSelectedVirtue(null)}
              >
                <ArrowLeft size={20} color={theme?.colors.text.secondary} />
                <Text style={styles.backToVirtuesText}>All Virtues</Text>
              </TouchableOpacity>
              
              <Text style={[styles.virtueDetailTitle, { color: selectedVirtue.color_code }]}>
                {selectedVirtue.name}
              </Text>
            </View>
            
            <View style={styles.virtueDetailCard}>
              <LinearGradient
                colors={[`${selectedVirtue.color_code}15`, `${selectedVirtue.color_code}05`]}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 1 }}
                style={styles.virtueDetailGradient}
              />
              
              <View style={styles.virtueDetailContent}>
                <View style={[styles.virtueDetailIconContainer, { backgroundColor: `${selectedVirtue.color_code}20` }]}>
                  <DynamicIcon icon={selectedVirtue.icon} size={32} color={selectedVirtue.color_code} />
                </View>
                
                <Text style={styles.virtueDetailDescription}>
                  {selectedVirtue.description}
                </Text>
                
                <View style={styles.scriptureContainer}>
                  <BookOpen size={16} color={selectedVirtue.color_code} />
                  <Text style={styles.scriptureText}>
                    {selectedVirtue.scriptureReference}
                  </Text>
                </View>
                
                <View style={styles.progressContainer}>
                  <Text style={styles.progressLabel}>Your Progress</Text>
                  <View style={styles.progressBar}>
                    <View 
                      style={[
                        styles.progressFill, 
                        { 
                          width: `${((selectedVirtue.userProgress?.current_level || 0) / (selectedVirtue.userProgress?.total_levels || 1)) * 100}%`,
                          backgroundColor: selectedVirtue.color_code 
                        }
                      ]} 
                    />
                  </View>
                  <Text style={styles.progressText}>
                    Level {selectedVirtue.userProgress?.current_level || 0}/{selectedVirtue.userProgress?.total_levels || 3} Completed
                  </Text>
                </View>
              </View>
            </View>
          </View>
          
          {/* Quiz Levels */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>QUIZ LEVELS</Text>
            
            <View style={styles.levelsContainer}>
              {[...Array(selectedVirtue.userProgress?.total_levels || 3)].map((_, index) => {
                const level = index + 1;
                const isCompleted = (selectedVirtue.userProgress?.current_level || 0) >= level;
                const isLocked = (selectedVirtue.userProgress?.current_level || 0) + 1 < level;
                
                return (
                  <TouchableOpacity
                    key={`level-${level}`}
                    style={[
                      styles.levelCard,
                      isCompleted && styles.completedLevelCard,
                      isLocked && styles.lockedLevelCard
                    ]}
                    onPress={() => {
                      if (isLocked) {
                        Alert.alert('Locked', 'Complete the previous level first.');
                      } else {
                        startQuiz(selectedVirtue, level);
                      }
                    }}
                    disabled={isLocked}
                  >
                    <LinearGradient
                      colors={[
                        isCompleted ? `${selectedVirtue.color_code}30` : `${selectedVirtue.color_code}15`,
                        isCompleted ? `${selectedVirtue.color_code}10` : `${selectedVirtue.color_code}05`
                      ]}
                      start={{ x: 0, y: 0 }}
                      end={{ x: 1, y: 1 }}
                      style={styles.levelGradient}
                    />
                    
                    {isLocked ? (
                      <View style={styles.lockedIconContainer}>
                        <Lock size={24} color={theme?.colors.text.secondary} />
                      </View>
                    ) : (
                      <Text 
                        style={[
                          styles.levelNumber, 
                          { color: isCompleted ? selectedVirtue.color_code : theme?.colors.text.primary }
                        ]}
                      >
                        {level}
                      </Text>
                    )}
                    
                    <Text 
                      style={[
                        styles.levelLabel,
                        isLocked && styles.lockedLevelLabel
                      ]}
                    >
                      {isLocked ? 'Locked' : isCompleted ? 'Completed' : 'Start'}
                    </Text>
                    
                    {isCompleted && (
                      <View style={[styles.completedBadge, { backgroundColor: selectedVirtue.color_code }]}>
                        <Sparkle size={12} color="#FFF" />
                      </View>
                    )}
                  </TouchableOpacity>
                );
              })}
            </View>
            
            {selectedVirtue.userProgress && selectedVirtue.userProgress.current_level < (selectedVirtue.userProgress.total_levels || 3) && (
              <TouchableOpacity
                style={[styles.continueButton, { backgroundColor: selectedVirtue.color_code }]}
                onPress={() => startQuiz(selectedVirtue)}
              >
                <Text style={styles.continueButtonText}>
                  {!selectedVirtue.userProgress || selectedVirtue.userProgress.current_level === 0 
                    ? 'Start Learning' 
                    : 'Continue Learning'}
                </Text>
                <ChevronRight size={20} color="#FFF" />
              </TouchableOpacity>
            )}
          </View>
          
          {/* Related Notes */}
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>RELATED NOTES</Text>
              <TouchableOpacity
                style={styles.viewAllButton}
                onPress={() => handleTabChange('notes')}
              >
                <Text style={styles.viewAllText}>View All</Text>
                <ChevronRight size={16} color={theme?.colors.text.secondary} />
              </TouchableOpacity>
            </View>
            
            {filteredNotes.filter(note => note.theme_id === selectedVirtue.name)
              .slice(0, 2)
              .map(note => (
                <TouchableOpacity
                  key={note.id}
                  style={styles.noteCard}
                  onPress={() => viewNote(note)}
                >
                  <Text style={styles.noteTitle}>{note.title}</Text>
                  <Text style={styles.noteExcerpt} numberOfLines={2}>
                    {note.excerpt}
                  </Text>
                  <View style={styles.noteMeta}>
                    <Text style={styles.noteAuthor}>{note.author?.first_name}</Text>
                    <View style={styles.noteLikes}>
                      <Heart size={14} color={theme?.colors.like} />
                      <Text style={styles.noteLikesCount}>{note.likes}</Text>
                    </View>
                  </View>
                </TouchableOpacity>
              ))}
          </View>
        </>
      )}
    </View>
  );
  
  const renderNotesTab = () => (
    <View style={styles.tabContent}>
      {/* Filters */}
      <View style={styles.filtersContainer}>
        <View style={styles.filterSection}>
          <Text style={styles.filterLabel}>Virtue</Text>
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.filterScrollContent}
          >
            <TouchableOpacity
              style={[
                styles.filterChip,
                !selectedVirtue && styles.activeFilterChip
              ]}
              onPress={() => setSelectedVirtue(null)}
            >
              <Text style={[
                styles.filterChipText,
                !selectedVirtue && styles.activeFilterChipText
              ]}>
                All
              </Text>
            </TouchableOpacity>
            
            {VIRTUES.map(virtue => (
              <TouchableOpacity
                key={virtue.id}
                style={[
                  styles.filterChip,
                  selectedVirtue?.id === virtue.id && styles.activeFilterChip,
                  selectedVirtue?.id === virtue.id && { borderColor: virtue.color_code }
                ]}
                onPress={() => setSelectedVirtue(virtue)}
              >
                <DynamicIcon icon={virtue.icon} size={16} color={selectedVirtue?.id === virtue.id ? virtue.color_code : theme?.colors.text.secondary} />
                <Text style={[
                  styles.filterChipText,
                  selectedVirtue?.id === virtue.id && styles.activeFilterChipText,
                  selectedVirtue?.id === virtue.id && { color: virtue.color_code }
                ]}>
                  {virtue.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
        
        <View style={styles.filterSection}>
          <Text style={styles.filterLabel}>Denomination</Text>
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.filterScrollContent}
          >
            {DENOMINATIONS.map(denom => (
              <TouchableOpacity
                key={denom.id}
                style={[
                  styles.filterChip,
                  selectedDenomination === denom.id && styles.activeFilterChip,
                  selectedDenomination === denom.id && { borderColor: denom.color }
                ]}
                onPress={() => setSelectedDenomination(denom.name as DenominationType)}
              >
                <View 
                  style={[
                    styles.denominationDot, 
                    { backgroundColor: denom.color }
                  ]} 
                />
                <Text style={[
                  styles.filterChipText,
                  selectedDenomination === denom.id && styles.activeFilterChipText,
                  selectedDenomination === denom.id && { color: denom.color }
                ]}>
                  {denom.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      </View>
      
      {/* Notes List */}
      <View style={styles.notesContainer}>
        {loading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={theme?.colors.primary} />
            <Text style={styles.loadingText}>Loading notes...</Text>
          </View>
        ) : filteredNotes.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>No notes found for the selected filters.</Text>
          </View>
        ) : (
          filteredNotes.map(note => (
            <TouchableOpacity
              key={note.id}
              style={styles.noteCard}
              onPress={() => viewNote(note)}
            >
              <View style={styles.noteHeader}>
                <Text style={styles.noteTitle}>{note.title}</Text>
                <View 
                  style={[
                    styles.denominationTag, 
                    { 
                      backgroundColor: DENOMINATIONS.find(d => d.id === note.denomination?.id)?.color + '20',
                      borderColor: DENOMINATIONS.find(d => d.id === note.denomination?.id)?.color + '40'
                    }
                  ]}
                >
                  <Text style={[
                    styles.denominationTagText,
                    { color: DENOMINATIONS.find(d => d.id === note.denomination?.id)?.color }
                  ]}>
                    {DENOMINATIONS.find(d => d.id === note.denomination?.id)?.name}
                  </Text>
                </View>
              </View>
              
              <Text style={styles.noteExcerpt} numberOfLines={3}>
                {note.excerpt}
              </Text>
              
              <View style={styles.noteFooter}>
                <View style={styles.noteAuthorContainer}>
                  <Text style={styles.noteAuthor}>{note.author?.first_name}</Text>
                  <Text style={styles.noteDate}>
                    {new Date(note.created_at || Date.now()).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric'
                    })}
                  </Text>
                </View>
                
                <View style={styles.noteLikes}>
                  <Heart size={16} color={theme?.colors.like} />
                  <Text style={styles.noteLikesCount}>{note.likes}</Text>
                </View>
              </View>
            </TouchableOpacity>
          ))
        )}
      </View>
    </View>
  );
  
  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {renderHeader()}
      
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        onScroll={handleScroll}
        scrollEventThrottle={16}
      >
        {activeTab === 'explore' && renderExploreTab()}
        {activeTab === 'learn' && renderLearnTab()}
        {activeTab === 'notes' && renderNotesTab()}
      </ScrollView>
      
      <AuthModal
        visible={showAuthModal}
        onClose={() => setShowAuthModal(false)}
      />
    </View>
  );
};

const createStyles = (theme: Theme) => StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme?.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.md,
  },
  headerTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
  },
  tabsContainer: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: theme?.colors.border,
    position: 'relative',
  },
  tab: {
    flex: 1,
    paddingVertical: theme?.spacing.md,
    alignItems: 'center',
  },
  tabText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
  },
  activeTabText: {
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  tabIndicator: {
    position: 'absolute',
    bottom: 0,
    height: 3,
    width: Dimensions.get('window').width / 3,
    backgroundColor: theme?.colors.primary,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: theme?.spacing.xl,
  },
  tabContent: {
    padding: theme?.spacing.md,
  },
  section: {
    marginBottom: theme?.spacing.lg,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.xs,
  },
  sectionTitle: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    fontWeight: '600',
    marginBottom: theme?.spacing.sm,
    letterSpacing: 1,
  },
  viewAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  viewAllText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  
  // Featured Card Styles
  featuredCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 3,
      },
    }),
  },
  featuredGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  featuredContent: {
    flexDirection: 'row',
    padding: theme?.spacing.md,
  },
  featuredIconContainer: {
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: theme?.spacing.md,
  },
  featuredTextContainer: {
    flex: 1,
  },
  featuredTitle: {
    ...theme?.typography.heading.medium,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.xs,
  },
  featuredDescription: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.sm,
  },
  featuredMeta: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: theme?.spacing.md,
  },
  featuredMetaItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  featuredMetaText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  featuredActions: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: theme?.colors.border,
    padding: theme?.spacing.md,
  },
  actionButton: {
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
  },
  
  // Virtues Grid Styles
  virtuesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    gap: theme?.spacing.sm,
  },
  virtueGridCard: {
    width: '31%',
    aspectRatio: 0.9,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    marginBottom: theme?.spacing.sm,
    overflow: 'hidden',
  },
  virtueGridGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  virtueIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.sm,
  },
  virtueGridName: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    textAlign: 'center',
    fontWeight: '500',
  },
  progressIndicator: {
    width: '100%',
    marginTop: theme?.spacing.sm,
  },
  progressBar: {
    height: 3,
    backgroundColor: `${theme?.colors.border}50`,
    borderRadius: theme?.borderRadius.full,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    borderRadius: theme?.borderRadius.full,
  },
  
  // Community Card Styles
  communityCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 3,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  communityHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme?.spacing.md,
  },
  communityTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
  },
  challengeText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    marginBottom: theme?.spacing.md,
  },
  communityStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.md,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  statText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  joinChallengeButton: {
    backgroundColor: theme?.colors.primary,
    paddingVertical: theme?.spacing.sm,
    paddingHorizontal: theme?.spacing.md,
    borderRadius: theme?.borderRadius.full,
    alignItems: 'center',
  },
  joinChallengeText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
  },
  
  // Virtue Detail Styles
  virtueDetailHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.md,
  },
  backToVirtuesButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  backToVirtuesText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  virtueDetailTitle: {
    ...theme?.typography.heading.medium,
    fontWeight: '600',
  },
  virtueDetailCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.lg,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    overflow: 'hidden',
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 3,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  virtueDetailGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  virtueDetailContent: {
    alignItems: 'center',
  },
  virtueDetailIconContainer: {
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: theme?.spacing.md,
  },
  virtueDetailDescription: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.primary,
    textAlign: 'center',
    marginBottom: theme?.spacing.md,
  },
  scriptureContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: `${theme?.colors.background}50`,
    borderRadius: theme?.borderRadius.md,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
  },
  scriptureText: {
    ...theme?.typography.body.serif,
    color: theme?.colors.text.primary,
    fontStyle: 'italic',
    marginLeft: theme?.spacing.sm,
  },
  progressContainer: {
    width: '100%',
    marginTop: theme?.spacing.md,
  },
  progressLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.xs,
  },
  progressText: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.xs,
    textAlign: 'center',
  },
  
  // Level Card Styles
  levelsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.lg,
  },
  levelCard: {
    width: '30%',
    aspectRatio: 0.8,
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: theme?.colors.border,
    overflow: 'hidden',
  },
  completedLevelCard: {
    borderColor: theme?.colors.success,
  },
  lockedLevelCard: {
    opacity: 0.6,
  },
  levelGradient: {
    ...StyleSheet.absoluteFillObject,
  },
  levelNumber: {
    ...theme?.typography.heading.large,
    fontWeight: 'bold',
    marginBottom: theme?.spacing.sm,
  },
  levelLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.primary,
    textAlign: 'center',
  },
  lockedLevelLabel: {
    color: theme?.colors.text.secondary,
  },
  lockedIconContainer: {
    marginBottom: theme?.spacing.sm,
  },
  completedBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    width: 20,
    height: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  continueButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: theme?.spacing.md,
    paddingHorizontal: theme?.spacing.lg,
    borderRadius: theme?.borderRadius.full,
    marginTop: theme?.spacing.md,
  },
  continueButtonText: {
    ...theme?.typography.body.sans,
    color: '#FFF',
    fontWeight: '600',
    marginRight: theme?.spacing.sm,
  },
  
  // Note Card Styles
  notesContainer: {
    marginTop: theme?.spacing.md,
  },
  noteCard: {
    backgroundColor: theme?.colors.surface,
    borderRadius: theme?.borderRadius.lg,
    padding: theme?.spacing.md,
    marginBottom: theme?.spacing.md,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.05,
        shadowRadius: 3,
      },
      android: {
        elevation: 1,
      },
    }),
  },
  noteHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: theme?.spacing.sm,
  },
  noteTitle: {
    ...theme?.typography.heading.small,
    color: theme?.colors.text.primary,
    flex: 1,
    marginRight: theme?.spacing.sm,
  },
  denominationTag: {
    paddingHorizontal: theme?.spacing.sm,
    paddingVertical: 2,
    borderRadius: theme?.borderRadius.full,
    borderWidth: 1,
  },
  denominationTagText: {
    ...theme?.typography.caption.secondary,
    fontSize: 10,
    fontWeight: '600',
  },
  noteExcerpt: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.md,
  }, noteFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  noteAuthorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  noteAuthor: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  noteDate: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.tertiary,
  },
  noteLikes: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: theme?.spacing.xs,
  },
  noteLikesCount: {
    ...theme?.typography.caption.secondary,
    color: theme?.colors.text.secondary,
  },
  
  // Filter Styles
  filtersContainer: {
    marginBottom: theme?.spacing.md,
  },
  filterSection: {
    marginBottom: theme?.spacing.md,
  },
  filterLabel: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
    marginBottom: theme?.spacing.sm,
    fontWeight: '600',
  },
  filterScrollContent: {
    paddingRight: theme?.spacing.md,
    gap: theme?.spacing.sm,
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: theme?.spacing.md,
    paddingVertical: theme?.spacing.sm,
    borderRadius: theme?.borderRadius.full,
    borderWidth: 1,
    borderColor: theme?.colors.border,
    marginRight: theme?.spacing.sm,
    backgroundColor: theme?.colors.surface,
    gap: theme?.spacing.xs,
  },
  activeFilterChip: {
    borderColor: theme?.colors.primary,
    backgroundColor: `${theme?.colors.primary}10`,
  },
  filterChipText: {
    ...theme?.typography.caption.primary,
    color: theme?.colors.text.secondary,
  },
  activeFilterChipText: {
    color: theme?.colors.primary,
    fontWeight: '600',
  },
  denominationDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  
  // Loading and Empty States
  loadingContainer: {
    padding: theme?.spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    marginTop: theme?.spacing.md,
  },
  emptyContainer: {
    padding: theme?.spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyText: {
    ...theme?.typography.body.sans,
    color: theme?.colors.text.secondary,
    textAlign: 'center',
    marginTop: theme?.spacing.md,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: theme?.spacing.sm,
  },
  backButton: {
    padding: theme?.spacing.sm,
    marginLeft: -theme?.spacing.sm,
  },
  tabContainer: {
    flexDirection: 'row',
    position: 'relative',
    height: 40,
  },
  activeTab: {
  },
  noteMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
});

export default VirtueScreen;