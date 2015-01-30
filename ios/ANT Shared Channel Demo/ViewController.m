//
//  ViewController.m
//  ANT Shared Channel Demo
//
//  Copyright (c) 2015, Nordic Semiconductor ASA
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other
//  materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific
//  prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
//  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ViewController.h"
#import "ScannerViewController.h"
#import "SettingsViewController.h"
#import "SWRevealViewController.h"
#import "AdvancedViewController.h"
#import "GroupManagerDelegate.h"
#import "HubView.h"
#import "NodeView.h"
#import "Constants.h"

#define NO_GROUP -1

@interface ViewController () {
    CBUUID *lightDemoServiceUUID;
    CBUUID *reportCharacteristicUUID;
    CBUUID *controlPointCharacteristicUUID;
    /// This characteristic is used to send commands to the system.
    CBCharacteristic* controlPointCharacteristic;
    UIColor* colorBlue;
    UIColor* colorOrange;
    /// A number of a group that is being currently edited or NO_GROUP if not in edit mode.
    SInt8 editGroup;
}


@property (strong, nonatomic) CBCentralManager *bluetoothManager;
/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *ascPeripheral;

@property (strong, nonatomic) NSMutableArray *hubs; // This array contains HubView objects
@property (assign, nonatomic) BOOL showTitles;

@property (strong, nonatomic) id<GroupManagerDelegate> groupManagerDelegate;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIView *introView;
@property (weak, nonatomic) IBOutlet UIView *progressIndicator;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *waitingForNodesLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* revealButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *editGroups;

- (IBAction)connectOrDisconnectClicked;

@end

@implementation ViewController
@synthesize bluetoothManager;
@synthesize connectButton;
@synthesize introView;
@synthesize editGroups;
@synthesize progressIndicator;
@synthesize progressLabel;
@synthesize waitingForNodesLabel;
@synthesize ascPeripheral;
@synthesize hubs;
@synthesize showTitles;

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        lightDemoServiceUUID = [CBUUID UUIDWithString:lightDemoUUIDString];
        reportCharacteristicUUID = [CBUUID UUIDWithString:reportCharacteristicUUIDString];
        controlPointCharacteristicUUID = [CBUUID UUIDWithString:controlPointCharacteristicUUIDString];
        
        editGroup = NO_GROUP;
        hubs = [NSMutableArray arrayWithCapacity:2];
        
        NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
        showTitles = [preferences boolForKey:@"showId"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController)
    {
        [self.revealButtonItem setTarget: self];
        [self.revealButtonItem setAction: @selector( revealRight: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
        // Create navigation bar colors
        colorBlue = [UIColor colorWithRed:0.0f green:0.611f blue:0.87f alpha:1.0f]; // standard one
        colorOrange = [UIColor colorWithRed:0.86f green:0.3451f blue:0.1647f alpha:1.0f]; // group editting
        
        // Assign self as advanced panel peripheral delegate
        AdvancedViewController* controller = (AdvancedViewController*) revealViewController.rightViewController;
        controller.peripheralDelegate = self;
        self.groupManagerDelegate = controller;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    // Otherwise the connectOrDisconnectClicked: method is invoked.
    return ![identifier isEqualToString:@"scan"] || ascPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Preparing the Scanner
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = [CBUUID UUIDWithString:advUUIDString];
        controller.delegate = self;
    }
    
    // Showing Settings popover
    if ([segue.identifier isEqualToString:@"showSettings"])
    {
        SettingsViewController *controller = (SettingsViewController *)segue.destinationViewController;
        controller.peripheralDelegate = self;
        
        // We have to set the popover presentation controller to ensure the popover will be shown as a popover also on phones (see the following method)
        UIPopoverPresentationController *popPC = controller.popoverPresentationController;
        popPC.delegate = self;
    }
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    // This ensures that the Settings popover will be displayed as a popover also on phones.
    return UIModalPresentationNone;
}

- (IBAction)connectOrDisconnectClicked {
    if (ascPeripheral != nil)
    {
        [self showProgress:@"Disconnecting..."];
        [bluetoothManager cancelPeripheralConnection:ascPeripheral];
    }
}

#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral {
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    ascPeripheral = peripheral;
    ascPeripheral.delegate = self;
    [introView setHidden:YES];
    [self showProgress:@"Connecting..."];
    [bluetoothManager connectPeripheral:ascPeripheral options:nil];
}

#pragma mark Central Manager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        // do nothing
    }
    else
    {
        // TODO
        NSLog(@"Bluetooth not ON");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
        [self showProgress:@"Discovering services..."];
    });
    
    // Peripheral has connected. Discover required services
    [ascPeripheral discoverServices:@[lightDemoServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [self hideProgress];
        [self clearUI];
    });
    ascPeripheral = nil;
    controlPointCharacteristic = nil;
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.groupManagerDelegate didDisconnectedPeripheral];
        [self hideProgress];
        [self clearUI];
        [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    });
    ascPeripheral = nil;
    controlPointCharacteristic = nil;
}

#pragma mark Peripheral Delegate methods

-(BOOL)isConnected {
    return ascPeripheral != nil;
}

-(void) sendData:(NSData *)data {
    if (ascPeripheral == nil)
        return;
    
    // NSLog(@"-> %@", [data description]); // uncomment this line to log outgoing packets
    [ascPeripheral writeValue:data forCharacteristic:controlPointCharacteristic type:CBCharacteristicWriteWithResponse];
}

-(void)setShowIds:(BOOL)show {
    self.showTitles = show;
    
    for (int i = 0; i < hubs.count; ++i)
    {
        HubView* hub = hubs[i];
        [hub setShowTitles:show];
    }
}

-(void)editGroup:(UInt8)group {
    [self.revealViewController rightRevealToggle:nil];
    editGroup = group;
    
    // Change Navigation bar color to orange
    [self animateNavigationBarFromColor:colorBlue toColor:colorOrange duration:0.3f];
    [self.revealButtonItem setTitle:@"Done"];
    [self.revealButtonItem setImage:nil];
    [self.view removeGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [UIView transitionWithView:editGroups duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [editGroups setHidden:NO];
}

-(BOOL)isEditingGroup {
    return editGroup > NO_GROUP;
}

-(UInt8)getGroupNumber {
    return editGroup;
}

-(void)revealRight:(id)sender {
    if (editGroup != NO_GROUP)
    {
        [self.groupManagerDelegate onGroupUpdated:editGroup];
        editGroup = NO_GROUP;
        
        [self animateNavigationBarFromColor:colorOrange toColor:colorBlue duration:0.3f];
        [self.revealButtonItem setTitle:nil];
        [self.revealButtonItem setImage:[UIImage imageNamed:@"reveal-icon"]];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
        
        [UIView transitionWithView:editGroups duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
        [editGroups setHidden:YES];
    }
    
    [self.revealViewController rightRevealToggle:sender];
}

#pragma mark Peripheral delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:lightDemoServiceUUID])
            {
                [ascPeripheral discoverCharacteristics:@[reportCharacteristicUUID, controlPointCharacteristicUUID] forService:service];
            }
        }
    } else {
        NSLog(@"error during discovering services");
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        if ([service.UUID isEqual:lightDemoServiceUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:reportCharacteristicUUID]) {
                    [ascPeripheral setNotifyValue:YES forCharacteristic:characteristic];
                } else if ([characteristic.UUID isEqual:controlPointCharacteristicUUID]) {
                    [ascPeripheral setNotifyValue:YES forCharacteristic:characteristic]; // this is required in order to send commands, but why?
                    controlPointCharacteristic = characteristic;
                }
            }
        }
    } else {
        NSLog(@"error during discovering characteristic");
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            if ([characteristic.UUID isEqual:reportCharacteristicUUID]) {
                [self hideProgress];
                [UIView transitionWithView:waitingForNodesLabel duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
                [waitingForNodesLabel setHidden:NO];
            }
        } else {
            NSLog(@"error during enabling CCCD for report characteristic");
        }
    });
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!error) {
            // NSLog(@"%@", [characteristic.value description]); // uncomment this to log incomming packets
            
            const NSData* data = characteristic.value;
            const uint8_t* bytes = [data bytes];
            // Small validation. Only the PAGE_UPDATE is supported.
            if (bytes[0] != PAGE_UPDATE)
                return;
            
            // Hide 'waiting for nodes...' label
            [UIView transitionWithView:waitingForNodesLabel duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
            [waitingForNodesLabel setHidden:YES];
            
            // Parse the data
            UInt16 sharedChannel = bytes[1];
            BOOL   enabled       = bytes[2] == 0x01; // 1 = ON, 0 = OFF
            UInt16 masterId      = CFSwapInt16LittleToHost(*(uint16_t *)(&bytes[3]));
            
            // Find and update the hub & node information
            BOOL hubFound = NO;
            BOOL repositionRequired = NO;
            BOOL repositionNodesRequired = NO;
            for (int i = 0; i < hubs.count; ++i)
            {
                HubView* hub = hubs[i];
                if (hub.hubId == masterId)
                {
                    BOOL nodeFound = [hub updateHubNodeIfExists:sharedChannel withState:enabled];
                    if (!nodeFound)
                    {
                        [hub addHubNode:sharedChannel withState:enabled to: self.view];
                        repositionNodesRequired = YES;
                    }
                    
                    hubFound = YES;
                    break;
                }
            }
            // Add the hub and the node if a new hub found
            if (!hubFound)
            {
                HubView* hub = [[HubView alloc] initWithHubId:masterId showTitles:self.showTitles];
                [hub setPeripheralDelegate:self];
                [hub addHubNode:sharedChannel withState:enabled to: self.view];
                [hubs addObject:hub];
                [self.view addSubview:hub];
                repositionRequired = YES;
                repositionNodesRequired = YES;
            }
            
            // Reposition hubs on the screen
            if (repositionRequired)
            {
                for (int i = 0; i < hubs.count; ++i)
                {
                    HubView* hub = hubs[i];
                    [hub repositionWithHubIndex:i outOf:hubs.count];
                }
            }
            
            // Reposition nodes on the screen
            if (repositionNodesRequired)
            {
                for (int i = 0; i < hubs.count; ++i)
                {
                    HubView* hub = hubs[i];
                    [hub repositionNodes];
                }
            }
        }
        else {
            NSLog(@"error during receiving report value");
        }
    });
}

-(void)removeHub:(HubView *)hub {
    [hubs removeObject:hub];
    [hub removeFromSuperview];
    
    for (int i = 0; i < hubs.count; ++i)
    {
        HubView* hub = hubs[i];
        [hub repositionWithHubIndex:i outOf:hubs.count];
    }
    
    if (hubs.count == 0)
    {
        [UIView transitionWithView:waitingForNodesLabel duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
        [waitingForNodesLabel setHidden:NO];
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // After orientation has changed we need to disable Landscape and enable Portrait constraints set
    // This will be performed by updateConstraints: in HubView
    for (int i = 0; i < hubs.count; ++i)
    {
        HubView* hub = hubs[i];
        [hub setNeedsUpdateConstraints];
    }
}

-(void) clearUI {
    [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
    [waitingForNodesLabel setHidden:YES];
    
    // Check if the group edit mode is enabled
    if (editGroup != NO_GROUP)
    {
        editGroup = NO_GROUP;
        [self animateNavigationBarFromColor:colorOrange toColor:colorBlue duration:0.3f];
        [self.revealButtonItem setTitle:nil];
        [self.revealButtonItem setImage:[UIImage imageNamed:@"reveal-icon"]];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
        
        [UIView transitionWithView:editGroups duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
        [editGroups setHidden:YES];
    }
    
    // Remove all hubs and their nodes
    for (int i = 0; i < hubs.count; ++i)
    {
        HubView* hub = hubs[i];
        [hub removeFromSuperview];
    }
    [hubs removeAllObjects];
    
    // Show the Bluetooth and ANT logos
    [UIView transitionWithView:introView duration:0.9 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [introView setHidden:NO];
}

-(void) showProgress: (NSString *) message {
    [progressIndicator setHidden:NO];
    [progressLabel setHidden: NO];
    [progressLabel setText:message];
}

-(void) hideProgress {
    [UIView transitionWithView:progressIndicator duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [UIView transitionWithView:progressLabel duration:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:NULL completion:NULL];
    [progressIndicator setHidden:YES];
    [progressLabel setHidden: YES];
}

#pragma mark Navigation Bar animations

#define STEP_DURATION 0.01

- (void) animateNavigationBarFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor duration:(NSTimeInterval)duration
{
    NSUInteger steps = duration / STEP_DURATION;
    
    CGFloat fromRed;
    CGFloat fromGreen;
    CGFloat fromBlue;
    CGFloat fromAlpha;
    
    [fromColor getRed:&fromRed green:&fromGreen blue:&fromBlue alpha:&fromAlpha];
    
    CGFloat toRed;
    CGFloat toGreen;
    CGFloat toBlue;
    CGFloat toAlpha;
    
    [toColor getRed:&toRed green:&toGreen blue:&toBlue alpha:&toAlpha];
    
    CGFloat diffRed = toRed - fromRed;
    CGFloat diffGreen = toGreen - fromGreen;
    CGFloat diffBlue = toBlue - fromBlue;
    CGFloat diffAlpha = toAlpha - fromAlpha;
    
    NSMutableArray *colorArray = [NSMutableArray array];
    
    [colorArray addObject:fromColor];
    
    for (NSUInteger i = 0; i < steps - 1; ++i) {
        CGFloat red = fromRed + diffRed / steps * (i + 1);
        CGFloat green = fromGreen + diffGreen / steps * (i + 1);
        CGFloat blue = fromBlue + diffBlue / steps * (i + 1);
        CGFloat alpha = fromAlpha + diffAlpha / steps * (i + 1);
        
        UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [colorArray addObject:color];
    }
    
    [colorArray addObject:toColor];
    
    [self animateNavigationBarWithArray:colorArray];
}

- (void)animateNavigationBarWithArray:(NSMutableArray *)array
{
    NSUInteger counter = 0;
    
    for (UIColor *color in array) {
        double delayInSeconds = STEP_DURATION * counter++;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:STEP_DURATION animations:^{
                self.navigationController.navigationBar.barTintColor = color;
            }];
        });
    }
}

@end
