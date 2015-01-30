//
//  PeripheralControllerDelegate.h
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

#import <Foundation/Foundation.h>

#define PAGE_COMMAND                    0x00 // outgoing message
#define PAGE_UPDATE                     0x03 // incoming report message

#define OP_CODE_REPORTING_MODE_OFF      0x00
#define OP_CODE_REPORTING_MPDE_ON       0x01
#define OP_CODE_REPORTING_MODE_WARNINGS 0x02 // not supported yet
#define OP_CODE_PERI_ON                 0x03
#define OP_CODE_PERI_OFF                0x04
#define OP_CODE_GROUP_ASSIGN            0x05
#define OP_CODE_GROUP_ON                0x06
#define OP_CODE_GROUP_OFF               0x07

#pragma pack(1)

typedef struct {
    uint8_t page;           // always PAGE_COMMAND
    uint8_t opCode;         // all but OP_CODE_GROUP_ON, OP_CODE_GROUP_OFF
    uint8_t sharedChannel;
    uint8_t group;
    uint16_t masterId;
    uint8_t reserved1;
    uint8_t reserved2;
} BasicCommand;

typedef struct {
    uint8_t page;           // always PAGE_COMMAND
    uint8_t opCode;         // OP_CODE_GROUP_ON or OP_CODE_GROUP_OFF
    uint8_t group;
    uint16_t masterId;
    uint8_t reserved1;
    uint8_t reserved2;
    uint8_t reserved3;
} GroupOnOffCommand;

#pragma options align=reset

@class HubView;

@protocol PeripheralControllerDelegate <NSObject>

/*!
 * @brief   Returns whether the peripheral has been selected.
 */
- (BOOL) isConnected;
/*!
 * @brief   Sends given data to the peripheral Control Point characteristic.
 * @param   data the data that will be sent
 */
- (void) sendData: (NSData*) data;
/*!
 * @brief   Sets the visibility of nodes' and hubs' labels.
 */
- (void) setShowIds: (BOOL) show;
/*!
 * @brief   Removes the given hub from the controller.
 */
- (void) removeHub: (HubView*) hub;
/*!
 * @brief   Enters the 'group edit mode'. Until the Done button is clicked user will be able to add nodes to the given group.
 */
- (void) editGroup: (UInt8) group;
/*!
 * @brief   Returns YES if the 'group editing mode' is enabled.
 */
- (BOOL) isEditingGroup;
/*!
 * @brief   Returns the group that is currently being edited. Use this method only when isEditingGroup: returns YES.
 */
- (UInt8) getGroupNumber;

@end
