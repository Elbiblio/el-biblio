export const endpoints = {
  auth: {
    login: '/auth/login',
    logout: '/auth/logout',
    user: '/auth/me',
    signup: '/users',
    refresh: '/auth/refresh',
    forgotPassword: '/auth/forgot-password',
    resetPassword: '/auth/reset-password',
    verifyEmail: '/auth/verify-email',
  },

  users: {
    list: '/users',
    show: (id: string) => `/users/${id}`,
    update: (id: string) => `/users/${id}`,
    delete: (id: string) => `/users/${id}`,
    avatar: (id: string) => `/users/${id}/avatar`,
    profile: (id: string) => `/users/${id}/profile`,
    preferences: (id: string) => `/users/${id}/preferences`,
    reminderPreferences: (id: string) => `/users/${id}/reminder-preferences`,
    activity: (id: string) => `/users/${id}/activity`,
    stats: (id: string) => `/users/${id}/stats`,
  },

  verses: {
    list: '/verses',
    daily: '/verses/daily',
    show: (id: string) => `/verses/${id}`,
    update: (id: string) => `/verses/${id}`,
    delete: (id: string) => `/verses/${id}`,
    vote: (id: string) => `/verses/${id}/vote`,
    like: (id: string) => `/verses/${id}/like`,
    share: (id: string) => `/verses/${id}/share`,
    trending: '/verses/trending',
    featured: '/verses/featured',
    search: '/verses/search',
    byTheme: (themeId: string) => `/verses/theme/${themeId}`,
  },

  notes: {
    list: '/notes',
    show: (id: string) => `/notes/${id}`,
    create: '/notes',
    update: (id: string) => `/notes/${id}`,
    delete: (id: string) => `/notes/${id}`,
    like: (id: string) => `/notes/${id}/like`,
    share: (id: string) => `/notes/${id}/share`,
    pin: (id: string) => `/notes/${id}/pin`,
    public: '/notes/public',
    featured: '/notes/featured',
    search: '/notes/search',
    byUser: (userId: string) => `/users/${userId}/notes`,
  },

  reflections: {
    list: '/reflections',
    show: (id: string) => `/reflections/${id}`,
    create: '/reflections',
    update: (id: string) => `/reflections/${id}`,
    delete: (id: string) => `/reflections/${id}`,
    like: (id: string) => `/reflections/${id}/like`,
    share: (id: string) => `/reflections/${id}/share`,
    byVerse: (verseId: string) => `/verses/${verseId}/reflections`,
    byUser: (userId: string) => `/users/${userId}/reflections`,
    featured: '/reflections/featured',
  },

  comments: {
    list: '/comments',
    show: (id: string) => `/comments/${id}`,
    create: '/comments',
    update: (id: string) => `/comments/${id}`,
    delete: (id: string) => `/comments/${id}`,
    like: (id: string) => `/comments/${id}/like`,
    byReflection: (reflectionId: string) => `/reflections/${reflectionId}/comments`,
    replies: (id: string) => `/comments/${id}/replies`,
  },

  bookmarks: {
    list: '/bookmarks',
    show: (id: string) => `/bookmarks/${id}`,
    create: '/bookmarks',
    update: (id: string) => `/bookmarks/${id}`,
    delete: (id: string) => `/bookmarks/${id}`,
    byUser: (userId: string) => `/users/${userId}/bookmarks`,
    byType: (type: string) => `/bookmarks/type/${type}`,
  },

  interactions: {
    list: '/user-interactions',
    create: '/user-interactions',
    update: (id: string) => `/user-interactions/${id}`,
    delete: (id: string) => `/user-interactions/${id}`,
    byUser: (userId: string) => `/users/${userId}/interactions`,
    byType: (type: string) => `/user-interactions/type/${type}`,
  },

  activities: {
    list: '/activities',
    show: (id: string) => `/activities/${id}`,
    create: '/activities',
    update: (id: string) => `/activities/${id}`,
    delete: (id: string) => `/activities/${id}`,
    byUser: (userId: string) => `/users/${userId}/activities`,
    feed: '/activities/feed',
    recent: '/activities/recent',
  },

  notifications: {
    list: '/notifications',
    show: (id: string) => `/notifications/${id}`,
    markAsRead: (id: string) => `/notifications/${id}/read`,
    markAllAsRead: '/notifications/mark-all-read',
    delete: (id: string) => `/notifications/${id}`,
    settings: '/notifications/settings',
    unreadCount: '/notifications/unread-count',
    registerDevice: '/notifications/register-device',
  },

  themes: {
    list: '/themes',
    show: (id: string) => `/themes/${id}`,
    create: '/themes',
    update: (id: string) => `/themes/${id}`,
    delete: (id: string) => `/themes/${id}`,
    foundational: '/themes/foundational',
    byUser: (userId: string) => `/users/${userId}/themes`,
  },

  wordHubs: {
    list: '/word-hubs',
    show: (id: string) => `/word-hubs/${id}`,
    create: '/word-hubs',
    update: (id: string) => `/word-hubs/${id}`,
    delete: (id: string) => `/word-hubs/${id}`,
    join: (id: string) => `/word-hubs/${id}/join`,
    leave: (id: string) => `/word-hubs/${id}/leave`,
    members: (id: string) => `/word-hubs/${id}/members`,
    messages: (id: string) => `/word-hubs/${id}/messages`,
    sendMessage: (id: string) => `/word-hubs/${id}/messages`,
    byUser: (userId: string) => `/users/${userId}/word-hubs`,
  },

  matches: {
    list: '/matches',
    show: (id: string) => `/matches/${id}`,
    create: '/matches',
    update: (id: string) => `/matches/${id}`,
    delete: (id: string) => `/matches/${id}`,
    cancel: (id: string) => `/matches/${id}/cancel`,
    accept: (id: string) => `/matches/${id}/accept`,
    reject: (id: string) => `/matches/${id}/reject`,
    active: '/matches/active',
    history: '/matches/history',
  },

  languages: {
    list: '/languages',
    show: (id: string) => `/languages/${id}`,
    active: '/languages/active',
  },

  cache: {
    get: (key: string) => `/cache/${key}`,
    set: '/cache',
    delete: (key: string) => `/cache/${key}`,
    clear: '/cache/clear',
  },

  jobs: {
    list: '/jobs',
    show: (id: string) => `/jobs/${id}`,
    create: '/jobs',
    retry: (id: string) => `/jobs/${id}/retry`,
    cancel: (id: string) => `/jobs/${id}/cancel`,
  },

  leaderboards: {
    global: '/leaderboards/global',
    byTheme: (themeId: string) => `/leaderboards/theme/${themeId}`,
    byTimeframe: (timeframe: string) => `/leaderboards/timeframe/${timeframe}`,
    userRank: (userId: string) => `/leaderboards/user/${userId}/rank`,
  },

  stats: {
    user: (userId: string) => `/stats/user/${userId}`,
    global: '/stats/global',
    theme: (themeId: string) => `/stats/theme/${themeId}`,
  },

  search: {
    global: '/search',
    verses: '/search/verses',
    notes: '/search/notes',
    reflections: '/search/reflections',
    users: '/search/users',
  },

  bible: {
    versions: '/bible/versions',
    verses: '/bible/verses',
    search: '/bible/search',
    compare: (version: string, reference: string) => `/bible/${version}/compare/${encodeURIComponent(reference)}`,
    installVersion: (version: string) => `/bible/verses/${version}/install`,
    toggleHighlight: (verseId: string) => `/bible/verses/${verseId}/highlight`,
    toggleBookmark: (verseId: string) => `/bible/verses/${verseId}/bookmark`,
    like: (verseId: string) => `/bible/verses/${verseId}/like`,
    share: (verseId: string) => `/bible/verses/${verseId}/share`,
    explain: (verseId: string) => `/bible/verses/${verseId}/explain`,
  },

  challenges: {
    personal: '/challenges/personal',
    community: '/challenges/community',
    suggested: '/challenges/suggested',
    daily: '/challenges/daily',
    show: (id: string) => `/challenges/${id}`,
    create: '/challenges',
    update: (id: string) => `/challenges/${id}`,
    delete: (id: string) => `/challenges/${id}`,
    join: (id: string) => `/challenges/${id}/join`,
    leave: (id: string) => `/challenges/${id}/leave`,
    upvote: (id: string) => `/challenges/${id}/upvote`,
    vote: (id: string) => `/challenges/${id}/vote`,
    complete: (id: string) => `/challenges/${id}/complete`,
    feedback: (id: string) => `/challenges/${id}/feedback`,
    addToPersonal: (id: string) => `/challenges/${id}/add-to-personal`,
    participants: (id: string) => `/challenges/${id}/participants`,
  },

  prayerRequests: {
    list: '/prayer-requests',
    show: (id: string) => `/prayer-requests/${id}`,
    create: '/prayer-requests',
    update: (id: string) => `/prayer-requests/${id}`,
    delete: (id: string) => `/prayer-requests/${id}`,
    pray: (id: string) => `/prayer-requests/${id}/pray`,
    amen: (id: string) => `/prayer-requests/${id}/amen`,
    byUser: (userId: string) => `/users/${userId}/prayer-requests`,
  },

  uploads: {
    presign: '/uploads/presign',
    upload: '/uploads/upload',
    delete: (id: string) => `/uploads/${id}`,
  },

  prayerRequestComments: {
    list: '/prayer-request-comments',
    show: (id: string) => `/prayer-request-comments/${id}`,
    create: '/prayer-request-comments',
    update: (id: string) => `/prayer-request-comments/${id}`,
    delete: (id: string) => `/prayer-request-comments/${id}`,
    amen: (id: string) => `/prayer-request-comments/${id}/amen`,
  },

  spiritualCareer: {
    progress: '/spiritual-career/progress',
    submit: '/spiritual-career/submit',
    config: '/spiritual-career/config',
    applyGrowth: '/spiritual-career/apply-growth',
    leaderboard: '/spiritual-career/leaderboard',
    growthHistory: '/spiritual-career/growth-history',
    reset: '/spiritual-career/progress',
  },

  featured: {
    list: '/featured',
    show: (id: string) => `/featured/${id}`,
  },

  public: {
    list: '/public',
    show: (id: string) => `/public/${id}`,
    mobileConfig: '/public/mobile-config',
  },

  guides: {
    list: '/guides',
    show: (id: string) => `/guides/${id}`,
    progress: (id: string) => `/guides/${id}/progress`,
  },

  readingProgress: {
    dailyComplete: '/bible-reading/daily/complete',
  },

  featureSuggestions: {
    list: '/feature-suggestions',
    show: (id: string) => `/feature-suggestions/${id}`,
    create: '/feature-suggestions',
    vote: (id: string) => `/feature-suggestions/${id}/vote`,
    unvote: (id: string) => `/feature-suggestions/${id}/vote`,
  },

  habitConquest: {
    base: '/habit-conquest',
    checkins: '/habit-conquest/checkins',
    entries: '/habit-conquest/entries',
    history: '/habit-conquest/history',
    reminders: '/habit-conquest/reminders/sync',
  },
};
