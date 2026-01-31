import SwiftUI

// MARK: - Animation Constants

enum AnimationConstants {
    static let defaultDuration: Double = 0.3
    static let springResponse: Double = 0.4
    static let springDamping: Double = 0.7
    
    static let easeInOut = Animation.easeInOut(duration: defaultDuration)
    static let spring = Animation.spring(response: springResponse, dampingFraction: springDamping)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - View Extensions for Animations

extension View {
    func animatedScale(_ scale: CGFloat) -> some View {
        self.scaleEffect(scale)
            .animation(AnimationConstants.spring, value: scale)
    }
    
    func animatedOpacity(_ opacity: Double) -> some View {
        self.opacity(opacity)
            .animation(AnimationConstants.easeInOut, value: opacity)
    }
    
    func animatedOffset(x: CGFloat = 0, y: CGFloat = 0) -> some View {
        self.offset(x: x, y: y)
            .animation(AnimationConstants.spring, value: x)
            .animation(AnimationConstants.spring, value: y)
    }
    
    func pressableButton() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }
    
    func withLoadingOverlay(isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    func withErrorAlert(error: Binding<AppError?>) -> some View {
        self.alert(item: error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(AnimationConstants.spring, value: configuration.isPressed)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading...")
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Animated Checkmark

struct AnimatedCheckmark: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 50, height: 50)
            
            Image(systemName: "checkmark")
                .font(.title)
                .foregroundStyle(.white)
                .scaleEffect(animate ? 1 : 0)
                .rotationEffect(.degrees(animate ? 0 : -90))
        }
        .onAppear {
            withAnimation(AnimationConstants.bouncy.delay(0.1)) {
                animate = true
            }
        }
    }
}

// MARK: - Animated Number Counter

struct AnimatedNumberCounter: View {
    let value: Int
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(.title)
            .fontWeight(.bold)
            .onAppear {
                animateValue()
            }
            .onChange(of: value) { _, newValue in
                animateValue()
            }
    }
    
    private func animateValue() {
        withAnimation(AnimationConstants.easeInOut) {
            displayValue = value
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}

extension View {
    func shake(count: CGFloat) -> some View {
        self.modifier(ShakeEffect(animatableData: count))
    }
}

// MARK: - Fade Transition

extension AnyTransition {
    static var fadeAndScale: AnyTransition {
        .opacity.combined(with: .scale)
    }
    
    static var slideAndFade: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }
}

// MARK: - Card Hover Effect

struct CardHoverEffect: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.1 : 0), radius: isHovered ? 10 : 0)
            .animation(AnimationConstants.spring, value: isHovered)
            .onHover { hovered in
                isHovered = hovered
            }
    }
}

extension View {
    func cardHoverEffect() -> some View {
        self.modifier(CardHoverEffect())
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Success Animation

struct SuccessAnimation: View {
    @State private var showCircle = false
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 60, height: 60)
                .scaleEffect(showCircle ? 1 : 0)
            
            Image(systemName: "checkmark")
                .font(.title)
                .foregroundStyle(.white)
                .scaleEffect(showCheckmark ? 1 : 0)
                .rotationEffect(.degrees(showCheckmark ? 0 : -45))
        }
        .onAppear {
            withAnimation(AnimationConstants.bouncy) {
                showCircle = true
            }
            withAnimation(AnimationConstants.bouncy.delay(0.2)) {
                showCheckmark = true
            }
        }
    }
}
