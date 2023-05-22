#import <UIKit/UIKit.h>
#import <bistriAPI2/conference.h>

@interface VideoCodec : NSObject
@end

@interface ViewController : UIViewController<
MediaStreamDelegate,
UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UITextField* roomInput;
@property(weak, nonatomic) IBOutlet UIView* videosView;
@property(weak, nonatomic) IBOutlet UIButton* leaveBtn;
@property(weak, nonatomic) IBOutlet UIButton* joinBtn;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

- (void)inRoom: (BOOL)inside;
- (void)addMediaStream: (MediaStream*)mediaStream;
- (void)removePeerStream: (PeerStream*)peerStream;
- (NSUInteger)supportedInterfaceOrientations;
- (void)join;
- (void)updateConnectionStatus: (ConferenceConnection)status;
@end

