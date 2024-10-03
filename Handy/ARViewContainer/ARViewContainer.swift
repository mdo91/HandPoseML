//
//  ARViewContainer.swift
//  Handy
//
//  Created by Mahmoud Aoata on 1.09.2024.
//
import SwiftUI
import Foundation
import ARKit

struct ARViewContainer: UIViewControllerRepresentable {

    
    @Binding var labelText: String
    

    
    func makeUIViewController(context: Context) -> some UIViewController {
        let arViewController = ARViewController()
        arViewController.labelText = labelText
        return arViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        let viewController = uiViewController as? ARViewController
        viewController?.labelText = labelText
    }
}
