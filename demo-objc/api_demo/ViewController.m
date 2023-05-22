#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@property(nonatomic, assign) UIInterfaceOrientation statusBarOrientation;

@end

@implementation ViewController{
	NSMutableDictionary* mediaStreams;
	NSString* roomName;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
	
	self.roomInput.delegate = self;
	[self.roomInput becomeFirstResponder];
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood.png"]];
	
	mediaStreams = [[NSMutableDictionary alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self resizeVideoViews];
	
	UIApplication* myApp = [UIApplication sharedApplication];
	myApp.idleTimerDisabled = YES;
	
}

- (void)addMediaStream: (MediaStream*)mediaStream {
	NSLog(@"addMediaStream pid:%@", [ [mediaStream getPeerStream] getId ] );
	
	[mediaStreams setObject:mediaStream forKey:[ [mediaStream getPeerStream] getId ] ];
	mediaStream.delegate = self;
	
	[self resizeVideoViews];
	
	UIView* v = [ [ mediaStream getVideoView ] getView];
	[self.videosView addSubview: v ];
}

- (void)removePeerStream: (PeerStream*)peerStream {
	
	NSString* id = [peerStream getId];
	
	[ [ [ [mediaStreams valueForKey:id] getVideoView ] getView] removeFromSuperview ];
	
	[mediaStreams removeObjectForKey:id];
	
	[self resizeVideoViews];
}

- (void)sizeVideoView:(VideoView*) vv ratio:(float)ratio top:(int)top left:(int)left width:(int)maxWidth height:(int)maxHeight{
	
	int height = maxHeight;
	int width = height * ratio;
	if ( width > maxWidth) {
		width = maxWidth;
		height = maxWidth / ratio;
	}
	
	int centeredTop = top + (maxHeight-height) /2;
	int centeredLeft = left + (maxWidth-width) /2;
	
	UIView* view = [vv getView];
	
	CGRect frame = view.frame;
	
	frame.size.height = height;
	frame.size.width = width;
	frame.origin.x = centeredLeft;
	frame.origin.y = centeredTop;
	
	view.frame = frame;
}

- (void)resizeVideoViews {
	
	CGRect videosRect = [self.videosView frame];
	CGFloat videosWidth = videosRect.size.width;
	CGFloat videosHeight = videosRect.size.height;
	NSArray* keys = [mediaStreams allKeys];
	NSUInteger count = keys.count;
	
	if ( !count ) return;
	
	int maxHeight = videosHeight / ( count/2 + count%2 );
	int maxWidth = videosWidth / ( (count>1) ? 2 : 1 );
	
	for (int i=0; i<count; i++) {
		NSString* id = keys[i];
		MediaStream* ms = [ mediaStreams valueForKey:id ];
		
		[self sizeVideoView:[ms getVideoView] ratio:[ms getVideoRatio] top:(i/2)*maxHeight left:(i%2)*maxWidth width:maxWidth height:maxHeight ];
	}
	
	// Be sure that leave button is visible
	[[self.leaveBtn superview] bringSubviewToFront:self.leaveBtn];
}

- (void)onVideoRatioChange:(float)ratio media:(MediaStream *)mediaStream {
	[self resizeVideoViews];
}

- (void)onVideoSizeChange:(int)width height:(int)height media:(MediaStream*)mediaStream {
	// Can be used to show video only at this moment
	NSLog(@"onVideoSizeChange");
}

- (void)onVideoReady:(MediaStream *)mediaStream {
	// Can be used to show video only at this moment
	NSLog(@"videoReady");
}

- (void)resetUI {
	[self.roomInput resignFirstResponder];
	self.roomInput.text = nil;
	[self inRoom:NO];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField*)textField {
	[ self join ];
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	[textField resignFirstResponder];
	return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (void)viewDidLayoutSubviews {
	if (self.statusBarOrientation != [UIApplication sharedApplication].statusBarOrientation) {
		self.statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:@"StatusBarOrientationDidChange"
		 object:nil ];
		
		[ self resizeVideoViews ];
	}
}

- (IBAction)leaveBtn:(id)sender {
	AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate leave:roomName];
}

- (void) join {
	roomName = self.roomInput.text;
	if ([roomName length] == 0) {
		return;
	}
	
	[self.roomInput resignFirstResponder];
	
	AppDelegate * appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	[appDelegate join:roomName];
}

- (IBAction)joinBtn:(id)sender {
	[ self join ];
}

- (void)inRoom:(BOOL)inside{
	self.roomInput.hidden = inside;
	self.videosView.hidden = !inside;
	self.leaveBtn.hidden = !inside;
	self.joinBtn.hidden = inside;
	self.statusLabel.hidden = inside;
}

- (void)updateConnectionStatus: (ConferenceConnection)status {
	if ( status == CONNECTED ) {
		[self.joinBtn setEnabled:YES];
		self.joinBtn.userInteractionEnabled = YES;
	} else {
		[self.joinBtn setEnabled:NO];
		self.joinBtn.userInteractionEnabled = NO;
	}
	switch ( status ) {
		case DISCONNECTED:
			self.statusLabel.text = @"Disconnected";
			break;
		case CONNECTING:
		case CONNECTING_SENDREQUEST:
			self.statusLabel.text = @"Connecting";
			break;
		case CONNECTED:
			self.statusLabel.text = @"Connected";
			break;
	}
}

@end
