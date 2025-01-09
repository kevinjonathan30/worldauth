//
//  CoachingOverlayView.swift
//  WorldAuth
//
//  Created by Kevin Jonathan on 2025/01/09.
//

import SwiftUI
import ARKit

struct CoachingOverlayView: UIViewRepresentable {
    let sceneView: ARSCNView
    @Binding var isCoachingActive: Bool

    func makeUIView(context: Context) -> ARCoachingOverlayView {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = sceneView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.delegate = context.coordinator
        
        return coachingOverlay
    }

    func updateUIView(_ uiView: ARCoachingOverlayView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isCoachingActive: $isCoachingActive)
    }

    class Coordinator: NSObject, ARCoachingOverlayViewDelegate {
        @Binding var isCoachingActive: Bool

        init(isCoachingActive: Binding<Bool>) {
            self._isCoachingActive = isCoachingActive
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            isCoachingActive = false
        }

        func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
            isCoachingActive = true
        }
    }
}
