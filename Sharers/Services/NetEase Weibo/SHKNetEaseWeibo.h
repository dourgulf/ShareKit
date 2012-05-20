//
//  SHKNetEaseWeibo.h
//  ShareKit
//
//  Created by icyleaf on 11-12-04.
//  Copyright 2011 icyleaf.com. All rights reserved.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"
#import "SHKFormControllerLargeTextField.h"


@interface SHKNetEaseWeibo : SHKOAuthSharer <SHKFormControllerLargeTextFieldDelegate>
{	
	BOOL xAuth;		
}

@property BOOL xAuth;
 
    
#pragma mark -
#pragma mark UI Implementation
    
- (void)showNetEaseWeiboForm;
    
#pragma mark -
#pragma mark Share API Methods
      
- (void)sendStatus;
- (void)sendStatusTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;

- (void)sendImage;
- (void)sendImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendImageTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;
    
- (void)followMe;
- (void)followMeTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)followMeTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;

@end
