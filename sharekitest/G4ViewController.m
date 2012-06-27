//
//  G4ViewController.m
//  sharekitest
//
//  Created by Dawen Rie on 12-5-19.
//  Copyright (c) 2012年 G4 Workshop. All rights reserved.
//

#import "G4ViewController.h"
#import "SHKTwitter.h"
#import "SHKSinaWeibo.h"
#import "SHKFacebook.h"

@interface G4ViewController ()

@end

@implementation G4ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(onSendSuccess)
                                                 name:@"SHKSendDidFinish"
                                               object:nil];
}
- (void)onSendSuccess {
    NSLog(@"send success notification");
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)onSharesClicked:(id)sender{
    UIImage *image = [UIImage imageNamed:@"test.png"];
    SHKItem *item = [SHKItem image:image title:@"一二三四五一二三四五一二三四五一二三四五一二三四五一二三四五一二三四五一二三四五一二三四五一二三四五"];
    item.URL = [NSURL URLWithString:@"http://www.g4next.com/loooooooooooooooooooooooooooooooooooooooooooooooooooooooong.link"];
    // 选择发送到那个SNS
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
	[actionSheet showInView:self.view];
}
- (IBAction)onShareTwitterClicked:(id)sender{
    SHKItem *item  = [SHKItem URL:[NSURL URLWithString:@"http://www.g4next.com/loooooooooooooooooooooooooooooooooooooooooooooooooooooooong"] title:@"又突破一万分！"];
    UIImage *image = [UIImage imageNamed:@"test.png"];
    item.image = image;
    // 直接发送到特定SNS
    [SHKSinaWeibo shareItem:item];
}


@end
