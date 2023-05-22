#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property(nonatomic, strong) Conference* conference;

@end

@implementation AppDelegate;

#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication*)application
didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"ViewController" ofType:@"nib"];
	NSBundle *resourcesBundle = [NSBundle bundleWithPath:path];
	self.viewController =
	[[ViewController alloc] initWithNibName:@"ViewController" bundle:resourcesBundle];
	self.window.rootViewController = self.viewController;
	
	[self.window makeKeyAndVisible];
	
	self.conference = [ Conference getInstance ];

	[ self.conference setDelegate:self];
	[ self.conference setInfoWithAppID: @"38077edb" APIKey: @"4f304359baa6d0fd1f9106aaeb116f33" userName: @"iosDemo" ];
	
	[ self.conference connect ];
	[ self.conference setLoudspeaker:true ];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application {
	//  Application lost focus, connection broken
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
	[ self.conference applicationInBackground ];
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
	[ self.conference applicationIsActive ];
}

- (void)applicationWillTerminate:(UIApplication*)application {
	[ self close ];
}

#pragma mark - internal methods

- (void)disconnect {
	[ self.conference disconnect ];
}

#pragma mark - ConferenceDelegate methods

// Implement ConferenceDelegate
- (void)onConnectionEvent:(ConferenceConnection)status {
	NSString* statusString = @"Unknown";
	switch ( status ) {
		case DISCONNECTED:
			statusString = @"DISCONNECTED";
			break;
		case CONNECTING:
			statusString = @"CONNECTING";
			break;
		case CONNECTING_SENDREQUEST:
			statusString = @"CONNECTING_SENDREQUEST";
			break;
		case CONNECTED:
			statusString = @"CONNECTED";
			break;
	}
	// Update status in view
	[self.viewController updateConnectionStatus: status];
	
	NSLog(@"onConnectionEvent status:%@", statusString);
}

// Implement ConferenceDelegate
- (void)onError:(ConferenceError)error {
	NSString* errorString = @"Unknown";
	switch ( error ) {
		case NO_ERROR:
			errorString = @"NO_ERROR";
			break;
		case CONNECTION_ERROR:
			errorString = @"CONNECTION_ERROR";
			break;
	}
	
	NSLog( @"onError error:%@", errorString );
}

// Implement ConferenceDelegate
- (void)onRoomJoined:(NSString *)room_name {
	NSLog( @"onRoomJoined room name:%@", room_name );
	
	[self.viewController inRoom: YES];
}

// Implement ConferenceDelegate
-(void)onRoomMembers:(NSString *)room members:(NSArray *)members{
	NSLog( @"onRoomMembers room name:%@ members count:%tu", room, members.count );
}

// Implement ConferenceDelegate
- (void)onRoomQuitted:(NSString*)roomName {
	NSLog( @"onRoomQuitted %@", roomName );
	
	[self.viewController inRoom: NO];
}


- (void)onPeerJoinedRoom: (NSString*)roomName peerId:(NSString*)peerId peerName:(NSString*)peerName {
	NSLog( @"onPeerJoinedRoom %@ pid:%@ name:%@", roomName, peerId, peerName );
}

- (void)onPeerQuittedRoom: (NSString*)roomName peerId:(NSString*)peerId {
	NSLog( @"onPeerQuittedRoom %@ pid:%@", roomName, peerId );
}

// Implement ConferenceDelegate
- (void)onNewPeer:(PeerStream *)peerStream {
	NSLog( @"onNewPeer peer id:%@", [ peerStream getId ] );
	[peerStream setDelegate: self];
	
	
	// Example Open dataChannel example
	if ( ! [peerStream isLocal] ) {
		[ peerStream openDataChannel:@"Test" ];
	}
	
	
}

// Implement ConferenceDelegate
- (void)onRemovedPeer:(PeerStream *)peerStream {
	NSLog( @"onRemovedPeer peer id:%@", [ peerStream getId ] );
	
	[self.viewController removePeerStream:peerStream];
}

// Implement ConferenceDelegate
-(void)onIncomingRequest:(NSString *)peerId name:(NSString *)peerName room:(NSString *)room callEvent:(NSString *)event {
	NSLog( @"onIncomingRequest peer id:%@ name:%@ room:%@ event:%@", peerId, peerName, room, event );
}

// Implement ConferenceDelegate
-(void)onPresence:(NSString *)peerId presence:(Presence)presence{
	NSLog( @"onPresence peer id:%@ presence:%@", peerId, [Conference presenceToString:presence] );
}

// Implement PeerStreamDelegate
- (void)onMediaStream:(MediaStream *)mediaStream peerId:(NSString *)peerId {
	NSLog( @"onMediaStream peer id:%@", peerId );
	
	if ( ![mediaStream hasVideo] ) {
		NSLog( @"No video for mediaStream of %@", peerId );
		return;
	}
	
	[self.viewController addMediaStream:mediaStream];
}

// Implement PeerStreamDelegate
- (void)onDataStream:(DataStream *)dataStream peerId:(NSString *)peerId {
	NSLog( @"onMediaStream peer id:%@", peerId );
	
	[dataStream setDelegate: self];
}

// Implement DataStreamDelegate
-(void)onOpen:(DataStream *)dataStream {
	NSLog( @"DataStreamDelegate onOpen" );
}

// Implement DataStreamDelegate
-(void)onError:(DataStream *)dataStream error:(NSString *)error {
	NSLog( @"DataStreamDelegate onError error:%@", error );
}

// Implement DataStreamDelegate
-(void)onClose:(DataStream *)dataStream {
	
}

// Implement DataStreamDelegate
-(void)onMessage:(DataStream *)dataStream message:(NSData *)message isBinary:(BOOL)binary {
	NSLog( @"DataStreamDelegate onMessage isBinary:%@", binary?@"YES" : @"NO" );
	NSString* text = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
	if (binary) {
		NSLog( @"message:%@", text );
	}
	text = [NSString stringWithFormat:@"(ios echo) %@", text];
	[ dataStream send:text ];
}

#pragma mark - public methods

- (void)close {
	[ self disconnect ];
}

- (void)join: (NSString*) room{
	if ( [ self.conference getStatus ] != CONNECTED ) return;
	
	[ self.conference join:room ];
}

- (void)leave: (NSString*) room{
	[ self.conference leave:room ];
}

@end


