//
//  CelebrationView.swift
//  Dynocards
//
//  Created by User on 2024
//

import SwiftUI

struct CelebrationView: View {
    let message: String
    @State private var animationScale: CGFloat = 0.5
    @State private var animationRotation: Double = 0
    @State private var showConfetti = false
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            // Confetti particles
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            VStack(spacing: 20) {
                // Animated icon
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animationScale)
                        .opacity(showConfetti ? 0.8 : 0)
                    
                    // Middle glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.4),
                                    Color.orange.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animationScale * 0.9)
                        .opacity(showConfetti ? 0.9 : 0)
                    
                    // Main icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // Icons
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                                .rotationEffect(.degrees(animationRotation))
                            
                            Image(systemName: "trophy.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                                .rotationEffect(.degrees(-animationRotation * 0.7))
                            
                            Image(systemName: "crown.fill")
                                .font(.title)
                                .foregroundColor(.purple)
                                .rotationEffect(.degrees(animationRotation * 0.5))
                        }
                    }
                    .scaleEffect(animationScale)
                }
                
                // Message
                Text(message)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(animationScale > 0.8 ? 1 : 0)
            }
        }
        .onAppear {
            generateParticles()
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Scale animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            animationScale = 1.0
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationRotation = 360
        }
        
        // Confetti delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showConfetti = true
            }
            
            // Animate particles
            animateParticles()
        }
    }
    
    private func generateParticles() {
        let centerX: CGFloat = 150
        let centerY: CGFloat = 150
        particles = (0..<30).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: centerX,
                    y: centerY
                ),
                color: [Color.red, Color.blue, Color.green, Color.yellow, Color.orange, Color.purple, Color.pink].randomElement() ?? .blue,
                size: CGFloat.random(in: 4...8),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        let centerX: CGFloat = 150
        let centerY: CGFloat = 150
        for index in particles.indices {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...120)
            let finalX = centerX + cos(angle) * distance
            let finalY = centerY + sin(angle) * distance
            
            withAnimation(.easeOut(duration: Double.random(in: 1.0...2.0))) {
                particles[index].position = CGPoint(x: finalX, y: finalY)
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    CelebrationView(message: "Amazing work! 🎉")
        .frame(width: 300, height: 400)
}

