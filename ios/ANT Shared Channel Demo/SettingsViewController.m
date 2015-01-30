//
//  SettingsViewController.m
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

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *showIdSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *immediateResponseSwitch;

@end

@implementation SettingsViewController
@synthesize peripheralDelegate;
@synthesize showIdSwitch;
@synthesize immediateResponseSwitch;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    
    [showIdSwitch setOn:[preferences boolForKey:@"showId"]];
    [immediateResponseSwitch setOn:[preferences boolForKey:@"immediateResponse"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)immediateResponseHelpClicked {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Information"
                            message:@"Enable immediate response to instantaneously change the color of a clicked node without waiting for an update notification, which may be several seconds delayed. If you select this option, the state of a node might be set to an outdated value by a queued message while the current message is propagated through the system. In this case, the state is set correctly after propagation of the current message is complete."
                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)showIdChanged {
    BOOL on = [showIdSwitch isOn];
    
    // Save the new value for the future
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    [preferences setBool:on forKey:@"showId"];
    
    // Notify the main View Controller to toggle the ids visibility.
    [peripheralDelegate setShowIds:on];
}

- (IBAction)immediateResponseChanged {
    BOOL on = [immediateResponseSwitch isOn];
    
    // Save the new value for the future. The value is read by HubView and NodeView in their action handlers.
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    [preferences setBool:on forKey:@"immediateResponse"];
}
@end
