// The whole-screen training surface: every training gesture works anywhere.
// Design: docs/intent/touch/touch-design.md

import HearChessCore
import SwiftUI
import UIKit

// @spec TOUCH-001, TOUCH-009, TOUCH-011
struct GestureSurface: UIViewRepresentable {
    let onGesture: (HearChessCore.Gesture) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onGesture: onGesture) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Training surface"
        // Let gestures reach the app directly while VoiceOver is on.
        view.accessibilityTraits = .allowsDirectInteraction
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onGesture = onGesture
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onGesture: (HearChessCore.Gesture) -> Void

        init(onGesture: @escaping (HearChessCore.Gesture) -> Void) {
            self.onGesture = onGesture
        }

        func install(on view: UIView) {
            func swipe(_ direction: UISwipeGestureRecognizer.Direction, touches: Int = 1) -> UISwipeGestureRecognizer {
                let r = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
                r.direction = direction
                r.numberOfTouchesRequired = touches
                view.addGestureRecognizer(r)
                return r
            }
            func tap(taps: Int, touches: Int) -> UITapGestureRecognizer {
                let r = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
                r.numberOfTapsRequired = taps
                r.numberOfTouchesRequired = touches
                view.addGestureRecognizer(r)
                return r
            }

            _ = swipe(.left)
            _ = swipe(.right)
            _ = swipe(.up)
            _ = swipe(.down)
            _ = swipe(.down, touches: 3)

            let singleTap = tap(taps: 1, touches: 1)
            let doubleTap = tap(taps: 2, touches: 1)
            let twoFingerTap = tap(taps: 1, touches: 2)
            let twoFingerDoubleTap = tap(taps: 2, touches: 2)
            singleTap.require(toFail: doubleTap)
            // A two-finger tap only counts once a two-finger double-tap is ruled out.
            twoFingerTap.require(toFail: twoFingerDoubleTap)

            let press = UILongPressGestureRecognizer(target: self, action: #selector(pressed(_:)))
            press.minimumPressDuration = 0.8
            view.addGestureRecognizer(press)
        }

        @objc func swiped(_ r: UISwipeGestureRecognizer) {
            if r.numberOfTouchesRequired == 3 { onGesture(.threeFingerSwipeDown); return }
            switch r.direction {
            case .left: onGesture(.swipeLeft)
            case .right: onGesture(.swipeRight)
            case .up: onGesture(.swipeUp)
            case .down: onGesture(.swipeDown)
            default: break
            }
        }

        @objc func tapped(_ r: UITapGestureRecognizer) {
            switch (r.numberOfTapsRequired, r.numberOfTouchesRequired) {
            case (1, 1): onGesture(.tap)
            case (2, 1): onGesture(.doubleTap)
            case (1, 2): onGesture(.twoFingerTap)
            case (2, 2): onGesture(.twoFingerDoubleTap)
            default: break
            }
        }

        @objc func pressed(_ r: UILongPressGestureRecognizer) {
            if r.state == .began { onGesture(.longPress) }
        }
    }
}
