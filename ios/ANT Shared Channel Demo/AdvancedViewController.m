//
//  AdvancedViewController.m
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

#import "AdvancedViewController.h"
#import "SWRevealViewController.h"
#import "ViewController.h"
#import "PeripheralControllerDelegate.h"
#import "GroupCell.h"
#import "Group.h"

// Add hexToBytes: method to NSString
@interface NSString (NSStringHexToBytes)

/*!
 * Returns the NSData object containing hex values from the string as bytes.
 */
-(NSData*) hexToBytes ;

@end

@implementation NSString (NSStringHexToBytes)

-(NSData*) hexToBytes {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= self.length; idx += 2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [self substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

@end

@interface AdvancedViewController () {
    /*! 
     * @brief   The array of Groups that are shown on the list. As in the current firmware implementation group information is not received with 
     *          node state, the app does not know what groups are already in the system so the groups are cleared (unless disconected). Groups are numbered 1-15.
     */
    NSMutableArray* groups;
}
@property (weak, nonatomic) IBOutlet UITextField *customData;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *addGroupButton;
@property (weak, nonatomic) IBOutlet UITableView *groupsTable;

/*!
 * @brief   The 'Create new group' button click handler.
 */
- (IBAction)createNewGroup;
/*!
 * @brief   The 'Send' (send custom message) button click handler.
 */
- (IBAction)sendCustomData;
/*!
 * @brief   The custom message info button click handler. This shows user the syntax of supported messages.
 */
- (IBAction)showCustomDataInfo;
/*!
 * @brief   The 'About the applicaiton' button click handler.
 */
- (IBAction)showAbout;

@end

@implementation AdvancedViewController
@synthesize peripheralDelegate;
@synthesize customData;
@synthesize sendButton;
@synthesize addGroupButton;
@synthesize groupsTable;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    customData.delegate = self;
    groups = [NSMutableArray arrayWithCapacity:4];
    groupsTable.dataSource = self;
    groupsTable.delegate = self;
    
    self.revealViewController.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated {
    // Enable or disable views based on whether we are connected or not
    BOOL connected = [peripheralDelegate isConnected];
    
    [customData setEnabled:connected];
    [sendButton setEnabled:connected];
    [addGroupButton setEnabled:connected];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Group Manager delegate methods

- (void)onGroupUpdated:(UInt8)number {
    Group* group = nil;
    // Find the group on the list
    for (int i = 0; i < groups.count; ++i)
    {
        Group* g = groups[i];
        if (g.number == number)
        {
            group = g;
            break;
        }
    }
    // Do nothing if such exists. If not - create a new row.
    if (!group)
    {
        group = [[Group alloc] initWithGroupNumber:number];
        [groups addObject:group];
        [groupsTable reloadData];
    }
}

-(void)didDisconnectedPeripheral {
    [groups removeAllObjects];
    [groupsTable reloadData];
}

#pragma mark Action handlers

- (IBAction)createNewGroup {
    // Groups may be numbered only 0-15. Initially all nodes belong to a group number 0, which is not listed here.
    if (groups.count < 15)
    {
        [peripheralDelegate editGroup: groups.count + 1];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information"
                    message:@"Maximum number of groups reached."
                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)sendCustomData {
    NSString* text = customData.text;
    NSData* data = text.hexToBytes;
    
    [peripheralDelegate sendData:data];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendCustomData];
    return NO;
}

- (IBAction)showCustomDataInfo {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information"
                message:@"Message syntax: (0x)\n00-CMD-SC-GR-MA(L)-MA(H)-00-00,\nCMD:\n00 - disable reporting (hub only),\n01 - enable reporting (hub only),\n03 - node ON, 04 - node OFF,\n05 - assign to group,\nSC: shared channel (0 - all, 1-15),\nGR: group number (0-15),\nMA: master ID (2 bytes),\nor: (0x)\n00-CMD-GR-MA(L)-MA(H)-00-00-00,\nCMD:\n06 - group ON, 07 - group OFF."
                delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)showAbout {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"About"
                message:@"This application demonstrates the capabilities of the experimental ANT Auto Shared Channel example from Nordic Semiconductor's nRF51 SDK 7.2+. The sample supports up to two ANT+BLE hubs and up to 15 ANT-only nodes for each hub. At least four boards are required to utilize all features of the reference design.\n\nMore information and the source code may be found on GitHub."
                delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"GitHub", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Only one alert view has a delegate set so...
    if (buttonIndex == 1) // "GitHub" button from "About the application" dialog.
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/NordicSemiconductor/ANT-Shared-Channel-Demo"]];
    }
}

#pragma mark Reveal View Controller delegate methods

-(void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position {
    // Hide the keyboard when the advanced view controller is to be closed
    [self.view endEditing:YES];
}

-(void)revealControllerPanGestureBegan:(SWRevealViewController *)revealController {
    // Hide the keyboard when the advanced view controller is to be closed
    [customData resignFirstResponder];
}

#pragma mark Table View delegate methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return groups.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupCell* cell = (GroupCell*) [tableView dequeueReusableCellWithIdentifier:@"GroupCell"];
    cell.peripheralDelegate = peripheralDelegate;
    
    Group* group = groups[indexPath.row];
    cell.group = group.number;
    return cell;
}

@end
