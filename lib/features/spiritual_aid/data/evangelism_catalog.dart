import '../domain/models/evangelism_content.dart';

class EvangelismCatalog {
  const EvangelismCatalog._();

  static final List<EvangelismContent> all = [
    // ─── VERSE CARDS (8) ─────────────────────────────────────────────
    EvangelismContent(
      id: 'vc_01',
      title: 'You Are Never Alone',
      body: 'Even in your darkest moment, God is right there with you. He has not forgotten you. He has not abandoned you. You are held.',
      category: 'encouragement',
      type: 'verse_card',
      relatedVerse: 'The Lord himself goes before you and will be with you; he will never leave you nor forsake you.',
      relatedVerseReference: 'Deuteronomy 31:8',
      createdAt: DateTime(2025, 1, 1),
    ),
    EvangelismContent(
      id: 'vc_02',
      title: 'Hope That Never Fades',
      body: 'When the world offers hope that disappoints, God offers hope that endures. Anchor your soul in the One who never changes.',
      category: 'hope',
      type: 'verse_card',
      relatedVerse: 'We have this hope as an anchor for the soul, firm and secure.',
      relatedVerseReference: 'Hebrews 6:19',
      createdAt: DateTime(2025, 1, 2),
    ),
    EvangelismContent(
      id: 'vc_03',
      title: 'Loved Beyond Measure',
      body: 'Before you did anything to earn it, God loved you. His love is not based on your performance. It is based on His character.',
      category: 'love',
      type: 'verse_card',
      relatedVerse: 'But God demonstrates his own love for us in this: While we were still sinners, Christ died for us.',
      relatedVerseReference: 'Romans 5:8',
      createdAt: DateTime(2025, 1, 3),
    ),
    EvangelismContent(
      id: 'vc_04',
      title: 'Strength for Today',
      body: 'You do not have to carry today\'s burdens alone. There is a strength available to you that is not your own. Ask for it.',
      category: 'faith',
      type: 'verse_card',
      relatedVerse: 'I can do all this through him who gives me strength.',
      relatedVerseReference: 'Philippians 4:13',
      createdAt: DateTime(2025, 1, 4),
    ),
    EvangelismContent(
      id: 'vc_05',
      title: 'A Future of Promise',
      body: 'Whatever you are facing, it is not the end of your story. God has plans for you that are beyond what you can imagine right now.',
      category: 'hope',
      type: 'verse_card',
      relatedVerse: 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you.',
      relatedVerseReference: 'Jeremiah 29:11',
      createdAt: DateTime(2025, 1, 5),
    ),
    EvangelismContent(
      id: 'vc_06',
      title: 'Peace in the Storm',
      body: 'Storms will come. But there is One who commands the wind and the waves. He is not panicking. Neither should you.',
      category: 'encouragement',
      type: 'verse_card',
      relatedVerse: 'Peace I leave with you; my peace I give you. I do not give to you as the world gives.',
      relatedVerseReference: 'John 14:27',
      createdAt: DateTime(2025, 1, 6),
    ),
    EvangelismContent(
      id: 'vc_07',
      title: 'Wisdom for the Asking',
      body: 'Confused about what to do next? God invites you to ask Him for wisdom, and He promises to give it generously, without finding fault.',
      category: 'wisdom',
      type: 'verse_card',
      relatedVerse: 'If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault.',
      relatedVerseReference: 'James 1:5',
      createdAt: DateTime(2025, 1, 7),
    ),
    EvangelismContent(
      id: 'vc_08',
      title: 'You Are His Masterpiece',
      body: 'You are not an accident. You are not a mistake. You are God\'s handiwork, created with intention and purpose.',
      category: 'love',
      type: 'verse_card',
      relatedVerse: 'For we are God\'s handiwork, created in Christ Jesus to do good works.',
      relatedVerseReference: 'Ephesians 2:10',
      createdAt: DateTime(2025, 1, 8),
    ),

    // ─── TESTIMONY TEMPLATES (6) ─────────────────────────────────────
    EvangelismContent(
      id: 'tt_01',
      title: 'My Life Before and After',
      body: 'Use this framework to share your story:\n\n'
          '1. MY LIFE BEFORE: Briefly describe what your life looked like before encountering God. What were you searching for? What was missing?\n\n'
          '2. HOW I MET GOD: Share the moment or season when everything changed. What happened? Who was involved? What did God do?\n\n'
          '3. MY LIFE NOW: Describe the difference God has made. Not perfection, but transformation. What has changed? What continues to change?\n\n'
          'Keep it personal, honest, and brief. Your story does not need to be dramatic to be powerful.',
      category: 'faith',
      type: 'testimony_template',
      createdAt: DateTime(2025, 1, 9),
    ),
    EvangelismContent(
      id: 'tt_02',
      title: 'How God Showed Up in My Darkest Moment',
      body: 'Framework for sharing God\'s faithfulness:\n\n'
          '1. THE SITUATION: What was the darkest season you faced? (Be honest but appropriate in detail.)\n\n'
          '2. WHERE I TURNED: How did you reach out to God? Or how did He reach you even when you were not looking?\n\n'
          '3. WHAT GOD DID: Share specifically how God showed up. Was it peace, provision, a person, a scripture that came alive?\n\n'
          '4. WHAT I LEARNED: What truth about God became real to you through this experience?\n\n'
          'Remember: vulnerability connects. You do not need to have it all figured out.',
      category: 'encouragement',
      type: 'testimony_template',
      createdAt: DateTime(2025, 1, 10),
    ),
    EvangelismContent(
      id: 'tt_03',
      title: 'A Simple Faith Story',
      body: 'Sometimes the simplest stories are the most powerful:\n\n'
          '"I used to think __________. Then I discovered __________. Now I __________." \n\n'
          'Examples:\n'
          '- "I used to think I had to be perfect for God to love me. Then I discovered grace. Now I live with freedom."\n'
          '- "I used to think prayer was just talking to the ceiling. Then I experienced God answering. Now prayer is my lifeline."\n'
          '- "I used to think the Bible was outdated. Then its words spoke directly to my situation. Now I read it daily."\n\n'
          'Fill in your own version. Practice saying it aloud.',
      category: 'faith',
      type: 'testimony_template',
      createdAt: DateTime(2025, 1, 11),
    ),
    EvangelismContent(
      id: 'tt_04',
      title: 'When Faith Was Hard but Worth It',
      body: 'Share about persevering through difficulty:\n\n'
          '1. THE CHALLENGE: What made faith difficult? Doubt? Suffering? Disappointment?\n\n'
          '2. WHAT I WANTED TO DO: Be honest about wanting to give up or walk away.\n\n'
          '3. WHY I STAYED: What kept you holding on? A verse, a community, a quiet conviction?\n\n'
          '4. WHAT I FOUND: On the other side of that difficulty, what did you discover about God?\n\n'
          'This template is powerful for people who think faith is only for those with easy lives.',
      category: 'hope',
      type: 'testimony_template',
      createdAt: DateTime(2025, 1, 12),
    ),
    EvangelismContent(
      id: 'tt_05',
      title: 'How God Changed My Relationships',
      body: 'Framework for sharing transformation in relationships:\n\n'
          '1. THE PATTERN: What unhealthy patterns did you carry into relationships? (Anger, withdrawal, people-pleasing, control?)\n\n'
          '2. THE TURNING POINT: When did you realize something needed to change?\n\n'
          '3. GOD\'S WORK: How did God begin to heal and transform the way you relate to others?\n\n'
          '4. THE DIFFERENCE: What do your relationships look like now compared to before?\n\n'
          'This resonates deeply because everyone has relationship struggles.',
      category: 'love',
      type: 'testimony_template',
      createdAt: DateTime(2025, 1, 13),
    ),
    EvangelismContent(
      id: 'tt_06',
      title: 'Finding Purpose Through Faith',
      body: 'Share how God gave your life direction:\n\n'
          '1. THE SEARCH: What were you looking for before? Success? Meaning? Belonging?\n\n'
          '2. THE DISCOVERY: How did you encounter God\'s purpose for your life?\n\n'
          '3. THE JOURNEY: What steps have you taken since? What has surprised you?\n\n'
          '4. THE INVITATION: How might someone else begin this same journey?\n\n'
          'End with a gentle invitation, not a sales pitch. Let your story do the work.',
      category: 'wisdom',
      type: 'testimony_template',
      createdAt: DateTime(2025, 1, 14),
    ),

    // ─── CONVERSATION STARTERS (8) ───────────────────────────────────
    EvangelismContent(
      id: 'cs_01',
      title: 'The Gratitude Opener',
      body: '"What is one thing you are really grateful for right now?"\n\n'
          'Why it works: Everyone can answer this, and it naturally leads to deeper conversations about purpose, meaning, and where good things come from.',
      category: 'encouragement',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 15),
    ),
    EvangelismContent(
      id: 'cs_02',
      title: 'The Big Question',
      body: '"If you could know the answer to one big question about life, what would it be?"\n\n'
          'Why it works: This opens the door to discuss meaning, purpose, the afterlife, and faith without being preachy. Listen first, share second.',
      category: 'wisdom',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 16),
    ),
    EvangelismContent(
      id: 'cs_03',
      title: 'The Peace Question',
      body: '"Where do you go for peace when life gets overwhelming?"\n\n'
          'Why it works: Everyone experiences stress. This question creates space to share about prayer, scripture, and finding rest in God.',
      category: 'hope',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 17),
    ),
    EvangelismContent(
      id: 'cs_04',
      title: 'The Story Invitation',
      body: '"Has anything happened recently that made you think there might be more to life than what we see?"\n\n'
          'Why it works: Many people have spiritual experiences they never talk about. This gives them permission to share.',
      category: 'faith',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 18),
    ),
    EvangelismContent(
      id: 'cs_05',
      title: 'The Comfort Bridge',
      body: '"When you are going through a really tough time, what gives you hope?"\n\n'
          'Why it works: Opens a natural bridge to sharing about the hope found in Christ, without forcing the conversation.',
      category: 'hope',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 19),
    ),
    EvangelismContent(
      id: 'cs_06',
      title: 'The Book Question',
      body: '"Have you ever read anything that genuinely changed your perspective on life?"\n\n'
          'Why it works: If they ask you back, you can naturally mention the Bible or a faith book that impacted you.',
      category: 'wisdom',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 20),
    ),
    EvangelismContent(
      id: 'cs_07',
      title: 'The Legacy Prompt',
      body: '"What do you hope people say about you at the end of your life?"\n\n'
          'Why it works: This naturally leads to conversations about values, purpose, and what really matters.',
      category: 'encouragement',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 21),
    ),
    EvangelismContent(
      id: 'cs_08',
      title: 'The Love Language',
      body: '"What is the kindest thing anyone has ever done for you?"\n\n'
          'Why it works: Stories of love and kindness naturally lead to conversations about the source of love itself.',
      category: 'love',
      type: 'conversation_starter',
      createdAt: DateTime(2025, 1, 22),
    ),

    // ─── GUIDES (4) ──────────────────────────────────────────────────
    EvangelismContent(
      id: 'gu_01',
      title: 'How to Share Your Faith Naturally',
      body: '5 PRINCIPLES FOR NATURAL FAITH SHARING:\n\n'
          '1. LIVE IT FIRST: Your life is your loudest sermon. Let people see the difference before you explain it.\n\n'
          '2. ASK, DON\'T TELL: Ask questions more than you give answers. Curiosity opens hearts; lectures close them.\n\n'
          '3. SHARE YOUR STORY: Personal experience is more powerful than theological arguments. People can argue with doctrine but not with your story.\n\n'
          '4. BE PATIENT: Faith journeys take time. Plant seeds. Water them. Trust God for the growth.\n\n'
          '5. LOVE WITHOUT AN AGENDA: Love people because God loves them, not because you want to convert them. Genuine love is the most persuasive argument.',
      category: 'faith',
      type: 'guide',
      createdAt: DateTime(2025, 1, 23),
    ),
    EvangelismContent(
      id: 'gu_02',
      title: 'Answering Hard Questions About Faith',
      body: 'WHEN SOMEONE ASKS A TOUGH QUESTION:\n\n'
          '1. DO NOT PANIC: It is okay to say "I do not know, but I will look into it."\n\n'
          '2. LISTEN CAREFULLY: Often the question behind the question is about pain, not theology.\n\n'
          '3. BE HONEST: If you have struggled with the same question, say so. Honesty builds trust.\n\n'
          '4. POINT TO JESUS: You do not need to have all the answers. Point people to the One who does.\n\n'
          '5. FOLLOW UP: If you promised to research something, do it. Faithfulness in small things matters.\n\n'
          'Common hard questions: Why does God allow suffering? Is the Bible reliable? What about other religions? Why does the church have so many problems?',
      category: 'wisdom',
      type: 'guide',
      createdAt: DateTime(2025, 1, 24),
    ),
    EvangelismContent(
      id: 'gu_03',
      title: 'Sharing Faith Online',
      body: 'TIPS FOR FAITH-SHARING ON SOCIAL MEDIA:\n\n'
          '1. BE AUTHENTIC: Do not perform a perfect life. Share real struggles and real hope.\n\n'
          '2. USE YOUR PLATFORM: Share what God is teaching you in real time.\n\n'
          '3. RESPOND WITH GRACE: When people disagree or attack, respond with kindness. The world is watching.\n\n'
          '4. CREATE SHAREABLE CONTENT: Beautiful verse images, short testimonies, and thoughtful reflections are easily shared.\n\n'
          '5. INVITE CONVERSATION: End posts with a question. Create space for dialogue, not monologue.\n\n'
          '6. REMEMBER THE PERSON: Behind every profile is a real person with real needs.',
      category: 'encouragement',
      type: 'guide',
      createdAt: DateTime(2025, 1, 25),
    ),
    EvangelismContent(
      id: 'gu_04',
      title: 'Praying for the People in Your Life',
      body: 'A PRACTICAL PRAYER FRAMEWORK:\n\n'
          '1. MAKE A LIST: Write down 5 people who do not yet know Christ.\n\n'
          '2. PRAY DAILY: Ask God to soften their hearts and open their eyes.\n\n'
          '3. PRAY FOR OPPORTUNITIES: Ask God to give you natural moments to share.\n\n'
          '4. PRAY FOR BOLDNESS: Ask for courage that is gentle, not aggressive.\n\n'
          '5. PRAY FOR OTHERS: Ask God to send other believers across their path as well.\n\n'
          'Remember: God loves them more than you do. You are partnering with Him, not doing this alone.',
      category: 'love',
      type: 'guide',
      createdAt: DateTime(2025, 1, 26),
    ),

    // ─── PRAYER CARDS (6) ────────────────────────────────────────────
    EvangelismContent(
      id: 'pc_01',
      title: 'A Prayer for a Friend',
      body: 'Lord, I lift up my friend to You today. You know them by name. You know their heart. Open their eyes to see Your love. Soften the soil of their heart to receive the seeds of Your truth. Send people, circumstances, and moments that point them to You. I trust You with this person I love. Amen.',
      category: 'love',
      type: 'prayer_card',
      relatedVerse: 'The Lord is not slow in keeping his promise... Instead he is patient with you, not wanting anyone to perish.',
      relatedVerseReference: '2 Peter 3:9',
      createdAt: DateTime(2025, 1, 27),
    ),
    EvangelismContent(
      id: 'pc_02',
      title: 'A Prayer for Someone Who Is Hurting',
      body: 'Compassionate God, someone I know is hurting deeply right now. They may not know You, but You know them. Reach into their pain with Your comfort. Use this moment of brokenness to draw them close. Let them feel Your presence even before they can name it. Show me how to be Your hands and feet to them. Amen.',
      category: 'encouragement',
      type: 'prayer_card',
      relatedVerse: 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
      relatedVerseReference: 'Psalm 34:18',
      createdAt: DateTime(2025, 1, 28),
    ),
    EvangelismContent(
      id: 'pc_03',
      title: 'A Prayer for Courage to Speak',
      body: 'Holy Spirit, give me the courage to share my faith when the moment comes. Remove the fear of rejection. Replace it with love for the person in front of me. Give me the right words at the right time. Let my words be seasoned with grace. I do not want to miss a divine appointment because I was afraid. Amen.',
      category: 'faith',
      type: 'prayer_card',
      relatedVerse: 'Always be prepared to give an answer to everyone who asks you to give the reason for the hope that you have.',
      relatedVerseReference: '1 Peter 3:15',
      createdAt: DateTime(2025, 1, 29),
    ),
    EvangelismContent(
      id: 'pc_04',
      title: 'A Prayer for Those Searching',
      body: 'Father, there are people right now who are searching for something they cannot name. They are looking for meaning, for peace, for love that does not disappoint. You are what they are looking for. Meet them in their search. Reveal Yourself in unmistakable ways. Draw them with cords of kindness. Amen.',
      category: 'hope',
      type: 'prayer_card',
      relatedVerse: 'You will seek me and find me when you seek me with all your heart.',
      relatedVerseReference: 'Jeremiah 29:13',
      createdAt: DateTime(2025, 1, 30),
    ),
    EvangelismContent(
      id: 'pc_05',
      title: 'A Prayer for Your Neighborhood',
      body: 'Lord, I pray for the people on my street, in my building, in my community. You placed me here for a reason. Help me be a light in this specific place. Give me opportunities to serve, to listen, to love. Let my home be a place where people encounter Your warmth. Amen.',
      category: 'love',
      type: 'prayer_card',
      relatedVerse: 'You are the light of the world. A town built on a hill cannot be hidden.',
      relatedVerseReference: 'Matthew 5:14',
      createdAt: DateTime(2025, 1, 31),
    ),
    EvangelismContent(
      id: 'pc_06',
      title: 'A Prayer of Blessing',
      body: 'May the Lord bless you and keep you. May His face shine upon you and be gracious to you. May He turn His face toward you and give you peace. May you know how deeply loved you are, today and always.',
      category: 'encouragement',
      type: 'prayer_card',
      relatedVerse: 'The Lord bless you and keep you; the Lord make his face shine on you and be gracious to you.',
      relatedVerseReference: 'Numbers 6:24-25',
      createdAt: DateTime(2025, 2, 1),
    ),
  ];

  static List<EvangelismContent> byType(String type) {
    return all.where((c) => c.type == type).toList();
  }

  static List<EvangelismContent> byCategory(String category) {
    return all.where((c) => c.category == category).toList();
  }

  static EvangelismContent? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
