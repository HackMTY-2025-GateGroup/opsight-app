//
//  SplashScreenView.swift
//  Opsight
//
//  Created by Claude on 25/10/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            // Solid background - professional blue
            Color(red: 0.1, green: 0.2, blue: 0.4)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // AI Vision Logo
                ZStack {
                    // Outer scanning ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)


                    // Inner circle - solid background
                    Circle()
                        .fill(Color(red: 0.15, green: 0.25, blue: 0.45))
                        .frame(width: 130, height: 130)

                    // AI Vision icon - camera with sparkle
                    ZStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.white)

                        // AI sparkle overlay
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.cyan)
                            .offset(x: 25, y: -25)
                            .opacity(isAnimating ? 1.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                }
                .opacity(opacity)

                VStack(spacing: 12) {
                    // App name
                    Text("Opsight")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(opacity)

                    // Separator line
                    Rectangle()
                        .fill(Color.cyan)
                        .frame(width: 60, height: 3)
                        .cornerRadius(1.5)
                        .opacity(opacity)

                    // Tagline
                    Text("A Gategroup AI solution")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
            withAnimation {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opsight - A Gategroup AI solution powered by Vision AI - Loading")
    }
}

#Preview {
    SplashScreenView()
}
