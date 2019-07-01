//
//  VideoViewController.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 25.06.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoViewController : UIViewController {
    
    @IBOutlet var videoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playVideo(from: "Files/erich.mp4")
    }
    
    private func playVideo(from file:String) {
        let file = file.components(separatedBy: ".")
        
        guard let path = Bundle.main.path(forResource: file[0], ofType:file[1]) else {
            debugPrint( "\(file.joined(separator: ".")) not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.videoView.bounds
        self.videoView.layer.addSublayer(playerLayer)
        player.play()
    }
}
