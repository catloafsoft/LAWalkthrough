//  LAWalkthroughViewController.m
//  LAWalkthrough
//
//  Created by Larry Aasen on 4/11/13.
//
// Copyright (c) 2013 Larry Aasen (http://larryaasen.wordpress.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LAWalkthroughViewController.h"

@interface LAWalkthroughViewController () <UIScrollViewDelegate>
{
    NSMutableArray *_pageViews;
}

@property (nonatomic) UIImageView *backgroundImageView;
@property (nonatomic) UIButton *nextButton, *skipButton;

@end

@implementation LAWalkthroughViewController
{
    UIScrollView *_scrollView;
    UIPageControl *_pageControl;
    BOOL _pageControlUsed;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _pageViews = NSMutableArray.new;
        
        self.pageControlBottomMargin = 10;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.backgroundImageView];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    _scrollView.delegate = self;
    [self.view addSubview:_scrollView];
    
    _pageControl = [self createPageControl];
    [_pageControl addTarget:self
                     action:@selector(changePage)
           forControlEvents:UIControlEventValueChanged];
    _pageControl.currentPage = 0;
    [self.view addSubview:_pageControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.backgroundImage)
    {
        self.backgroundImageView.frame = self.view.frame;
        self.backgroundImageView.image = self.backgroundImage;
    }
    
    _scrollView.frame = self.view.frame;
    _scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * self.numberOfPages,
                                         _scrollView.frame.size.height);
    
    _pageControl.frame = self.pageControlFrame;
    _pageControl.numberOfPages = self.numberOfPages;
    
    BOOL useDefaultNextButton = !(self.nextButtonImage || self.nextButtonText);
    if (useDefaultNextButton)
    {
        self.nextButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        self.nextButton.frame = CGRectMake(0, 0, self.nextButton.frame.size.width+20, self.nextButton.frame.size.height);
    }
    else
    {
        self.nextButton = UIButton.new;
        CGRect buttonFrame = self.nextButton.frame;
        if (self.nextButtonText)
        {
            [self.nextButton setTitle:self.nextButtonText forState:UIControlStateNormal];
            self.nextButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
            buttonFrame.size = CGSizeMake(100, 36);
        }
        else if (self.nextButtonImage)
        {
            self.nextButton.imageView.image = self.nextButtonImage;
            buttonFrame.size = self.nextButtonImage.size;
        }
        self.nextButton.frame = buttonFrame;
    }
    CGRect buttonFrame = self.nextButton.frame;
    buttonFrame.origin = self.nextButtonOrigin;
    self.nextButton.frame = buttonFrame;
    [self.view addSubview:self.nextButton];
    [self.nextButton addTarget:self
                        action:@selector(displayNextPage)
              forControlEvents:UIControlEventTouchUpInside];
    
    // Add optional Skip button on the left
    if (self.completionHandler && self.skipButtonText) {
        self.skipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.skipButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        [self.skipButton setTitle:self.skipButtonText
                         forState:UIControlStateNormal];
        [self.skipButton addTarget:self
                            action:@selector(skipWalkthrough)
                  forControlEvents:UIControlEventTouchUpInside];
        self.skipButton.frame = CGRectMake(_pageControl.frame.origin.x, _pageControl.frame.origin.y, 100, 36);
        [self.view addSubview:self.skipButton];
    }
    
    [super viewWillAppear:animated];
}

- (CGRect)defaultPageFrame
{
    return self.view.frame;
}

- (UIView *)addPageWithBody:(NSString *)bodyText
{
    UIView *pageView = [self addPageWithView:nil];
    
    CGRect frame = pageView.frame;
    frame.origin = CGPointZero;
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.textColor = [UIColor lightGrayColor];
    label.font = [UIFont systemFontOfSize:22];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.autoresizesSubviews = YES;
    
    label.text = bodyText;
    
    [pageView addSubview:label];
    
    return pageView;
}

- (UIView *)addPageWithNibName:(NSString *)name bundle:(NSBundle *)bundleOrNil owner:(id)ownerOrNil
{
    UINib *nib = [UINib nibWithNibName:name bundle:bundleOrNil];
    NSArray *objects = [nib instantiateWithOwner:ownerOrNil options:nil];
    UIView *view = objects.lastObject;
    view.frame = self.view.frame;
    [self addPageWithView:view];
    
    return view;
}

- (UIView *)addPageWithView:(UIView *)pageView
{
    if (!pageView)
    {
        pageView = [[UIView alloc] initWithFrame:[self defaultPageFrame]];
        pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    // Move the view to its correct page location
    CGRect frame = pageView.frame;
    frame.origin.x = self.numberOfPages * _scrollView.frame.size.width;
    pageView.frame = frame;
    
    [_pageViews addObject:pageView];
    [_scrollView addSubview:pageView];
    return pageView;
}

- (void)displayNextPage
{
    _pageControl.currentPage++;
    [self changePage];
}

- (void)skipWalkthrough
{
    if (self.completionHandler) {
        self.completionHandler(self); // Executed only once
        self.completionHandler = nil;
    }
}

- (void)changePage
{
    NSInteger pageIndex = _pageControl.currentPage;
    
    // update the scroll view to the appropriate page
    CGRect frame = _scrollView.frame;
    frame.origin.x = frame.size.width * pageIndex;
    frame.origin.y = 0;
    [_scrollView scrollRectToVisible:frame animated:YES];
    
    _pageControlUsed = YES;
}

- (NSArray *)pages
{
    return [_pageViews copy];
}

// Used only by consumers
- (NSInteger)numberOfPages
{
    return _pageViews.count;
}

- (CGPoint)nextButtonOrigin
{
    return CGPointMake(_pageControl.frame.size.width - self.nextButton.frame.size.width, _pageControl.frame.origin.y);
}

- (CGRect)pageControlFrame
{
    CGSize pagerSize = [_pageControl sizeForNumberOfPages:self.numberOfPages];
    
    return CGRectMake(0,
                      _scrollView.frame.size.height - self.pageControlBottomMargin - pagerSize.height,
                      self.view.frame.size.width,
                      pagerSize.height);
}

- (UIPageControl *)createPageControl
{
    UIPageControl *pc = [[UIPageControl alloc] initWithFrame:CGRectZero];
    pc.hidesForSinglePage = YES;
    return pc;
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    CGFloat pageWidth = _scrollView.frame.size.width;
    int nextPage = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    // Hide the Next button when this is the last page
    self.nextButton.hidden = nextPage == (_pageControl.numberOfPages-1);
    
    if (_pageControlUsed)
    {
        return;
    }
    
    _pageControl.currentPage = nextPage;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _pageControlUsed = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _pageControlUsed = NO;
}

@end
