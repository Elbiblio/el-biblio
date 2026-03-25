import '../domain/models/quick_prayer.dart';

class PrayerCatalog {
  const PrayerCatalog._();

  static const List<QuickPrayer> all = [
    // ─── ANXIETY (5) ─────────────────────────────────────────────────
    QuickPrayer(
      id: 'anx_01',
      title: 'When Worry Overwhelms',
      body:
          'Father, my mind is racing and my heart feels heavy with worry. '
          'I lay every anxious thought at Your feet right now. '
          'You have not given me a spirit of fear, but of power, love, and a sound mind. '
          'Quiet the storm inside me. Replace every "what if" with trust in who You are. '
          'I choose to believe that You are working even in what I cannot see. '
          'Hold me steady, Lord. I am safe in Your hands. Amen.',
      category: 'anxiety',
      relatedVerse: 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
      relatedVerseReference: 'Philippians 4:6',
      estimatedSeconds: 30,
    ),
    QuickPrayer(
      id: 'anx_02',
      title: 'Surrendering Fear',
      body:
          'Lord Jesus, fear is whispering lies and I am tempted to believe them. '
          'But You are the truth that silences every lie. '
          'I surrender this fear to You. Take it from my hands, from my chest, from my mind. '
          'Fill the space it occupied with the certainty of Your love. '
          'When I am afraid, I will trust in You. '
          'You are my refuge and my fortress. I will not be shaken. Amen.',
      category: 'anxiety',
      relatedVerse: 'When I am afraid, I put my trust in you.',
      relatedVerseReference: 'Psalm 56:3',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'anx_03',
      title: 'Peace in Uncertainty',
      body:
          'God of all comfort, the future feels uncertain and my soul is restless. '
          'Remind me that You hold tomorrow in Your hands. '
          'You are the same yesterday, today, and forever. '
          'I do not need to know every step ahead; I only need to know You walk beside me. '
          'Grant me peace that transcends understanding, '
          'the kind that guards my heart and mind in Christ Jesus. Amen.',
      category: 'anxiety',
      relatedVerse: 'And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.',
      relatedVerseReference: 'Philippians 4:7',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'anx_04',
      title: 'Calming a Restless Heart',
      body:
          'Heavenly Father, my heart will not be still. '
          'Thoughts spin and my body tenses with worry I cannot name. '
          'Breathe Your peace into me now. '
          'Like a child resting in its mother\'s arms, let me rest in You. '
          'I choose stillness. I choose trust. I choose You over fear. '
          'Be my calm in this chaos. Amen.',
      category: 'anxiety',
      relatedVerse: 'Be still, and know that I am God.',
      relatedVerseReference: 'Psalm 46:10',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'anx_05',
      title: 'Casting My Burdens',
      body:
          'Lord, I have been carrying things that were never mine to hold. '
          'Worries about tomorrow, regrets about yesterday, pressures of today. '
          'You said to cast all my cares on You, because You care for me. '
          'So here they are, Lord. I release them now. '
          'Lighten my load. Renew my strength. '
          'Let me walk freely, knowing You carry what I cannot. Amen.',
      category: 'anxiety',
      relatedVerse: 'Cast all your anxiety on him because he cares for you.',
      relatedVerseReference: '1 Peter 5:7',
      estimatedSeconds: 25,
    ),

    // ─── GRATITUDE (5) ───────────────────────────────────────────────
    QuickPrayer(
      id: 'gra_01',
      title: 'For Daily Blessings',
      body:
          'Father, thank You for this day. '
          'For breath in my lungs, for a mind that thinks, for a heart that beats. '
          'I have taken so much for granted. Open my eyes to Your goodness all around me. '
          'Every sunrise, every kindness from a stranger, every moment of laughter '
          'is a gift from Your hand. '
          'Let gratitude be the rhythm of my life. Amen.',
      category: 'gratitude',
      relatedVerse: 'Give thanks in all circumstances; for this is God\'s will for you in Christ Jesus.',
      relatedVerseReference: '1 Thessalonians 5:18',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'gra_02',
      title: 'Thanking God for His Faithfulness',
      body:
          'Lord, when I look back on my life, I see Your fingerprints on every season. '
          'In every valley, You were there. In every storm, You sheltered me. '
          'Your faithfulness has never failed. '
          'Thank You for the prayers You answered differently than I expected, '
          'for the doors You closed that protected me, '
          'for the grace that carried me when I could not carry myself. Amen.',
      category: 'gratitude',
      relatedVerse: 'The Lord is faithful, and he will strengthen you and protect you from the evil one.',
      relatedVerseReference: '2 Thessalonians 3:3',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'gra_03',
      title: 'For the People I Love',
      body:
          'God, thank You for the people You have placed in my life. '
          'For those who encourage me, challenge me, and love me. '
          'For family and friends, for mentors and companions on this journey. '
          'Bless them abundantly. Protect them. '
          'Let me never take for granted the gift of community and connection. '
          'Help me love them as You love me. Amen.',
      category: 'gratitude',
      relatedVerse: 'I thank my God every time I remember you.',
      relatedVerseReference: 'Philippians 1:3',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'gra_04',
      title: 'Gratitude in Hard Times',
      body:
          'Father, even in this difficult season, I choose to thank You. '
          'Not because things are easy, but because You are good. '
          'Thank You for the strength You give me each morning. '
          'Thank You for the lessons that pain teaches. '
          'Thank You that nothing is wasted in Your hands. '
          'Turn my mourning into dancing, and my sorrow into joy. Amen.',
      category: 'gratitude',
      relatedVerse: 'And we know that in all things God works for the good of those who love him.',
      relatedVerseReference: 'Romans 8:28',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'gra_05',
      title: 'For Grace Undeserved',
      body:
          'Lord Jesus, I do not deserve Your love, yet You give it freely. '
          'I do not deserve Your mercy, yet it is new every morning. '
          'Thank You for the cross. Thank You for salvation. '
          'Thank You for looking at my brokenness and choosing to make me whole. '
          'Let my life be a living thank-you letter to You. Amen.',
      category: 'gratitude',
      relatedVerse: 'Because of the Lord\'s great love we are not consumed, for his compassions never fail. They are new every morning.',
      relatedVerseReference: 'Lamentations 3:22-23',
      estimatedSeconds: 20,
    ),

    // ─── HEALING (5) ─────────────────────────────────────────────────
    QuickPrayer(
      id: 'hea_01',
      title: 'For Physical Healing',
      body:
          'Great Physician, my body is weary and in pain. '
          'You who spoke the world into existence can speak healing into my body. '
          'Touch me now, Lord. Restore what is broken. '
          'Strengthen what is weak. Remove what does not belong. '
          'Whether healing comes instantly or gradually, I trust Your timing. '
          'You are my healer. I place my body in Your caring hands. Amen.',
      category: 'healing',
      relatedVerse: 'He heals the brokenhearted and binds up their wounds.',
      relatedVerseReference: 'Psalm 147:3',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'hea_02',
      title: 'Healing a Wounded Heart',
      body:
          'Father, my heart carries wounds that no one can see. '
          'Betrayal, loss, rejection, and memories that still sting. '
          'You see every scar, and You are gentle with broken things. '
          'Pour Your healing oil into these hidden places. '
          'Let Your love reach the deepest parts of me. '
          'Make me whole again. I trust You with my heart. Amen.',
      category: 'healing',
      relatedVerse: 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.',
      relatedVerseReference: 'Psalm 34:18',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'hea_03',
      title: 'For a Loved One Who Is Ill',
      body:
          'Lord, I lift up my loved one to You right now. '
          'You know their pain, their fear, their weariness. '
          'Be their comfort and their strength. '
          'Guide the hands of those who care for them. '
          'Give wisdom to doctors and peace to their spirit. '
          'Surround them with Your healing presence. '
          'Restore them to health, according to Your perfect will. Amen.',
      category: 'healing',
      relatedVerse: 'Is anyone among you sick? Let them call the elders of the church to pray over them.',
      relatedVerseReference: 'James 5:14',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'hea_04',
      title: 'Healing from Grief',
      body:
          'God of all comfort, grief has carved a hollow place inside me. '
          'The weight of loss feels unbearable. '
          'But You are near to the brokenhearted. '
          'Hold me in this darkness. Weep with me. '
          'And when I am ready, lead me gently toward the light again. '
          'Let love be stronger than loss. Let hope outlast sorrow. Amen.',
      category: 'healing',
      relatedVerse: 'Blessed are those who mourn, for they will be comforted.',
      relatedVerseReference: 'Matthew 5:4',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'hea_05',
      title: 'Renewing My Mind',
      body:
          'Lord, heal my mind from the patterns that keep me trapped. '
          'The negative thoughts, the self-doubt, the replaying of past failures. '
          'Renew my mind with Your truth. '
          'Where there is darkness, shine Your light. '
          'Where there are lies, plant Your Word. '
          'Help me think the thoughts You think about me. '
          'I am fearfully and wonderfully made. Amen.',
      category: 'healing',
      relatedVerse: 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.',
      relatedVerseReference: 'Romans 12:2',
      estimatedSeconds: 25,
    ),

    // ─── STRENGTH (5) ────────────────────────────────────────────────
    QuickPrayer(
      id: 'str_01',
      title: 'When I Feel Weak',
      body:
          'Lord, I have reached the end of my own strength. '
          'I cannot keep going on my own. '
          'But You promise that when I am weak, You are strong. '
          'Be my strength today. Carry me when I cannot walk. '
          'Lift me up when I fall. '
          'Let Your power be made perfect in my weakness. '
          'I depend entirely on You. Amen.',
      category: 'strength',
      relatedVerse: 'But he said to me, "My grace is sufficient for you, for my power is made perfect in weakness."',
      relatedVerseReference: '2 Corinthians 12:9',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'str_02',
      title: 'Strength for the Battle',
      body:
          'Mighty God, I feel as though I am in a battle I did not choose. '
          'Temptation, discouragement, and opposition press in from every side. '
          'Arm me with Your armor. '
          'Belt of truth, breastplate of righteousness, shield of faith. '
          'I cannot fight this alone, but with You, I am more than a conqueror. '
          'Fight for me, Lord. Give me courage to stand. Amen.',
      category: 'strength',
      relatedVerse: 'The Lord your God is the one who goes with you to fight for you against your enemies to give you victory.',
      relatedVerseReference: 'Deuteronomy 20:4',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'str_03',
      title: 'Endurance for the Journey',
      body:
          'Father, this road is long and I grow tired. '
          'Help me not to lose heart. Help me not to give up. '
          'You who began a good work in me will carry it to completion. '
          'Renew my strength like the eagle\'s. '
          'Let me run and not grow weary. Let me walk and not faint. '
          'One step at a time, with You. Amen.',
      category: 'strength',
      relatedVerse: 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles.',
      relatedVerseReference: 'Isaiah 40:31',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'str_04',
      title: 'Courage to Do Hard Things',
      body:
          'Lord, there is something hard before me that I am afraid to face. '
          'Give me the courage of Joshua, the faith of David, the perseverance of Paul. '
          'You have not given me a spirit of timidity. '
          'I can do all things through Christ who strengthens me. '
          'I step forward in faith, knowing You go before me. Amen.',
      category: 'strength',
      relatedVerse: 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
      relatedVerseReference: 'Joshua 1:9',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'str_05',
      title: 'Strength to Resist Temptation',
      body:
          'Jesus, temptation pulls at me and I feel its weight. '
          'You know what it is to be tempted, yet You never sinned. '
          'Give me Your strength to say no. '
          'Show me the way of escape You have promised. '
          'Guard my heart, my eyes, my hands. '
          'Let me choose what is right, not what is easy. '
          'I lean on You. Amen.',
      category: 'strength',
      relatedVerse: 'No temptation has overtaken you except what is common to mankind. And God is faithful; he will not let you be tempted beyond what you can bear.',
      relatedVerseReference: '1 Corinthians 10:13',
      estimatedSeconds: 25,
    ),

    // ─── FORGIVENESS (5) ─────────────────────────────────────────────
    QuickPrayer(
      id: 'for_01',
      title: 'Asking God for Forgiveness',
      body:
          'Father, I have sinned. I have fallen short of Your glory and my own intentions. '
          'I am sorry. Not just with words, but with my whole heart. '
          'Wash me clean. Remove this guilt. '
          'You promise that if I confess, You are faithful and just to forgive me. '
          'I receive Your forgiveness now. '
          'Help me walk in the freedom it brings. Amen.',
      category: 'forgiveness',
      relatedVerse: 'If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.',
      relatedVerseReference: '1 John 1:9',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'for_02',
      title: 'Forgiving Someone Who Hurt Me',
      body:
          'Lord, someone has wounded me deeply, and the pain is still fresh. '
          'I do not want to carry bitterness in my heart. '
          'Help me forgive, not because they deserve it, but because You have forgiven me. '
          'I release this person into Your hands. I release the debt they owe me. '
          'Heal the wound. Set me free from the prison of unforgiveness. Amen.',
      category: 'forgiveness',
      relatedVerse: 'Bear with each other and forgive one another if any of you has a grievance against someone. Forgive as the Lord forgave you.',
      relatedVerseReference: 'Colossians 3:13',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'for_03',
      title: 'Forgiving Myself',
      body:
          'God, I struggle to forgive myself. '
          'The memory of what I\'ve done haunts me. '
          'But You say there is no condemnation for those in Christ Jesus. '
          'If You have forgiven me, who am I to refuse that gift? '
          'Help me let go of the shame. Help me accept Your grace. '
          'I am a new creation. The old has gone. Amen.',
      category: 'forgiveness',
      relatedVerse: 'Therefore, there is now no condemnation for those who are in Christ Jesus.',
      relatedVerseReference: 'Romans 8:1',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'for_04',
      title: 'Breaking the Cycle of Resentment',
      body:
          'Father, resentment has taken root in my heart and it is poisoning me. '
          'I confess that I have rehearsed offenses and nursed grudges. '
          'Uproot this bitterness. Plant love in its place. '
          'Give me the grace to see others through Your eyes. '
          'Let mercy triumph over judgment in my heart. '
          'Free me from this heavy chain. Amen.',
      category: 'forgiveness',
      relatedVerse: 'Get rid of all bitterness, rage and anger, brawling and slander, along with every form of malice.',
      relatedVerseReference: 'Ephesians 4:31',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'for_05',
      title: 'A Clean Slate',
      body:
          'Merciful God, I come to You as I am, with all my imperfections. '
          'I ask for a clean slate, a fresh start, a new beginning. '
          'You are the God of second chances and third chances and infinite chances. '
          'Write a new chapter in my story. '
          'Let today be the first page of a life transformed by Your grace. Amen.',
      category: 'forgiveness',
      relatedVerse: 'As far as the east is from the west, so far has he removed our transgressions from us.',
      relatedVerseReference: 'Psalm 103:12',
      estimatedSeconds: 20,
    ),

    // ─── GUIDANCE (5) ────────────────────────────────────────────────
    QuickPrayer(
      id: 'gui_01',
      title: 'For a Major Decision',
      body:
          'Lord, I stand at a crossroads and I need Your wisdom. '
          'The paths before me are uncertain, and I fear choosing wrongly. '
          'You promise that if I ask for wisdom, You will give it generously. '
          'Speak clearly to my heart. Close wrong doors. Open right ones. '
          'Give me the discernment to know Your voice from my own desires. '
          'I trust Your plan more than my plans. Amen.',
      category: 'guidance',
      relatedVerse: 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.',
      relatedVerseReference: 'Proverbs 3:5-6',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'gui_02',
      title: 'Direction for My Purpose',
      body:
          'Father, I want my life to matter. I want to fulfill the purpose You created me for. '
          'Show me what that is. Reveal my gifts. Clarify my calling. '
          'Remove distractions that pull me away from Your best. '
          'Whether the next step is big or small, make it clear. '
          'I want to hear "well done" at the end of my days. '
          'Lead me. I will follow. Amen.',
      category: 'guidance',
      relatedVerse: 'For we are God\'s handiwork, created in Christ Jesus to do good works, which God prepared in advance for us to do.',
      relatedVerseReference: 'Ephesians 2:10',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'gui_03',
      title: 'Wisdom in Relationships',
      body:
          'God, I need Your wisdom in my relationships. '
          'Help me know who to trust, who to love closely, and where to set boundaries. '
          'Give me discernment to recognize healthy connections. '
          'Protect me from those who would lead me astray. '
          'Surround me with people who sharpen me and draw me closer to You. '
          'Be the center of every relationship I have. Amen.',
      category: 'guidance',
      relatedVerse: 'Walk with the wise and become wise, for a companion of fools suffers harm.',
      relatedVerseReference: 'Proverbs 13:20',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'gui_04',
      title: 'When the Path Is Dark',
      body:
          'Lord, I cannot see where I am going. '
          'The way ahead is dark and I feel lost. '
          'But You are the light of the world. '
          'Your Word is a lamp to my feet and a light to my path. '
          'I do not need to see the whole road; just the next step will do. '
          'Shine Your light before me. I will follow where You lead. Amen.',
      category: 'guidance',
      relatedVerse: 'Your word is a lamp for my feet, a light on my path.',
      relatedVerseReference: 'Psalm 119:105',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'gui_05',
      title: 'Patience While Waiting',
      body:
          'Father, I am waiting and the waiting is hard. '
          'I do not understand Your timing. I want answers now. '
          'But You ask me to be still and trust. '
          'Teach me patience. Teach me to rest in the waiting. '
          'You are not slow; You are thorough. '
          'What You have planned is worth the wait. '
          'Help me wait well. Amen.',
      category: 'guidance',
      relatedVerse: 'Wait for the Lord; be strong and take heart and wait for the Lord.',
      relatedVerseReference: 'Psalm 27:14',
      estimatedSeconds: 20,
    ),

    // ─── PROTECTION (5) ──────────────────────────────────────────────
    QuickPrayer(
      id: 'pro_01',
      title: 'Shield Around Me',
      body:
          'Almighty God, I ask for Your divine protection over me today. '
          'Shield me from danger seen and unseen. '
          'Let no weapon formed against me prosper. '
          'Station Your angels around me and those I love. '
          'Cover us under the shadow of Your wings. '
          'You are our fortress, our strong tower, our hiding place. Amen.',
      category: 'protection',
      relatedVerse: 'He who dwells in the shelter of the Most High will rest in the shadow of the Almighty.',
      relatedVerseReference: 'Psalm 91:1',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'pro_02',
      title: 'Protection for My Family',
      body:
          'Lord, I place my family under Your protective hand. '
          'Guard my loved ones wherever they go today. '
          'Keep them safe on the road, at work, at school. '
          'Protect their hearts from evil influences. '
          'Surround our home with Your presence. '
          'Let peace dwell within our walls. '
          'You are our keeper who neither slumbers nor sleeps. Amen.',
      category: 'protection',
      relatedVerse: 'The Lord will keep you from all harm -- he will watch over your life.',
      relatedVerseReference: 'Psalm 121:7',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'pro_03',
      title: 'Spiritual Protection',
      body:
          'Father, I recognize that my battle is not against flesh and blood. '
          'Protect me from spiritual attacks, from the enemy\'s schemes, from deception. '
          'Clothe me in Your full armor. '
          'Guard my mind against lies. Guard my heart against compromise. '
          'Greater is He who is in me than he who is in the world. '
          'I stand firm in Your name. Amen.',
      category: 'protection',
      relatedVerse: 'Put on the full armor of God, so that you can take your stand against the devil\'s schemes.',
      relatedVerseReference: 'Ephesians 6:11',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'pro_04',
      title: 'Safe Travels',
      body:
          'Lord, I am about to travel and I ask for Your hand of protection. '
          'Guide me safely to my destination and back. '
          'Protect against accidents, delays, and anything that would cause harm. '
          'Give me alertness and wisdom on the road. '
          'Surround this journey with Your angels. '
          'May I arrive safely, with a grateful heart. Amen.',
      category: 'protection',
      relatedVerse: 'The Lord will watch over your coming and going both now and forevermore.',
      relatedVerseReference: 'Psalm 121:8',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'pro_05',
      title: 'Guarding My Heart',
      body:
          'God, guard my heart above all things, for from it flows the wellspring of life. '
          'Protect me from bitterness, jealousy, and pride. '
          'Keep my heart soft toward You and toward others. '
          'Let nothing enter that would corrupt or wound. '
          'Fill my heart with things that are true, noble, right, and pure. '
          'My heart is Yours, Lord. Keep it safe. Amen.',
      category: 'protection',
      relatedVerse: 'Above all else, guard your heart, for everything you do flows from it.',
      relatedVerseReference: 'Proverbs 4:23',
      estimatedSeconds: 25,
    ),

    // ─── PEACE (5) ───────────────────────────────────────────────────
    QuickPrayer(
      id: 'pea_01',
      title: 'A Still and Quiet Soul',
      body:
          'Lord, bring stillness to my soul. '
          'The noise of the world is deafening and my spirit longs for quiet. '
          'Lead me beside still waters. Restore my soul. '
          'Let me hear Your gentle whisper above the chaos. '
          'I choose to set my mind on things above, where true peace is found. '
          'Be the calm at the center of my storm. Amen.',
      category: 'peace',
      relatedVerse: 'He leads me beside quiet waters, he refreshes my soul.',
      relatedVerseReference: 'Psalm 23:2-3',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'pea_02',
      title: 'Peace in Conflict',
      body:
          'Prince of Peace, there is conflict in my life and it steals my peace. '
          'Help me respond with grace rather than anger. '
          'Give me words that heal instead of wound. '
          'Where reconciliation is possible, make me a peacemaker. '
          'Where it is not, give me peace within. '
          'Let me carry Your peace wherever I go today. Amen.',
      category: 'peace',
      relatedVerse: 'Blessed are the peacemakers, for they will be called children of God.',
      relatedVerseReference: 'Matthew 5:9',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'pea_03',
      title: 'Rest for My Weary Soul',
      body:
          'Jesus, You invited the weary and burdened to come to You. '
          'Here I am. I am tired, Lord. Bone-tired. Soul-tired. '
          'Take my yoke and give me Yours, for Yours is easy and light. '
          'Let me rest in Your presence right now. '
          'No striving. No performing. Just resting in Your love. '
          'Refresh me. Renew me. Restore me. Amen.',
      category: 'peace',
      relatedVerse: 'Come to me, all you who are weary and burdened, and I will give you rest.',
      relatedVerseReference: 'Matthew 11:28',
      estimatedSeconds: 25,
    ),
    QuickPrayer(
      id: 'pea_04',
      title: 'Peace Before Sleep',
      body:
          'Father, as this day ends, I surrender it to You. '
          'The worries, the victories, the unfinished tasks, all of it. '
          'Grant me peaceful sleep tonight. '
          'Guard my mind from anxious thoughts in the dark hours. '
          'Let me rest knowing You are watching over me. '
          'Tomorrow is in Your hands. Tonight, I sleep in peace. Amen.',
      category: 'peace',
      relatedVerse: 'In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.',
      relatedVerseReference: 'Psalm 4:8',
      estimatedSeconds: 20,
    ),
    QuickPrayer(
      id: 'pea_05',
      title: 'Morning Peace',
      body:
          'Good morning, Lord. Before the day rushes in, I pause to invite Your peace. '
          'Whatever today brings, let me face it with a calm spirit. '
          'Help me not to rush, not to worry, not to react in haste. '
          'Fill my morning with Your presence and my steps with Your peace. '
          'This day belongs to You. Let it be well with my soul. Amen.',
      category: 'peace',
      relatedVerse: 'The Lord gives strength to his people; the Lord blesses his people with peace.',
      relatedVerseReference: 'Psalm 29:11',
      estimatedSeconds: 20,
    ),
  ];

  static List<QuickPrayer> byCategory(String category) {
    return all.where((p) => p.category == category).toList();
  }

  static QuickPrayer? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
