//
//  SHKCustomFormControllerLargeTextField.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/28/10.

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

#import "SHKCustomFormControllerLargeTextField.h"


@implementation SHKCustomFormControllerLargeTextField

- (void)loadView 
{
	[super loadView];
    CGFloat imageSize = 100.0;
    CGRect textFrame = self.view.bounds;
	self.view.backgroundColor = [UIColor grayColor];
    
    // background image view
    UIImage *backgroundImage = [UIImage imageNamed:@"SHKLargeTextFieldBG.png"];
	UIImageView *backgroundView = [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
    [self.view addSubview:backgroundView];
    textFrame = backgroundView.bounds;

    textFrame.size.height -= imageSize;
    textFrame.size.width = textFrame.size.width*2.0/3.0;
	self.textView = [[[UITextView alloc] initWithFrame:textFrame] autorelease];
	self.textView.delegate = self;
	self.textView.font = [UIFont systemFontOfSize:15];
	self.textView.backgroundColor = [UIColor clearColor];	
    self.textView.editable = NO;
	[backgroundView addSubview:self.textView];
    
    if (self.image != nil) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];
        CGRect imageFrame;
        imageFrame.origin.x = textFrame.size.width;
        imageFrame.origin.y = textFrame.origin.y+10;
        imageFrame.size.width = 96;
        imageFrame.size.height = 96;
        imageView.frame = imageFrame;
        [self.view addSubview:imageView];
    }
}
- (void) viewDidLoad {
    [super viewDidLoad];
    CGRect textFrame = self.view.frame;
    NSLog(@"(%f,%f)", textFrame.size.width, textFrame.size.height);
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGRect textFrame = self.view.frame;
    NSLog(@"(%f,%f)", textFrame.size.width, textFrame.size.height);
}
@end
