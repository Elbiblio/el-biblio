import '../domain/models/faith_question.dart';

class FaithQuestionCatalog {
  const FaithQuestionCatalog._();

  static FaithQuestion getById(String id) {
    return allQuestions.firstWhere((q) => q.id == id);
  }

  static List<FaithQuestion> getByCategory(String category) {
    return allQuestions.where((q) => q.category == category).toList();
  }

  static List<FaithQuestion> getByDifficulty(int difficulty) {
    return allQuestions.where((q) => q.difficulty == difficulty).toList();
  }

  static const List<String> categories = [
    'theology',
    'suffering',
    'science_faith',
    'daily_life',
    'morality',
    'history',
  ];

  static const Map<String, String> categoryLabels = {
    'theology': 'Theology',
    'suffering': 'Suffering',
    'science_faith': 'Science & Faith',
    'daily_life': 'Daily Life',
    'morality': 'Morality',
    'history': 'History',
  };

  static const allQuestions = <FaithQuestion>[
    // ── Theology (difficulty 1-5) ─────────────────────────────────────
    FaithQuestion(
      id: 'theo_01',
      question: 'What is the Trinity?',
      shortAnswer:
          'The Trinity is the Christian belief that God exists as three persons — Father, Son, and Holy Spirit — in one divine being.',
      parable:
          'Think of the sun: the star itself, its light, and its warmth are distinct — yet they are inseparably one sun. You cannot have sunlight without the star, nor warmth without the light. The Trinity is like that — three expressions of one God, each fully divine, none existing without the others.',
      fullAnswer:
          'The doctrine of the Trinity teaches that there is one God who eternally exists as three distinct persons: the Father, the Son (Jesus Christ), and the Holy Spirit. Each person is fully God, yet there is only one God. This is not three gods (tritheism) or one God wearing three masks (modalism). The Trinity is seen at Jesus\' baptism where the Father speaks, the Son is baptized, and the Spirit descends. While the word "Trinity" does not appear in Scripture, the concept is woven throughout both Old and New Testaments.',
      scriptureRefs: ['Matthew 28:19', '2 Corinthians 13:14', 'John 1:1-3'],
      category: 'theology',
      difficulty: 2,
      quizOptions: [
        'God takes three different forms at different times',
        'Three separate gods working together',
        'One God existing eternally as three distinct persons',
        'A concept invented at the Council of Nicaea',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'theo_02',
      question: 'Are we saved by grace or by works?',
      shortAnswer:
          'Christians are saved by grace through faith, not by works. However, genuine faith naturally produces good works as its fruit.',
      parable:
          'A drowning man cannot save himself by swimming harder — he needs someone to pull him out. But once rescued, he naturally uses his arms to help others. Grace is the rescue; works are the arms now free to serve.',
      fullAnswer:
          'The apostle Paul makes clear that salvation is a gift of God\'s grace received through faith, not earned by human effort. This prevents any boasting. However, James writes that faith without works is dead — meaning true saving faith inevitably expresses itself in action. The two are not contradictory: grace saves us, and that same grace transforms us to live differently. Works are the evidence of salvation, not the cause of it. Think of it like a fruit tree: the fruit doesn\'t make it a tree, but a healthy tree naturally bears fruit.',
      scriptureRefs: ['Ephesians 2:8-9', 'James 2:17', 'Titus 3:5'],
      category: 'theology',
      difficulty: 2,
      quizOptions: [
        'Only by doing enough good works to outweigh the bad',
        'By grace through faith, with works as evidence of genuine faith',
        'By faith alone with no connection to how we live',
        'By a combination of faith and works in equal measure',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'theo_03',
      question: 'What does predestination mean?',
      shortAnswer:
          'Predestination is the biblical teaching that God, before the foundation of the world, chose those who would be saved according to His foreknowledge and purpose.',
      parable:
          'A master playwright writes a story knowing every character\'s arc — yet each character speaks with their own voice and makes real choices on stage. The author\'s foreknowledge does not make the characters puppets. God is the playwright who holds the pen and honors the performance.',
      fullAnswer:
          'Predestination is one of the most debated doctrines in Christianity. Calvinists emphasize God\'s sovereign choice in election, while Arminians stress God\'s foreknowledge of those who would freely choose Him. Both traditions affirm that God is sovereign and humans are responsible. The tension between divine sovereignty and human free will is held throughout Scripture. What all Christians agree on is that salvation ultimately originates with God\'s initiative — we love Him because He first loved us.',
      scriptureRefs: ['Romans 8:29-30', 'Ephesians 1:4-5', '1 Peter 1:2'],
      category: 'theology',
      difficulty: 4,
      quizOptions: [
        'That every event in life is scripted with no real choices',
        'That God chose who would be saved before the world began',
        'That only a select few can ever know God',
        'That our salvation depends entirely on our own decision',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'theo_04',
      question: 'Who is the Holy Spirit?',
      shortAnswer:
          'The Holy Spirit is the third person of the Trinity — fully God — who indwells believers, convicts the world of sin, and empowers Christians for godly living.',
      fullAnswer:
          'The Holy Spirit is not an impersonal force but a divine person who thinks, feels, and acts. Jesus called Him "the Helper" or "Counselor" who would come after His ascension. The Spirit inspired Scripture, empowered Jesus\' ministry, raised Christ from the dead, and now lives within every believer. His work includes convicting people of sin, regenerating hearts, sealing believers for eternity, producing spiritual fruit (love, joy, peace, etc.), and distributing spiritual gifts to the church.',
      scriptureRefs: ['John 14:16-17', 'Acts 1:8', 'Galatians 5:22-23'],
      category: 'theology',
      difficulty: 1,
      quizOptions: [
        'An impersonal force or energy from God',
        'An angel sent to guide believers',
        'The third person of the Trinity, fully God, who indwells believers',
        'A symbolic representation of God\'s power',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'theo_05',
      question: 'What happens when we die?',
      shortAnswer:
          'Christians believe that at death, the soul immediately enters God\'s presence (for believers) or is separated from God, awaiting final resurrection and judgment.',
      fullAnswer:
          'Scripture teaches that death is not the end. For believers, to be absent from the body is to be present with the Lord. Jesus told the thief on the cross, "Today you will be with me in paradise." At Christ\'s return, the dead in Christ will be raised with glorified bodies. For those who rejected God, there is a conscious existence separated from Him. The final judgment will result in eternal life with God in the new heaven and new earth, or eternal separation. Christians disagree on some details, but all affirm bodily resurrection and eternal life through Christ.',
      scriptureRefs: [
        '2 Corinthians 5:8',
        'Luke 23:43',
        '1 Thessalonians 4:16-17',
      ],
      category: 'theology',
      difficulty: 3,
      quizOptions: [
        'We cease to exist entirely',
        'Everyone goes to the same place regardless of faith',
        'Believers enter God\'s presence; the final resurrection awaits all',
        'Souls are reincarnated into new bodies',
      ],
      correctOptionIndex: 2,
    ),

    // ── Suffering (difficulty 1-5) ────────────────────────────────────
    FaithQuestion(
      id: 'suf_01',
      question: 'Why does God allow suffering?',
      shortAnswer:
          'God allows suffering for purposes that include developing character, demonstrating His comfort, and accomplishing greater good — though some reasons remain a mystery this side of eternity.',
      fullAnswer:
          'The problem of suffering is perhaps the most challenging question in Christianity. Scripture offers several perspectives: suffering can produce perseverance, character, and hope (Romans 5). God can bring good out of evil (Genesis 50:20). Free will, given in love, makes evil possible. We live in a fallen world affected by sin. Job teaches us that God is trustworthy even when we don\'t understand. Jesus Himself suffered on the cross, showing God is not distant from our pain. Ultimately, God promises to make all things new and wipe away every tear.',
      scriptureRefs: ['Romans 8:28', 'Job 1:21', 'Romans 5:3-5'],
      category: 'suffering',
      difficulty: 3,
      quizOptions: [
        'Because God is not powerful enough to stop it',
        'Because God does not care about human pain',
        'For multiple purposes including growth, though some reasons remain mysterious',
        'As direct punishment for personal sins',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'suf_02',
      question: 'Why do innocent children suffer?',
      shortAnswer:
          'The suffering of innocent children is one of the deepest mysteries of faith. Scripture shows God\'s special care for children while acknowledging we live in a broken world affected by sin.',
      fullAnswer:
          'This question strikes at the heart of theodicy. The Bible affirms that God deeply loves children and is angered by injustice against them. Jesus warned severely against causing little ones to stumble. Children suffer because we live in a world broken by sin — through disease, abuse by those misusing free will, natural disasters in a fallen creation, and systemic injustice. God does not cause their suffering but He is present in it. David, after losing his infant son, found comfort knowing he would see his child again. God promises ultimate justice and restoration.',
      scriptureRefs: [
        'Matthew 18:10',
        '2 Samuel 12:23',
        'Matthew 19:14',
      ],
      category: 'suffering',
      difficulty: 4,
      quizOptions: [
        'Children are being punished for their parents\' sins',
        'We live in a broken world, but God cares deeply for children and promises restoration',
        'God is testing parents through their children\'s pain',
        'Suffering has no meaning and is purely random',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'suf_03',
      question: 'How can I find God in my suffering?',
      shortAnswer:
          'God draws near to the brokenhearted. Through prayer, Scripture, community, and honest lament, we can experience His presence even in our darkest moments.',
      fullAnswer:
          'The Psalms model honest engagement with God in suffering — including anger, confusion, and grief. David, Job, and Jeremiah all brought their raw pain to God. Finding God in suffering often involves: honest prayer (even angry prayer), meditating on Scripture that speaks to pain, receiving support from Christian community, remembering God\'s past faithfulness, and practicing lament as a spiritual discipline. God never promised to remove all suffering, but He promised never to leave us. Jesus wept at Lazarus\' tomb, showing that grief is not a lack of faith.',
      scriptureRefs: ['Psalm 34:18', 'Psalm 23:4', '2 Corinthians 1:3-4'],
      category: 'suffering',
      difficulty: 2,
      quizOptions: [
        'By suppressing all negative emotions and pretending to be fine',
        'Through prayer, Scripture, lament, and community — God draws near to the brokenhearted',
        'By working harder to earn God\'s favor and end the suffering',
        'By isolating yourself until the suffering passes',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'suf_04',
      question: 'If God is good, why is there evil in the world?',
      shortAnswer:
          'Evil exists because God gave creatures free will, and that freedom was misused. God permits evil temporarily while working to redeem and ultimately eliminate it.',
      fullAnswer:
          'This is known as the "problem of evil" in philosophy. Christianity teaches that God created a good world and gave moral agents (angels and humans) genuine freedom. That freedom was misused, introducing evil and its consequences. God could have created robots who never chose evil, but that would eliminate love, which requires freedom. God does not passively accept evil — He actively works against it through redemption, the cross, the Holy Spirit, the church, and ultimately the final judgment. Evil is temporal; God\'s goodness is eternal. The cross is God\'s definitive answer to evil.',
      scriptureRefs: ['Genesis 3:1-7', 'Romans 8:18-21', 'Revelation 21:4'],
      category: 'suffering',
      difficulty: 3,
      quizOptions: [
        'God created evil as part of His plan',
        'Evil is an illusion that doesn\'t really exist',
        'God gave free will which was misused; He is working to redeem and eliminate evil',
        'Good and evil are equal opposing forces',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'suf_05',
      question: 'Does God cause natural disasters?',
      shortAnswer:
          'Natural disasters result from living in a fallen creation groaning under the effects of sin, not from God targeting specific people for punishment.',
      fullAnswer:
          'Scripture teaches that all of creation was affected by the Fall and "groans" awaiting redemption. Earthquakes, hurricanes, and disease are part of a world that is not yet fully restored. Jesus explicitly corrected the assumption that disasters target sinful people (Luke 13:1-5). While God is sovereign over nature, these events are generally consequences of a broken physical world, not divine punishment against individuals. God is present in disasters — comforting, healing, and working through His people to bring relief. The ultimate hope is a new creation free from all destruction.',
      scriptureRefs: ['Romans 8:22', 'Luke 13:1-5', 'Revelation 21:1'],
      category: 'suffering',
      difficulty: 3,
      quizOptions: [
        'Yes, God sends disasters to punish sinful cities',
        'They result from a fallen creation, not God targeting specific people',
        'Natural disasters prove God does not exist',
        'They are caused by demonic forces outside God\'s control',
      ],
      correctOptionIndex: 1,
    ),

    // ── Science & Faith (difficulty 1-5) ──────────────────────────────
    FaithQuestion(
      id: 'sci_01',
      question: 'Can a Christian believe in evolution?',
      shortAnswer:
          'Christians hold diverse views. Some accept evolutionary science as God\'s method of creation, others hold to young earth creationism. The core truth is that God is Creator.',
      fullAnswer:
          'Christians span a spectrum of views: Young Earth Creationism reads Genesis 1 literally (6 24-hour days), Old Earth Creationism accepts an ancient universe with special creation events, and Evolutionary Creationism sees evolution as God\'s creative mechanism. All affirm God as Creator, humans as made in His image, and the reality of the Fall. The Bible\'s purpose is to reveal who created and why, not necessarily the precise scientific mechanism. Many great scientists throughout history have been devout Christians. Faith and science address different but complementary questions.',
      scriptureRefs: ['Genesis 1:1', 'Psalm 19:1', 'Romans 1:20'],
      category: 'science_faith',
      difficulty: 3,
      quizOptions: [
        'No, evolution and Christianity are completely incompatible',
        'Christians hold diverse views; the core truth is that God is Creator',
        'Yes, but only if you reject the Bible entirely',
        'Science has disproven all religious claims about origins',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'sci_02',
      question: 'Are miracles scientifically possible?',
      shortAnswer:
          'If God exists and created natural laws, He can act beyond them. Miracles are not violations of science but actions by the Author of nature.',
      fullAnswer:
          'Science describes how nature normally operates — it cannot rule out that the Creator of nature might act in extraordinary ways. C.S. Lewis argued that miracles are not "breaking" natural laws but the introduction of a new factor (God\'s direct action) into the equation. Science deals with repeatable, observable phenomena; miracles by definition are unique divine acts. The real question is not "can miracles happen?" but "does God exist?" If an all-powerful God exists, miracles are not only possible but expected. The resurrection of Jesus is the central miracle claim of Christianity, supported by historical evidence.',
      scriptureRefs: ['Luke 1:37', 'John 2:1-11', 'Acts 2:22'],
      category: 'science_faith',
      difficulty: 3,
      quizOptions: [
        'No, miracles violate the laws of physics and are impossible',
        'Miracles are just misunderstood natural phenomena',
        'If God exists and created natural laws, He can act beyond them',
        'Science has explained away all reported miracles',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'sci_03',
      question: 'Does the Big Bang theory contradict the Bible?',
      shortAnswer:
          'Many Christians see the Big Bang as consistent with Genesis — the universe had a definite beginning, which points to a Beginner.',
      fullAnswer:
          'The Big Bang theory was actually first proposed by Georges Lemaitre, a Belgian Catholic priest and physicist. The idea that the universe had a beginning from nothing is remarkably consistent with Genesis 1:1. Before the Big Bang theory, many scientists believed in an eternal universe — it was the scientific discovery of a cosmic beginning that aligned with what Scripture had always taught. The Big Bang describes how the universe expanded; Genesis reveals who initiated it and why. Many Christian cosmologists see their science as exploring the mechanics of God\'s creative act.',
      scriptureRefs: ['Genesis 1:1', 'Hebrews 11:3', 'Isaiah 40:26'],
      category: 'science_faith',
      difficulty: 2,
      quizOptions: [
        'Yes, the Big Bang completely disproves creation',
        'Many Christians see it as consistent — the universe had a beginning pointing to a Beginner',
        'The Big Bang proves God exists',
        'Christians must reject all modern cosmology',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'sci_04',
      question: 'Where do dinosaurs fit in the Bible?',
      shortAnswer:
          'The Bible doesn\'t specifically mention dinosaurs by name. Christians hold different views based on their interpretation of Genesis timelines and the age of the earth.',
      fullAnswer:
          'Young Earth Creationists believe dinosaurs were created on Day 6 alongside humans and may be referenced in Job 40-41 as "behemoth" and "leviathan." They believe dinosaurs went extinct after the Flood. Old Earth Creationists and Evolutionary Creationists place dinosaurs in the deep geological past, millions of years before humans, fitting within an old earth reading of Genesis. The Bible\'s purpose is not to be a zoological encyclopedia but to reveal God and His relationship with humanity. All views affirm God as the Creator of all life, including dinosaurs.',
      scriptureRefs: ['Job 40:15-24', 'Genesis 1:24-25', 'Psalm 104:24-25'],
      category: 'science_faith',
      difficulty: 2,
      quizOptions: [
        'The Bible explicitly says dinosaurs never existed',
        'Christians hold different views depending on their reading of Genesis timelines',
        'Dinosaurs disprove the Bible completely',
        'The Bible says dinosaurs lived alongside humans in the Garden of Eden',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'sci_05',
      question: 'Can faith and reason coexist?',
      shortAnswer:
          'Absolutely. Christianity has always valued reason alongside faith. Biblical faith is trust based on evidence, not blind belief without reason.',
      fullAnswer:
          'The idea that faith and reason are enemies is a modern myth. The Bible commands us to love God with our minds (Matthew 22:37). Christianity gave rise to the university system and the scientific method. Thinkers like Augustine, Aquinas, Newton, Pascal, and many modern scientists have integrated faith and reason. Biblical faith is not "believing without evidence" — it\'s trusting in what has been shown to be reliable. Thomas was invited to examine the evidence. Paul reasoned in synagogues. Isaiah says, "Come now, let us reason together." Faith goes beyond reason but not against it.',
      scriptureRefs: ['Isaiah 1:18', 'Matthew 22:37', '1 Peter 3:15'],
      category: 'science_faith',
      difficulty: 1,
      quizOptions: [
        'No, you must abandon reason to have faith',
        'Faith is only for people who cannot think critically',
        'Yes, Christianity values reason alongside faith; biblical faith is evidence-based trust',
        'Reason proves everything, making faith unnecessary',
      ],
      correctOptionIndex: 2,
    ),

    // ── Daily Life (difficulty 1-5) ───────────────────────────────────
    FaithQuestion(
      id: 'daily_01',
      question: 'How should I pray?',
      shortAnswer:
          'Prayer is conversation with God. While the Lord\'s Prayer provides a pattern, God welcomes honest, heartfelt communication in any form.',
      fullAnswer:
          'Jesus taught His disciples the Lord\'s Prayer as a model: begin with worship (hallowed be Your name), submit to God\'s will, ask for daily needs, seek forgiveness, and request protection. But prayer is broader than any formula. It includes praise, confession, thanksgiving, and supplication (ACTS model). You can pray with written prayers, in your own words, silently, aloud, alone, or with others. The key is sincerity — God looks at the heart. Even when you don\'t know what to say, the Holy Spirit intercedes for you. Consistency matters more than eloquence.',
      scriptureRefs: ['Matthew 6:9-13', 'Romans 8:26', '1 Thessalonians 5:17'],
      category: 'daily_life',
      difficulty: 1,
      quizOptions: [
        'Only using memorized formal prayers in church',
        'Using the Lord\'s Prayer as a pattern, but God welcomes honest conversation in any form',
        'Only when you have something urgent to ask for',
        'With specific body postures and ritual words',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'daily_02',
      question: 'How do I discern God\'s will for my life?',
      shortAnswer:
          'Discerning God\'s will involves Scripture, prayer, wise counsel, circumstances, and the Holy Spirit\'s leading — not a single dramatic sign.',
      fullAnswer:
          'Many Christians wait for a dramatic sign, but God typically guides through multiple means working together: Scripture provides clear moral guidance and principles. Prayer opens our hearts to God\'s direction. The Holy Spirit gives peace or conviction. Wise counselors offer perspective. Circumstances open and close doors. Your gifts, passions, and opportunities reveal patterns. For decisions not explicitly addressed in Scripture (which career, whom to marry), seek alignment between these sources. God is more concerned with who you\'re becoming than the specific path you take. Walk faithfully and trust that He directs your steps.',
      scriptureRefs: ['Proverbs 3:5-6', 'Romans 12:2', 'Psalm 32:8'],
      category: 'daily_life',
      difficulty: 2,
      quizOptions: [
        'Wait for a dramatic supernatural sign before making any decision',
        'Follow your feelings without thinking critically',
        'Through Scripture, prayer, wise counsel, circumstances, and the Spirit\'s leading together',
        'Ask a pastor to make all major decisions for you',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'daily_03',
      question: 'Why should I read the Bible regularly?',
      shortAnswer:
          'Regular Bible reading nourishes spiritual growth, renews the mind, equips for life\'s challenges, and deepens relationship with God.',
      fullAnswer:
          'The Bible is described as spiritual food (milk and solid food), a lamp for guidance, a sword for spiritual battle, and living water. Regular reading transforms thinking by exposing us to God\'s perspective on life. It builds faith ("faith comes from hearing the word"), equips us to discern truth from error, provides comfort in trials, and reveals God\'s character and promises. Jesus Himself quoted Scripture when tempted. Reading regularly — even when it feels dry — builds a reservoir of truth that the Holy Spirit can bring to mind when needed most. Consistency over quantity is the key to a fruitful Bible habit.',
      scriptureRefs: ['Psalm 119:105', '2 Timothy 3:16-17', 'Romans 10:17'],
      category: 'daily_life',
      difficulty: 1,
      quizOptions: [
        'It\'s not really necessary if you attend church',
        'To earn God\'s approval through religious duty',
        'It nourishes growth, renews the mind, and deepens relationship with God',
        'Only scholars and pastors need to read the Bible',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'daily_04',
      question: 'How do I deal with doubt in my faith?',
      shortAnswer:
          'Doubt is a normal part of the faith journey. Bring your honest questions to God, study the evidence, and lean on community.',
      fullAnswer:
          'Nearly every biblical hero experienced doubt: Abraham, Moses, David, John the Baptist, Thomas, even the father who cried "I believe; help my unbelief!" Doubt becomes dangerous only when it leads to isolation and suppression. Healthy doubt drives you to study deeper, ask harder questions, and build a more resilient faith. Share doubts with trusted believers. Read thoughtful Christian thinkers who have wrestled with the same questions. Remember that feelings of doubt don\'t equal absence of faith. God is big enough to handle your questions. Often the strongest faith is forged through seasons of honest wrestling.',
      scriptureRefs: ['Mark 9:24', 'Jude 1:22', 'James 1:5-6'],
      category: 'daily_life',
      difficulty: 2,
      quizOptions: [
        'Doubt means you\'ve lost your salvation',
        'Suppress all questions and pretend you have no doubts',
        'Bring honest questions to God, study the evidence, and lean on community',
        'Doubt is a sin that must be repented of immediately',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'daily_05',
      question: 'What does it mean to have a personal relationship with God?',
      shortAnswer:
          'A personal relationship with God means knowing Him intimately through prayer, Scripture, worship, and daily dependence — not just knowing about Him.',
      fullAnswer:
          'Christianity is unique among religions in offering a personal relationship with the Creator. God is not a distant force but a personal being who knows you, loves you, and desires to be known by you. This relationship begins with accepting Christ and being adopted as God\'s child. It grows through regular communication (prayer), learning His character (Scripture), worship, obedience, and community with other believers. Like any relationship, it requires time, honesty, and intentionality. God speaks through His Word, His Spirit, circumstances, and other believers. The goal is not religious performance but genuine intimacy with your Creator.',
      scriptureRefs: ['John 17:3', 'Jeremiah 29:13', 'Philippians 3:10'],
      category: 'daily_life',
      difficulty: 1,
      quizOptions: [
        'Attending church every Sunday',
        'Following a strict set of rules perfectly',
        'Knowing God intimately through prayer, Scripture, worship, and daily dependence',
        'Feeling emotional during worship services',
      ],
      correctOptionIndex: 2,
    ),

    // ── Morality (difficulty 1-5) ─────────────────────────────────────
    FaithQuestion(
      id: 'mor_01',
      question: 'Is morality absolute or relative?',
      shortAnswer:
          'Christianity teaches that objective moral truths exist, grounded in God\'s unchanging character — not determined by culture, feelings, or majority vote.',
      fullAnswer:
          'If morality is merely a social construct, then no culture can be truly "wrong" — making it impossible to condemn atrocities like slavery or genocide. Christianity holds that God\'s nature is the foundation of objective morality. Murder is wrong not because society says so, but because human beings bear God\'s image. This doesn\'t mean moral understanding never develops — the church has grown in its application of biblical principles (e.g., on slavery). But the foundation is fixed: God\'s character is the unchanging standard by which all moral claims are measured. Even atheists who sense moral outrage are appealing to something beyond mere preference.',
      scriptureRefs: ['Romans 2:14-15', 'Micah 6:8', 'Isaiah 5:20'],
      category: 'morality',
      difficulty: 3,
      quizOptions: [
        'Morality is entirely relative to each culture and era',
        'Morality is just personal opinion with no objective basis',
        'Objective moral truths exist, grounded in God\'s unchanging character',
        'Morality evolves through natural selection alone',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'mor_02',
      question: 'How should Christians think about forgiveness?',
      shortAnswer:
          'Forgiveness is central to Christianity: we forgive because God first forgave us. It\'s a choice to release bitterness, not a denial that wrong was done.',
      fullAnswer:
          'Jesus made forgiveness non-negotiable for His followers: "Forgive as the Lord forgave you." But forgiveness is widely misunderstood. It does not mean pretending nothing happened, excusing sin, removing consequences, or trusting an unsafe person. Forgiveness is choosing to release the debt of resentment and entrusting justice to God. It\'s a process that may take time, especially for deep wounds. Forgiveness frees the forgiver from the prison of bitterness. It does not require reconciliation — that requires the offender\'s repentance and changed behavior. Jesus forgave from the cross, modeling radical grace even toward those who harmed Him.',
      scriptureRefs: [
        'Colossians 3:13',
        'Matthew 18:21-22',
        'Luke 23:34',
      ],
      category: 'morality',
      difficulty: 2,
      quizOptions: [
        'Forgiveness means pretending nothing happened',
        'Christians should never forgive serious wrongs',
        'A choice to release bitterness; not denial of wrong, not always reconciliation',
        'Forgiveness is only necessary if the other person apologizes first',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'mor_03',
      question: 'Is it wrong to be angry?',
      shortAnswer:
          'Anger itself is not sinful — even Jesus expressed anger. Scripture warns against sinful responses to anger such as resentment, revenge, and cruelty.',
      fullAnswer:
          'Ephesians 4:26 says "Be angry and do not sin," showing anger can exist without sin. Jesus was angry at the money changers in the temple, and God\'s wrath against injustice is a theme throughout Scripture. Righteous anger responds to genuine injustice and motivates positive action. Sinful anger is self-centered, disproportionate, harbored into bitterness, or expressed destructively. The test is: what triggers my anger (injustice or inconvenience?), how do I express it (constructively or destructively?), and how long do I hold it (resolved quickly or nursed into resentment?). Anger is an emotion God gave us; stewarding it wisely is the call.',
      scriptureRefs: ['Ephesians 4:26-27', 'James 1:19-20', 'Mark 11:15-17'],
      category: 'morality',
      difficulty: 2,
      quizOptions: [
        'All anger is sinful and must be completely eliminated',
        'Anger is always justified if we feel strongly about something',
        'Anger itself isn\'t sinful; sinful responses like resentment and revenge are',
        'Christians should suppress all emotions, including anger',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'mor_04',
      question: 'What does the Bible say about justice?',
      shortAnswer:
          'The Bible calls God\'s people to actively pursue justice for the oppressed, the poor, and the vulnerable — justice is central to God\'s character.',
      fullAnswer:
          'Justice is not a peripheral topic in Scripture — it\'s mentioned over 200 times. God identifies Himself as a God of justice who defends the fatherless, the widow, and the stranger. The prophets thundered against those who oppressed the poor while performing religious rituals. Micah summarized God\'s requirements: do justice, love mercy, walk humbly with God. Jesus launched His ministry quoting Isaiah about proclaiming freedom for the oppressed. Biblical justice is not merely punitive but restorative — seeking to make things right, protect the vulnerable, and reflect God\'s heart for all people created in His image.',
      scriptureRefs: ['Micah 6:8', 'Isaiah 1:17', 'Luke 4:18-19'],
      category: 'morality',
      difficulty: 2,
      quizOptions: [
        'Justice is only about punishing wrongdoers',
        'The Bible doesn\'t address social justice at all',
        'Actively pursue justice for the oppressed, poor, and vulnerable — it\'s central to God\'s character',
        'Christians should focus only on spiritual matters, not earthly justice',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'mor_05',
      question: 'Can a Christian support the death penalty?',
      shortAnswer:
          'Christians disagree. Some cite Genesis 9:6 supporting capital punishment for murderers, while others emphasize Jesus\' teachings on mercy and redemption.',
      fullAnswer:
          'This is a topic where sincere Christians hold opposing views. Those supporting capital punishment point to Genesis 9:6 (whoever sheds human blood, by humans shall their blood be shed), Romans 13 (the state bears the sword), and the principle that justice for murder victims requires the ultimate penalty. Those opposing it emphasize Jesus\' mercy, the risk of executing innocents, the disproportionate application to marginalized communities, and the possibility of redemption. Both sides affirm the sanctity of human life — they disagree on what best upholds it. This is a matter of conscience where Christians should engage with humility and respect for differing views.',
      scriptureRefs: ['Genesis 9:6', 'Romans 13:4', 'John 8:7'],
      category: 'morality',
      difficulty: 4,
      quizOptions: [
        'The Bible clearly prohibits the death penalty in all cases',
        'All Christians must support the death penalty because of Genesis 9:6',
        'Christians disagree; both sides affirm sanctity of life with different applications',
        'Morality has nothing to say about criminal justice',
      ],
      correctOptionIndex: 2,
    ),

    // ── History (difficulty 1-5) ──────────────────────────────────────
    FaithQuestion(
      id: 'hist_01',
      question: 'How do we know the Bible is reliable?',
      shortAnswer:
          'The Bible\'s reliability is supported by manuscript evidence, archaeological discoveries, fulfilled prophecy, internal consistency, and its transformative impact.',
      fullAnswer:
          'The New Testament has over 5,800 Greek manuscripts — far more than any other ancient text. The Dead Sea Scrolls confirmed the Old Testament was transmitted with remarkable accuracy over a millennium. Archaeology has repeatedly confirmed biblical places, people, and events. The Bible was written by over 40 authors across 1,500 years yet maintains a coherent narrative. Hundreds of specific prophecies about Jesus were written centuries before His birth. While no ancient text can be "proven" with mathematical certainty, the Bible has more supporting evidence than any comparable document from antiquity.',
      scriptureRefs: ['2 Timothy 3:16', '2 Peter 1:21', 'Isaiah 40:8'],
      category: 'history',
      difficulty: 2,
      quizOptions: [
        'We can\'t know — it\'s entirely a matter of blind faith',
        'Manuscript evidence, archaeology, fulfilled prophecy, and internal consistency',
        'Because the church declared it reliable',
        'The Bible was written recently and has no ancient evidence',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'hist_02',
      question: 'What happened in the early church?',
      shortAnswer:
          'After Pentecost, the early church grew rapidly through apostolic preaching, communal living, miracles, and the bold witness of believers — often under persecution.',
      fullAnswer:
          'The early church began at Pentecost when the Holy Spirit empowered the apostles. The book of Acts records explosive growth: 3,000 saved in one day, communal sharing, bold preaching, healings, and the spread of the gospel from Jerusalem to Rome. Early Christians faced persecution from both Jewish authorities and the Roman Empire. Despite this, the church grew because of (not in spite of) persecution. The apostles established churches, wrote letters addressing theology and practice, appointed leaders, and eventually laid down their lives for their faith. By 313 AD, Christianity went from a persecuted minority to a recognized religion under Constantine.',
      scriptureRefs: ['Acts 2:42-47', 'Acts 1:8', 'Acts 4:32-35'],
      category: 'history',
      difficulty: 1,
      quizOptions: [
        'Christianity spread slowly and peacefully without opposition',
        'The church grew rapidly through preaching, community, miracles, and bold witness under persecution',
        'The early church was a political movement, not a spiritual one',
        'Christianity didn\'t exist until Constantine invented it',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'hist_03',
      question: 'Was Jesus a real historical person?',
      shortAnswer:
          'Yes. Virtually all historians, including non-Christians, affirm that Jesus of Nazareth was a real person who lived in first-century Palestine.',
      fullAnswer:
          'The historical existence of Jesus is one of the most well-attested facts of antiquity. Beyond the New Testament (27 documents), Jesus is mentioned by Jewish historian Josephus, Roman historians Tacitus and Pliny the Younger, the Babylonian Talmud, and other ancient sources. The criterion of embarrassment (the gospels include material that would embarrass the early church), multiple independent attestation, and the explosion of a movement within years of His death all point to a real historical figure. The scholarly consensus — shared by secular historians — is that Jesus existed, was baptized by John, and was crucified under Pontius Pilate.',
      scriptureRefs: ['Luke 3:1-2', '1 Corinthians 15:3-8', 'John 1:14'],
      category: 'history',
      difficulty: 1,
      quizOptions: [
        'No, Jesus was a myth invented centuries later',
        'There is no evidence outside the Bible for Jesus\' existence',
        'Yes, virtually all historians affirm Jesus was a real historical person',
        'We cannot know anything about historical figures from that era',
      ],
      correctOptionIndex: 2,
    ),
    FaithQuestion(
      id: 'hist_04',
      question: 'How was the Bible put together?',
      shortAnswer:
          'The biblical canon developed over centuries through a process of recognition — the church identified which books were already authoritative, not by arbitrary selection.',
      fullAnswer:
          'The Old Testament canon was largely settled before Jesus\' time — He and the apostles quoted from these books as authoritative Scripture. The New Testament books were recognized by their apostolic authorship or connection, consistency with apostolic teaching, widespread use in churches, and spiritual power. The church councils of the 4th century (Hippo 393, Carthage 397) did not "choose" the books by vote — they formally recognized what churches had already been using for centuries. The process was one of recognition, not invention. Books like the Gnostic gospels were rejected because they were written much later and contradicted apostolic teaching.',
      scriptureRefs: ['2 Peter 3:15-16', 'Luke 24:44', '1 Timothy 5:18'],
      category: 'history',
      difficulty: 3,
      quizOptions: [
        'A single person chose which books to include based on personal preference',
        'The church recognized which books were already authoritative through apostolic connection and widespread use',
        'The Bible fell from heaven as a complete book',
        'Constantine personally selected all the books at the Council of Nicaea',
      ],
      correctOptionIndex: 1,
    ),
    FaithQuestion(
      id: 'hist_05',
      question: 'Did the Crusades represent true Christianity?',
      shortAnswer:
          'The Crusades were a complex historical phenomenon mixing political, economic, and religious motives. They often contradicted Jesus\' teachings on love and peace.',
      fullAnswer:
          'The Crusades (1096-1291) are a painful chapter in church history. While some participants had genuine religious motives (defending pilgrims, recovering holy sites), the Crusades were deeply entangled with political power, land acquisition, and papal authority. Atrocities committed by Crusaders contradicted Jesus\' teachings to love enemies and turn the other cheek. The Fourth Crusade even attacked fellow Christians in Constantinople. Honest Christians acknowledge these failures rather than defending them. The Crusades remind us that claiming to act in God\'s name does not guarantee alignment with God\'s character. Jesus\' kingdom is not advanced by the sword.',
      scriptureRefs: [
        'Matthew 5:44',
        'Matthew 26:52',
        'John 18:36',
      ],
      category: 'history',
      difficulty: 4,
      quizOptions: [
        'Yes, the Crusades perfectly reflected Jesus\' teachings',
        'The Crusades never happened — they are historical fiction',
        'A complex mix of motives that often contradicted Jesus\' teachings on love and peace',
        'The Crusades were purely political with no religious element',
      ],
      correctOptionIndex: 2,
    ),
  ];
}
