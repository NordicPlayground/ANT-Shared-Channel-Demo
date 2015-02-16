//
//  NodeVIew.m
//  ANT Shared Channel
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

#import "NodeView.h"

// Each node has to be updated at least once every TIMEOUT seconds not to be removed from the view.
#define TIMEOUT 16.0f

@interface NodeView () {
    /// The last time a node got an update.
    NSTimeInterval lastUpadte;
    /// The timer is reset every time an update for the node will be received. When fired will remove the node from its parent.
    NSTimer* garbageCollectorTimer;
}

@property (nonatomic, weak) HubView* hub;
@end

@implementation NodeView
@synthesize nodeConstraints;
@synthesize peripheralDelegate;
@synthesize nodeId;
@synthesize hub;

-(instancetype) initWithNodeId: (UInt16) _id hub:(id)_hub{
    self = [super init];
    if (self)
    {
        [self setImage:[UIImage imageNamed:@"dotOff"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"dotOn"] forState:UIControlStateSelected];
        [self setImage:[UIImage imageNamed:@"dotHighlited"] forState:UIControlStateHighlighted];
        [self setImage:[UIImage imageNamed:@"dotDisabled"] forState:UIControlStateDisabled];
        [self setImage:[UIImage imageNamed:@"dotDisabled"] forState:UIControlStateDisabled | UIControlStateSelected];
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.nodeConstraints = [NSMutableArray arrayWithCapacity:4];
        self.nodeId = _id;
        self.hub = _hub;
        
        [self addTarget:self action:@selector(nodeClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

-(void) nodeClicked: (id) sender {
    uint8_t opCode = !self.selected ? OP_CODE_PERI_ON : OP_CODE_PERI_OFF;
    uint8_t group = 0; // default
    
    BOOL isInEditMode = [peripheralDelegate isEditingGroup];
    if (isInEditMode)
    {
        opCode = OP_CODE_GROUP_ASSIGN;
        group = [peripheralDelegate getGroupNumber];
    }
    
    BasicCommand command;
    command.page = PAGE_COMMAND;
    command.opCode = opCode;
    command.sharedChannel = nodeId;
    command.group = group;
    command.masterId = hub.hubId;
    command.reserved1 = command.reserved2 = 0;
    
    NSData* data = [NSData dataWithBytes:(void*)&command length:sizeof(BasicCommand)];
    [peripheralDelegate sendData:data];
    
    // Check if the immediate response option is set. If so, change the node color immediately
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    if (!isInEditMode && [preferences boolForKey:@"immediateResponse"])
    {
        [self setSelected:!self.selected];
    }
    if (isInEditMode)
    {
        // This will mark the node orange and disable it
        [self setEnabled:NO];
    }
}

-(void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    lastUpadte = [[NSDate date] timeIntervalSince1970];
    if (garbageCollectorTimer)
    {
        [garbageCollectorTimer invalidate];
        garbageCollectorTimer = nil;
    }
    garbageCollectorTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT target:self selector:@selector(removeNode:) userInfo:nil repeats:NO];
}

-(void)removeNode:(NSTimer*)timer {
    [timer invalidate];
    garbageCollectorTimer = nil;
    
    [hub removeHubNode:self];
}

-(void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    // If disabled run a timer that will enable it in a moment. This is just to let user know that the node was pressed by changing the color.
    if (!enabled)
    {
        [NSTimer scheduledTimerWithTimeInterval:0.7f target:self selector:@selector(reenableNode:) userInfo:nil repeats:YES];
    }
}

-(void)reenableNode:(NSTimer *)timer {
    [self setEnabled:YES];
}

@end
