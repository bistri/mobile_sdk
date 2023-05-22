//
//  ViewController.swift
//  demo
//
//  Created by Aurélien Hiron on 11/04/2023.
//

import UIKit
import bistriAPI2

class ViewController: UIViewController, UITextFieldDelegate, MediaStreamDelegate {
	
	@IBOutlet var contentView: UIView!
	@IBOutlet weak var roomInput: UITextField!
	@IBOutlet weak var videosView: UIView!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var leaveBtn: UIButton!
	@IBOutlet weak var joinBtn: UIButton!

	var orientation: UIInterfaceOrientation = .unknown
	var mediaStreams: [String: MediaStream] = [:]
	var roomName: String?

	override func viewDidLoad() {
		super.viewDidLoad()
		orientation = getInterfaceOrientation()
		
		roomInput.delegate = self
		roomInput.becomeFirstResponder()

		mediaStreams = [:]
	}
	
	func getInterfaceOrientation() -> UIInterfaceOrientation {
		let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		return windowScene?.interfaceOrientation ?? UIInterfaceOrientation.unknown
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		resizeVideoViews()

		let myApp = UIApplication.shared
		myApp.isIdleTimerDisabled = true
	}

	func addMediaStream(_ mediaStream: MediaStream) {
		print("addMediaStream pid:\(mediaStream.getPeerStream().getId())")

		mediaStreams[mediaStream.getPeerStream().getId()] = mediaStream
		mediaStream.delegate = self

		let v = mediaStream.getVideoView().getView()
		videosView.addSubview(v!)

		resizeVideoViews()

	}

	func removePeerStream(_ peerStream: PeerStream) {
		guard let id = peerStream.getId() else { return }

		mediaStreams[id]?.getVideoView().getView().removeFromSuperview()
		mediaStreams.removeValue(forKey: id)

		resizeVideoViews()
	}

	func sizeVideoView(_ vv: VideoView, ratio: Float, top: Int, left: Int, maxWidth: Int, maxHeight: Int) {
		
		var height = maxHeight
		var width = Int(Float(height) * ratio)
		if width > maxWidth {
			width = maxWidth
			height = Int(Float(width) / ratio)
		}

		let centeredTop = top + (maxHeight - height) / 2
		let centeredLeft = left + (maxWidth - width) / 2

		guard let view = vv.getView() else { return }
		var frame = view.frame
		frame.size.height = CGFloat(height)
		frame.size.width = CGFloat(width)
		frame.origin.x = CGFloat(centeredLeft)
		frame.origin.y = CGFloat(centeredTop)

		view.frame = frame
	}

	func resizeVideoViews() {

		let videosRect = videosView.frame
		let videosWidth = videosRect.size.width
		let videosHeight = videosRect.size.height
		let keys = Array(mediaStreams.keys)
		let count = keys.count

		if count == 0 {
			return
		}

		let maxHeight = Int(videosHeight / CGFloat(count/2 + count%2))
		let maxWidth = Int(videosWidth / CGFloat(count > 1 ? 2 : 1))

		for i in 0..<count {
			let id = keys[i]
			let ms = mediaStreams[id]

			sizeVideoView(ms!.getVideoView(), ratio: ms!.getVideoRatio(), top: (i/2)*maxHeight, left: (i%2)*maxWidth, maxWidth: maxWidth, maxHeight: maxHeight)
		}

		// Be sure that leave button is visible
		leaveBtn.superview?.bringSubviewToFront(leaveBtn)
	}

	func onVideoRatioChange(_ ratio: Float, media mediaStream: MediaStream) {
		resizeVideoViews()
	}

	func onVideoSizeChange(_ width: Int32, height: Int32, media mediaStream: MediaStream!) {
		// Peut être utilisé pour afficher uniquement la vidéo à ce moment-là
		print("onVideoSizeChange")
	}

	func onVideoReady(_ mediaStream: MediaStream) {
		// Peut être utilisé pour afficher uniquement la vidéo à ce moment-là
		print("videoReady")
	}

	func resetUI() {
		roomInput.resignFirstResponder()
		roomInput.text = nil
		inRoom(false)
	}

	// MARK: - UITextFieldDelegate

	func textFieldDidEndEditing(_ textField: UITextField) {
		join()
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .all
	}

	override func viewDidLayoutSubviews() {
		let newOrientation = getInterfaceOrientation()
		if orientation != newOrientation {
			orientation = newOrientation
			NotificationCenter.default.post(name: NSNotification.Name("StatusBarOrientationDidChange"), object: nil)
			resizeVideoViews()
		}
	}

	@IBAction func leaveBtnTapped(_ sender: Any) {
		guard let roomName = roomName else {return}
		let appDelegate = UIApplication.shared.delegate as? AppDelegate
		appDelegate?.leave(roomName)
	}

	func join() {
		roomName = roomInput.text
		guard let roomName = roomName else {return}

		roomInput.resignFirstResponder()

		let appDelegate = UIApplication.shared.delegate as? AppDelegate
		appDelegate?.join(roomName)
	}

	@IBAction func joinBtnTapped(_ sender: Any) {
		print("join tapped")
		join()
	}

	func inRoom(_ inside: Bool) {
		roomInput.isHidden = inside
		videosView.isHidden = !inside
		leaveBtn.isHidden = !inside
		joinBtn.isHidden = inside
		statusLabel.isHidden = inside
	}

	func updateConnectionStatus(_ status: ConferenceConnection) {
		let connected = (status == CONNECTED)
		joinBtn.isEnabled = connected
		joinBtn.isUserInteractionEnabled = connected

		switch status {
		case CONNECTING:
			statusLabel.text = "Connecting"
		case CONNECTING_SENDREQUEST:
			statusLabel.text = "Connecting"
		case CONNECTED:
			statusLabel.text = "Connected"
		default:
			statusLabel.text = "Disconnected"
		}
	}

	// Autres méthodes et fonctionnalités de la classe ViewController en Swift
}




