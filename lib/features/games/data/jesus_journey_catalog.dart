import 'package:flutter/material.dart';
import '../domain/models/jesus_journey_event.dart';

/// Complete catalog of all 30 events in the Journey with Jesus game.
/// Each event includes biblically accurate narratives, quiz questions,
/// key verses, and spiritual takeaways.
class JesusJourneyCatalog {
  const JesusJourneyCatalog._();

  static List<JesusJourneyEvent> get allEvents => _events;

  static JesusJourneyEvent getEvent(int order) {
    return _events.firstWhere(
      (e) => e.order == order,
      orElse: () => _events.first,
    );
  }

  static final List<JesusJourneyEvent> _events = [
    // ── 1. Prophecies of the Messiah ──────────────────────────────────
    const JesusJourneyEvent(
      order: 0,
      id: 'prophecies_of_messiah',
      title: 'Prophecies of the Messiah',
      subtitle: 'Old Testament promises fulfilled',
      narrative:
          'Centuries before the birth of Jesus, God spoke through prophets '
          'to foretell the coming of the Messiah. Isaiah prophesied that a '
          'virgin would conceive and bear a son called Immanuel. Micah '
          'declared that the ruler of Israel would come from Bethlehem, a '
          'small and humble town. These prophecies kindled hope in the '
          'hearts of God\'s people across generations.',
      bibleReference: 'Isaiah 7:14; Micah 5:2; Isaiah 9:6',
      keyVerse:
          'For to us a child is born, to us a son is given, and the '
          'government will be on his shoulders.',
      keyVerseReference: 'Isaiah 9:6',
      spiritualTakeaway:
          'God keeps every promise He makes. The hundreds of '
          'prophecies fulfilled in Jesus remind us that we can trust God\'s '
          'word completely, even when fulfillment seems far away.',
      themeColor: Color(0xFF5C4B8A),
      iconName: 'scroll_text',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'Which prophet foretold that a virgin would conceive?',
          options: ['Jeremiah', 'Isaiah', 'Ezekiel', 'Daniel'],
          correctIndex: 1,
          explanation:
              'Isaiah 7:14 says, "The virgin will conceive and give birth '
              'to a son, and will call him Immanuel."',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'According to Micah, from which town would the Messiah come?',
          options: ['Nazareth', 'Jerusalem', 'Bethlehem', 'Capernaum'],
          correctIndex: 2,
          explanation:
              'Micah 5:2 prophesies that the ruler would come from '
              'Bethlehem Ephrathah.',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What does "Immanuel" mean?',
          options: [
            'Prince of Peace',
            'God with us',
            'Mighty Savior',
            'Anointed One'
          ],
          correctIndex: 1,
          explanation:
              'Immanuel literally means "God with us," signifying that '
              'God Himself would dwell among His people.',
          difficulty: 2,
        ),
      ],
    ),

    // ── 2. Annunciation to Mary ──────────────────────────────────────
    const JesusJourneyEvent(
      order: 1,
      id: 'annunciation_to_mary',
      title: 'Annunciation to Mary',
      subtitle: 'Angel Gabriel\'s visit',
      narrative:
          'In the small town of Nazareth, God sent the angel Gabriel to a '
          'young woman named Mary, who was pledged to marry Joseph. Gabriel '
          'greeted her with startling words: she had found favor with God '
          'and would conceive a son by the Holy Spirit. Though bewildered, '
          'Mary responded with extraordinary faith, declaring herself the '
          'Lord\'s servant and accepting His will.',
      bibleReference: 'Luke 1:26-38',
      keyVerse:
          'I am the Lord\'s servant. May your word to me be fulfilled.',
      keyVerseReference: 'Luke 1:38',
      spiritualTakeaway:
          'Mary\'s response teaches us that true faith is saying "yes" '
          'to God even when we do not fully understand His plan. Surrender '
          'to God opens the door for Him to do miraculous things through us.',
      themeColor: Color(0xFF6B8FB2),
      iconName: 'sparkles',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What was the name of the angel who visited Mary?',
          options: ['Michael', 'Gabriel', 'Raphael', 'Uriel'],
          correctIndex: 1,
          explanation:
              'Luke 1:26 tells us God sent the angel Gabriel to Nazareth.',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What town was Mary living in when Gabriel appeared?',
          options: ['Bethlehem', 'Jerusalem', 'Nazareth', 'Jericho'],
          correctIndex: 2,
          explanation:
              'Gabriel was sent to Nazareth, a town in Galilee (Luke 1:26).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'To whom was Mary pledged to be married?',
          options: ['Simon', 'Joseph', 'Andrew', 'Zechariah'],
          correctIndex: 1,
          explanation:
              'Mary was pledged to be married to Joseph, a descendant of '
              'David (Luke 1:27).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 3. Birth in Bethlehem ────────────────────────────────────────
    const JesusJourneyEvent(
      order: 2,
      id: 'birth_in_bethlehem',
      title: 'Birth in Bethlehem',
      subtitle: 'The Nativity',
      narrative:
          'A decree from Caesar Augustus brought Mary and Joseph on a long '
          'journey to Bethlehem for a census. With no room at the inn, the '
          'King of Kings was born in the humblest of places and laid in a '
          'manger. That night, angels announced the glorious news to '
          'shepherds in nearby fields, and they hurried to see the newborn '
          'Savior, just as the angels had described.',
      bibleReference: 'Luke 2:1-20',
      keyVerse:
          'Today in the town of David a Savior has been born to you; '
          'he is the Messiah, the Lord.',
      keyVerseReference: 'Luke 2:11',
      spiritualTakeaway:
          'God often works in unexpected ways. The Savior of the world '
          'came not in a palace but a stable, reminding us that God\'s '
          'greatest gifts frequently arrive in humble wrappings.',
      themeColor: Color(0xFFC4A35A),
      iconName: 'baby',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'Which Roman ruler ordered the census that brought Mary and '
              'Joseph to Bethlehem?',
          options: ['Nero', 'Tiberius', 'Caesar Augustus', 'Pontius Pilate'],
          correctIndex: 2,
          explanation:
              'Luke 2:1 states that Caesar Augustus issued a decree for '
              'a census of the entire Roman world.',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Where was baby Jesus laid after his birth?',
          options: ['A cradle', 'A manger', 'A bed', 'A basket'],
          correctIndex: 1,
          explanation:
              'Because there was no guest room available, Mary placed '
              'Jesus in a manger (Luke 2:7).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Who were the first to visit the newborn Jesus?',
          options: ['The Magi', 'Shepherds', 'King Herod', 'The priests'],
          correctIndex: 1,
          explanation:
              'Angels announced the birth to shepherds keeping watch '
              'over their flocks, and they came to see the baby (Luke 2:8-16).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 4. Visit of the Magi ────────────────────────────────────────
    const JesusJourneyEvent(
      order: 3,
      id: 'visit_of_the_magi',
      title: 'Visit of the Magi',
      subtitle: 'Wise men follow the star',
      narrative:
          'Wise men from the East saw a special star signaling the birth of '
          'a king and traveled a great distance to worship him. They first '
          'went to Jerusalem, asking King Herod where the new king had been '
          'born. Following the star to Bethlehem, they found Jesus with Mary '
          'and presented gifts of gold, frankincense, and myrrh -- treasures '
          'fit for a king, a priest, and a sacrifice.',
      bibleReference: 'Matthew 2:1-12',
      keyVerse:
          'They saw the child with his mother Mary, and they bowed down '
          'and worshiped him.',
      keyVerseReference: 'Matthew 2:11',
      spiritualTakeaway:
          'The Magi remind us that seeking Jesus is worth any journey. '
          'When we find Him, the only fitting response is worship and '
          'offering our very best to Him.',
      themeColor: Color(0xFFD4AF37),
      iconName: 'star',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'Which of these was NOT a gift the Magi brought to Jesus?',
          options: ['Gold', 'Silver', 'Frankincense', 'Myrrh'],
          correctIndex: 1,
          explanation:
              'The Magi brought gold, frankincense, and myrrh '
              '(Matthew 2:11). Silver is not mentioned.',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'Why did the Magi not return to Herod after visiting Jesus?',
          options: [
            'They got lost',
            'They were warned in a dream',
            'They forgot',
            'The road was blocked'
          ],
          correctIndex: 1,
          explanation:
              'God warned them in a dream not to go back to Herod, '
              'so they returned home by another route (Matthew 2:12).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'What guided the Magi to find Jesus?',
          options: ['A pillar of fire', 'A star', 'An angel', 'A map'],
          correctIndex: 1,
          explanation:
              'The Magi followed a star they had seen when it rose '
              '(Matthew 2:2).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 5. Flight to Egypt ──────────────────────────────────────────
    const JesusJourneyEvent(
      order: 4,
      id: 'flight_to_egypt',
      title: 'Flight to Egypt',
      subtitle: 'Escape from Herod',
      narrative:
          'After the Magi departed, an angel appeared to Joseph in a dream '
          'with an urgent warning: King Herod planned to kill the child. '
          'Joseph rose in the night, took Mary and Jesus, and fled to Egypt. '
          'They remained there until Herod\'s death, fulfilling the prophecy, '
          '"Out of Egypt I called my son."',
      bibleReference: 'Matthew 2:13-23',
      keyVerse: 'Out of Egypt I called my son.',
      keyVerseReference: 'Hosea 11:1; Matthew 2:15',
      spiritualTakeaway:
          'God protects His purposes. Even when evil threatens, God provides '
          'a way of escape. We can trust that His hand guides and guards us '
          'through every danger.',
      themeColor: Color(0xFF8B6E4E),
      iconName: 'route',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'How did Joseph learn about Herod\'s plan?',
          options: [
            'From the Magi',
            'Through an angel in a dream',
            'From a prophet',
            'Through a letter'
          ],
          correctIndex: 1,
          explanation:
              'An angel of the Lord appeared to Joseph in a dream '
              'and warned him to flee to Egypt (Matthew 2:13).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Where did Joseph take his family to escape Herod?',
          options: ['Syria', 'Egypt', 'Persia', 'Greece'],
          correctIndex: 1,
          explanation:
              'Joseph took Mary and Jesus to Egypt, where they stayed '
              'until Herod died (Matthew 2:14-15).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'Which Old Testament book contains the prophecy "Out of Egypt '
              'I called my son"?',
          options: ['Isaiah', 'Hosea', 'Micah', 'Jeremiah'],
          correctIndex: 1,
          explanation:
              'This prophecy comes from Hosea 11:1, fulfilled when '
              'the family returned from Egypt (Matthew 2:15).',
          difficulty: 3,
        ),
      ],
    ),

    // ── 6. Boy Jesus at the Temple ──────────────────────────────────
    const JesusJourneyEvent(
      order: 5,
      id: 'boy_jesus_temple',
      title: 'Boy Jesus at the Temple',
      subtitle: 'Age 12, teaching elders',
      narrative:
          'When Jesus was twelve, His family traveled to Jerusalem for the '
          'Feast of Passover. On the return trip, Mary and Joseph realized '
          'Jesus was missing. After three anxious days of searching, they '
          'found Him in the temple courts, sitting among the teachers, '
          'listening and asking questions that amazed everyone who heard Him.',
      bibleReference: 'Luke 2:41-52',
      keyVerse:
          'Didn\'t you know I had to be in my Father\'s house?',
      keyVerseReference: 'Luke 2:49',
      spiritualTakeaway:
          'Even as a child, Jesus understood His mission and identity. '
          'We too should cultivate a desire to know God\'s Word deeply '
          'and to be about our Father\'s business from an early age.',
      themeColor: Color(0xFF4A7C59),
      iconName: 'book_open',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'How old was Jesus when He stayed behind at the temple?',
          options: ['8', '10', '12', '14'],
          correctIndex: 2,
          explanation:
              'Luke 2:42 tells us Jesus was twelve years old when this '
              'event took place.',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What feast had the family traveled to Jerusalem for?',
          options: [
            'Feast of Tabernacles',
            'Feast of Passover',
            'Feast of Weeks',
            'Day of Atonement'
          ],
          correctIndex: 1,
          explanation:
              'They went to Jerusalem for the annual Feast of Passover '
              '(Luke 2:41).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question:
              'How many days did Mary and Joseph search before finding Jesus?',
          options: ['One day', 'Two days', 'Three days', 'Seven days'],
          correctIndex: 2,
          explanation:
              'After three days they found Him in the temple courts '
              '(Luke 2:46).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 7. Baptism by John ──────────────────────────────────────────
    const JesusJourneyEvent(
      order: 6,
      id: 'baptism_by_john',
      title: 'Baptism by John',
      subtitle: 'Jordan River, dove descends',
      narrative:
          'John the Baptist was preaching repentance and baptizing in the '
          'Jordan River when Jesus came to him. Though John felt unworthy, '
          'Jesus insisted on being baptized to fulfill all righteousness. '
          'As Jesus rose from the water, heaven opened, the Spirit of God '
          'descended like a dove, and a voice from heaven declared, "This is '
          'my Son, whom I love; with him I am well pleased."',
      bibleReference: 'Matthew 3:13-17',
      keyVerse:
          'This is my Son, whom I love; with him I am well pleased.',
      keyVerseReference: 'Matthew 3:17',
      spiritualTakeaway:
          'At Jesus\' baptism, the entire Trinity is revealed: the Son '
          'baptized, the Spirit descending, and the Father speaking. This '
          'moment affirms our identity as beloved children of God when we '
          'follow Him in obedience.',
      themeColor: Color(0xFF3B82C4),
      iconName: 'droplets',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'In which river was Jesus baptized?',
          options: ['Nile', 'Euphrates', 'Jordan', 'Tigris'],
          correctIndex: 2,
          explanation:
              'Jesus was baptized in the Jordan River by John '
              '(Matthew 3:13).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'In what form did the Holy Spirit descend upon Jesus?',
          options: ['A flame of fire', 'A dove', 'A wind', 'A cloud'],
          correctIndex: 1,
          explanation:
              'The Spirit of God descended like a dove and alighted '
              'on Jesus (Matthew 3:16).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Why did Jesus say He needed to be baptized?',
          options: [
            'To wash away His sins',
            'To fulfill all righteousness',
            'Because John commanded it',
            'To set an example only'
          ],
          correctIndex: 1,
          explanation:
              'Jesus told John, "Let it be so now; it is proper for us '
              'to do this to fulfill all righteousness" (Matthew 3:15).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 8. Temptation in the Wilderness ─────────────────────────────
    const JesusJourneyEvent(
      order: 7,
      id: 'temptation_wilderness',
      title: 'Temptation in the Wilderness',
      subtitle: '40 days, 3 temptations',
      narrative:
          'Immediately after His baptism, the Spirit led Jesus into the '
          'wilderness where He fasted forty days and nights. Satan came with '
          'three temptations: to turn stones into bread, to throw Himself '
          'from the temple, and to worship Satan in exchange for all the '
          'kingdoms of the world. Each time, Jesus resisted by quoting '
          'Scripture, showing that God\'s Word is our strongest weapon '
          'against temptation.',
      bibleReference: 'Matthew 4:1-11',
      keyVerse:
          'Man shall not live on bread alone, but on every word that comes '
          'from the mouth of God.',
      keyVerseReference: 'Matthew 4:4',
      spiritualTakeaway:
          'Jesus faced real temptation and overcame it with Scripture. '
          'We are never alone in our struggles; God\'s Word equips us to '
          'stand firm against every temptation we face.',
      themeColor: Color(0xFF9B5D3A),
      iconName: 'shield',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'How many days did Jesus fast in the wilderness?',
          options: ['7', '12', '30', '40'],
          correctIndex: 3,
          explanation:
              'Jesus fasted forty days and forty nights in the wilderness '
              '(Matthew 4:2).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'What was the first temptation Satan presented to Jesus?',
          options: [
            'Jump from the temple',
            'Turn stones into bread',
            'Worship Satan',
            'Call down fire'
          ],
          correctIndex: 1,
          explanation:
              'Satan first tempted Jesus to turn stones into bread '
              '(Matthew 4:3).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'How did Jesus respond to each temptation?',
          options: [
            'He ignored Satan',
            'He called angels to fight',
            'He quoted Scripture',
            'He performed miracles'
          ],
          correctIndex: 2,
          explanation:
              'Jesus answered each temptation by quoting from the book '
              'of Deuteronomy (Matthew 4:4, 7, 10).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 9. Calling the First Disciples ──────────────────────────────
    const JesusJourneyEvent(
      order: 8,
      id: 'calling_first_disciples',
      title: 'Calling the First Disciples',
      subtitle: 'Peter, Andrew, James, John',
      narrative:
          'Walking beside the Sea of Galilee, Jesus saw Simon Peter and '
          'Andrew casting their nets. He called out to them, "Come, follow '
          'me, and I will send you out to fish for people." Without '
          'hesitation, they left their nets and followed Him. A little '
          'farther along, He called James and John, sons of Zebedee, and '
          'they too immediately left their boat and father to follow Jesus.',
      bibleReference: 'Matthew 4:18-22',
      keyVerse:
          'Come, follow me, and I will send you out to fish for people.',
      keyVerseReference: 'Matthew 4:19',
      spiritualTakeaway:
          'Jesus still calls ordinary people to extraordinary purpose. '
          'Following Him may mean leaving behind what is comfortable, but '
          'the adventure of walking with Him is beyond anything we could '
          'achieve on our own.',
      themeColor: Color(0xFF4682B4),
      iconName: 'users',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'What were Peter and Andrew doing when Jesus called them?',
          options: [
            'Collecting taxes',
            'Casting their nets',
            'Building a house',
            'Praying at the temple'
          ],
          correctIndex: 1,
          explanation:
              'They were casting a net into the lake, for they were '
              'fishermen (Matthew 4:18).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Who was the father of James and John?',
          options: ['Alphaeus', 'Zebedee', 'Jonah', 'Simon'],
          correctIndex: 1,
          explanation:
              'James and John were the sons of Zebedee (Matthew 4:21).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question:
              'By which body of water did Jesus call His first disciples?',
          options: [
            'Dead Sea',
            'Sea of Galilee',
            'Jordan River',
            'Red Sea'
          ],
          correctIndex: 1,
          explanation:
              'Jesus was walking beside the Sea of Galilee when He '
              'called them (Matthew 4:18).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 10. Wedding at Cana ─────────────────────────────────────────
    const JesusJourneyEvent(
      order: 9,
      id: 'wedding_at_cana',
      title: 'Wedding at Cana',
      subtitle: 'Water to wine, first miracle',
      narrative:
          'Jesus, His mother, and His disciples attended a wedding in Cana '
          'of Galilee. When the wine ran out -- a source of great shame '
          'for the host -- Mary told Jesus. He instructed the servants to '
          'fill six stone jars with water, then draw some out. The master '
          'of the banquet tasted it and was astonished: it was the finest '
          'wine. This first miracle revealed Jesus\' glory and deepened '
          'His disciples\' faith.',
      bibleReference: 'John 2:1-11',
      keyVerse:
          'What Jesus did here in Cana of Galilee was the first of the '
          'signs through which he revealed his glory.',
      keyVerseReference: 'John 2:11',
      spiritualTakeaway:
          'Jesus cares about the everyday details of our lives. He can '
          'transform the ordinary into the extraordinary. When we bring '
          'our lack to Him, He provides abundantly.',
      themeColor: Color(0xFF8B2252),
      iconName: 'wine',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'Where did Jesus perform His first miracle?',
          options: [
            'Jerusalem',
            'Cana of Galilee',
            'Bethlehem',
            'Capernaum'
          ],
          correctIndex: 1,
          explanation:
              'Jesus performed His first sign at a wedding in Cana of '
              'Galilee (John 2:11).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus turn the water into?',
          options: ['Juice', 'Milk', 'Wine', 'Oil'],
          correctIndex: 2,
          explanation:
              'Jesus turned the water into wine, and the master of '
              'the banquet said it was the best (John 2:9-10).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'How many stone jars were filled with water?',
          options: ['Three', 'Four', 'Six', 'Twelve'],
          correctIndex: 2,
          explanation:
              'There were six stone water jars, each holding twenty to '
              'thirty gallons (John 2:6).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 11. Sermon on the Mount ─────────────────────────────────────
    const JesusJourneyEvent(
      order: 10,
      id: 'sermon_on_the_mount',
      title: 'Sermon on the Mount',
      subtitle: 'The Beatitudes',
      narrative:
          'Jesus went up on a mountainside, sat down, and began to teach '
          'the crowds. In the Beatitudes, He described the qualities of '
          'those who belong to God\'s kingdom: the poor in spirit, the '
          'meek, the merciful, the peacemakers, and more. He taught about '
          'love for enemies, the Lord\'s Prayer, and living as salt and '
          'light in the world. This sermon remains the most influential '
          'ethical teaching in all of history.',
      bibleReference: 'Matthew 5-7',
      keyVerse:
          'Blessed are the poor in spirit, for theirs is the kingdom of '
          'heaven.',
      keyVerseReference: 'Matthew 5:3',
      spiritualTakeaway:
          'Jesus redefines greatness. In God\'s kingdom, true blessing '
          'comes not from power or wealth but from humility, mercy, and '
          'a hunger for righteousness.',
      themeColor: Color(0xFF5C8A4A),
      iconName: 'mountain',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What are the opening statements of Jesus\' sermon called?',
          options: [
            'The Parables',
            'The Beatitudes',
            'The Commandments',
            'The Proverbs'
          ],
          correctIndex: 1,
          explanation:
              'The opening blessings of the Sermon on the Mount are known '
              'as the Beatitudes (Matthew 5:3-12).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'In the sermon, Jesus said His followers are the salt of the '
              'earth and the _____ of the world.',
          options: ['Hope', 'Bread', 'Light', 'Joy'],
          correctIndex: 2,
          explanation:
              'Jesus said, "You are the light of the world" '
              '(Matthew 5:14).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Which prayer did Jesus teach during this sermon?',
          options: [
            'The Sinner\'s Prayer',
            'The Lord\'s Prayer',
            'The Priestly Blessing',
            'The Psalms of Ascent'
          ],
          correctIndex: 1,
          explanation:
              'Jesus taught the Lord\'s Prayer as a model for how to '
              'pray (Matthew 6:9-13).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 12. Healing the Paralytic ───────────────────────────────────
    const JesusJourneyEvent(
      order: 11,
      id: 'healing_paralytic',
      title: 'Healing the Paralytic',
      subtitle: 'Lowered through the roof',
      narrative:
          'So many people crowded into the house where Jesus was teaching '
          'that four friends carrying a paralyzed man could not get through '
          'the door. Undeterred, they climbed to the roof, dug an opening, '
          'and lowered their friend on his mat right in front of Jesus. '
          'Seeing their faith, Jesus first forgave the man\'s sins, then '
          'healed his body, and the man walked out carrying his mat.',
      bibleReference: 'Mark 2:1-12',
      keyVerse:
          'Son, your sins are forgiven.',
      keyVerseReference: 'Mark 2:5',
      spiritualTakeaway:
          'Persistent faith moves the heart of God. The friends\' '
          'determination teaches us that bringing others to Jesus -- even '
          'when obstacles seem impossible -- is always worth the effort.',
      themeColor: Color(0xFF3A9D5C),
      iconName: 'heart_handshake',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'How did the paralyzed man\'s friends get him to Jesus?',
          options: [
            'Through a window',
            'Through the back door',
            'By lowering him through the roof',
            'By pushing through the crowd'
          ],
          correctIndex: 2,
          explanation:
              'They made an opening in the roof above Jesus and lowered '
              'the man on his mat (Mark 2:4).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus say first to the paralyzed man?',
          options: [
            'Stand up and walk',
            'Your sins are forgiven',
            'Your faith has healed you',
            'Go and sin no more'
          ],
          correctIndex: 1,
          explanation:
              'Before healing his body, Jesus said, "Son, your sins are '
              'forgiven" (Mark 2:5).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'How many friends carried the paralyzed man?',
          options: ['Two', 'Three', 'Four', 'Five'],
          correctIndex: 2,
          explanation:
              'Four men carried the paralyzed man to Jesus (Mark 2:3).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 13. Calming the Storm ───────────────────────────────────────
    const JesusJourneyEvent(
      order: 12,
      id: 'calming_the_storm',
      title: 'Calming the Storm',
      subtitle: 'Peace, be still!',
      narrative:
          'Jesus and His disciples set out across the Sea of Galilee by '
          'boat. A furious storm arose, waves breaking over the vessel, '
          'yet Jesus slept peacefully in the stern. Terrified, the disciples '
          'woke Him, crying, "Don\'t you care if we drown?" Jesus stood, '
          'rebuked the wind, and said to the waves, "Quiet! Be still!" '
          'Instantly, the wind died down and it was completely calm.',
      bibleReference: 'Mark 4:35-41',
      keyVerse: 'Quiet! Be still!',
      keyVerseReference: 'Mark 4:39',
      spiritualTakeaway:
          'No storm in our life is beyond the authority of Jesus. '
          'When we feel overwhelmed, we can call on Him with confidence. '
          'He is Lord over nature, circumstances, and every fear we face.',
      themeColor: Color(0xFF2E5A88),
      iconName: 'cloud_lightning',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What was Jesus doing when the storm struck?',
          options: ['Praying', 'Sleeping', 'Teaching', 'Fishing'],
          correctIndex: 1,
          explanation:
              'Jesus was sleeping on a cushion in the stern of the '
              'boat (Mark 4:38).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus say to calm the storm?',
          options: [
            'Peace, be still',
            'In my Father\'s name, stop',
            'I command you, cease',
            'Let there be calm'
          ],
          correctIndex: 0,
          explanation:
              'Jesus said, "Quiet! Be still!" and the wind died down '
              '(Mark 4:39).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'What question did the disciples ask each other afterward?',
          options: [
            'Is He the Messiah?',
            'Who is this? Even the wind and waves obey him!',
            'Should we follow him?',
            'How did he do that?'
          ],
          correctIndex: 1,
          explanation:
              'They asked, "Who is this? Even the wind and the waves '
              'obey him!" (Mark 4:41).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 14. Feeding the 5,000 ───────────────────────────────────────
    const JesusJourneyEvent(
      order: 13,
      id: 'feeding_five_thousand',
      title: 'Feeding the 5,000',
      subtitle: 'Loaves and fishes',
      narrative:
          'A vast crowd of over five thousand had followed Jesus to a remote '
          'place, and evening was approaching. The disciples wanted to send '
          'them away, but Jesus said, "You give them something to eat." All '
          'they found was a boy\'s lunch: five loaves and two fish. Jesus '
          'gave thanks, broke the bread, and distributed it. Everyone ate '
          'their fill, and twelve baskets of leftovers were collected.',
      bibleReference: 'John 6:1-14',
      keyVerse:
          'Jesus then took the loaves, gave thanks, and distributed to '
          'those who were seated as much as they wanted.',
      keyVerseReference: 'John 6:11',
      spiritualTakeaway:
          'When we offer what little we have to Jesus, He multiplies it '
          'far beyond what we could imagine. No gift is too small when '
          'placed in the hands of the Creator.',
      themeColor: Color(0xFF7BAA55),
      iconName: 'wheat',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'How many loaves of bread and fish did the boy have?',
          options: [
            '3 loaves and 3 fish',
            '5 loaves and 2 fish',
            '7 loaves and 5 fish',
            '2 loaves and 5 fish'
          ],
          correctIndex: 1,
          explanation:
              'Andrew found a boy with five small barley loaves and '
              'two small fish (John 6:9).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'How many baskets of leftovers were collected?',
          options: ['Five', 'Seven', 'Twelve', 'Three'],
          correctIndex: 2,
          explanation:
              'They gathered twelve baskets full of pieces left over '
              '(John 6:13).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'About how many men were fed, not counting women and children?',
          options: ['1,000', '3,000', '5,000', '10,000'],
          correctIndex: 2,
          explanation:
              'The number of men who ate was about five thousand '
              '(John 6:10).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 15. Walking on Water ────────────────────────────────────────
    const JesusJourneyEvent(
      order: 14,
      id: 'walking_on_water',
      title: 'Walking on Water',
      subtitle: 'Peter\'s faith tested',
      narrative:
          'After feeding the five thousand, Jesus sent His disciples ahead '
          'by boat while He went up on a mountainside to pray. During the '
          'fourth watch of the night, Jesus came to them, walking on the '
          'lake. Peter called out, "Lord, if it\'s you, tell me to come." '
          'Jesus said, "Come." Peter stepped out and walked on water, but '
          'when he saw the wind, he became afraid and began to sink. Jesus '
          'immediately reached out and caught him.',
      bibleReference: 'Matthew 14:22-33',
      keyVerse:
          'You of little faith, why did you doubt?',
      keyVerseReference: 'Matthew 14:31',
      spiritualTakeaway:
          'Peter walked on water as long as his eyes were on Jesus. '
          'When we focus on our circumstances instead of Christ, we begin '
          'to sink. But even when our faith wavers, Jesus reaches out His '
          'hand to lift us up.',
      themeColor: Color(0xFF1E6E8E),
      iconName: 'waves',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'What was Jesus doing on the mountainside before walking on water?',
          options: ['Sleeping', 'Praying', 'Teaching', 'Fasting'],
          correctIndex: 1,
          explanation:
              'Jesus went up on a mountainside by Himself to pray '
              '(Matthew 14:23).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Why did Peter begin to sink?',
          options: [
            'The waves were too strong',
            'He was too heavy',
            'He saw the wind and was afraid',
            'Jesus let go of him'
          ],
          correctIndex: 2,
          explanation:
              'When Peter saw the wind, he was afraid and began to '
              'sink (Matthew 14:30).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'During which watch of the night did Jesus come walking on the lake?',
          options: ['First', 'Second', 'Third', 'Fourth'],
          correctIndex: 3,
          explanation:
              'Jesus came toward them during the fourth watch of the '
              'night, roughly 3-6 AM (Matthew 14:25).',
          difficulty: 3,
        ),
      ],
    ),

    // ── 16. The Transfiguration ─────────────────────────────────────
    const JesusJourneyEvent(
      order: 15,
      id: 'transfiguration',
      title: 'The Transfiguration',
      subtitle: 'Moses and Elijah appear',
      narrative:
          'Jesus took Peter, James, and John up a high mountain. There, '
          'He was transfigured before them: His face shone like the sun, '
          'and His clothes became dazzling white. Moses and Elijah appeared '
          'and spoke with Him. A bright cloud enveloped them and a voice '
          'from the cloud declared, "This is my Son, whom I love; with him '
          'I am well pleased. Listen to him!"',
      bibleReference: 'Matthew 17:1-9',
      keyVerse:
          'This is my Son, whom I love; with him I am well pleased. '
          'Listen to him!',
      keyVerseReference: 'Matthew 17:5',
      spiritualTakeaway:
          'The Transfiguration reveals Jesus\' divine glory and '
          'confirms that He is the fulfillment of the Law (Moses) and the '
          'Prophets (Elijah). We are called to listen to Him above all '
          'other voices.',
      themeColor: Color(0xFFE8C84A),
      iconName: 'sun',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'Which three disciples did Jesus take up the mountain?',
          options: [
            'Peter, Andrew, and John',
            'Peter, James, and John',
            'Matthew, Mark, and Luke',
            'Thomas, Philip, and Bartholomew'
          ],
          correctIndex: 1,
          explanation:
              'Jesus took Peter, James, and John with Him (Matthew 17:1).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'Which two Old Testament figures appeared with Jesus?',
          options: [
            'Abraham and David',
            'Moses and Elijah',
            'Isaiah and Jeremiah',
            'Noah and Daniel'
          ],
          correctIndex: 1,
          explanation:
              'Moses and Elijah appeared, talking with Jesus '
              '(Matthew 17:3).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What happened to Jesus\' appearance?',
          options: [
            'He grew taller',
            'His face shone like the sun',
            'He became invisible',
            'His hair turned white'
          ],
          correctIndex: 1,
          explanation:
              'His face shone like the sun, and His clothes became as '
              'white as the light (Matthew 17:2).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 17. The Good Samaritan ──────────────────────────────────────
    const JesusJourneyEvent(
      order: 16,
      id: 'good_samaritan',
      title: 'The Good Samaritan',
      subtitle: 'Teaching through parables',
      narrative:
          'When a law expert asked, "Who is my neighbor?" Jesus answered '
          'with a powerful parable. A man traveling from Jerusalem to Jericho '
          'was attacked by robbers and left half dead. A priest and a Levite '
          'both passed by on the other side. But a Samaritan -- despised by '
          'Jews -- stopped, bandaged his wounds, took him to an inn, and '
          'paid for his care. Jesus asked, "Which was a neighbor?" The answer '
          'was clear.',
      bibleReference: 'Luke 10:25-37',
      keyVerse: 'Go and do likewise.',
      keyVerseReference: 'Luke 10:37',
      spiritualTakeaway:
          'Love knows no boundaries. Jesus teaches that our neighbor '
          'is anyone in need, regardless of nationality, background, or '
          'social status. True faith is expressed through compassionate '
          'action.',
      themeColor: Color(0xFFD48E3B),
      iconName: 'hand_helping',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'Which road was the injured man traveling on in the parable?',
          options: [
            'Road to Damascus',
            'Jerusalem to Jericho',
            'Road to Emmaus',
            'Jerusalem to Bethlehem'
          ],
          correctIndex: 1,
          explanation:
              'A man was going down from Jerusalem to Jericho when he '
              'was attacked (Luke 10:30).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question:
              'Who passed by the injured man without helping (besides the priest)?',
          options: ['A Pharisee', 'A Levite', 'A Roman soldier', 'A tax collector'],
          correctIndex: 1,
          explanation:
              'Both a priest and a Levite passed by on the other side '
              '(Luke 10:31-32).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'What did Jesus tell the law expert at the end?',
          options: [
            'Judge not',
            'Love your enemy',
            'Go and do likewise',
            'Pray without ceasing'
          ],
          correctIndex: 2,
          explanation:
              'Jesus told him, "Go and do likewise" (Luke 10:37).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 18. Raising Lazarus ─────────────────────────────────────────
    const JesusJourneyEvent(
      order: 17,
      id: 'raising_lazarus',
      title: 'Raising Lazarus',
      subtitle: 'Death conquered',
      narrative:
          'Lazarus, a close friend of Jesus, became ill and died. By the '
          'time Jesus arrived in Bethany, Lazarus had been in the tomb four '
          'days. Martha said, "If you had been here, my brother would not '
          'have died." Jesus wept, showing His deep love, then commanded, '
          '"Lazarus, come out!" And the dead man walked out, still wrapped '
          'in burial cloths. This miracle powerfully foreshadowed Jesus\' '
          'own resurrection.',
      bibleReference: 'John 11:1-44',
      keyVerse:
          'I am the resurrection and the life. The one who believes in me '
          'will live, even though they die.',
      keyVerseReference: 'John 11:25',
      spiritualTakeaway:
          'Jesus is Lord over death itself. No situation is beyond hope '
          'when He is present. His tears show that He shares our grief, '
          'and His power proves that death does not have the final word.',
      themeColor: Color(0xFF6A5C8A),
      iconName: 'sunrise',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'How many days had Lazarus been in the tomb?',
          options: ['One', 'Two', 'Three', 'Four'],
          correctIndex: 3,
          explanation:
              'Lazarus had already been in the tomb for four days '
              '(John 11:17).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What is the shortest verse in the Bible, found in this story?',
          options: [
            'God is love',
            'Jesus wept',
            'Pray always',
            'Be still'
          ],
          correctIndex: 1,
          explanation:
              '"Jesus wept" (John 11:35) is the shortest verse in the '
              'Bible and shows His compassion.',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'In which town did Lazarus live?',
          options: ['Nazareth', 'Bethany', 'Capernaum', 'Jericho'],
          correctIndex: 1,
          explanation:
              'Lazarus and his sisters Martha and Mary lived in Bethany '
              '(John 11:1).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 19. Blessing the Children ───────────────────────────────────
    const JesusJourneyEvent(
      order: 18,
      id: 'blessing_children',
      title: 'Blessing the Children',
      subtitle: 'Let them come to me',
      narrative:
          'People brought little children to Jesus for Him to place His '
          'hands on them and pray. The disciples rebuked them, thinking the '
          'children were not important enough for the Master\'s time. But '
          'Jesus was indignant and said, "Let the little children come to '
          'me, and do not hinder them, for the kingdom of God belongs to '
          'such as these." He took the children in His arms and blessed them.',
      bibleReference: 'Mark 10:13-16',
      keyVerse:
          'Let the little children come to me, and do not hinder them, '
          'for the kingdom of God belongs to such as these.',
      keyVerseReference: 'Mark 10:14',
      spiritualTakeaway:
          'God treasures every person, regardless of age or status. '
          'Childlike faith -- humble, trusting, and dependent -- is the '
          'model for entering God\'s kingdom.',
      themeColor: Color(0xFFE8A0BF),
      iconName: 'heart',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'How did the disciples react when people brought children?',
          options: [
            'They welcomed them',
            'They rebuked the people',
            'They ignored them',
            'They asked Jesus first'
          ],
          correctIndex: 1,
          explanation:
              'The disciples rebuked those who brought the children '
              '(Mark 10:13).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'How did Jesus feel about the disciples\' reaction?',
          options: ['Happy', 'Indifferent', 'Indignant', 'Confused'],
          correctIndex: 2,
          explanation:
              'Jesus was indignant, showing His strong disapproval '
              '(Mark 10:14).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'What did Jesus do with the children?',
          options: [
            'Taught them Scripture',
            'Sent them away',
            'Took them in His arms and blessed them',
            'Asked them questions'
          ],
          correctIndex: 2,
          explanation:
              'He took the children in His arms, placed His hands on '
              'them and blessed them (Mark 10:16).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 20. Zacchaeus the Tax Collector ─────────────────────────────
    const JesusJourneyEvent(
      order: 19,
      id: 'zacchaeus',
      title: 'Zacchaeus the Tax Collector',
      subtitle: 'Come down from the tree',
      narrative:
          'In Jericho, a wealthy chief tax collector named Zacchaeus wanted '
          'desperately to see Jesus, but he was too short to see over the '
          'crowd. So he ran ahead and climbed a sycamore-fig tree. When Jesus '
          'reached the spot, He looked up and said, "Zacchaeus, come down '
          'immediately. I must stay at your house today." Zacchaeus welcomed '
          'Him joyfully and pledged to give half his possessions to the poor.',
      bibleReference: 'Luke 19:1-10',
      keyVerse:
          'For the Son of Man came to seek and to save the lost.',
      keyVerseReference: 'Luke 19:10',
      spiritualTakeaway:
          'No one is beyond the reach of God\'s love. Jesus seeks out '
          'those whom society rejects. An encounter with Christ transforms '
          'our hearts and our priorities.',
      themeColor: Color(0xFF6B8E4E),
      iconName: 'tree_pine',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What kind of tree did Zacchaeus climb?',
          options: ['Olive', 'Palm', 'Sycamore-fig', 'Oak'],
          correctIndex: 2,
          explanation:
              'Zacchaeus climbed a sycamore-fig tree to see Jesus '
              '(Luke 19:4).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What was Zacchaeus\' occupation?',
          options: [
            'Fisherman',
            'Chief tax collector',
            'Pharisee',
            'Carpenter'
          ],
          correctIndex: 1,
          explanation:
              'He was a chief tax collector and was wealthy '
              '(Luke 19:2).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Zacchaeus promise to do after meeting Jesus?',
          options: [
            'Build a temple',
            'Become a disciple',
            'Give half his possessions to the poor',
            'Move to Jerusalem'
          ],
          correctIndex: 2,
          explanation:
              'Zacchaeus said he would give half his possessions to '
              'the poor and repay anyone he had cheated four times over '
              '(Luke 19:8).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 21. Triumphal Entry ─────────────────────────────────────────
    const JesusJourneyEvent(
      order: 20,
      id: 'triumphal_entry',
      title: 'Triumphal Entry',
      subtitle: 'Palm Sunday',
      narrative:
          'As Jesus approached Jerusalem, He sent two disciples to bring a '
          'young donkey. Riding upon it, He entered the city while crowds '
          'spread their cloaks and palm branches on the road, shouting, '
          '"Hosanna to the Son of David! Blessed is he who comes in the name '
          'of the Lord!" The whole city was stirred. Yet Jesus wept over '
          'Jerusalem, knowing what was to come.',
      bibleReference: 'Matthew 21:1-11',
      keyVerse:
          'Hosanna to the Son of David! Blessed is he who comes in the '
          'name of the Lord!',
      keyVerseReference: 'Matthew 21:9',
      spiritualTakeaway:
          'Jesus came as a humble king, riding a donkey rather than a '
          'war horse. He teaches us that true kingship is marked by '
          'humility and service, not by worldly power and display.',
      themeColor: Color(0xFF4E8C3E),
      iconName: 'palm_tree',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What animal did Jesus ride into Jerusalem?',
          options: ['Horse', 'Donkey', 'Camel', 'Chariot'],
          correctIndex: 1,
          explanation:
              'Jesus rode a donkey, fulfilling the prophecy of Zechariah '
              '9:9 (Matthew 21:7).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did the crowds shout as Jesus entered?',
          options: ['Hallelujah', 'Hosanna', 'Amen', 'Glory'],
          correctIndex: 1,
          explanation:
              'The crowds shouted "Hosanna to the Son of David!" '
              '(Matthew 21:9).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did the people spread on the road before Jesus?',
          options: [
            'Flowers and spices',
            'Cloaks and palm branches',
            'Gold and silver',
            'Sand and stones'
          ],
          correctIndex: 1,
          explanation:
              'The crowd spread their cloaks on the road, while others '
              'cut branches from the trees (Matthew 21:8).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 22. Cleansing the Temple ────────────────────────────────────
    const JesusJourneyEvent(
      order: 21,
      id: 'cleansing_temple',
      title: 'Cleansing the Temple',
      subtitle: 'Righteous anger',
      narrative:
          'Jesus entered the temple courts and found merchants selling '
          'animals and money changers exploiting worshippers. Filled with '
          'righteous anger, He overturned their tables and drove out the '
          'sellers, declaring, "My house will be called a house of prayer, '
          'but you are making it a den of robbers." Even in His anger, '
          'Jesus healed the blind and lame who came to Him in the temple.',
      bibleReference: 'Matthew 21:12-17',
      keyVerse:
          'My house will be called a house of prayer, but you are making '
          'it a den of robbers.',
      keyVerseReference: 'Matthew 21:13',
      spiritualTakeaway:
          'Jesus is passionate about authentic worship and justice. '
          'He challenges us to examine whether we have allowed anything '
          'to corrupt or commercialize our relationship with God.',
      themeColor: Color(0xFFC0392B),
      iconName: 'flame',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What were the merchants doing in the temple?',
          options: [
            'Teaching Scripture',
            'Selling animals and changing money',
            'Building an altar',
            'Collecting offerings'
          ],
          correctIndex: 1,
          explanation:
              'People were buying and selling in the temple courts, '
              'and money changers were conducting business (Matthew 21:12).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus say the temple should be called?',
          options: [
            'A house of prayer',
            'A house of sacrifice',
            'A house of learning',
            'A house of rest'
          ],
          correctIndex: 0,
          explanation:
              'Jesus declared, "My house will be called a house of '
              'prayer" (Matthew 21:13).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus do to the money changers\' tables?',
          options: [
            'Blessed them',
            'Sat at them',
            'Overturned them',
            'Ignored them'
          ],
          correctIndex: 2,
          explanation:
              'Jesus overturned the tables of the money changers '
              '(Matthew 21:12).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 23. The Last Supper ─────────────────────────────────────────
    const JesusJourneyEvent(
      order: 22,
      id: 'last_supper',
      title: 'The Last Supper',
      subtitle: 'Communion established',
      narrative:
          'On the night before His crucifixion, Jesus gathered with His '
          'twelve disciples for the Passover meal. He took bread, gave '
          'thanks, broke it, and said, "This is my body given for you." '
          'Then He took the cup, saying, "This is my blood of the covenant, '
          'poured out for many for the forgiveness of sins." He also washed '
          'His disciples\' feet, teaching them to serve one another with '
          'humility.',
      bibleReference: 'Luke 22:7-23; John 13:1-17',
      keyVerse:
          'Do this in remembrance of me.',
      keyVerseReference: 'Luke 22:19',
      spiritualTakeaway:
          'The Lord\'s Supper reminds us of the ultimate sacrifice Jesus '
          'made. In washing the disciples\' feet, He showed that true '
          'leadership is servant leadership. We honor Him when we serve '
          'others humbly.',
      themeColor: Color(0xFF722F37),
      iconName: 'utensils',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What Jewish feast was being celebrated at the Last Supper?',
          options: ['Purim', 'Hanukkah', 'Passover', 'Pentecost'],
          correctIndex: 2,
          explanation:
              'The Last Supper was a Passover meal (Luke 22:7-8).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus do to demonstrate servant leadership?',
          options: [
            'Cooked the meal',
            'Washed the disciples\' feet',
            'Carried the water',
            'Served the wine'
          ],
          correctIndex: 1,
          explanation:
              'Jesus washed His disciples\' feet, including those of '
              'Judas who would betray Him (John 13:5).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Jesus say the bread represented?',
          options: ['His word', 'His body', 'His spirit', 'His promise'],
          correctIndex: 1,
          explanation:
              'Jesus said, "This is my body given for you" '
              '(Luke 22:19).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 24. Garden of Gethsemane ────────────────────────────────────
    const JesusJourneyEvent(
      order: 23,
      id: 'garden_gethsemane',
      title: 'Garden of Gethsemane',
      subtitle: 'Not my will but yours',
      narrative:
          'After the supper, Jesus went to the Garden of Gethsemane to pray. '
          'He was deeply troubled and sorrowful, saying, "My soul is '
          'overwhelmed with sorrow to the point of death." Three times He '
          'prayed, "Father, if it is possible, take this cup from me. Yet '
          'not as I will, but as you will." His sweat fell like drops of '
          'blood. The disciples, whom He had asked to keep watch, fell '
          'asleep.',
      bibleReference: 'Matthew 26:36-46',
      keyVerse:
          'Not as I will, but as you will.',
      keyVerseReference: 'Matthew 26:39',
      spiritualTakeaway:
          'Jesus\' prayer in Gethsemane teaches us that surrender to '
          'God\'s will is the highest form of prayer. Even when we face '
          'overwhelming circumstances, we can bring our honest anguish '
          'to God while trusting His perfect plan.',
      themeColor: Color(0xFF2F4858),
      iconName: 'moon',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'What is the name of the garden where Jesus prayed?',
          options: ['Eden', 'Gethsemane', 'Olive Press', 'Kidron'],
          correctIndex: 1,
          explanation:
              'Jesus went to a place called Gethsemane to pray '
              '(Matthew 26:36).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'How many times did Jesus pray the same prayer?',
          options: ['Once', 'Twice', 'Three times', 'Seven times'],
          correctIndex: 2,
          explanation:
              'Jesus went away three times to pray the same thing '
              '(Matthew 26:39, 42, 44).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'What were the disciples doing while Jesus prayed?',
          options: ['Praying', 'Sleeping', 'Talking', 'Eating'],
          correctIndex: 1,
          explanation:
              'He found them sleeping, for their eyes were heavy '
              '(Matthew 26:43).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 25. Trial Before Pilate ─────────────────────────────────────
    const JesusJourneyEvent(
      order: 24,
      id: 'trial_before_pilate',
      title: 'Trial Before Pilate',
      subtitle: 'Innocent yet condemned',
      narrative:
          'After being arrested and tried by the Jewish leaders, Jesus '
          'was brought before Pontius Pilate, the Roman governor. Pilate '
          'found no basis for a charge against Him and tried to release '
          'Him. But the crowd, stirred up by the chief priests, demanded '
          'His crucifixion, shouting, "Crucify him!" Pilate washed his '
          'hands and handed Jesus over to be crucified, though he knew '
          'Jesus was innocent.',
      bibleReference: 'Matthew 27:11-26',
      keyVerse:
          'What shall I do, then, with Jesus who is called the Messiah?',
      keyVerseReference: 'Matthew 27:22',
      spiritualTakeaway:
          'Pilate\'s question echoes through history: what will you do '
          'with Jesus? Every person must answer this question. Indifference '
          'or trying to wash our hands of the decision is itself a choice.',
      themeColor: Color(0xFF4A4A4A),
      iconName: 'scale',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'Who was the Roman governor who tried Jesus?',
          options: ['Herod', 'Pilate', 'Caesar', 'Felix'],
          correctIndex: 1,
          explanation:
              'Jesus stood before Pontius Pilate, the Roman governor '
              '(Matthew 27:11).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did Pilate do to symbolize washing himself of blame?',
          options: [
            'Tore his robe',
            'Washed his hands',
            'Covered his face',
            'Broke a staff'
          ],
          correctIndex: 1,
          explanation:
              'Pilate washed his hands in front of the crowd, saying '
              'he was innocent of this man\'s blood (Matthew 27:24).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did the crowd shout when Pilate asked what to do with Jesus?',
          options: ['Release him', 'Crucify him', 'Stone him', 'Exile him'],
          correctIndex: 1,
          explanation:
              'They all answered, "Crucify him!" (Matthew 27:22-23).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 26. The Crucifixion ─────────────────────────────────────────
    const JesusJourneyEvent(
      order: 25,
      id: 'crucifixion',
      title: 'The Crucifixion',
      subtitle: 'It is finished',
      narrative:
          'Jesus was led to Golgotha, the Place of the Skull, and nailed '
          'to a cross between two criminals. Darkness covered the land for '
          'three hours. Jesus cried out, "My God, my God, why have you '
          'forsaken me?" He then said, "It is finished," bowed His head, '
          'and gave up His spirit. At that moment, the temple curtain tore '
          'in two from top to bottom, signifying that access to God was '
          'now open to all.',
      bibleReference: 'Matthew 27:32-56; John 19:30',
      keyVerse: 'It is finished.',
      keyVerseReference: 'John 19:30',
      spiritualTakeaway:
          'The cross is not a symbol of defeat but of ultimate victory. '
          'Jesus bore the penalty for our sins so that we could be reconciled '
          'to God. The torn curtain means we can now approach God directly, '
          'through Christ.',
      themeColor: Color(0xFF3D0C02),
      iconName: 'cross',
      xpReward: 20,
      questions: [
        JourneyQuestion(
          question: 'What was the place called where Jesus was crucified?',
          options: ['Gethsemane', 'Golgotha', 'Bethany', 'Mount Sinai'],
          correctIndex: 1,
          explanation:
              'They came to a place called Golgotha, which means "the '
              'Place of the Skull" (Matthew 27:33).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What happened to the temple curtain when Jesus died?',
          options: [
            'It caught fire',
            'It turned white',
            'It was torn in two from top to bottom',
            'It disappeared'
          ],
          correctIndex: 2,
          explanation:
              'The curtain of the temple was torn in two from top to '
              'bottom (Matthew 27:51).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'How many hours did darkness cover the land?',
          options: ['One', 'Two', 'Three', 'Six'],
          correctIndex: 2,
          explanation:
              'From noon until three in the afternoon, darkness came '
              'over all the land (Matthew 27:45).',
          difficulty: 2,
        ),
      ],
    ),

    // ── 27. The Burial ──────────────────────────────────────────────
    const JesusJourneyEvent(
      order: 26,
      id: 'burial',
      title: 'The Burial',
      subtitle: 'Joseph of Arimathea',
      narrative:
          'As evening approached, a wealthy man named Joseph of Arimathea, '
          'a secret disciple of Jesus, went to Pilate and asked for Jesus\' '
          'body. He wrapped it in a clean linen cloth and placed it in his '
          'own new tomb, cut out of the rock. He rolled a big stone in front '
          'of the entrance and went away. Mary Magdalene and the other Mary '
          'sat there watching the tomb.',
      bibleReference: 'Matthew 27:57-66',
      keyVerse:
          'Joseph took the body, wrapped it in a clean linen cloth, and '
          'placed it in his own new tomb.',
      keyVerseReference: 'Matthew 27:59-60',
      spiritualTakeaway:
          'Even in the darkest moments, God has faithful people in '
          'unexpected places. Joseph risked his reputation to honor Jesus. '
          'The burial was not the end of the story but a prelude to the '
          'greatest miracle in history.',
      themeColor: Color(0xFF5A5A5A),
      iconName: 'landmark',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question: 'Who asked Pilate for the body of Jesus?',
          options: [
            'Peter',
            'John',
            'Joseph of Arimathea',
            'Nicodemus'
          ],
          correctIndex: 2,
          explanation:
              'Joseph of Arimathea, a disciple of Jesus, asked Pilate '
              'for the body (Matthew 27:57-58).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Where was Jesus\' body placed?',
          options: [
            'A cave',
            'A new tomb cut in rock',
            'A garden',
            'A borrowed room'
          ],
          correctIndex: 1,
          explanation:
              'Joseph placed the body in his own new tomb, which he '
              'had cut out of the rock (Matthew 27:60).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What was rolled in front of the tomb entrance?',
          options: [
            'A wooden door',
            'A big stone',
            'A curtain',
            'An iron gate'
          ],
          correctIndex: 1,
          explanation:
              'He rolled a big stone in front of the entrance to the '
              'tomb (Matthew 27:60).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 28. The Resurrection ────────────────────────────────────────
    const JesusJourneyEvent(
      order: 27,
      id: 'resurrection',
      title: 'The Resurrection',
      subtitle: 'He is risen!',
      narrative:
          'On the third day, at dawn, there was a violent earthquake. An '
          'angel of the Lord descended, rolled back the stone, and sat on '
          'it. The guards were so afraid they shook and became like dead '
          'men. The angel told the women, "Do not be afraid. He is not here; '
          'he has risen, just as he said!" They ran to tell the disciples '
          'with fear and great joy. Jesus met them on the way and said, '
          '"Greetings."',
      bibleReference: 'Matthew 28:1-10',
      keyVerse:
          'He is not here; he has risen, just as he said.',
      keyVerseReference: 'Matthew 28:6',
      spiritualTakeaway:
          'The resurrection is the foundation of the Christian faith. '
          'Because Jesus conquered death, we have the assurance of '
          'eternal life. Every fear, every grief, every hopeless situation '
          'is answered by the empty tomb.',
      themeColor: Color(0xFFDAA520),
      iconName: 'sun_rise',
      xpReward: 25,
      questions: [
        JourneyQuestion(
          question: 'On which day did Jesus rise from the dead?',
          options: [
            'The first day (Sunday)',
            'The second day',
            'The third day',
            'The seventh day'
          ],
          correctIndex: 2,
          explanation:
              'Jesus rose on the third day, just as He had foretold '
              '(Matthew 28:1; 1 Corinthians 15:4).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'Who were the first to visit the empty tomb?',
          options: [
            'Peter and John',
            'Mary Magdalene and the other Mary',
            'The eleven disciples',
            'Joseph of Arimathea'
          ],
          correctIndex: 1,
          explanation:
              'Mary Magdalene and the other Mary went to look at the '
              'tomb (Matthew 28:1).',
          difficulty: 2,
        ),
        JourneyQuestion(
          question: 'What did the angel tell the women?',
          options: [
            'Wait here',
            'He is not here; he has risen',
            'Go to Galilee',
            'Tell no one'
          ],
          correctIndex: 1,
          explanation:
              'The angel said, "He is not here; he has risen, just as '
              'he said" (Matthew 28:6).',
          difficulty: 1,
        ),
      ],
    ),

    // ── 29. Appearances to Disciples ────────────────────────────────
    const JesusJourneyEvent(
      order: 28,
      id: 'appearances_to_disciples',
      title: 'Appearances to Disciples',
      subtitle: '40 days of teaching',
      narrative:
          'Over forty days, the risen Jesus appeared many times to His '
          'followers. He appeared to the women at the tomb, to two disciples '
          'on the road to Emmaus, to Peter, to the gathered disciples '
          'behind locked doors, and even to over five hundred people at once. '
          'He ate with them, let Thomas touch His wounds, and gave them '
          'instructions about the coming of the Holy Spirit and their '
          'mission to make disciples of all nations.',
      bibleReference: 'Acts 1:3; 1 Corinthians 15:3-8; John 20:24-29',
      keyVerse:
          'Because you have seen me, you have believed; blessed are those '
          'who have not seen and yet have believed.',
      keyVerseReference: 'John 20:29',
      spiritualTakeaway:
          'The risen Christ appeared to many witnesses, providing '
          'overwhelming evidence of His resurrection. Like Thomas, we may '
          'have doubts, but Jesus invites us to come, see, and believe.',
      themeColor: Color(0xFF3E7CB1),
      iconName: 'users_round',
      xpReward: 15,
      questions: [
        JourneyQuestion(
          question:
              'How many days did Jesus appear to His followers after the resurrection?',
          options: ['7', '12', '30', '40'],
          correctIndex: 3,
          explanation:
              'Jesus appeared to them over a period of forty days '
              '(Acts 1:3).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'Which disciple said he would not believe unless he saw and touched Jesus\' wounds?',
          options: ['Peter', 'Thomas', 'Andrew', 'Philip'],
          correctIndex: 1,
          explanation:
              'Thomas said he would not believe unless he saw the nail '
              'marks and put his hand into Jesus\' side (John 20:25).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question:
              'To how many people did Jesus appear at one time, according to Paul?',
          options: ['Twelve', 'One hundred', 'Five hundred', 'One thousand'],
          correctIndex: 2,
          explanation:
              'He appeared to more than five hundred of the brothers '
              'and sisters at the same time (1 Corinthians 15:6).',
          difficulty: 3,
        ),
      ],
    ),

    // ── 30. The Ascension ───────────────────────────────────────────
    const JesusJourneyEvent(
      order: 29,
      id: 'ascension',
      title: 'The Ascension',
      subtitle: 'Return to heaven',
      narrative:
          'Jesus led His disciples to the vicinity of Bethany. He gave them '
          'their final commission: "Go and make disciples of all nations, '
          'baptizing them in the name of the Father and of the Son and of '
          'the Holy Spirit." Then He lifted His hands, blessed them, and '
          'was taken up before their very eyes. A cloud hid Him from their '
          'sight. Two angels appeared and promised that He would return in '
          'the same way they had seen Him go.',
      bibleReference: 'Acts 1:6-11; Luke 24:50-53',
      keyVerse:
          'Surely I am with you always, to the very end of the age.',
      keyVerseReference: 'Matthew 28:20',
      spiritualTakeaway:
          'The Ascension is not a farewell but a commissioning. Jesus '
          'entrusted His mission to His followers -- and to us. He promises '
          'to be with us always and will one day return in glory. Until '
          'then, we carry His message of hope to the world.',
      themeColor: Color(0xFF5B86E5),
      iconName: 'cloud',
      xpReward: 25,
      questions: [
        JourneyQuestion(
          question:
              'What command did Jesus give the disciples before ascending?',
          options: [
            'Stay in Jerusalem forever',
            'Go and make disciples of all nations',
            'Build a church in Bethany',
            'Write down His teachings'
          ],
          correctIndex: 1,
          explanation:
              'Jesus said, "Go and make disciples of all nations" '
              '(Matthew 28:19).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What happened as the disciples watched Jesus ascend?',
          options: [
            'Lightning struck',
            'A cloud hid Him from their sight',
            'He vanished instantly',
            'A bright light appeared'
          ],
          correctIndex: 1,
          explanation:
              'He was taken up before their very eyes, and a cloud hid '
              'Him from their sight (Acts 1:9).',
          difficulty: 1,
        ),
        JourneyQuestion(
          question: 'What did the two angels tell the disciples?',
          options: [
            'Go back to Galilee',
            'He will come back in the same way',
            'Build an altar here',
            'Wait for seven days'
          ],
          correctIndex: 1,
          explanation:
              'The angels said Jesus would come back in the same way '
              'they had seen Him go into heaven (Acts 1:11).',
          difficulty: 2,
        ),
      ],
    ),
  ];
}
