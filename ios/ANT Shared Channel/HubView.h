//
//  HubImage.h
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

#import <UIKit/UIKit.h>
#import "PeripheralControllerDelegate.h"

@class NodeView;

@interface HubView : UIButton

/*!
 * @brief The id (2 bytes) of the hub.
 */
@property (nonatomic, assign) UInt16 hubId;
@property (nonatomic, strong) NSMutableArray* nodes; // This array must contain NodeViews
@property (nonatomic, assign) BOOL showTitles;
@property (nonatomic, strong) id <PeripheralControllerDelegate> peripheralDelegate;

-(instancetype)initWithHubId: (UInt16) hubId showTitles: (BOOL) show;

/*!
 * @brief   Adds a new node to the hub. It will also add the node view to the parent UIView.
 */
-(void) addHubNode: (UInt16) sharedChannel withState:(BOOL)enabled to: (UIView*) parent;

/*!
 * @brief   Removes the node from the hub and from parent view.
 */
-(void) removeHubNode: (NodeView*) node;

/*!
 * @brief   Updated the node's state if a node with the given shared channel number was found as it's child. In that case it returns YES.
 *          If there is no node with given shared channel number this method returns NO.
 */
-(BOOL) updateHubNodeIfExists: (UInt16) sharedChannel withState:(BOOL) enabled;

/*!
 * @brief   The method will recreate layout constraints for all hubs. This method has to be called after a new hub was found
 *          or an old one removed.
 */
-(void) repositionWithHubIndex: (int) index outOf: (unsigned long) count;
/*!
 * @brief   This method will recreate layout constraints for all nodes belonging to this hub. This method has to be called after
 *          a new node has been added or an old one removed.
 */
-(void) repositionNodes;

@end
