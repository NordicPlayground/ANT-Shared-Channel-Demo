//
//  GroupCell.m
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

#import "GroupCell.h"

#define OP_CODE_BY_INDEX(i) (i == 0 ? OP_CODE_GROUP_ON : OP_CODE_GROUP_OFF)

@interface GroupCell ()
@property (weak, nonatomic) IBOutlet UILabel *label;

/*!
 * Method invoked when user press On or Off button.
 * Use sender.selectedSegmentIndex to determine which segment was pressed. 0 - On, 1 - Off
 */
- (IBAction)groupActionTriggered:(UISegmentedControl *)sender;

/*!
 * @brief   The 'Edit' button click handler.
 */
- (IBAction)editActionClicked;
@end

@implementation GroupCell
@synthesize peripheralDelegate;

- (void)awakeFromNib {
    // Initialization code
}

-(void)setGroup:(uint8_t)group {
    _group = group;
    [self.label setText:[NSString stringWithFormat:@"%d.", group]];
}

- (IBAction)groupActionTriggered:(UISegmentedControl *)sender {
    GroupOnOffCommand command;
    command.page = PAGE_COMMAND;
    command.opCode = OP_CODE_BY_INDEX(sender.selectedSegmentIndex);
    command.group = self.group;
    command.masterId = 0; // all hubs
    command.reserved1 = command.reserved2 = command.reserved3 = 0;
    
    NSData* data = [NSData dataWithBytes:&command length:sizeof(GroupOnOffCommand)];
    [peripheralDelegate sendData:data];
}

- (IBAction)editActionClicked {
    [peripheralDelegate editGroup:self.group];
}
@end
