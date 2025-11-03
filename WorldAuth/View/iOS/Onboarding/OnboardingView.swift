//
//  GatherOnboardingView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/06/17.
//

import SwiftUI
import AVFoundation
import FirebaseCore
import FirebaseAnalytics

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("userConsented") private var userConsented = false
    @State private var showDataConsent = false
    @State private var cameraAuthorized = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPageView] = [
        OnboardingPageView(
            imageName: "star.circle.fill",
            headline: "Welcome to WorldAuth",
            subheadline: "Introducing WorldAuth, real-world based authentication using LiDAR sensor."
        ),
        OnboardingPageView(
            imageName: "house.circle.fill",
            headline: "How to Scan an Environment",
            subheadline: "Scan your room partially, not farther than 2 meters from your phone."
        ),
        OnboardingPageView(
            imageName: "timer.circle.fill",
            headline: "Scanning Time",
            subheadline: "Scan your surrounding for around 1-3 seconds while moving slowly."
        ),
        OnboardingPageView(
            imageName: "exclamationmark.circle.fill",
            headline: "Be Aware of Your Surroundings",
            subheadline: "Watch out of your surroundings while scanning to avoid accidents."
        )
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Always same sized container to keep image position consistent
            ZStack {
                Color.clear
                pages[currentPage].image
            }
            .frame(height: 200) // fixed height
            .padding(.top, 40)
            
            VStack(spacing: 12) {
                Text(pages[currentPage].headline)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center) // Center the title text
                    .frame(maxWidth: .infinity)      // Expand so it's centered
                
                Text(pages[currentPage].subheadline)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center) // Center the subtitle text
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    hasSeenOnboarding = true
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            requestCameraAccess()
            showDataConsent = true
        }
        .alert("Privacy & Data Collection", isPresented: $showDataConsent) {
            Button("Decline", role: .cancel) {
                userConsented = false
                Analytics.setAnalyticsCollectionEnabled(false)
            }
            Button("Agree") {
                userConsented = true
                Analytics.setAnalyticsCollectionEnabled(true)
            }
        } message: {
            Text("We collect logs data to improve the system. Your data will never be shared with third parties.")
        }
        .animation(.easeInOut, value: currentPage)
        .transition(.slide)
        .padding()
    }
}

// MARK: Helper

private extension OnboardingView {
    private func requestCameraAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraAuthorized = granted
                }
            }
        case .authorized:
            cameraAuthorized = true
        case .denied, .restricted:
            cameraAuthorized = false
        @unknown default:
            cameraAuthorized = false
        }
    }
}
