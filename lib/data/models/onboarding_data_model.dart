class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingData {
  static List<OnboardingPage> pages = [
    OnboardingPage(
      title: "Let's answer a few questions before we start to focus!",
      description: "",
      imagePath: "assets/onboarding/intro.png",
    ),
    OnboardingPage(
      title: "No worries — block every distraction with Regain and get in the flow.",
      description: "YouTube Shorts are Blocked\nWebsites are Blocked",
      imagePath: "assets/onboarding/blocking.png",
    ),
    OnboardingPage(
      title: "Join a focus group on Regain and Study smarter, together.",
      description: "",
      imagePath: "assets/onboarding/groups.png",
    ),
  ];
}