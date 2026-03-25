class CareerAlignment {
  final String archetypeId;
  final List<SpiritualGift> spiritualGifts;
  final List<CareerPath> suggestedPaths;
  final String callingStatement;
  final List<String> nextSteps;
  final List<String> resources;

  const CareerAlignment({
    required this.archetypeId,
    required this.spiritualGifts,
    required this.suggestedPaths,
    required this.callingStatement,
    required this.nextSteps,
    required this.resources,
  });

  factory CareerAlignment.fromJson(Map<String, dynamic> json) {
    return CareerAlignment(
      archetypeId: json['archetypeId'] as String,
      spiritualGifts: (json['spiritualGifts'] as List)
          .map((e) => SpiritualGift.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestedPaths: (json['suggestedPaths'] as List)
          .map((e) => CareerPath.fromJson(e as Map<String, dynamic>))
          .toList(),
      callingStatement: json['callingStatement'] as String,
      nextSteps: List<String>.from(json['nextSteps'] as List),
      resources: List<String>.from(json['resources'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'archetypeId': archetypeId,
      'spiritualGifts': spiritualGifts.map((e) => e.toJson()).toList(),
      'suggestedPaths': suggestedPaths.map((e) => e.toJson()).toList(),
      'callingStatement': callingStatement,
      'nextSteps': nextSteps,
      'resources': resources,
    };
  }
}

class SpiritualGift {
  final String name;
  final String description;
  final double strength;
  final String biblicalExample;

  const SpiritualGift({
    required this.name,
    required this.description,
    required this.strength,
    required this.biblicalExample,
  });

  factory SpiritualGift.fromJson(Map<String, dynamic> json) {
    return SpiritualGift(
      name: json['name'] as String,
      description: json['description'] as String,
      strength: (json['strength'] as num).toDouble(),
      biblicalExample: json['biblicalExample'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'strength': strength,
      'biblicalExample': biblicalExample,
    };
  }
}

class CareerPath {
  final String title;
  final String description;
  final List<String> alignedGifts;
  final String whyItFits;

  const CareerPath({
    required this.title,
    required this.description,
    required this.alignedGifts,
    required this.whyItFits,
  });

  factory CareerPath.fromJson(Map<String, dynamic> json) {
    return CareerPath(
      title: json['title'] as String,
      description: json['description'] as String,
      alignedGifts: List<String>.from(json['alignedGifts'] as List),
      whyItFits: json['whyItFits'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'alignedGifts': alignedGifts,
      'whyItFits': whyItFits,
    };
  }
}
