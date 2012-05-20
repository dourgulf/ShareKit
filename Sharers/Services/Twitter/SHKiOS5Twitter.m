//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 17.11.2011.
//  Copyright (c) 2011 Cocoa Miners. All rights reserved.
//

#import "SHKiOS5Twitter.h"
#import "SHK.h"
#import <Twitter/Twitter.h>
#import "SHKConfiguration.h"

@interface SHKiOS5Twitter ()

@property (retain) UIViewController *currentTopViewController;

- (void)callUI:(NSNotification *)notif;
- (void)presentUI;

@end

@implementation SHKiOS5Twitter

@synthesize currentTopViewController;

- (void)dealloc {
    
    [currentTopViewController release];
    [super dealloc];
}

+ (NSString *)sharerTitle
{
	return @"Twitter";
}

+ (NSString *)sharerId
{
	return @"SHKTwitter";
}

- (void)share {
    if (item.URL != nil) {
        [self shortenURL];
        //URL to be shortened on background thread, [super share] is called in callback method
    }
    else {
        [self show];
    }
}

- (void)show {
    if ([[SHK currentHelper] currentView]) { //user is sharing from SHKShareMenu    
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(callUI:) 
                                                     name:SHKHideCurrentViewFinishedNotification                                       
                                                   object:nil];
        [self retain];  //must retain, so that it is still around for SHKShareMenu hide callback. Menu hides asynchronously when sharer is chosen.
        
    } else {  
        
        [self presentUI];   
    }
}

- (BOOL)shortenURL
{	
	NSString *bitLyLogin = SHKCONFIG(bitLyLogin);
	NSString *bitLyKey = SHKCONFIG(bitLyKey);
	BOOL bitLyConfigured = [bitLyLogin length] > 0 && [bitLyKey length] > 0;
	
	if (bitLyConfigured == NO || ![SHK connected])
	{
		return YES;
	}
	
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Shortening URL...")];
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[NSMutableString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apikey=%@&longUrl=%@&format=txt",
																		  bitLyLogin,
																		  bitLyKey,																		  
																		  SHKEncodeURL(item.URL)
																		  ]]
											 params:nil
										   delegate:self
								 isFinishedSelector:@selector(shortenURLFinished:)
											 method:@"GET"
										  autostart:YES] autorelease];
    return NO;
}

- (void)shortenURLFinished:(SHKRequest *)aRequest
{
	[[SHKActivityIndicator currentIndicator] hide];
	
	NSString *result = [[aRequest getResult] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	if (result == nil || [NSURL URLWithString:result] == nil)
	{
		// TODO - better error message
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Shorten URL Error")
                                     message:SHKLocalizedString(@"We could not shorten the URL.")
                                    delegate:nil
                           cancelButtonTitle:SHKLocalizedString(@"Continue")
                           otherButtonTitles:nil] autorelease] show];
		result = [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	else
	{		
		///if already a bitly login, use url instead
		if ([result isEqualToString:@"ALREADY_A_BITLY_LINK"])
			result = [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
    item.URL = [NSURL URLWithString:result];
	
	[self show];
}

#pragma mark -

- (void)callUI:(NSNotification *)notif {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SHKHideCurrentViewFinishedNotification object:nil];
    [self presentUI];
    [self release]; //see share
}

- (void)presentUI {
    if ([self.item shareType] == SHKShareTypeUserInfo) {
        SHKLog(@"User info not possible to download on iOS5+. You can get Twitter enabled user info from Accounts framework");
        return;
    }
    
    TWTweetComposeViewController *iOS5twitter = [[TWTweetComposeViewController alloc] init];
    
    [iOS5twitter addImage:self.item.image];    
    [iOS5twitter addURL:self.item.URL];
    
    if (self.item.shareType == SHKShareTypeText) 
    {
        NSUInteger textLength = [item.text length] > 140 ? 140 : [item.text length];
        
        while ([iOS5twitter setInitialText:[item.text substringToIndex:textLength]] == NO && textLength > 0)
        {
            textLength--;
        }
    } 
    else 
    {
        NSUInteger titleLength = [item.title length] > 140 ? 140 : [item.title length];      
        
        while ([iOS5twitter setInitialText:[item.title substringToIndex:titleLength]] == NO && titleLength > 0)
        {
            titleLength--;
        }
    }
    
    iOS5twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) 
    {
         [self.currentTopViewController dismissViewControllerAnimated:YES completion:^{                                                                           
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SHKHideCurrentViewFinishedNotification object:nil];
            }];
        }];
        
        switch (result) {
                
            case TWTweetComposeViewControllerResultDone:
                [self sendDidFinish];
                break;
                
            case TWTweetComposeViewControllerResultCancelled:
                [self sendDidCancel];                
                
            default:
                break;
        }
    };   
    
    self.currentTopViewController = [[SHK currentHelper] rootViewForCustomUIDisplay];
    [self.currentTopViewController presentViewController:iOS5twitter animated:YES completion:nil];
    [iOS5twitter release];
}

@end
