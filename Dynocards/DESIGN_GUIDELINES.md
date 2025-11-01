# iOS App Design Guidelines

## 🎯 **Page Layout Guidelines**

### **1. Tab Bar Safety**
**Problem**: Content getting hidden behind tab bar
**Solution**: Always add safe area spacer at the bottom

```swift
VStack(spacing: 0) {
    // Your content here
    
    // Safe area spacer for tab bar
    Color.clear
        .frame(height: 83) // Standard tab bar height + safe area
}
```

### **2. Navigation Bar Safety**
**Problem**: Content overlapping with navigation bar
**Solution**: Use proper navigation bar configuration

```swift
.navigationBarHidden(true) // For custom headers
// OR
.navigationBarTitleDisplayMode(.inline) // For standard headers
```

### **3. Safe Area Handling**
**Problem**: Content in safe areas (notch, home indicator)
**Solution**: Use GeometryReader or safe area insets

```swift
GeometryReader { geometry in
    VStack {
        // Content
    }
    .padding(.top, geometry.safeAreaInsets.top)
    .padding(.bottom, geometry.safeAreaInsets.bottom)
}
```

## 📱 **Layout Structure**

### **Standard Page Structure**
```swift
var body: some View {
    GeometryReader { geometry in
        VStack(spacing: 0) {
            // 1. Header Section
            headerSection
            
            // 2. Content Section
            ScrollView {
                VStack(spacing: 20) {
                    // Content cards/sections
                }
                .padding(.horizontal, 20)
            }
            
            // 3. Action Buttons (if any)
            actionButtonsSection
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            // 4. Safe Area Spacer
            Color.clear
                .frame(height: 83) // Tab bar height
        }
    }
    .background(backgroundGradient)
}
```

### **Modal/Full Screen Structure**
```swift
var body: some View {
    VStack(spacing: 0) {
        // 1. Custom Header
        customHeader
        
        // 2. Content
        contentSection
        
        // 3. Action Buttons
        actionButtons
    }
    .background(Color(.systemBackground))
}
```

## 🎨 **Component Guidelines**

### **Card Design**
```swift
VStack(spacing: 16) {
    // Card content
}
.padding(20)
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
)
```

### **Button Design**
```swift
Button(action: { /* action */ }) {
    HStack(spacing: 12) {
        Image(systemName: "icon.name")
            .font(.title3)
        
        Text("Button Text")
            .font(.headline)
            .fontWeight(.semibold)
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 18)
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .cornerRadius(16)
    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
}
```

### **Progress Indicators**
```swift
GeometryReader { geometry in
    ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGray5))
            .frame(height: 8)
        
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [.green, .mint],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: geometry.size.width * progress, height: 8)
            .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
.frame(height: 8)
```

## 📏 **Spacing Standards**

### **Padding Values**
- **Horizontal**: 20px (standard)
- **Vertical**: 16px (standard)
- **Card padding**: 20px
- **Button padding**: 18px vertical, 16px horizontal
- **Section spacing**: 20px

### **Corner Radius**
- **Cards**: 16px
- **Buttons**: 16px
- **Small elements**: 8px or 12px

### **Shadow Values**
- **Cards**: `radius: 8, x: 0, y: 4, opacity: 0.05`
- **Buttons**: `radius: 8, x: 0, y: 4, opacity: 0.3`

## 🎨 **Color Guidelines**

### **Primary Colors**
- **Blue**: `Color.blue` (primary actions)
- **Green**: `Color.green` (success, completion)
- **Orange**: `Color.orange` (warnings, premium features)
- **Red**: `Color.red` (errors, destructive actions)

### **Background Colors**
- **Primary**: `Color(.systemBackground)`
- **Secondary**: `Color(.systemGray6)`
- **Gradient**: `LinearGradient(colors: [.blue.opacity(0.03), .mint.opacity(0.02)])`

## 📱 **Device Considerations**

### **iPhone Sizes**
- **Small**: iPhone SE, mini (375pt width)
- **Medium**: iPhone 12, 13, 14 (390pt width)
- **Large**: iPhone 12 Pro Max, 13 Pro Max, 14 Pro Max (428pt width)

### **Safe Areas**
- **Top**: 47pt (notch devices), 20pt (non-notch)
- **Bottom**: 34pt (home indicator), 0pt (home button)
- **Tab Bar**: 49pt + 34pt safe area = 83pt total

## ⚠️ **Common Mistakes to Avoid**

### **1. Tab Bar Overlap**
❌ **Wrong**: Adding padding to content
✅ **Correct**: Adding spacer at bottom of VStack

### **2. Navigation Bar Issues**
❌ **Wrong**: Ignoring navigation bar height
✅ **Correct**: Using proper navigation configuration

### **3. Safe Area Problems**
❌ **Wrong**: Content in safe areas
✅ **Correct**: Using GeometryReader or safe area insets

### **4. Scroll View Issues**
❌ **Wrong**: ScrollView without proper padding
✅ **Correct**: Padding inside ScrollView content

### **5. Button Positioning**
❌ **Wrong**: Buttons at bottom without safe area consideration
✅ **Correct**: Proper spacing and safe area handling

## 🔧 **Debugging Tips**

### **Layout Debugging**
```swift
// Add this to see layout bounds
.background(Color.red.opacity(0.3))
.border(Color.blue, width: 2)
```

### **Safe Area Debugging**
```swift
// Show safe area insets
.onAppear {
    print("Safe area top: \(geometry.safeAreaInsets.top)")
    print("Safe area bottom: \(geometry.safeAreaInsets.bottom)")
}
```

## 📋 **Checklist for New Pages**

- [ ] Tab bar safe area spacer added
- [ ] Navigation bar properly configured
- [ ] Safe areas handled
- [ ] Proper padding and spacing
- [ ] Responsive design for different screen sizes
- [ ] Accessibility considerations
- [ ] Dark mode compatibility
- [ ] Loading states handled
- [ ] Error states handled
- [ ] Empty states handled

---

**Remember**: Always test on different device sizes and orientations! 