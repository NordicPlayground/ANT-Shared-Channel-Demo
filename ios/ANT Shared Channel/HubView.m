//
//  HubImage.m
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

#import <CoreBluetooth/CoreBluetooth.h>
#import "HubView.h"
#import "NodeView.h"

@interface HubView () {
    GLfloat groupIconSize;
}
@property (nonatomic, strong) NSMutableArray* constraintsPortrait;
@property (nonatomic, strong) NSMutableArray* constraintsLandscape;
@end

@implementation HubView
@synthesize showTitles;
@synthesize hubId;
@synthesize nodes;
@synthesize constraintsPortrait;
@synthesize constraintsLandscape;
@synthesize peripheralDelegate;

- (instancetype) initWithHubId:(UInt16)_id showTitles: (BOOL)_show {
    self = [super init];
    if (self)
    {
        [self setImage:[UIImage imageNamed:@"dotBlack"] forState:UIControlStateNormal];
        [self setImage:[UIImage imageNamed:@"dotBlack"] forState:UIControlStateDisabled];
        [self setImage:[UIImage imageNamed:@"dotBlackHighlited"] forState:UIControlStateHighlighted];
        groupIconSize = self.imageView.image.size.width;
        
        self.hubId = _id;
        self.showTitles = _show;
        UIColor* color = _show ? [UIColor blackColor] : [UIColor clearColor];
        [self setTitleColor:color forState:UIControlStateNormal];
        [self setTitle:[NSString stringWithFormat:@"%04X", _id] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:12];
        
        self.nodes = [NSMutableArray arrayWithCapacity:6];
        self.constraintsPortrait = [NSMutableArray arrayWithCapacity:2];
        self.constraintsLandscape = [NSMutableArray arrayWithCapacity:2];
        
        [self addTarget:self action:@selector(hubClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}


-(void) hubClicked: (id) sender {
    uint8_t enabledCount = 0;
    for (int i = 0; i < nodes.count; ++i)
    {
        NodeView* node = nodes[i];
        if (node.selected)
            enabledCount++;
    }
    uint8_t opCode = enabledCount == 0 ? OP_CODE_PERI_ON : OP_CODE_PERI_OFF;
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
    command.sharedChannel = 0; // all nodes
    command.group = group;
    command.masterId = hubId;
    command.reserved1 = command.reserved2 = 0;
    
    NSData* data = [NSData dataWithBytes:(void*)&command length:sizeof(BasicCommand)];
    [peripheralDelegate sendData:data];
    
    // Check if the immediate response option is set. If so, change the nodes color immediately
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    if (!isInEditMode && [preferences boolForKey:@"immediateResponse"])
    {
        for (int i = 0; i < nodes.count; ++i)
        {
            NodeView* node = nodes[i];
            [node setSelected:enabledCount == 0];
        }
    }
    if (isInEditMode)
    {
        // This will set the hub disabled and mark all nodes orange and disabled
        [self setEnabled:NO];
    }
}

-(void)setEnabled:(BOOL)enabled {
    [super setEnabled:YES];
    
    // Enable or disable also all children
    for (int i = 0; i < nodes.count; ++i)
    {
        NodeView* node = nodes[i];
        [node setEnabled:enabled];
    }
}

-(void)setShowTitles:(BOOL)_showTitles {
    showTitles = _showTitles;
    UIColor* color = _showTitles ? [UIColor blackColor] : [UIColor clearColor];
    
    [self setTitleColor:color forState:UIControlStateNormal];
    
    for (int i = 0; i < nodes.count; ++i)
    {
        NodeView* node = nodes[i];
        [node setTitleColor:color forState:UIControlStateNormal];
    }
}

- (void) addHubNode:(UInt16)sharedChannel withState:(BOOL)enabled to:(UIView *)parent {
    NodeView* node = [[NodeView alloc] initWithNodeId:sharedChannel hub:self];
    node.peripheralDelegate = peripheralDelegate;
    
    UIColor* color = showTitles ? [UIColor blackColor] : [UIColor clearColor];
    [node setSelected:enabled];
    [node setTitleColor:color forState:UIControlStateNormal];
    [node setTitle:[NSString stringWithFormat:@"%d", node.nodeId] forState:UIControlStateNormal];
    node.titleLabel.font = [UIFont systemFontOfSize:12];
    
    [nodes addObject:node];
    [parent addSubview:node];
}

-(void)removeHubNode:(NodeView *)node {
    [nodes removeObject:node];
    [node removeFromSuperview];
    
    if (nodes.count > 0)
    {
        // Reposition all nodes
        [self repositionNodes];
    }
    else
    {
        // Remove this hub
        [peripheralDelegate removeHub:self];
    }
}

-(BOOL)updateHubNodeIfExists:(UInt16)sharedChannel withState:(BOOL)enabled {
    for (int i = 0; i < nodes.count; ++i)
    {
        NodeView* node = nodes[i];
        if (node.nodeId == sharedChannel)
        {
            [node setSelected:enabled];
            return YES;
        }
    }
    return NO;
}

-(void)repositionWithHubIndex:(int)index outOf:(unsigned long)count {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    UIView* parent = self.superview;
    
    [NSLayoutConstraint deactivateConstraints:constraintsPortrait];
    [NSLayoutConstraint deactivateConstraints:constraintsLandscape];
    [constraintsPortrait removeAllObjects];
    [constraintsLandscape removeAllObjects];
    
    if (count == 1)
    {
        // Center the hub in the parent view
        [constraintsPortrait addObject:[NSLayoutConstraint
                         constraintWithItem:self
                         attribute:NSLayoutAttributeLeft
                         relatedBy:NSLayoutRelationEqual
                         toItem:parent attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-groupIconSize / 2]];
    
        [constraintsPortrait addObject:[NSLayoutConstraint
                         constraintWithItem:self
                         attribute:NSLayoutAttributeCenterY
                         relatedBy:NSLayoutRelationEqual
                         toItem:parent attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-30]];
        [constraintsLandscape addObjectsFromArray:constraintsPortrait];
    }
    else
    {
        // Place hubs on a circle
        CGFloat x, y;
        x = sinf((float) index * 2.0f * M_PI / count) / 3 + 1.0f;
        y = cosf((float) index * 2.0f * M_PI / count) / 3 + 1.0f;
        
        [constraintsPortrait addObject:[NSLayoutConstraint
                                constraintWithItem:self
                                attribute:NSLayoutAttributeLeft
                                relatedBy:NSLayoutRelationEqual
                                toItem:parent attribute:NSLayoutAttributeCenterX multiplier:x constant:-groupIconSize / 2]];
        
        [constraintsPortrait addObject:[NSLayoutConstraint
                                constraintWithItem:self
                                attribute:NSLayoutAttributeCenterY
                                relatedBy:NSLayoutRelationEqual
                                        toItem:parent attribute:NSLayoutAttributeCenterY multiplier:y constant:-40]];
        [NSLayoutConstraint deactivateConstraints:constraintsPortrait];
        
        // In the landscape orientation we want to have hubs a little bit rotated (PI/count) so that they look better on narrow devices
        if (count % 2 == 0)
        {
            x = sinf(M_PI / count + index * 2.0f * M_PI / count) / 3 + 1.0f;
            y = cosf(M_PI / count + index * 2.0f * M_PI / count) / 3 + 1.0f;
        }
        [constraintsLandscape addObject:[NSLayoutConstraint
                                        constraintWithItem:self
                                        attribute:NSLayoutAttributeLeft
                                        relatedBy:NSLayoutRelationEqual
                                        toItem:parent attribute:NSLayoutAttributeCenterX multiplier:x constant:-groupIconSize / 2]];
        
        [constraintsLandscape addObject:[NSLayoutConstraint
                                        constraintWithItem:self
                                        attribute:NSLayoutAttributeCenterY
                                        relatedBy:NSLayoutRelationEqual
                                         toItem:parent attribute:NSLayoutAttributeCenterY multiplier:y constant:-30]];
        [NSLayoutConstraint deactivateConstraints:constraintsLandscape];
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) repositionNodes {
    for (int i = 0; i < nodes.count; ++i) {
        NodeView* node = nodes[i];
        
        [NSLayoutConstraint deactivateConstraints:node.nodeConstraints];
        [node.nodeConstraints removeAllObjects];
        
        CGFloat x, y;
        UInt8 R = 20 * ((nodes.count + 1) / 4) + 40;
        x = sinf((float) i * 2.0f * M_PI / nodes.count) * R;
        y = cosf((float) i * 2.0f * M_PI / nodes.count) * R;
        
        [node.nodeConstraints addObject:[NSLayoutConstraint
                                         constraintWithItem:node
                                         attribute:NSLayoutAttributeLeft
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:self
                                         attribute:NSLayoutAttributeLeft multiplier:1.0 constant:x]];
        
        [node.nodeConstraints addObject:[NSLayoutConstraint
                                         constraintWithItem:node
                                         attribute:NSLayoutAttributeCenterY
                                         relatedBy:NSLayoutRelationEqual
                                         toItem:self
                                         attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:y]];
        
        [NSLayoutConstraint activateConstraints:node.nodeConstraints];
     }
}

-(void)updateConstraints {
    [super updateConstraints];
    
    CGSize size = [self.superview frame].size;
    BOOL landscape = size.width > size.height;
    
    if (landscape)
    {
        [NSLayoutConstraint deactivateConstraints:constraintsPortrait];
        [NSLayoutConstraint activateConstraints:constraintsLandscape];
    }
    else
    {
        [NSLayoutConstraint deactivateConstraints:constraintsLandscape];
        [NSLayoutConstraint activateConstraints:constraintsPortrait];
    }
}

-(void)removeFromSuperview {
    // Remove this hub's constraints
    [NSLayoutConstraint deactivateConstraints:constraintsPortrait];
    [NSLayoutConstraint deactivateConstraints:constraintsLandscape];
    [constraintsPortrait removeAllObjects];
    [constraintsLandscape removeAllObjects];
    
    // Remove the view
    [super removeFromSuperview];
    
    // Remove also its nodes
    for (int i = 0; i < nodes.count; ++i)
    {
        NodeView* node = nodes[i];
        [NSLayoutConstraint deactivateConstraints:node.nodeConstraints];
        [node removeFromSuperview];
    }
    [nodes removeAllObjects];
}

@end
