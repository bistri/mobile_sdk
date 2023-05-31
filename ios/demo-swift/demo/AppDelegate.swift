//
//  AppDelegate.swift
//  demo
//
//  Created by Aurélien Hiron on 11/04/2023.
//

import UIKit
import bistriAPI2

//@main
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ConferenceDelegate, PeerStreamDelegate, DataStreamDelegate
{
	var window: UIWindow?
	var conference: Conference?
	var viewController: ViewController?
	

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		window = UIWindow(frame: UIScreen.main.bounds)
		
		viewController = ViewController(nibName: "ViewController", bundle: nil)
		window?.rootViewController = viewController
		window?.makeKeyAndVisible()
		
		initConference()

		return true
	}
	
	func initConference() {
		
		conference = Conference.getInstance()
		conference?.delegate = self
		conference?.setInfoWithAppID("38077edb", apiKey: "4f304359baa6d0fd1f9106aaeb116f33", userName: "iosDemo")

		conference?.connect()
		conference?.setLoudspeaker(true)
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Application lost focus, connection broken
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		conference?.applicationInBackground()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		conference?.applicationIsActive()
	}

	func applicationWillTerminate(_ application: UIApplication) {
		close()
	}

	func disconnect() {
		conference?.disconnect()
	}

	func onConnectionEvent(_ status: ConferenceConnection) {
		var statusString = ""
		switch status {
		case DISCONNECTED:
			statusString = "DISCONNECTED"
		case CONNECTING:
			statusString = "CONNECTING"
		case CONNECTING:
			statusString = "CONNECTING_SENDREQUEST"
		case CONNECTED:
			statusString = "CONNECTED"
		default:
			statusString = "Unknown"
		}
		print("onConnectionEvent status:\(statusString)")

		// Update status in view
		viewController?.updateConnectionStatus(status)
	}

	func onError(_ error: ConferenceError) {
		var errorString = ""
		switch error {
		case NO_ERROR:
			errorString = "NO_ERROR"
		case CONNECTION_ERROR:
			errorString = "CONNECTION_ERROR"
		default:
			errorString = "UNKNOWN_ERROR"
		}
		
		print("onError error:\(errorString)")
	}

	func onRoomJoined(_ roomName: String) {
		print("onRoomJoined room name:\(roomName)")
		
		viewController?.inRoom(true)
	}

	func onRoomMembers(_ room: String, members: [Any]) {
		print("onRoomMembers room name:\(room) members count:\(members.count)")
	}

	func onRoomQuitted(_ roomName: String) {
		print("onRoomQuitted \(roomName)")
		
		viewController?.inRoom(false)
	}

	func onPeerJoinedRoom(_ roomName: String, peerId: String, peerName: String) {
		print("onPeerJoinedRoom \(roomName) pid:\(peerId) name:\(peerName)")
	}

	func onPeerQuittedRoom(_ roomName: String, peerId: String) {
		print("onPeerQuittedRoom \(roomName) pid:\(peerId)")
	}

	func onNewPeer(_ peer: PeerStream!) {
		print("onNewPeer peer")
		// Called when a new peer joins the conference
		peer.delegate = self

		// Open dataChannel example
		if ( peer.isLocal() == false ) {
			peer.openDataChannel( "Test" )
		}
	}

	// ConferenceDelegate

	func onRemovedPeer(_ peerStream: PeerStream!) {
		print("onRemovedPeer peer id: \(peerStream.getId() ?? "")")
		viewController?.removePeerStream(peerStream)
	}
	
	func onIncomingRequest(_ peerId: String, name peerName: String, room: String, callEvent event: String) {
		print("onIncomingRequest peer id: \(peerId) name: \(peerName) room: \(room) event: \(event)")
	}

	func onPresence(_ peerId: String, presence: Presence) {
		print("onPresence peer id: \(peerId) presence: \(Conference.presence(toString: presence))")
	}

	func onMediaStream(_ mediaStream: MediaStream!, peerId: String) {
		print("onMediaStream peer id: \(peerId)")
		
		if !mediaStream.hasVideo() {
			print("No video for mediaStream of \(peerId)")
			return
		}
		
		viewController?.addMediaStream(mediaStream)
	}
	
	func onDataStream(_ dataStream: DataStream!, peerId: String) {
		print("onDataStream peer id: \(peerId)")
		
		dataStream.delegate = self
	}

	// DataStreamDelegate
	func onOpen(_ dataStream: DataStream) {
		print("DataStreamDelegate onOpen")
	}

	func onError(_ dataStream: DataStream, error: String) {
		print("DataStreamDelegate onError error: \(error)")
	}

	func onClose(_ dataStream: DataStream) {
		print("DataStreamDelegate onClose")
	}

	func onMessage(_ dataStream: DataStream, message: Data, isBinary binary: Bool) {
		print("DataStreamDelegate onMessage isBinary: \(binary ? "YES" : "NO")")
		let text = String(data: message, encoding: .utf8)
		if binary {
			print("message: \(text ?? "")")
		}

		dataStream.send("(ios echo) \(text ?? "")")
	}

	// Public methods

	func close() {
		disconnect()
	}

	func join(_ room: String) {
		if conference?.getStatus() != CONNECTED { return }
		
		conference?.join(room)
	}

	func leave(_ room: String) {
		conference?.leave(room)
	}

}


