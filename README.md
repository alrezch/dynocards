# Dynocards - AI-Powered Flashcard Learning App

<div align="center">
  <img src="https://img.shields.io/badge/Platform-iOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-5.0-green.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/iOS-16.0+-brightgreen.svg" alt="iOS Version">
</div>

## 📱 Overview

Dynocards is a sophisticated flashcard learning application built with Swift and SwiftUI that leverages AI to automatically generate comprehensive flashcards. The app features an intelligent Leitner spaced repetition system, gamification elements, and comprehensive progress tracking.

## ✨ Features

### 🤖 AI-Powered Flashcard Generation
- **Smart Content Creation**: Enter any word and let AI generate complete flashcards
- **Comprehensive Data**: Automatic generation of definitions, translations, examples, and phonetics
- **Multi-language Support**: Support for 10+ languages including English, Spanish, French, German, Italian, Portuguese, Chinese, Japanese, Korean, and Arabic
- **Audio Pronunciation**: Text-to-speech integration for proper pronunciation learning

### 🧠 Intelligent Learning System
- **Leitner Spaced Repetition**: Scientific approach to optimize learning retention
- **5-Box System**: Cards progress through difficulty levels based on performance
- **Adaptive Scheduling**: Smart review timing based on individual performance
- **Mastery Tracking**: Automatic detection when words are fully mastered

### 🎮 Gamification & Motivation
- **Points System**: Earn points for correct answers and consistency
- **Streak Tracking**: Daily study streak counter with rewards
- **Achievement System**: Unlock achievements for various milestones
- **Progress Visualization**: Beautiful charts and statistics

### 📊 Comprehensive Dashboard
- **Learning Analytics**: Detailed statistics on learning progress
- **Performance Metrics**: Success rates, study session data, and trends
- **Goal Setting**: Customizable daily study goals
- **Progress Charts**: Visual representation of learning journey

### 🔔 Smart Notifications
- **Study Reminders**: Customizable daily study notifications
- **Due Card Alerts**: Notifications when cards are ready for review
- **Streak Reminders**: Gentle nudges to maintain study streaks

## 🏗️ Architecture

### Tech Stack
- **UI Framework**: SwiftUI
- **Data Persistence**: Core Data
- **Audio**: AVFoundation (Text-to-Speech)
- **Notifications**: UserNotifications
- **Architecture Pattern**: MVVM

### Project Structure
```
Dynocards/
├── App/
│   ├── DynocardsApp.swift          # App entry point
│   └── ContentView.swift           # Main tab navigation
├── Models/
│   ├── Flashcard.swift            # Core Data model for flashcards
│   └── User.swift                 # Core Data model for user data
├── Views/
│   ├── HomeView.swift             # Dashboard and overview
│   ├── AddWordView.swift          # AI-powered word addition
│   ├── StudyView.swift            # Study session interface
│   ├── DashboardView.swift        # Analytics and progress
│   └── SettingsView.swift         # App configuration
├── Services/
│   ├── CoreDataManager.swift      # Core Data operations
│   ├── AIService.swift            # AI integration service
│   ├── AudioService.swift         # Text-to-speech functionality
│   └── NotificationService.swift  # Notification management
├── Utils/
│   ├── Constants.swift            # App constants and configuration
│   └── Extensions.swift           # Swift extensions and utilities
└── Resources/
    ├── Info.plist                 # App configuration
    └── Dynocards.xcdatamodeld     # Core Data model
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 16.0+
- macOS 13.0+ (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/username/dynocards.git
   cd dynocards
   ```

2. **Open in Xcode**
   ```bash
   open Dynocards.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Configuration

#### AI Integration Setup
The app includes placeholder AI integration. To enable full AI functionality:

1. **OpenAI Integration** (Optional)
   - Sign up for an OpenAI API key
   - Add your API key to `AIService.swift`
   - Uncomment the API integration code

2. **Translation Services** (Optional)
   - Integrate with Google Translate API or similar
   - Update the translation logic in `AIService.swift`

#### Notification Permissions
The app will automatically request notification permissions on first launch for:
- Daily study reminders
- Due card notifications
- Streak maintenance alerts

## 🎯 Core Functionality

### Leitner Spaced Repetition System
The app implements a sophisticated 5-box Leitner system:

- **Box 1**: New cards, reviewed daily
- **Box 2**: Familiar cards, reviewed every 3 days  
- **Box 3**: Known cards, reviewed weekly
- **Box 4**: Well-known cards, reviewed bi-weekly
- **Box 5**: Mastered cards, reviewed monthly

Cards move up boxes with correct answers and drop to Box 1 with incorrect answers.

### Study Sessions
- **Progressive Disclosure**: Show word first, then reveal definition/translation
- **Multiple Choice**: Rate difficulty (Hard/Good/Easy) for optimal scheduling
- **Audio Integration**: Pronunciation practice with native TTS
- **Progress Tracking**: Real-time session statistics

### Data Management
- **Local Storage**: All data stored locally using Core Data
- **Export Functionality**: CSV export for backup/transfer
- **Privacy First**: No data sent to external servers (except AI API calls)

## 🔧 Customization

### Adding New Languages
To add support for additional languages:

1. Update `Constants.swift`:
   ```swift
   struct Languages {
       static let supported = [
           // Add new language here
           "NewLanguage"
       ]
       
       static let languageCodes: [String: String] = [
           // Add language code mapping
           "NewLanguage": "xx-XX"
       ]
   }
   ```

2. Update the language pickers in views
3. Test TTS support for the new language

### Modifying Study Algorithms
The Leitner system can be customized in `Constants.swift`:

```swift
struct LeitnerSystem {
    static let maxBox = 5  // Adjust number of boxes
    static let masteryThreshold = 0.8  // Adjust mastery threshold
    
    // Customize review intervals
    static let reviewIntervals: [Int16: Int] = [
        1: 1,    // Box 1: 1 day
        2: 3,    // Box 2: 3 days
        // Modify as needed
    ]
}
```

## 🧪 Testing

### Running Tests
```bash
# Run unit tests
xcodebuild test -scheme Dynocards -destination 'platform=iOS Simulator,name=iPhone 15'

# Run on device
xcodebuild test -scheme Dynocards -destination 'platform=iOS,name=Your Device Name'
```

### Test Coverage
The app includes tests for:
- Core Data operations
- Leitner system logic
- User progress calculations
- Notification scheduling

## 📈 Performance Considerations

### Optimization Features
- **Lazy Loading**: Views load content on-demand
- **Efficient Queries**: Optimized Core Data fetch requests
- **Memory Management**: Proper lifecycle management for services
- **Background Processing**: Non-blocking AI API calls

### Data Storage
- **Core Data**: Efficient local storage with relationships
- **Batch Operations**: Optimized for large datasets
- **Migration Support**: Seamless data model updates

## 🔒 Privacy & Security

### Data Protection
- **Local Storage**: All personal data stored locally
- **Minimal Permissions**: Only required permissions requested
- **No Analytics**: No third-party analytics or tracking
- **Transparent AI Usage**: Clear indication when AI services are used

### Permissions Used
- **Notifications**: For study reminders and due card alerts
- **Microphone**: For future speech recognition features (optional)

## 🛠️ Troubleshooting

### Common Issues

**Core Data Migration Errors**
- Delete and reinstall the app for clean data model
- Check `Dynocards.xcdatamodeld` for model conflicts

**Notification Not Working**
- Verify notification permissions in iOS Settings
- Check `NotificationService.swift` implementation
- Ensure proper scheduling in background

**TTS Not Working**
- Verify device language settings
- Check internet connection for some TTS voices
- Test with different languages

## 🚀 Future Enhancements

### Planned Features
- **iCloud Sync**: Cross-device synchronization
- **Speech Recognition**: Pronunciation practice with feedback
- **Community Features**: Shared deck marketplace
- **Advanced Analytics**: ML-powered learning insights
- **Widget Support**: Quick study access from home screen
- **Apple Watch App**: Study sessions on the go

### API Integrations
- **Enhanced AI**: GPT-4 integration for better definitions
- **Professional Audio**: High-quality pronunciation audio
- **Image Recognition**: Visual learning with pictures
- **Dictionary APIs**: Multiple definition sources

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Leitner System**: Based on Sebastian Leitner's spaced repetition research
- **SwiftUI Community**: For excellent learning resources and examples
- **iOS Development Community**: For best practices and design patterns

## 📞 Support

For support, feedback, or questions:
- **Email**: support@dynocards.com
- **Issues**: GitHub Issues page
- **Documentation**: In-app help and tutorials

---

**Made with ❤️ and Swift**

*Dynocards - Making vocabulary learning intelligent, efficient, and engaging.* 