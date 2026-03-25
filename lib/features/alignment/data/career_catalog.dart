import '../domain/models/career_alignment.dart';

/// Career alignment data mapping spiritual archetypes to career paths.
class CareerCatalog {
  const CareerCatalog._();

  static CareerAlignment? forArchetype(String archetypeId) {
    return _alignments[archetypeId];
  }

  static const Map<String, CareerAlignment> _alignments = {
    'Artisan': CareerAlignment(
      archetypeId: 'Artisan',
      spiritualGifts: [
        SpiritualGift(name: 'Creative Expression', description: 'The ability to bring beauty and truth to life through art, music, writing, or design.', strength: 0.9, biblicalExample: 'Bezalel was filled with the Spirit to craft the tabernacle (Exodus 31:1-5).'),
        SpiritualGift(name: 'Prophetic Imagination', description: 'Seeing and expressing spiritual realities through creative mediums.', strength: 0.75, biblicalExample: 'David expressed deep spiritual truths through the Psalms.'),
        SpiritualGift(name: 'Innovation', description: 'The gift of finding new ways to communicate timeless truths.', strength: 0.7, biblicalExample: 'Jesus used parables: everyday stories carrying eternal truths.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Creative Arts', description: 'Music, visual arts, filmmaking, or worship leadership.', alignedGifts: ['Creative Expression', 'Prophetic Imagination'], whyItFits: 'Your ability to see beauty and truth uniquely equips you to create works that move hearts.'),
        CareerPath(title: 'Design and Architecture', description: 'Graphic design, interior design, UX/UI, or architectural work.', alignedGifts: ['Creative Expression', 'Innovation'], whyItFits: 'You naturally create spaces and experiences that reflect divine order and beauty.'),
        CareerPath(title: 'Writing and Communication', description: 'Journalism, content creation, authorship, or scriptwriting.', alignedGifts: ['Prophetic Imagination', 'Innovation'], whyItFits: 'Your words carry weight and your stories carry truth that transforms.'),
        CareerPath(title: 'Education through Arts', description: 'Teaching art, music, creative writing, or mentoring young artists.', alignedGifts: ['Creative Expression'], whyItFits: 'Your creativity multiplies when you pour it into the next generation.'),
      ],
      callingStatement: 'You are called to reveal the beauty of God through creative expression, awakening hearts to truth through art, story, and innovation.',
      nextSteps: [
        'Identify your primary creative medium and dedicate time to mastering it.',
        'Find ways to use your creativity in your local church or community.',
        'Study how great artists throughout history have expressed faith through their work.',
        'Create a portfolio of faith-inspired work.',
      ],
      resources: [
        'Walking on Water by Madeleine L\'Engle',
        'Art and the Bible by Francis Schaeffer',
        'Imagine: A Vision for Christians in the Arts by Steve Turner',
      ],
    ),

    'Watchman': CareerAlignment(
      archetypeId: 'Watchman',
      spiritualGifts: [
        SpiritualGift(name: 'Discernment', description: 'The ability to perceive spiritual realities and distinguish truth from deception.', strength: 0.9, biblicalExample: 'Nehemiah discerned the plots of his enemies and protected the people.'),
        SpiritualGift(name: 'Intercession', description: 'Standing in the gap through prayer for others and situations.', strength: 0.8, biblicalExample: 'Nehemiah\'s first response to crisis was always prayer.'),
        SpiritualGift(name: 'Protection', description: 'A drive to guard and protect what God has entrusted.', strength: 0.85, biblicalExample: 'The watchmen on the walls of Jerusalem kept vigil day and night.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Law and Justice', description: 'Legal practice, law enforcement, advocacy, or policy work.', alignedGifts: ['Discernment', 'Protection'], whyItFits: 'Your sense of justice and protection naturally translates to defending the vulnerable.'),
        CareerPath(title: 'Cybersecurity and Risk Management', description: 'Protecting digital assets, assessing threats, and managing risk.', alignedGifts: ['Discernment', 'Protection'], whyItFits: 'Your watchful nature and attention to threats make you ideal for safeguarding systems.'),
        CareerPath(title: 'Ministry and Pastoral Care', description: 'Church leadership, pastoral counseling, or intercessory ministry.', alignedGifts: ['Intercession', 'Discernment'], whyItFits: 'Your spiritual sensitivity helps protect and shepherd God\'s people.'),
        CareerPath(title: 'Investigative Work', description: 'Journalism, research, auditing, or quality assurance.', alignedGifts: ['Discernment'], whyItFits: 'Your ability to see what others miss makes you an exceptional investigator.'),
      ],
      callingStatement: 'You are called to stand watch over what God values, using your discernment and courage to protect truth and guard the vulnerable.',
      nextSteps: [
        'Develop your prayer life as the foundation of your watchman calling.',
        'Study the areas where your protection instincts are strongest.',
        'Find a community that values your discernment and prophetic voice.',
        'Learn to balance vigilance with rest and trust in God.',
      ],
      resources: [
        'The Intercessors by Rees Howells',
        'Watchman Nee: A Seer of the Divine Revelation',
        'Spiritual Discernment by Tim Challies',
      ],
    ),

    'Cultivator': CareerAlignment(
      archetypeId: 'Cultivator',
      spiritualGifts: [
        SpiritualGift(name: 'Nurture', description: 'The ability to see hidden potential in people and help them grow.', strength: 0.9, biblicalExample: 'Joseph stewarded Egypt\'s resources during famine, nurturing an entire nation.'),
        SpiritualGift(name: 'Patience', description: 'The gift of investing long-term without needing immediate results.', strength: 0.85, biblicalExample: 'The farmer plants seeds and waits faithfully for the harvest (James 5:7).'),
        SpiritualGift(name: 'Stewardship', description: 'Faithfully managing and multiplying what has been entrusted to you.', strength: 0.8, biblicalExample: 'The Parable of the Talents: the faithful servants multiplied what they received.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Education and Teaching', description: 'Classroom teaching, tutoring, curriculum design, or training.', alignedGifts: ['Nurture', 'Patience'], whyItFits: 'Your ability to see potential and patiently develop it makes you an exceptional educator.'),
        CareerPath(title: 'Healthcare and Counseling', description: 'Nursing, therapy, counseling, or wellness coaching.', alignedGifts: ['Nurture', 'Patience'], whyItFits: 'Your caring nature and long-term perspective bring healing to others.'),
        CareerPath(title: 'Agriculture and Environmental Work', description: 'Farming, sustainability, environmental science, or conservation.', alignedGifts: ['Stewardship', 'Patience'], whyItFits: 'Cultivating the earth reflects God\'s original mandate and your natural gifting.'),
        CareerPath(title: 'Project Management', description: 'Managing long-term projects and developing teams over time.', alignedGifts: ['Stewardship', 'Nurture'], whyItFits: 'Your ability to manage processes and develop people makes projects thrive.'),
      ],
      callingStatement: 'You are called to cultivate growth wherever God plants you, patiently nurturing people, projects, and places toward their full potential.',
      nextSteps: [
        'Identify what you are currently cultivating and whether it aligns with your calling.',
        'Invest in developing your coaching and mentoring skills.',
        'Practice patience as a spiritual discipline.',
        'Find the "soil" where your cultivation gifts are most needed.',
      ],
      resources: [
        'The Master Gardener by John Ortberg',
        'Spiritual Disciplines for the Christian Life by Donald Whitney',
        'The Patient Ferment of the Early Church by Alan Kreider',
      ],
    ),

    'Sower': CareerAlignment(
      archetypeId: 'Sower',
      spiritualGifts: [
        SpiritualGift(name: 'Evangelism', description: 'A passion to share the good news and start new things.', strength: 0.9, biblicalExample: 'Paul planted churches across the Roman Empire, always moving to new territory.'),
        SpiritualGift(name: 'Faith', description: 'The ability to step out boldly without full clarity, trusting God for outcomes.', strength: 0.85, biblicalExample: 'Abraham left his homeland not knowing where he was going (Hebrews 11:8).'),
        SpiritualGift(name: 'Inspiration', description: 'Igniting vision and passion in others to join God\'s mission.', strength: 0.8, biblicalExample: 'Nehemiah inspired a broken people to rebuild the walls in 52 days.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Entrepreneurship', description: 'Starting businesses, ministries, or social enterprises.', alignedGifts: ['Faith', 'Inspiration'], whyItFits: 'Your boldness and vision make you a natural founder and initiator.'),
        CareerPath(title: 'Missions and Church Planting', description: 'Cross-cultural missions, church planting, or parachurch ministry.', alignedGifts: ['Evangelism', 'Faith'], whyItFits: 'You thrive in pioneering new work where no one has gone before.'),
        CareerPath(title: 'Sales and Marketing', description: 'Business development, marketing, or brand evangelism.', alignedGifts: ['Evangelism', 'Inspiration'], whyItFits: 'Your ability to cast vision and inspire action translates powerfully in marketplace contexts.'),
        CareerPath(title: 'Innovation and R&D', description: 'Research, product development, or emerging technology.', alignedGifts: ['Faith', 'Inspiration'], whyItFits: 'Your comfort with the unknown and passion for new possibilities fuel innovation.'),
      ],
      callingStatement: 'You are called to scatter seeds of faith and vision into new ground, trusting God for the harvest as you boldly go where He sends you.',
      nextSteps: [
        'Identify the "field" God is calling you to sow into.',
        'Build relationships with people who can water what you plant.',
        'Develop resilience for the seasons when seeds seem not to grow.',
        'Practice discerning divine timing for your initiatives.',
      ],
      resources: [
        'The Art of the Start by Guy Kawasaki',
        'Church Planter by Darrin Patrick',
        'Let My People Go Surfing by Yvon Chouinard',
      ],
    ),

    'Welcomer': CareerAlignment(
      archetypeId: 'Welcomer',
      spiritualGifts: [
        SpiritualGift(name: 'Hospitality', description: 'Creating warm, safe spaces where people feel valued and loved.', strength: 0.9, biblicalExample: 'Lydia opened her home to Paul and his companions, becoming a pillar of the early church.'),
        SpiritualGift(name: 'Generosity', description: 'Giving freely of time, resources, and attention to bless others.', strength: 0.85, biblicalExample: 'The widow\'s offering showed that generosity is about the heart, not the amount.'),
        SpiritualGift(name: 'Atmosphere Setting', description: 'The ability to create environments where God\'s work can flourish.', strength: 0.8, biblicalExample: 'The upper room was a space of hospitality where the Holy Spirit fell at Pentecost.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Hospitality Industry', description: 'Hotel management, event planning, restaurant ownership, or tourism.', alignedGifts: ['Hospitality', 'Atmosphere Setting'], whyItFits: 'Your gift for making people feel welcome translates directly into hospitality work.'),
        CareerPath(title: 'Community Development', description: 'Social work, nonprofit management, or community organizing.', alignedGifts: ['Hospitality', 'Generosity'], whyItFits: 'Your warmth and generosity build thriving communities.'),
        CareerPath(title: 'Human Resources', description: 'HR management, employee experience, or workplace culture.', alignedGifts: ['Hospitality', 'Atmosphere Setting'], whyItFits: 'You naturally create environments where people feel valued and can do their best work.'),
        CareerPath(title: 'Children and Family Ministry', description: 'Children\'s ministry, family counseling, or youth work.', alignedGifts: ['Hospitality', 'Generosity'], whyItFits: 'Families and children thrive in the safe, warm spaces you create.'),
      ],
      callingStatement: 'You are called to open doors, set tables, and create spaces where every person feels seen, valued, and invited into God\'s family.',
      nextSteps: [
        'Open your home or space regularly for fellowship.',
        'Study the biblical theology of hospitality.',
        'Learn to balance hosting others with caring for yourself.',
        'Explore how your hospitality gifts can serve your workplace or community.',
      ],
      resources: [
        'The Gospel Comes with a House Key by Rosaria Butterfield',
        'Making Room by Christine Pohl',
        'A Meal with Jesus by Tim Chester',
      ],
    ),

    'Pillar': CareerAlignment(
      archetypeId: 'Pillar',
      spiritualGifts: [
        SpiritualGift(name: 'Helps', description: 'Faithfully supporting others and their callings behind the scenes.', strength: 0.9, biblicalExample: 'Barnabas came alongside Paul, providing encouragement and support at every turn.'),
        SpiritualGift(name: 'Perseverance', description: 'Remaining faithful and steady when others give up.', strength: 0.85, biblicalExample: 'Ruth\'s loyalty to Naomi through poverty and loss is a picture of steadfast love.'),
        SpiritualGift(name: 'Encouragement', description: 'Building others up with words and actions that strengthen faith.', strength: 0.8, biblicalExample: 'Barnabas was called "Son of Encouragement" (Acts 4:36).'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Administration and Operations', description: 'Office management, operations, or executive assistance.', alignedGifts: ['Helps', 'Perseverance'], whyItFits: 'Your reliability and supportive nature keep organizations running smoothly.'),
        CareerPath(title: 'Healthcare Support', description: 'Nursing, caregiving, physical therapy, or medical administration.', alignedGifts: ['Helps', 'Encouragement'], whyItFits: 'Your steady presence and encouragement bring comfort to those in need.'),
        CareerPath(title: 'Teaching and Mentoring', description: 'Teaching, coaching, or mentoring in any field.', alignedGifts: ['Encouragement', 'Perseverance'], whyItFits: 'Your patience and belief in others helps them reach their potential.'),
        CareerPath(title: 'Nonprofit and Ministry Support', description: 'Church administration, missions support, or ministry coordination.', alignedGifts: ['Helps', 'Encouragement'], whyItFits: 'Your faithfulness in the background enables frontline workers to thrive.'),
      ],
      callingStatement: 'You are called to be a steadfast foundation for others, faithfully supporting God\'s work and strengthening those around you with quiet, persistent love.',
      nextSteps: [
        'Recognize that your behind-the-scenes work is deeply valued by God.',
        'Find leaders and visions worth supporting with your faithfulness.',
        'Develop boundaries so your supportive nature does not lead to burnout.',
        'Celebrate your unique role: pillars hold up the entire structure.',
      ],
      resources: [
        'The Encouragement Factor by Tom Rath',
        'Strengthsfinder 2.0 by Tom Rath',
        'Faithful Presence by David Fitch',
      ],
    ),

    'Sentinel': CareerAlignment(
      archetypeId: 'Sentinel',
      spiritualGifts: [
        SpiritualGift(name: 'Spiritual Sensitivity', description: 'An acute awareness of spiritual realities and dynamics.', strength: 0.9, biblicalExample: 'Daniel was given understanding of visions and dreams (Daniel 1:17).'),
        SpiritualGift(name: 'Prayer Authority', description: 'Powerful, effective intercession that shifts spiritual atmospheres.', strength: 0.85, biblicalExample: 'Elijah prayed and fire fell from heaven; he prayed again and rain came (1 Kings 18).'),
        SpiritualGift(name: 'Discernment', description: 'The ability to perceive what is hidden and see beyond the surface.', strength: 0.8, biblicalExample: 'Elisha saw the angelic armies when his servant saw only the enemy (2 Kings 6:17).'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Counseling and Spiritual Direction', description: 'Pastoral counseling, spiritual direction, or life coaching.', alignedGifts: ['Spiritual Sensitivity', 'Discernment'], whyItFits: 'Your ability to perceive the deeper issues equips you to guide others wisely.'),
        CareerPath(title: 'Research and Analysis', description: 'Academic research, data analysis, strategic consulting, or intelligence work.', alignedGifts: ['Discernment', 'Spiritual Sensitivity'], whyItFits: 'Your observational skills and depth of perception make you an excellent analyst.'),
        CareerPath(title: 'Prayer Ministry', description: 'Intercessory prayer leadership, retreat facilitation, or contemplative ministry.', alignedGifts: ['Prayer Authority', 'Spiritual Sensitivity'], whyItFits: 'Your prayer life is your greatest ministry tool.'),
        CareerPath(title: 'Writing and Theology', description: 'Theological writing, academic teaching, or devotional content creation.', alignedGifts: ['Spiritual Sensitivity', 'Discernment'], whyItFits: 'Your insights into spiritual realities translate into powerful written works.'),
      ],
      callingStatement: 'You are called to watch, pray, and perceive what others cannot, serving as a spiritual early-warning system and a conduit of God\'s deeper revelation.',
      nextSteps: [
        'Develop a consistent, deep prayer practice.',
        'Learn to steward your sensitivity without becoming isolated.',
        'Share your insights with trusted leaders who value your perception.',
        'Study the prophetic tradition in Scripture and church history.',
      ],
      resources: [
        'The Practice of the Presence of God by Brother Lawrence',
        'Celebration of Discipline by Richard Foster',
        'The Contemplative Pastor by Eugene Peterson',
      ],
    ),

    'Bridgebuilder': CareerAlignment(
      archetypeId: 'Bridgebuilder',
      spiritualGifts: [
        SpiritualGift(name: 'Peacemaking', description: 'The ability to reconcile opposing parties and create unity.', strength: 0.9, biblicalExample: 'Abigail prevented bloodshed by wisely mediating between David and Nabal (1 Samuel 25).'),
        SpiritualGift(name: 'Empathy', description: 'Deep understanding of others\' feelings and perspectives.', strength: 0.85, biblicalExample: 'Jesus wept at Lazarus\' tomb, entering fully into others\' grief (John 11:35).'),
        SpiritualGift(name: 'Unity Building', description: 'Bringing diverse groups together around shared purpose.', strength: 0.8, biblicalExample: 'Paul unified Jewish and Gentile believers into one body (Ephesians 2:14).'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Mediation and Conflict Resolution', description: 'Mediation, diplomacy, negotiation, or conflict resolution.', alignedGifts: ['Peacemaking', 'Empathy'], whyItFits: 'Your natural ability to see both sides and build bridges is rare and deeply needed.'),
        CareerPath(title: 'Cross-Cultural Ministry', description: 'Missions, multicultural church leadership, or interfaith dialogue.', alignedGifts: ['Unity Building', 'Empathy'], whyItFits: 'You thrive in bringing diverse people together under Christ.'),
        CareerPath(title: 'Human Resources and Organizational Development', description: 'HR leadership, team building, or organizational consulting.', alignedGifts: ['Peacemaking', 'Unity Building'], whyItFits: 'Your peacemaking and empathy transform workplace cultures.'),
        CareerPath(title: 'Social Work and Community Building', description: 'Social services, community development, or nonprofit leadership.', alignedGifts: ['Empathy', 'Unity Building'], whyItFits: 'Your ability to connect with people and build community transforms neighborhoods.'),
      ],
      callingStatement: 'You are called to build bridges where there are walls, connecting people across divides with empathy, wisdom, and the reconciling love of Christ.',
      nextSteps: [
        'Identify divisions in your community where bridges are needed.',
        'Study conflict resolution and mediation techniques.',
        'Guard your own identity while connecting others.',
        'Practice active listening in every conversation.',
      ],
      resources: [
        'The Peacemaker by Ken Sande',
        'Disunity in Christ by Christena Cleveland',
        'Reconciling All Things by Emmanuel Katongole',
      ],
    ),

    'Healer': CareerAlignment(
      archetypeId: 'Healer',
      spiritualGifts: [
        SpiritualGift(name: 'Compassion', description: 'Deep empathy that moves you to action for those who suffer.', strength: 0.9, biblicalExample: 'Luke, the beloved physician, accompanied Paul and cared for the sick.'),
        SpiritualGift(name: 'Restorative Faith', description: 'The belief that broken things can be made whole again.', strength: 0.85, biblicalExample: 'Jesus touched lepers, healed the blind, and restored the outcast.'),
        SpiritualGift(name: 'Presence', description: 'The ability to simply be with people in their pain.', strength: 0.8, biblicalExample: 'Job\'s friends sat with him in silence for seven days (Job 2:13).'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Healthcare', description: 'Medicine, nursing, therapy, or public health.', alignedGifts: ['Compassion', 'Restorative Faith'], whyItFits: 'Your compassion and belief in restoration naturally guide you toward healing professions.'),
        CareerPath(title: 'Counseling and Psychology', description: 'Clinical counseling, psychology, or trauma recovery.', alignedGifts: ['Compassion', 'Presence'], whyItFits: 'Your presence and empathy create safe spaces for emotional healing.'),
        CareerPath(title: 'Social Services', description: 'Child welfare, addiction recovery, or crisis intervention.', alignedGifts: ['Compassion', 'Restorative Faith'], whyItFits: 'Your belief that the broken can be made whole fuels restoration work.'),
        CareerPath(title: 'Healing Ministry', description: 'Prayer ministry, inner healing, or pastoral care.', alignedGifts: ['Restorative Faith', 'Presence'], whyItFits: 'Your gifts align directly with the healing ministry of Jesus.'),
      ],
      callingStatement: 'You are called to bring healing and restoration to the broken, carrying the compassion of Christ into the deepest places of human pain.',
      nextSteps: [
        'Learn about compassion fatigue and develop sustainable self-care.',
        'Study how Jesus balanced healing with solitude.',
        'Find training in the specific type of healing you feel called to.',
        'Build a support network that sustains your calling.',
      ],
      resources: [
        'Wounded Healer by Henri Nouwen',
        'The Body Keeps the Score by Bessel van der Kolk',
        'Healing by Francis MacNutt',
      ],
    ),

    'Harvester': CareerAlignment(
      archetypeId: 'Harvester',
      spiritualGifts: [
        SpiritualGift(name: 'Effectiveness', description: 'The drive and ability to produce tangible results.', strength: 0.9, biblicalExample: 'Boaz managed his fields effectively, providing abundantly for his workers and community.'),
        SpiritualGift(name: 'Mobilization', description: 'Rallying others to action and organizing collective effort.', strength: 0.85, biblicalExample: 'Nehemiah mobilized an entire city to rebuild the walls in record time.'),
        SpiritualGift(name: 'Celebration', description: 'The joy of bringing in the harvest and celebrating God\'s faithfulness.', strength: 0.8, biblicalExample: 'The Feast of Tabernacles celebrated God\'s provision through the harvest.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Business Leadership', description: 'CEO, COO, or executive management roles.', alignedGifts: ['Effectiveness', 'Mobilization'], whyItFits: 'Your results-orientation and ability to mobilize teams drive organizational success.'),
        CareerPath(title: 'Evangelism and Outreach', description: 'Evangelistic ministry, outreach coordination, or missions leadership.', alignedGifts: ['Mobilization', 'Celebration'], whyItFits: 'Your joy in gathering people and producing results fuels kingdom expansion.'),
        CareerPath(title: 'Fundraising and Development', description: 'Nonprofit fundraising, donor relations, or capital campaigns.', alignedGifts: ['Mobilization', 'Effectiveness'], whyItFits: 'Your ability to inspire generosity and produce results makes campaigns successful.'),
        CareerPath(title: 'Event Management', description: 'Conference planning, festival coordination, or large-scale events.', alignedGifts: ['Mobilization', 'Celebration'], whyItFits: 'You naturally bring people together for meaningful experiences.'),
      ],
      callingStatement: 'You are called to bring in the harvest, mobilizing others with joy and effectiveness to gather what God has been growing.',
      nextSteps: [
        'Ensure your effectiveness is driven by love, not metrics alone.',
        'Learn to celebrate others\' contributions to the harvest.',
        'Develop patience for the planting and growing seasons.',
        'Use your mobilization gift to serve causes bigger than yourself.',
      ],
      resources: [
        'Good to Great by Jim Collins',
        'Celebration of Discipline by Richard Foster',
        'Half Time by Bob Buford',
      ],
    ),

    'Reformer': CareerAlignment(
      archetypeId: 'Reformer',
      spiritualGifts: [
        SpiritualGift(name: 'Righteous Anger', description: 'A holy dissatisfaction with injustice that drives you to act.', strength: 0.9, biblicalExample: 'Moses confronted Pharaoh repeatedly, demanding justice for the enslaved.'),
        SpiritualGift(name: 'Vision for Transformation', description: 'The ability to see what could be and inspire others toward change.', strength: 0.85, biblicalExample: 'Martin Luther saw a church in need of reform and catalyzed transformation.'),
        SpiritualGift(name: 'Courage', description: 'Boldness to speak truth to power and challenge the status quo.', strength: 0.8, biblicalExample: 'Esther risked her life to advocate for her people before the king.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Advocacy and Social Justice', description: 'Human rights, social justice organizations, or policy advocacy.', alignedGifts: ['Righteous Anger', 'Courage'], whyItFits: 'Your passion for justice and courage to confront make you a powerful advocate.'),
        CareerPath(title: 'Organizational Transformation', description: 'Change management, organizational consulting, or turnaround leadership.', alignedGifts: ['Vision for Transformation', 'Courage'], whyItFits: 'Your ability to see what needs changing and courage to act transforms organizations.'),
        CareerPath(title: 'Political Leadership', description: 'Government, public policy, or political advocacy.', alignedGifts: ['Vision for Transformation', 'Courage'], whyItFits: 'Your vision for a better society and willingness to fight for it suits public service.'),
        CareerPath(title: 'Prophetic Ministry', description: 'Teaching, preaching, or prophetic ministry in the church.', alignedGifts: ['Righteous Anger', 'Vision for Transformation'], whyItFits: 'Your boldness and vision for God\'s kingdom align with the prophetic tradition.'),
      ],
      callingStatement: 'You are called to be an agent of holy change, confronting injustice and casting vision for transformation with the courage and conviction of the biblical prophets.',
      nextSteps: [
        'Channel your passion for change through prayer first.',
        'Study how reformers throughout history balanced courage with humility.',
        'Find allies who share your vision and build a coalition.',
        'Guard against bitterness: let righteous anger lead to love, not resentment.',
      ],
      resources: [
        'Prophetic Imagination by Walter Brueggemann',
        'Just Mercy by Bryan Stevenson',
        'The Irresistible Revolution by Shane Claiborne',
      ],
    ),

    'Architect': CareerAlignment(
      archetypeId: 'Architect',
      spiritualGifts: [
        SpiritualGift(name: 'Strategic Thinking', description: 'The ability to see the big picture and design systems that work.', strength: 0.9, biblicalExample: 'Solomon designed and built the temple with extraordinary strategic planning.'),
        SpiritualGift(name: 'Integrity', description: 'A deep commitment to building on solid foundations.', strength: 0.85, biblicalExample: 'Nehemiah built with integrity, refusing to cut corners despite opposition.'),
        SpiritualGift(name: 'Multiplication', description: 'Creating structures that sustain and multiply growth.', strength: 0.8, biblicalExample: 'Paul established churches with governance structures that outlasted his presence.'),
      ],
      suggestedPaths: [
        CareerPath(title: 'Engineering and Technology', description: 'Software engineering, systems architecture, or civil engineering.', alignedGifts: ['Strategic Thinking', 'Integrity'], whyItFits: 'Your systematic thinking and commitment to solid foundations create lasting structures.'),
        CareerPath(title: 'Business Strategy', description: 'Strategic consulting, business architecture, or process design.', alignedGifts: ['Strategic Thinking', 'Multiplication'], whyItFits: 'Your ability to design scalable systems drives organizational growth.'),
        CareerPath(title: 'Church Administration', description: 'Church operations, ministry infrastructure, or denominational leadership.', alignedGifts: ['Strategic Thinking', 'Multiplication'], whyItFits: 'Your gift for creating sustainable structures strengthens the body of Christ.'),
        CareerPath(title: 'Financial Planning', description: 'Financial advising, wealth management, or institutional finance.', alignedGifts: ['Integrity', 'Strategic Thinking'], whyItFits: 'Your integrity and strategic thinking build financial security for others.'),
      ],
      callingStatement: 'You are called to build lasting structures for God\'s kingdom, combining strategic vision with unwavering integrity to create foundations that endure.',
      nextSteps: [
        'Identify the systems and structures God wants you to build.',
        'Balance structure with flexibility: leave room for the Spirit to move.',
        'Study how great builders in Scripture combined planning with faith.',
        'Mentor others in the disciplines of planning and execution.',
      ],
      resources: [
        'Built to Last by Jim Collins',
        'Spiritual Leadership by J. Oswald Sanders',
        'The E-Myth Revisited by Michael Gerber',
      ],
    ),
  };
}
