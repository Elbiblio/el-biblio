class ServiceOpportunity {
  const ServiceOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timeCommitment,
    this.contactInfo,
    this.organization,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String timeCommitment;
  final String? contactInfo;
  final String? organization;
}

final List<ServiceOpportunity> curatedServiceOpportunities = [
  ServiceOpportunity(
    id: '1',
    title: 'Help with children\'s ministry',
    description: 'Assist with Sunday school, vacation Bible school, or weekly children\'s programs at your local church.',
    category: 'Church',
    timeCommitment: '1-2 hours/week',
    organization: 'Local Church',
    contactInfo: 'Contact your church office',
  ),
  ServiceOpportunity(
    id: '2',
    title: 'Visit elderly neighbors',
    description: 'Regular visits to elderly or isolated individuals in your community to provide companionship and practical help.',
    category: 'Community',
    timeCommitment: '1 hour/week',
    organization: 'Community',
    contactInfo: 'Check with local senior centers',
  ),
  ServiceOpportunity(
    id: '3',
    title: 'Food bank volunteer',
    description: 'Sort, pack, or distribute food at a local food bank or pantry to help those in need.',
    category: 'Community',
    timeCommitment: '2-4 hours/month',
    organization: 'Food Bank',
    contactInfo: 'Search for local food banks',
  ),
  ServiceOpportunity(
    id: '4',
    title: 'Prayer team member',
    description: 'Join your church\'s prayer team to intercede for others, pray for services, and support prayer requests.',
    category: 'Church',
    timeCommitment: '1 hour/week',
    organization: 'Local Church',
    contactInfo: 'Contact your church prayer coordinator',
  ),
  ServiceOpportunity(
    id: '5',
    title: 'Mentor youth or young adults',
    description: 'Provide guidance, support, and spiritual mentorship to young people in your church or community.',
    category: 'Mentorship',
    timeCommitment: '2-3 hours/month',
    organization: 'Church or Community Organization',
    contactInfo: 'Contact youth ministry leaders',
  ),
  ServiceOpportunity(
    id: '6',
    title: 'Hospital or care facility visits',
    description: 'Visit patients in hospitals, nursing homes, or care facilities to offer encouragement and prayer.',
    category: 'Community',
    timeCommitment: '1-2 hours/month',
    organization: 'Healthcare Facility',
    contactInfo: 'Check with facility volunteer programs',
  ),
  ServiceOpportunity(
    id: '7',
    title: 'Homeless shelter support',
    description: 'Serve meals, help with donations, or provide support at a local homeless shelter.',
    category: 'Community',
    timeCommitment: '3-4 hours/month',
    organization: 'Homeless Shelter',
    contactInfo: 'Contact local shelters',
  ),
  ServiceOpportunity(
    id: '8',
    title: 'Welcome/greeter ministry',
    description: 'Greet visitors and members at church services, help newcomers feel welcome, and provide information.',
    category: 'Church',
    timeCommitment: '30 minutes/week',
    organization: 'Local Church',
    contactInfo: 'Contact your church hospitality team',
  ),
  ServiceOpportunity(
    id: '9',
    title: 'Tutor or homework help',
    description: 'Help students with homework, reading, or skills development through schools or community programs.',
    category: 'Education',
    timeCommitment: '1-2 hours/week',
    organization: 'School or Community Center',
    contactInfo: 'Contact local schools or libraries',
  ),
  ServiceOpportunity(
    id: '10',
    title: 'Disaster relief volunteer',
    description: 'Join a disaster response team to help with relief efforts after natural disasters in your area.',
    category: 'Emergency',
    timeCommitment: 'As needed',
    organization: 'Red Cross or similar',
    contactInfo: 'Red Cross or local emergency services',
  ),
  ServiceOpportunity(
    id: '11',
    title: 'Community cleanup',
    description: 'Participate in or organize neighborhood cleanup events, park maintenance, or environmental projects.',
    category: 'Community',
    timeCommitment: '4-6 hours/event',
    organization: 'Community Groups',
    contactInfo: 'Local community organizations',
  ),
  ServiceOpportunity(
    id: '12',
    title: 'Bible study small group leader',
    description: 'Lead or host a small group Bible study in your home or at church.',
    category: 'Church',
    timeCommitment: '2 hours/week + prep',
    organization: 'Local Church',
    contactInfo: 'Contact your church small groups coordinator',
  ),
];
